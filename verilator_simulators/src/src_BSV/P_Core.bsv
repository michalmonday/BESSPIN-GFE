// Copyright (c) 2018-2019 Bluespec, Inc. All Rights Reserved.

package P_Core;

// ================================================================
// This package is a shell for a core processor in the DARPA SSITH project.

// ================================================================
// Project imports

// Main Fabric
import AXI4_Types   :: *;
import AXI4_Fabric  :: *;
import Fabric_Defs  :: *;
import SoC_Map_Veril  :: *;
import JtagTap ::*;
import Giraffe_IFC ::*;

import Vector :: *;
import Clocks :: *;

`ifdef INCLUDE_TANDEM_VERIF
typedef SizeOf #(Info_CPU_to_Verifier)Wd_SData;
typedef 0 Wd_SDest;
typedef 0 Wd_SUser;
typedef 0 Wd_SId;


//import TV_Info :: *;
import AXI4_Stream ::*;
`endif

// ================================================================
// Trace_Data is encoded in module mkTV_Encode into vectors of bytes,
// which are eventually streamed out to an on-line tandem verifier/
// analyzer (or to a file for off-line tandem-verification/analysis).

// Various 'transactions' produce a Trace_Data struct (e.g., reset,
// each instruction retirement, each GDB write to registers or memory,
// etc.).  Each struct is encoded into a vector of bytes; the number
// of bytes depends on the kind of transaction and various encoding
// choices.

typedef 72   TV_VB_SIZE;    // max bytes needed for each transaction
typedef  Vector #(TV_VB_SIZE, Byte)  TV_Vec_Bytes;

// ================================================================

typedef Bit#(8) Byte;

typedef struct {
   Bit #(32)     num_bytes;
   TV_Vec_Bytes  vec_bytes;
} Info_CPU_to_Verifier deriving (Bits, FShow);

// ================================================================

interface P_Core_IFC;

   // ----------------------------------------------------------------
   // Core CPU interfaces

   // CPU IMem to Fabric master interface
   interface AXI4_Master_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) master0;

   // CPU DMem (incl. I/O) to Fabric master interface
   interface AXI4_Master_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) master1;

   // External interrupt sources
   (* always_ready, always_enabled, prefix="" *)
   method  Action interrupt_reqs ((* port="cpu_external_interrupt_req" *) Bit #(N_External_Interrupt_Sources)  reqs);

`ifdef INCLUDE_TANDEM_VERIF
   // ----------------------------------------------------------------
   // Optional Tandem Verifier interface.  The data signal is
   // packed output tuples (n,vb),/ where 'vb' is a vector of
   // bytes with relevant bytes in locations [0]..[n-1]

      interface AXI4_Stream_Master_IFC #(Wd_SId, Wd_SDest, Wd_SData, Wd_SUser)  tv_verifier_info_tx;
`endif

`ifdef INCLUDE_GDB_CONTROL
   // ----------------
   // JTAG interface

`ifdef JTAG_TAP
   interface JTAG_IFC jtag;
`endif
`endif
endinterface

// ================================================================

(* synthesize *)
module mkP_Core (P_Core_IFC);
   let clk <- exposeCurrentClock;
   // INTERFACE

   // CPU IMem to Fabric master interface
   interface AXI4_Master_IFC master0 = ?;

   // CPU DMem to Fabric master interface
   interface AXI4_Master_IFC master1 = ?;

   // External interrupts
   method  Action interrupt_reqs (Bit #(N_External_Interrupt_Sources) reqs) = ?;

`ifdef INCLUDE_TANDEM_VERIF
   // ----------------------------------------------------------------
   // Optional Tandem Verifier interface.  The data signal is
   // packed output tuples (n,vb),/ where 'vb' is a vector of
   // bytes with relevant bytes in locations [0]..[n-1]

   interface tv_verifier_info_tx = ?;
`endif

`ifdef INCLUDE_GDB_CONTROL
   // ----------------------------------------------------------------
   // Optional Debug Module interfaces

`ifdef JTAG_TAP

   interface JTAG_IFC jtag;
      method tclk(x) = noAction;
      method tms(x) = noAction;
      method tdi(x) = noAction;
      method tdo = 0;
      interface tclk_out = clk;
   endinterface
`endif

`endif
endmodule
endpackage
