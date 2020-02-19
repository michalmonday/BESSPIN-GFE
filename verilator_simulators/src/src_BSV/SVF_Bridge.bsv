package SVF_Bridge;  // Mock TCP version

import AXI4_Stream ::*;
import PCIE ::*;
import FIFO::*;
import FIFOF::*;
import Vector           ::*;
import BuildVector      ::*;
import Gearbox           ::*;
import Reserved          ::*;
import SpecialFIFOs      ::*;
import GetPut ::*;
import ClientServer ::*;
import TieOff ::*;
import Connectable ::*;
import DefaultValue ::*;
import BRAMFIFO          ::*;
import BlueNoC  ::*;
import SceMi ::*;
import SceMiNoC ::*;
import Clocks ::*;
import TV_Info ::*;
//import TCPtoBNoCBridgeMock ::*;
// ================================================================
// TV AXI4 Stream Parameters (must match those in P2_Core.bsv)

typedef SizeOf #(Info_CPU_to_Verifier)Wd_SData;
typedef 0 Wd_SDest;
typedef 0 Wd_SUser;
typedef 0 Wd_SId;

typedef 4 BPB;

typedef Bit#(8) Byte;
// ================================================================

(* always_ready, always_enabled *)
interface PCIE_Connector_Ifc;
   // Towards SSITH Core:
   interface AXI4_Stream_Slave_IFC #(Wd_SId, Wd_SDest, Wd_SData, Wd_SUser) axi_in;
   // Towards gfe_system:
`ifdef INCLUDE_TANDEM_VERIF
   (*prefix=""*) method Action tv_switch((* port="tvswitch" *) Bit#(2) x);
`endif
   //interface Clock axi_clk; -- these two supplied as arguments to instance
   //interface Reset axi_rstn;
endinterface

// -------------------------

(*synthesize*)
(*no_default_clock, no_default_reset*)
// Largely derived from SceMiVirtexUltraScalePCIE.bsv
module mkSVF_Bridge #(Clock aclk,
		      Reset aresetn
		      ) (PCIE_Connector_Ifc);
   let aresetAsserted <- isResetAssertedDirect( clocked_by aclk, reset_by aresetn );

   // Build the PCIe-to-NoC bridge
   TCPtoBNoC#(BPB) bridge   <- mkTCPtoBNoC( clocked_by aclk, reset_by aresetn ); // clocked_by epClock125, reset_by epReset125 );

   // Initialize bridge
   rule initializeBridge;
      let b <- bridge.listen('h357B);
      if (!b) begin
	 $display("Couldn't listen!");
      end
   endrule

   // Tie off noc's source (not required)
   mkTieOff(bridge.noc.out);

   // Provide traces to noc's sink
   FIFOF#(MsgBeat#(BPB)) beatFF <- mkFIFOF( clocked_by aclk, reset_by aresetn );
   FifoMsgSource#(BPB) fOut <- mkFifoMsgSource( clocked_by aclk, reset_by aresetn );
   mkConnection(get_source_ifc(fOut), bridge.noc.in);

   rule egress(!fOut.full);
      let x <- toGet(beatFF).get;
      fOut.enq(x);
   endrule

//////////////////////

/*
   ReadOnly#(Bool) wIsOutOfReset <- mkNullCrossing(epClock125, _dut.isOutOfReset, reset_by epReset125);

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_status_out_of_reset;
      bridge.status_out_of_reset(_dut.isOutOfReset);
   endrule
*/
//////////////////////
`define DELAY 8

   Reg#(Bool) tracesOn <- mkReg(False, clocked_by aclk, reset_by aresetn);
   Vector#(`DELAY, Reg#(Bit#(2))) vrgs <- replicateM(mkReg(0, clocked_by aclk, reset_by aresetn));
   Bool sendTraces = tracesOn;

   AXI4_Stream_Slave_Xactor_IFC #(Wd_SId, Wd_SDest, Wd_SData, Wd_SUser)
      axis_xactor <- mkAXI4_Stream_Slave_Xactor(clocked_by aclk, reset_by aresetn
);

   function Info_CPU_to_Verifier axi4sTOictv(AXI4_Stream#(Wd_SId, Wd_SDest, Wd_SData, Wd_SUser) x)
      = unpack(x.tdata);

   let traces = fmap(axi4sTOictv,toGet(axis_xactor.o_stream).get);

   Reg#(TV_Vec_Bytes)  trace <- mkRegU(clocked_by aclk, reset_by aresetn);
   Vector#(TDiv#(SizeOf#(TV_Vec_Bytes),SizeOf#(MsgBeat#(BPB))),
	   MsgBeat#(BPB)) msgs = unpack(pack(trace));
   Reg#(UInt#(8)) cnt <- mkReg(0, clocked_by aclk, reset_by aresetn);
   Reg#(UInt#(8)) vecSize <- mkReg(0, clocked_by aclk, reset_by aresetn);

   rule xferBeat;
      if (cnt == vecSize) begin
	 let tr <- traces;
	 trace <=  tr.vec_bytes;
	 UInt#(32) bpb = fromInteger(valueof(BPB));
	 vecSize <= truncate((unpack(tr.num_bytes)+bpb-1)/bpb);
	 cnt <= 0;
	 Vector#(BPB, Byte) v = vec(0,1, truncate(pack(tr.num_bytes)), 1);
	                              // (the final 1 means always flush)
	 beatFF.enq(pack(v));
      end
      else begin
	 cnt <= cnt+1;
	 beatFF.enq(msgs[cnt]);
      end
   endrule

//////////////////////

   interface axi_in  = slaveSend(axis_xactor.axi_side, sendTraces);

`ifdef INCLUDE_TANDEM_VERIF
   method Action tv_switch(x);
      vrgs[`DELAY-1] <= x;
      for (Integer i=0; i<`DELAY-1; i=i+1)
	 vrgs[i] <= vrgs[i+1];
      if (vrgs[0]==1) tracesOn <= True;
      if (vrgs[0]==2) tracesOn <= False;
   endmethod
`endif
endmodule

// ================================================================

// The timing is tight through the core module, so we try to reduce the
// path length with this wrapper that adds a buffer on both the
// input and output.
module mkAXISBuffer#( Integer depth
                    , function Bool isEOF(t x) )
                   (FIFO#(t))
                   provisos (Bits#(t,tsz), Add#(1, j, tsz));

  (* hide *)
  FIFO#(t)  _core   <- mkAXISBufferCore(depth, isEOF);
  FIFO#(t)  in_buf  <- mkFIFO;
  FIFO#(t)  out_buf <- mkFIFO;

  (* fire_when_enabled *)
  rule moveIn;
    _core.enq(in_buf.first);
    in_buf.deq;
  endrule

  (* fire_when_enabled *)
  rule moveOut;
    out_buf.enq(_core.first);
    _core.deq;
  endrule

  method enq(x)  = in_buf.enq(x);

  method first() = out_buf.first;
  method deq()   = out_buf.deq;

  method Action clear();
    _core.clear;
    in_buf.clear;
    out_buf.clear;
  endmethod

endmodule

module mkAXISBufferCore#( Integer depth
                        , function Bool isEOF(t x) )
                       (FIFO#(t))
                       provisos (Bits#(t,tsz), Add#(1, j, tsz));

  FIFO#(t)      data_buf <- mkSizedBRAMFIFO(depth);
  FIFOF#(void)  eof_buf  <- mkSizedFIFOF(4);

  Bool has_data = eof_buf.notEmpty;

  method Action enq(t x);
    data_buf.enq(x);
    if (isEOF(x))
      eof_buf.enq(?);
  endmethod

  method t first() if (has_data) = data_buf.first;

  method Action deq() if (has_data);
    data_buf.deq;
    if (isEOF(data_buf.first))
      eof_buf.deq();
  endmethod

  method Action clear();
    data_buf.clear;
    eof_buf.clear;
  endmethod

endmodule

// ================================================================
// Connecting/converting stream AxiCq ==> stream TLPData#(16)


// Functions to convert between the byte order inside data words of
// Xilinx AXI packets and PCIe TLP packets

function Bit#(32) convertDW(Bit#(32) dw);
  Vector#(4, Bit#(8)) bytes = unpack(dw);
  return pack(reverse(bytes));
endfunction

// -------------------------

function AXI4_Stream_Slave_IFC #(i,a,d,u) slaveSend(AXI4_Stream_Slave_IFC #(i,a,d,u) s, Bool dontDrop);
   return (interface AXI4_Stream_Slave_IFC;
	      method m_tready = s.m_tready || !dontDrop;
	      method Action m_tvalid (tvalid,
				      tid,
				      tdata,
				      tstrb,
				      tkeep,
				      tlast,
				      tdest,
				      tuser);
		 s.m_tvalid (tvalid && dontDrop,
			     tid,
			     tdata,
			     tstrb,
			     tkeep,
			     tlast,
			     tdest,
			     tuser);
	      endmethod
	   endinterface );
endfunction


// -------------------------

endpackage
