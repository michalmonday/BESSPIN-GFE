###  -*-Makefile-*-

XLEN      = 32
ISA       = ACIMU
PROCESSOR = Piccolo
PROCESSOR_RTL = $(REPO)/bluespec-processors/P1/$(PROCESSOR)/src_SSITH_P1/Verilog_RTL
TOPNAME   = mkP1_Core
WD_ID     = 6
SOC_MAP_SUFFIX = _Veril
INCLUDE_TANDEM_VERIF = no
