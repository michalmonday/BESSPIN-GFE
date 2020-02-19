// Copyright (c) 2016-2019 Bluespec, Inc. All Rights Reserved.

package SoC_Top;

// ================================================================
// This package is the SoC "top-level".

// (Note: there will be further layer(s) above this for
//    simulation top-level, FPGA top-level, etc.)

// ================================================================
// Exports

export SoC_Top_IFC (..), mkSoC_Top;

// ================================================================
// BSV library imports

import FIFOF         :: *;
import GetPut        :: *;
import ClientServer  :: *;
import Connectable   :: *;
import Memory        :: *;
import Clocks        :: *;

// ----------------
// BSV additional libs

import Cur_Cycle   :: *;
import GetPut_Aux  :: *;
import AXI4_Stream :: *;
import Semi_FIFOF  :: *;

// ================================================================
// Project imports

// Main fabric
import AXI4_Types     :: *;
import AXI4_Fabric    :: *;
import AXI4_Deburster :: *;

import Fabric_Defs :: *;
import SoC_Map_Veril     :: *;
import SoC_Fabric  :: *;

// SoC components (CPU, mem, and IPs)

import P_Core        :: *;

import Boot_ROM       :: *;
import Mem_Controller :: *;
import UART_Model     :: *;
import Flash          :: *;
import GPIO           :: *;
import SVF_Bridge     :: *;

import JtagTap ::*;
import Giraffe_IFC ::*;

`ifdef INCLUDE_ACCEL0
import AXI4_Accel_IFC :: *;
import AXI4_Accel     :: *;
`endif

// ================================================================
// Local types and constants

typedef enum {SOC_START, SOC_IDLE, SOC_RESETTING} SoC_State
deriving (Bits, Eq, FShow);

// ================================================================
// The outermost interface of the SoC

interface SoC_Top_IFC;
   // Set core's verbosity
   method Action  set_verbosity (Bit #(4)  verbosity, Bit #(64)  logdelay);

`ifdef INCLUDE_TANDEM_VERIF
   // To tandem verifier
   interface Get #(Info_CPU_to_Verifier) tv_verifier_info_get;
`endif

   // External real memory
   interface MemoryClient #(Bits_per_Raw_Mem_Addr, Bits_per_Raw_Mem_Word)  to_raw_mem;

   // UART0 to external console
   interface Get #(Bit #(8)) get_to_console;
   interface Put #(Bit #(8)) put_from_console;

   // soft reset
   method Bool assert_soft_reset;

   // For ISA tests: watch memory writes to <tohost> addr
   method Action set_watch_tohost (Bool  watch_tohost, Fabric_Addr  tohost_addr);
endinterface

// ================================================================
// The module

(* synthesize *)
module mkSoC_Top (SoC_Top_IFC);
   Integer verbosity = 0;    // Normally 0; non-zero for debugging

   Reg #(SoC_State) rg_state <- mkReg (SOC_START);

   // SoC address map specifying base and limit for memories, IPs, etc.
   SoC_Map_Veril_IFC soc_map_veril <- mkSoC_Map_Veril;

   // We keep the processor in reset until after rg_state has become SOC_IDLE:
   Reg#(Bool) cpu_initial_reset <- mkReg(True);
   let clk <- exposeCurrentClock;
   let cpu_reset <- mkReset(2, True, clk);
   rule assert_cpu_reset_rl (cpu_initial_reset || rg_state == SOC_RESETTING);
      cpu_reset.assertReset();
      if (rg_state == SOC_RESETTING) cpu_initial_reset <= False;
   endrule

   // Core: As produced by src_SSITH_Px (mk_Px_Core)
   P_Core_IFC  core <- mkP_Core(reset_by cpu_reset.new_rst);

   // Mock SVF Bridge
   let aclk <- exposeCurrentClock;
   let arstn <- exposeCurrentReset;
   let svfBridge <- mkSVF_Bridge(aclk, arstn);

   Fabric_AXI4_IFC  fabric <- mkFabric_AXI4;

   // SoC Boot ROM
   Boot_ROM_IFC  boot_rom <- mkBoot_ROM;
   // AXI4 Deburster in front of Boot_ROM
   AXI4_Deburster_IFC #(Wd_Id,
			Wd_Addr,
			Wd_Data,
			Wd_User) boot_rom_axi4_deburster <- mkAXI4_Deburster;

   // SoC Flash
   Flash_IFC flash <- mkFlash;
   // AXI4 Deburster in front of Flash
   AXI4_Deburster_IFC #(Wd_Id,
			Wd_Addr,
			Wd_Data,
			Wd_User) flash_axi4_deburster <- mkAXI4_Deburster;

   // GPIO (for soft reset)
   Gpio_IFC gpio <- mkGpio;

   // SoC Memory
   Mem_Controller_IFC  mem0_controller <- mkMem_Controller;
   // AXI4 Deburster in front of SoC Memory
   AXI4_Deburster_IFC #(Wd_Id,
			Wd_Addr,
			Wd_Data,
			Wd_User) mem0_controller_axi4_deburster <- mkAXI4_Deburster;

   // SoC IPs
   UART_IFC   uart0  <- mkUART;

`ifdef INCLUDE_ACCEL0
   // Accel0 master to fabric
   AXI4_Accel_IFC  accel0 <- mkAXI4_Accel;
`endif

   // ----------------
   // SoC fabric master connections
   // Note: see 'SoC_Map_Veril' for 'master_num' definitions

   // CPU IMem master to fabric
   mkConnection (core.master0,  fabric.v_from_masters [imem_master_num]);

   // CPU DMem master to fabric
   mkConnection (core.master1,  fabric.v_from_masters [dmem_master_num]);

`ifdef INCLUDE_ACCEL0
   // accel_aes0 to fabric
   mkConnection (accel0.master,  fabric.v_from_masters [accel0_master_num]);
`endif

   // ----------------
   // SoC fabric slave connections
   // Note: see 'SoC_Map_Veril' for 'slave_num' definitions

   // Fabric to Boot ROM
   mkConnection (fabric.v_to_slaves [boot_rom_slave_num], boot_rom_axi4_deburster.from_master);
   mkConnection (boot_rom_axi4_deburster.to_slave,        boot_rom.slave);

   // Fabric to Mem Controller
   mkConnection (fabric.v_to_slaves [mem0_controller_slave_num], mem0_controller_axi4_deburster.from_master);
   mkConnection (mem0_controller_axi4_deburster.to_slave,        mem0_controller.slave);

   // Fabric to UART0
   mkConnection (fabric.v_to_slaves [uart0_slave_num],           uart0.slave);

`ifdef INCLUDE_ACCEL0
   // Fabric to accel0
   mkConnection (fabric.v_to_slaves [accel0_slave_num], accel0.slave);
`endif

   // Fabric to Flash
   mkConnection (fabric.v_to_slaves [flash_slave_num],    flash_axi4_deburster.from_master);
   mkConnection (flash_axi4_deburster.to_slave,           flash.slave);

   // Fabric to GPIO
   mkConnection (fabric.v_to_slaves [gpio_slave_num],          gpio.slave);
`ifdef INCLUDE_TANDEM_VERIF
   mkConnection (gpio.tv_switch, svfBridge.tv_switch);
`endif
   // ----------------
   // Connect interrupt sources for CPU external interrupt request inputs.

   (* fire_when_enabled, no_implicit_conditions *)
   rule rl_connect_external_interrupt_requests;
      Bit#(N_External_Interrupt_Sources) intr = 0;
      // UART
      intr[irq_num_uart16550_0] = pack(uart0.intr);
`ifdef INCLUDE_ACCEL0
      intr[irq_num_accel0] = pack(accel0.interrupt_req);
`endif
      core.interrupt_reqs (intr);
   endrule

`ifdef INCLUDE_TANDEM_VERIF
   mkConnection(core.tv_verifier_info_tx, svfBridge.axi_in);
`endif

   // ================================================================
   // RESET BEHAVIOR WITHOUT DEBUG MODULE

   rule rl_reset_start_2 (rg_state == SOC_START);
      mem0_controller.server_reset.request.put (?);
      uart0.server_reset.request.put (?);

      fabric.reset;
      rg_state <= SOC_RESETTING;

      $display ("%0d: SoC_Top. Reset start ...", cur_cycle);
   endrule

   // ================================================================
   // BEHAVIOR WITH DEBUG MODULE

   // In this version, SoC_Top can't see the debug module.

`ifdef INCLUDE_GDB_CONTROL
`ifdef ACTUAL_GDB
   // Instantiate JTAG TAP controller,
   // connect to core.dm_dmi;
   // and export its JTAG interface
`ifdef JTAG_TAP
   let sim_jtag <- mkSimJtag(core.jtag.tclk_out);
   mkConnection(core.jtag, sim_jtag);
`endif
`endif
`endif

   rule rl_reset_complete (rg_state == SOC_RESETTING);
      let mem0_controller_rsp <- mem0_controller.server_reset.response.get;
      let uart0_rsp           <- uart0.server_reset.response.get;

      // Initialize address maps of slave IPs
      boot_rom.set_addr_map (soc_map_veril.m_boot_rom_addr_base,
			     soc_map_veril.m_boot_rom_addr_lim);

      mem0_controller.set_addr_map (soc_map_veril.m_ddr4_0_uncached_addr_base,
				    soc_map_veril.m_ddr4_0_cached_addr_lim);

      uart0.set_addr_map (soc_map_veril.m_uart16550_0_addr_base, soc_map_veril.m_uart16550_0_addr_lim);

      flash.set_addr_map (soc_map_veril.m_flash_mem_addr_base,
			     soc_map_veril.m_flash_mem_addr_lim);

      gpio.set_addr_map (soc_map_veril.m_gpio_0_addr_base,
			     soc_map_veril.m_gpio_0_addr_lim);

`ifdef INCLUDE_ACCEL0
      accel0.init (fabric_default_id,
		   soc_map_veril.m_accel0_addr_base,
		   soc_map_veril.m_accel0_addr_lim);
`endif

      rg_state <= SOC_IDLE;
      $display ("%0d: SoC_Top. Reset complete ...", cur_cycle);

      if (verbosity != 0) begin
	 $display ("  SoC address map:");
	 $display ("  Boot ROM:        0x%0h .. 0x%0h",
		   soc_map_veril.m_boot_rom_addr_base,
		   soc_map_veril.m_boot_rom_addr_lim);
	 $display ("  Mem0 Controller: 0x%0h .. 0x%0h",
		   soc_map_veril.m_ddr4_0_cached_addr_base,
		   soc_map_veril.m_ddr4_0_cached_addr_lim);
	 $display ("  UART0:           0x%0h .. 0x%0h",
		   soc_map_veril.m_uart16550_0_addr_base,
		   soc_map_veril.m_uart16550_0_addr_lim);
	 $display ("  Flash:           0x%0h .. 0x%0h",
		   soc_map_veril.m_flash_mem_addr_base,
		   soc_map_veril.m_flash_mem_addr_lim);
	 $display ("  Gpio:           0x%0h .. 0x%0h",
		   soc_map_veril.m_gpio_0_addr_base,
		   soc_map_veril.m_gpio_0_addr_lim);
`ifdef INCLUDE_ACCEL0
	 $display ("  Accel:          0x%0h .. 0x%0h",
		   soc_map_veril.m_accel0_addr_base,
		   soc_map_veril.m_accel0_addr_lim);
`endif
      end
   endrule

   // ================================================================
   // INTERFACE

   method Action  set_verbosity (Bit #(4)  verbosity, Bit #(64)  logdelay);
      noAction; // for now
   endmethod

`ifdef INCLUDE_TANDEM_VERIF
   // To tandem verifier
   interface Get tv_verifier_info_get;
      method get () if (False);
	 actionvalue
	    return ?;
	 endactionvalue
      endmethod
   endinterface
`endif

   // External real memory
   interface to_raw_mem = mem0_controller.to_raw_mem;

   // UART to external console
   interface get_to_console   = uart0.get_to_console;
   interface put_from_console = uart0.put_from_console;

   // soft reset
   method assert_soft_reset = gpio.assert_soft_reset;

   // For ISA tests: watch memory writes to <tohost> addr
   method Action set_watch_tohost (Bool  watch_tohost, Fabric_Addr  tohost_addr);
      mem0_controller.set_watch_tohost (watch_tohost, tohost_addr);
   endmethod
endmodule: mkSoC_Top

// ================================================================

endpackage
