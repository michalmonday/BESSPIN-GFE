// Copyright (c) 2013-2019 Bluespec, Inc. All Rights Reserved.

package Top_HW_Side;

// ================================================================
// mkTop_HW_Side is the top-level system for simulation.
// mkMem_Model is a memory model.

// **** CAVEAT FOR IVERILOG USERS: The 'C_Imports' sections below are
// disabled for IVerilog until we find a clean solution.  They depend
// on imported C which is non-trivial in IVerilog because IVerilog
// still depends on the older Verilog VPI standard instead of the
// newer DPI-C standard.  C-imported functions are used for:
//     UART input polling and character-reading
//     Writing tandem-verfication encoded trace data

// (Note: UART output does not depend on C-imported functions and so
// will work ok even in IVerilog)

// ================================================================
// BSV lib imports

import GetPut       :: *;
import ClientServer :: *;
import Connectable  :: *;
import Clocks       :: *;

// ----------------
// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;

// ================================================================
// Project imports

import SoC_Top        :: *;
import Mem_Controller :: *;
import Mem_Model      :: *;
import Fabric_Defs    :: *;
import P_Core :: *;
import PLIC :: *;

`ifndef IVERILOG
import C_Imports      :: *;
`endif

`ifdef INCLUDE_GDB_CONTROL
import External_Control :: *;
`endif

// ================================================================
// Top-level module.
// Instantiates the SoC.
// Instantiates a memory model.

(* synthesize *)
module mkTop_HW_Side (Empty) ;
   let clk <- exposeCurrentClock;
   let sysRst_Ifc <- mkReset(2, True, clk);
   let systemReset = sysRst_Ifc.new_rst;

   SoC_Top_IFC    soc_top   <- mkSoC_Top(reset_by systemReset);
   Mem_Model_IFC  mem_model <- mkMem_Model(reset_by systemReset);

   rule rl_soft_reset (soc_top.assert_soft_reset);
      sysRst_Ifc.assertReset();
   endrule

   // Connect SoC to raw memory
   let memCnx <- mkConnection (soc_top.to_raw_mem, mem_model.mem_server,
			       reset_by systemReset);

   // ================================================================
   // BEHAVIOR

   Reg #(Bool) rg_banner_printed <- mkReg (False, reset_by systemReset);

   // Display a banner
   rule rl_step0 (! rg_banner_printed);
      $display ("================================================================");
      $display ("Bluespec RISC-V standalone system simulation v1.2");
      $display ("Copyright (c) 2017-2019 Bluespec, Inc. All Rights Reserved.");
      $display ("================================================================");

      rg_banner_printed <= True;

      // Set CPU verbosity and logdelay (simulation only)
      Bool v1 <- $test$plusargs ("v1");
      Bool v2 <- $test$plusargs ("v2");
      Bit #(4)  verbosity = ((v2 ? 2 : (v1 ? 1 : 0)));
      Bit #(64) logdelay  = 0;    // # of instructions after which to set verbosity
      soc_top.set_verbosity  (verbosity, logdelay);

      // ----------------
      // Load tohost addr from symbol-table file
`ifndef IVERILOG
      // Note: see 'CAVEAT FOR IVERILOG USERS' above
      Bool watch_tohost <- $test$plusargs ("tohost");
      let tha <- c_get_symbol_val ("tohost");
      Fabric_Addr tohost_addr = truncate (tha);
      $display ("INFO: watch_tohost = %0d, tohost_addr = 0x%0h",
		pack (watch_tohost), tohost_addr);
      soc_top.set_watch_tohost (watch_tohost, tohost_addr);
`endif

      // ----------------
      // Open file for Tandem Verification trace output
`ifdef INCLUDE_TANDEM_VERIF
`ifndef IVERILOG
      // Note: see 'CAVEAT FOR IVERILOG USERS' above
      let success <- c_trace_file_open ('h_AA);
      if (success == 0) begin
	 $display ("ERROR: Top_HW_Side.rl_step0: error opening trace file.");
	 $display ("    Aborting.");
	 $finish (1);
      end
      else
	 $display ("Top_HW_Side.rl_step0: opened trace file.");
`else
      $display ("Warning: tandem verification output logs not available in IVerilog");
`endif
`endif

      // ----------------
      // Open connection to remote debug client
`ifdef INCLUDE_GDB_CONTROL
`ifndef JTAG_TAP
`ifndef IVERILOG
      // Note: see 'CAVEAT FOR IVERILOG USERS' above
      let dmi_status <- c_debug_client_connect (dmi_default_tcp_port);
      if (dmi_status != dmi_status_ok) begin
	 $display ("ERROR: Top_HW_Side.rl_step0: error opening debug client connection.");
	 $display ("    Aborting.");
	 $finish (1);
      end
`else
      $display ("Warning: Debug client connection not available in IVerilog");
`endif
`endif
`endif
   endrule

   // ================================================================
   // Tandem verifier: drain and output vectors of bytes

`ifdef INCLUDE_TANDEM_VERIF
   rule rl_tv_vb_out;
      let tv_info <- soc_top.tv_verifier_info_get.get;
      let n  = tv_info.num_bytes;
      let vb = tv_info.vec_bytes;
`ifndef IVERILOG
      Bit #(32) success = 1;

      for (Bit #(32) j = 0; j < fromInteger (valueOf (TV_VB_SIZE)); j = j + 8) begin
	 Bit #(64) w64 = { vb [j+7], vb [j+6], vb [j+5], vb [j+4], vb [j+3], vb [j+2], vb [j+1], vb [j] };
	 let success1 <- c_trace_file_load_word64_in_buffer (j, w64);
      end

      if (success == 0)
	 $display ("ERROR: Top_HW_Side.rl_tv_vb_out: error loading %0d bytes into buffer", n);
      else begin
	 // Send the data
	 success <- c_trace_file_write_buffer (n);
	 if (success == 0)
	    $display ("ERROR: Top_HW_Side.rl_tv_vb_out: error writing out bytevec data buffer (%0d bytes)", n);
      end

      if (success == 0) begin
	 $finish (1);
      end
`endif
   endrule
`endif

   // ================================================================
   // UART console I/O

   // Relay system console output to terminal

   rule rl_relay_console_out;
      let ch <- soc_top.get_to_console.get;
      $write ("%c", ch);
      $fflush (stdout);
   endrule

   // Poll terminal input and relay any chars into system console input.
   // Note: rg_console_in_poll is used to poll only every N cycles, whenever it wraps around to 0.
   // Note: see 'CAVEAT FOR IVERILOG USERS' above for why this is ifdef'd out for iVerilog users.

`ifndef IVERILOG

   Reg #(Bit #(12)) rg_console_in_poll <- mkReg (0);

   rule rl_relay_console_in;
      if (rg_console_in_poll == 0) begin
	 Bit #(8) ch <- c_trygetchar (?);
	 if (ch != 0) begin
	    soc_top.put_from_console.put (ch);
	    /*
	    $write ("%0d: Top_HW_Side.bsv.rl_relay_console: ch = 0x%0h", cur_cycle, ch);
	    if (ch >= 'h20) $write (" ('%c')", ch);
	    $display ("");
	    */
	 end
      end
      rg_console_in_poll <= rg_console_in_poll + 1;
   endrule

`endif

   /*
   // ================================================================
   // Interaction with remote debug client
   */

   // ================================================================
   // INTERFACE

   //  None (this is top-level)

endmodule

// ================================================================

endpackage: Top_HW_Side
