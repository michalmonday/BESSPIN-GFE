//
// Generated by Bluespec Compiler, version 2019.05.beta2 (build a88bf40db, 2019-05-24)
//
//
//
//
// Ports:
// Name                         I/O  size props
// CLK                            I     1 clock
// RST_N                          I     1 reset
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module mkTop_HW_Side(CLK,
		     RST_N);
  input  CLK;
  input  RST_N;

  // register rg_banner_printed
  reg rg_banner_printed;
  wire rg_banner_printed$D_IN, rg_banner_printed$EN;

  // register rg_console_in_poll
  reg [11 : 0] rg_console_in_poll;
  wire [11 : 0] rg_console_in_poll$D_IN;
  wire rg_console_in_poll$EN;

  // ports of submodule mem_model
  wire [352 : 0] mem_model$mem_server_request_put;
  wire [255 : 0] mem_model$mem_server_response_get;
  wire mem_model$EN_mem_server_request_put,
       mem_model$EN_mem_server_response_get,
       mem_model$RDY_mem_server_request_put,
       mem_model$RDY_mem_server_response_get;

  // ports of submodule soc_top
  wire [607 : 0] soc_top$tv_verifier_info_get_get;
  wire [352 : 0] soc_top$to_raw_mem_request_get;
  wire [255 : 0] soc_top$to_raw_mem_response_put;
  wire [63 : 0] soc_top$set_verbosity_logdelay,
		soc_top$set_watch_tohost_tohost_addr;
  wire [7 : 0] soc_top$get_to_console_get, soc_top$put_from_console_put;
  wire [3 : 0] soc_top$set_verbosity_verbosity;
  wire soc_top$EN_get_to_console_get,
       soc_top$EN_put_from_console_put,
       soc_top$EN_set_verbosity,
       soc_top$EN_set_watch_tohost,
       soc_top$EN_to_raw_mem_request_get,
       soc_top$EN_to_raw_mem_response_put,
       soc_top$EN_tv_verifier_info_get_get,
       soc_top$RDY_get_to_console_get,
       soc_top$RDY_put_from_console_put,
       soc_top$RDY_to_raw_mem_request_get,
       soc_top$RDY_to_raw_mem_response_put,
       soc_top$RDY_tv_verifier_info_get_get,
       soc_top$assert_soft_reset,
       soc_top$set_watch_tohost_watch_tohost;

  // ports of submodule sysRst_Ifc
  wire sysRst_Ifc$ASSERT_IN, sysRst_Ifc$OUT_RST;

  // rule scheduling signals
  wire WILL_FIRE_RL_rl_relay_console_in;

  // declarations used by system tasks
  // synopsys translate_off
  reg TASK_testplusargs___d13;
  reg TASK_testplusargs___d12;
  reg TASK_testplusargs___d16;
  reg [63 : 0] tohost_addr__h693;
  reg [31 : 0] v__h749;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue1;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue2;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue3;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue4;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue5;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue6;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue7;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue8;
  reg [31 : 0] c_trace_file_load_word64_in_buffer__avValue9;
  reg [31 : 0] v__h6003;
  reg [7 : 0] v__h6266;
  // synopsys translate_on

  // submodule mem_model
  mkMem_Model mem_model(.CLK(CLK),
			.RST_N(sysRst_Ifc$OUT_RST),
			.mem_server_request_put(mem_model$mem_server_request_put),
			.EN_mem_server_request_put(mem_model$EN_mem_server_request_put),
			.EN_mem_server_response_get(mem_model$EN_mem_server_response_get),
			.RDY_mem_server_request_put(mem_model$RDY_mem_server_request_put),
			.mem_server_response_get(mem_model$mem_server_response_get),
			.RDY_mem_server_response_get(mem_model$RDY_mem_server_response_get));

  // submodule soc_top
  mkSoC_Top soc_top(.CLK(CLK),
		    .RST_N(sysRst_Ifc$OUT_RST),
		    .put_from_console_put(soc_top$put_from_console_put),
		    .set_verbosity_logdelay(soc_top$set_verbosity_logdelay),
		    .set_verbosity_verbosity(soc_top$set_verbosity_verbosity),
		    .set_watch_tohost_tohost_addr(soc_top$set_watch_tohost_tohost_addr),
		    .set_watch_tohost_watch_tohost(soc_top$set_watch_tohost_watch_tohost),
		    .to_raw_mem_response_put(soc_top$to_raw_mem_response_put),
		    .EN_set_verbosity(soc_top$EN_set_verbosity),
		    .EN_tv_verifier_info_get_get(soc_top$EN_tv_verifier_info_get_get),
		    .EN_to_raw_mem_request_get(soc_top$EN_to_raw_mem_request_get),
		    .EN_to_raw_mem_response_put(soc_top$EN_to_raw_mem_response_put),
		    .EN_get_to_console_get(soc_top$EN_get_to_console_get),
		    .EN_put_from_console_put(soc_top$EN_put_from_console_put),
		    .EN_set_watch_tohost(soc_top$EN_set_watch_tohost),
		    .RDY_set_verbosity(),
		    .tv_verifier_info_get_get(soc_top$tv_verifier_info_get_get),
		    .RDY_tv_verifier_info_get_get(soc_top$RDY_tv_verifier_info_get_get),
		    .to_raw_mem_request_get(soc_top$to_raw_mem_request_get),
		    .RDY_to_raw_mem_request_get(soc_top$RDY_to_raw_mem_request_get),
		    .RDY_to_raw_mem_response_put(soc_top$RDY_to_raw_mem_response_put),
		    .get_to_console_get(soc_top$get_to_console_get),
		    .RDY_get_to_console_get(soc_top$RDY_get_to_console_get),
		    .RDY_put_from_console_put(soc_top$RDY_put_from_console_put),
		    .assert_soft_reset(soc_top$assert_soft_reset),
		    .RDY_assert_soft_reset(),
		    .RDY_set_watch_tohost());

  // submodule sysRst_Ifc
  MakeResetA #(.RSTDELAY(32'd2), .init(1'd0)) sysRst_Ifc(.CLK(CLK),
							 .RST(RST_N),
							 .DST_CLK(CLK),
							 .ASSERT_IN(sysRst_Ifc$ASSERT_IN),
							 .ASSERT_OUT(),
							 .OUT_RST(sysRst_Ifc$OUT_RST));

  // rule RL_rl_relay_console_in
  assign WILL_FIRE_RL_rl_relay_console_in =
	     rg_console_in_poll != 12'd0 || soc_top$RDY_put_from_console_put ;

  // register rg_banner_printed
  assign rg_banner_printed$D_IN = 1'd1 ;
  assign rg_banner_printed$EN = !rg_banner_printed ;

  // register rg_console_in_poll
  assign rg_console_in_poll$D_IN = rg_console_in_poll + 12'd1 ;
  assign rg_console_in_poll$EN = WILL_FIRE_RL_rl_relay_console_in ;

  // submodule mem_model
  assign mem_model$mem_server_request_put = soc_top$to_raw_mem_request_get ;
  assign mem_model$EN_mem_server_request_put =
	     soc_top$RDY_to_raw_mem_request_get &&
	     mem_model$RDY_mem_server_request_put ;
  assign mem_model$EN_mem_server_response_get =
	     soc_top$RDY_to_raw_mem_response_put &&
	     mem_model$RDY_mem_server_response_get ;

  // submodule soc_top
  assign soc_top$put_from_console_put = v__h6266 ;
  assign soc_top$set_verbosity_logdelay = 64'd0 ;
  assign soc_top$set_verbosity_verbosity =
	     TASK_testplusargs___d12 ?
	       4'd2 :
	       (TASK_testplusargs___d13 ? 4'd1 : 4'd0) ;
  assign soc_top$set_watch_tohost_tohost_addr = tohost_addr__h693 ;
  assign soc_top$set_watch_tohost_watch_tohost = TASK_testplusargs___d16 ;
  assign soc_top$to_raw_mem_response_put = mem_model$mem_server_response_get ;
  assign soc_top$EN_set_verbosity = !rg_banner_printed ;
  assign soc_top$EN_tv_verifier_info_get_get =
	     soc_top$RDY_tv_verifier_info_get_get ;
  assign soc_top$EN_to_raw_mem_request_get =
	     soc_top$RDY_to_raw_mem_request_get &&
	     mem_model$RDY_mem_server_request_put ;
  assign soc_top$EN_to_raw_mem_response_put =
	     soc_top$RDY_to_raw_mem_response_put &&
	     mem_model$RDY_mem_server_response_get ;
  assign soc_top$EN_get_to_console_get = soc_top$RDY_get_to_console_get ;
  assign soc_top$EN_put_from_console_put =
	     WILL_FIRE_RL_rl_relay_console_in &&
	     rg_console_in_poll == 12'd0 &&
	     v__h6266 != 8'd0 ;
  assign soc_top$EN_set_watch_tohost = !rg_banner_printed ;

  // submodule sysRst_Ifc
  assign sysRst_Ifc$ASSERT_IN = soc_top$assert_soft_reset ;

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (RST_N == `BSV_RESET_VALUE)
      begin
        rg_console_in_poll <= `BSV_ASSIGNMENT_DELAY 12'd0;
      end
    else
      begin
        if (rg_console_in_poll$EN)
	  rg_console_in_poll <= `BSV_ASSIGNMENT_DELAY rg_console_in_poll$D_IN;
      end
    if (sysRst_Ifc$OUT_RST == `BSV_RESET_VALUE)
      begin
        rg_banner_printed <= `BSV_ASSIGNMENT_DELAY 1'd0;
      end
    else
      begin
        if (rg_banner_printed$EN)
	  rg_banner_printed <= `BSV_ASSIGNMENT_DELAY rg_banner_printed$D_IN;
      end
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    rg_banner_printed = 1'h0;
    rg_console_in_poll = 12'hAAA;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on

  // handling of system tasks

  // synopsys translate_off
  always@(negedge CLK)
  begin
    #0;
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	$display("================================================================");
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	$display("Bluespec RISC-V standalone system simulation v1.2");
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	$display("Copyright (c) 2017-2019 Bluespec, Inc. All Rights Reserved.");
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	$display("================================================================");
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	begin
	  TASK_testplusargs___d13 = $test$plusargs("v1");
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	begin
	  TASK_testplusargs___d12 = $test$plusargs("v2");
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	begin
	  TASK_testplusargs___d16 = $test$plusargs("tohost");
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	begin
	  tohost_addr__h693 = $imported_c_get_symbol_val("tohost");
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	$display("INFO: watch_tohost = %0d, tohost_addr = 0x%0h",
		 TASK_testplusargs___d16,
		 tohost_addr__h693);
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed)
	begin
	  v__h749 = $imported_c_trace_file_open(8'hAA);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed && v__h749 == 32'd0)
	$display("ERROR: Top_HW_Side.rl_step0: error opening trace file.");
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed && v__h749 == 32'd0) $display("    Aborting.");
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed && v__h749 == 32'd0) $finish(32'd1);
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (!rg_banner_printed && v__h749 != 32'd0)
	$display("Top_HW_Side.rl_step0: opened trace file.");
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue1 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd0,
							   soc_top$tv_verifier_info_get_get[63:0]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue2 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd8,
							   soc_top$tv_verifier_info_get_get[127:64]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue3 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd16,
							   soc_top$tv_verifier_info_get_get[191:128]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue4 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd24,
							   soc_top$tv_verifier_info_get_get[255:192]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue5 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd32,
							   soc_top$tv_verifier_info_get_get[319:256]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue6 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd40,
							   soc_top$tv_verifier_info_get_get[383:320]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue7 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd48,
							   soc_top$tv_verifier_info_get_get[447:384]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue8 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd56,
							   soc_top$tv_verifier_info_get_get[511:448]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  c_trace_file_load_word64_in_buffer__avValue9 =
	      $imported_c_trace_file_load_word64_in_buffer(32'd64,
							   soc_top$tv_verifier_info_get_get[575:512]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get)
	begin
	  v__h6003 =
	      $imported_c_trace_file_write_buffer(soc_top$tv_verifier_info_get_get[607:576]);
	  #0;
	end
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get && v__h6003 == 32'd0)
	$display("ERROR: Top_HW_Side.rl_tv_vb_out: error writing out bytevec data buffer (%0d bytes)",
		 soc_top$tv_verifier_info_get_get[607:576]);
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_tv_verifier_info_get_get && v__h6003 == 32'd0)
	$finish(32'd1);
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_get_to_console_get)
	$write("%c", soc_top$get_to_console_get);
    if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
      if (soc_top$RDY_get_to_console_get) $fflush(32'h80000001);
    if (RST_N != `BSV_RESET_VALUE)
      if (sysRst_Ifc$OUT_RST != `BSV_RESET_VALUE)
	if (WILL_FIRE_RL_rl_relay_console_in && rg_console_in_poll == 12'd0)
	  begin
	    v__h6266 = $imported_c_trygetchar(8'hAA);
	    #0;
	  end
  end
  // synopsys translate_on
endmodule  // mkTop_HW_Side

