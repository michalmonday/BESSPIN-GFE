// Copyright (c) 2016-2019 Bluespec, Inc. All Rights Reserved

package Boot_ROM;

// ================================================================
// This package implements a slave IP that is a RISC-V boot ROM of
// 1024 32b locations.
// - Ignores all writes, always responsing OKAY
// - Assumes all reads are 4-byte aligned requests for 4-bytes

// ================================================================

export Boot_ROM_IFC (..), mkBoot_ROM;

// ================================================================
// BSV library imports

import ConfigReg :: *;

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
// Include the auto-generated BSV-include file with the ROM function

`include  "fn_read_ROM.bsvi"

// ================================================================
// Interface

interface Boot_ROM_IFC;
   // set_addr_map should be called after this module's reset
   method Action set_addr_map (Fabric_Addr addr_base, Fabric_Addr addr_lim);

   // Main Fabric Reqs/Rsps
   interface AXI4_Slave_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) slave;
endinterface

// ================================================================

(* synthesize *)
module mkBoot_ROM (Boot_ROM_IFC);

   // Verbosity: 0: quiet; 1: reads/writes
   Integer verbosity = 0;

   Reg #(Bool) rg_module_ready <- mkReg (False);

   Reg #(Fabric_Addr)  rg_addr_base <- mkRegU;
   Reg #(Fabric_Addr)  rg_addr_lim  <- mkRegU;

   // ----------------
   // Connector to fabric

   AXI4_Slave_Xactor_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) slave_xactor <- mkAXI4_Slave_Xactor;

   // ----------------

   function Bool fn_addr_is_aligned (Fabric_Addr addr, AXI4_Size size);
      case (size)
	 axsize_8: return (addr [2:0] == 0);
	 axsize_4: return (addr [1:0] == 0);
	 axsize_2: return (addr [0] == 0);
	 axsize_1: return (True);
	 default:  return (False);
      endcase
   endfunction

   function Bool fn_addr_is_in_range (Fabric_Addr base, Fabric_Addr addr, Fabric_Addr lim);
      return ((base <= addr) && (addr < lim));
   endfunction

   function Bool fn_addr_is_ok (Fabric_Addr addr, AXI4_Size size, Fabric_Addr base, Fabric_Addr lim);
      return (   fn_addr_is_aligned (addr, size)
	      && fn_addr_is_in_range (base, addr, lim));
   endfunction

   // ================================================================
   // BEHAVIOR

   // ----------------------------------------------------------------
   // Handle fabric read requests

   rule rl_process_rd_req (rg_module_ready);
      let rda <- pop_o (slave_xactor.o_rd_addr);

      let byte_addr = (rda.araddr - rg_addr_base) & ~7; // rounded down to mod(8)
      Bit #(32) d0 = fn_read_ROM_0 (byte_addr);
      Bit #(32) d1 = fn_read_ROM_4 (byte_addr + 4);
      Bit #(64) data64 = { d1, d0 };

      AXI4_Resp  rresp  = axi4_resp_okay;
      if (! fn_addr_is_ok (rda.araddr, rda.arsize, rg_addr_base, rg_addr_lim)) begin
	 rresp = axi4_resp_slverr;
	 $display ("%0d: ERROR: Boot_ROM.rl_process_rd_req: unrecognized or misaligned addr",  cur_cycle);
	 $display ("    ", fshow (rda));
      end
      else if (valueOf (Wd_Data) == 32)
	 data64 = data64 >> (Bit#(8))'(extend({rda.araddr [2], 2'b0}) * 8);

      Bit #(Wd_Data) rdata  = truncate (data64);
      let rdr = AXI4_Rd_Data {rid:   rda.arid,
			      rdata: rdata,
			      rresp: rresp,
			      rlast: True,
			      ruser: rda.aruser};
      slave_xactor.i_rd_data.enq (rdr);

      if (verbosity > 0) begin
	 $display ("%0d: Boot_ROM.rl_process_rd_req: ", cur_cycle);
	 $display ("        ", fshow (rda));
	 $display ("     => ", fshow (rdr));
      end
   endrule

   // ----------------------------------------------------------------
   // Handle fabric write requests: ignore all of them (this is a ROM)

   rule rl_process_wr_req (rg_module_ready);
      let wra <- pop_o (slave_xactor.o_wr_addr);
      let wrd <- pop_o (slave_xactor.o_wr_data);

      AXI4_Resp  bresp = axi4_resp_okay;
      if (! fn_addr_is_ok (wra.awaddr, wra.awsize, rg_addr_base, rg_addr_lim)) begin
	 bresp = axi4_resp_slverr;
	 $display ("%0d: ERROR: Boot_ROM.rl_process_wr_req: unrecognized addr",  cur_cycle);
	 $display ("    ", fshow (wra));
      end

      let wrr = AXI4_Wr_Resp {bid:   wra.awid,
			      bresp: bresp,
			      buser: wra.awuser};
      slave_xactor.i_wr_resp.enq (wrr);

      if (verbosity > 0) begin
	 $display ("%0d: Boot_ROM.rl_process_wr_req; ignoring all writes", cur_cycle);
	 $display ("        ", fshow (wra));
	 $display ("        ", fshow (wrd));
	 $display ("     => ", fshow (wrr));
      end
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
	 $display ("%0d: Boot_ROM.set_addr_map: base 0x%0h lim 0x%0h", cur_cycle, addr_base, addr_lim);
      end
   endmethod

   // Main Fabric Reqs/Rsps
   interface  slave = slave_xactor.axi_side;
endmodule

// ================================================================

endpackage
