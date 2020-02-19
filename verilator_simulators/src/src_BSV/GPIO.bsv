// Copyright (c) 2016-2019 Bluespec, Inc. All Rights Reserved

package GPIO;

// ================================================================
// This package implements a Gpio IP that is a ROM of
// 1024 32b locations.
// - Ignores all writes, always responsing OKAY
// - Assumes all reads are 4-byte aligned requests for 4-bytes

// ================================================================

export Gpio_IFC (..), mkGpio;

// ================================================================
// Address for soft reset

Fabric_Addr rESET_ADDR = 'h_6FFF_0000;

// ================================================================
// BSV library imports

import ConfigReg :: *;
import Clocks    :: *;

// ----------------
// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;
import Semi_FIFOF :: *;

// ================================================================
// Project imports

import AXI4_Types  :: *;
import Fabric_Defs :: *;

// ================================================================
// Interface

interface Gpio_IFC;
   // set_addr_map should be called after this module's reset
   method Action set_addr_map (Fabric_Addr addr_base, Fabric_Addr addr_lim);

   // Main Fabric Reqs/Rsps
   interface AXI4_Slave_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) slave;

   method Bool assert_soft_reset;
`ifdef INCLUDE_TANDEM_VERIF
   method Bit#(2) tv_switch;
`endif
endinterface

// ================================================================

(* synthesize *)
module mkGpio (Gpio_IFC);

   // Verbosity: 0: quiet; 1: reads/writes
   Integer verbosity = 1;

   Reg #(Bool) rg_module_ready <- mkReg (False);

   Reg #(Fabric_Addr)  rg_addr_base <- mkRegU;
   Reg #(Fabric_Addr)  rg_addr_lim  <- mkRegU;

   // ----------------
   // Connector to fabric

   AXI4_Slave_Xactor_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) slave_xactor <- mkAXI4_Slave_Xactor;

   // ----------------

   function Bool fn_addr_is_aligned (Fabric_Addr addr);
      if (valueOf (Wd_Data) == 32)
	 return (addr [1:0] == 2'b_00);
      else if (valueOf (Wd_Data) == 64)
	 return (addr [2:0] == 3'b_000);
      else
	 return False;
   endfunction

   function Bool fn_addr_is_in_range (Fabric_Addr base, Fabric_Addr addr, Fabric_Addr lim);
      return ((base <= addr) && (addr < lim));
   endfunction

   function Bool fn_addr_is_ok (Fabric_Addr base, Fabric_Addr addr, Fabric_Addr lim);
      return (   fn_addr_is_aligned (addr)
	      && fn_addr_is_in_range (base, addr, lim));
   endfunction

   // ================================================================
   // BEHAVIOR

   // ----------------------------------------------------------------
   // Handle fabric read requests

   rule rl_process_rd_req (rg_module_ready);
      let rda <- pop_o (slave_xactor.o_rd_addr);

      let byte_addr = rda.araddr - rg_addr_base;

      AXI4_Resp  rresp  = axi4_resp_slverr;
      $display ("%0d: ERROR: GPIO.rl_process_rd_req: reads not allowed in this version",  cur_cycle);

      let rdr = AXI4_Rd_Data {rid:   rda.arid,
			      rdata: 0,
			      rresp: rresp,
			      rlast: True,
			      ruser: rda.aruser};
      slave_xactor.i_rd_data.enq (rdr);
   endrule

   // ----------------------------------------------------------------
   // Handle fabric write requests: ignore all except rESET_ADDR

   Reg#(Bool) rg_assertReset <- mkReg(False);
   Reg#(Bit#(2)) rg_tvswitch <- mkReg(0);

   rule rl_process_wr_req (rg_module_ready);
      let wra <- pop_o (slave_xactor.o_wr_addr);
      let wrd <- pop_o (slave_xactor.o_wr_data);

      AXI4_Resp  bresp = axi4_resp_okay;
      if (! fn_addr_is_ok (rg_addr_base, wra.awaddr, rg_addr_lim)) begin
	 bresp = axi4_resp_slverr;
	 $display ("%0d: ERROR: GPIO.rl_process_wr_req: unrecognized addr",  cur_cycle);
	 $display ("    ", fshow (wra));
      end

      let wrr = AXI4_Wr_Resp {bid:   wra.awid,
			      bresp: bresp,
			      buser: wra.awuser};
      slave_xactor.i_wr_resp.enq (wrr);

      if (verbosity > 0) begin
	 $display ("%0d: GPIO.rl_process_wr_req:", cur_cycle);
	 $display ("        ", fshow (wra));
	 $display ("        ", fshow (wrd));
	 $display ("     => ", fshow (wrr));
      end

      if (bresp == axi4_resp_okay
	  && wra.awaddr == rESET_ADDR)
	 if (wrd.wdata == 1)
	    begin
	       rg_assertReset <= True; //assert reset
	       $display ("%0d: ASSERTING SOFT RESET!",  cur_cycle);
	    end
         else rg_tvswitch <= truncate(wrd.wdata >> 8);
   endrule

   // ================================================================
   // INTERFACE

   // set_addr_map should be called after this module's reset
   method Action  set_addr_map (Fabric_Addr addr_base, Fabric_Addr addr_lim);
      if (valueOf (Wd_Data) == 32) begin
	 if (addr_base [1:0] != 0)
	    $display ("%0d: WARNING: Boot_ROM.set_addr_map: addr_base 0x%0h is not 4-Byte-aligned",
		      cur_cycle, addr_base);

	 if (addr_lim [1:0] != 0)
	    $display ("%0d: WARNING: Boot_ROM.set_addr_map: addr_lim 0x%0h is not 4-Byte-aligned",
		      cur_cycle, addr_lim);
      end
      else if (valueOf (Wd_Data) == 64) begin
	 if (addr_base [2:0] != 0)
	    $display ("%0d: WARNING: Boot_ROM.set_addr_map: addr_base 0x%0h is not 4-Byte-aligned",
		      cur_cycle, addr_base);

	 if (addr_lim [2:0] != 0)
	    $display ("%0d: WARNING: Boot_ROM.set_addr_map: addr_lim 0x%0h is not 4-Byte-aligned",
		      cur_cycle, addr_lim);
      end

      rg_addr_base    <= addr_base;
      rg_addr_lim     <= addr_lim;
      rg_module_ready <= True;
      if (verbosity > 0) begin
	 $display ("%0d: GPIO.set_addr_map: base 0x%0h lim 0x%0h", cur_cycle, addr_base, addr_lim);
      end
   endmethod

   // Main Fabric Reqs/Rsps
   interface  slave = slave_xactor.axi_side;

   method assert_soft_reset = rg_assertReset;
`ifdef INCLUDE_TANDEM_VERIF
   method tv_switch = rg_tvswitch;
`endif
endmodule

// ================================================================

endpackage
