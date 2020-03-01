###  -*-Makefile-*-

XLEN      = 64
ISA       = ACDFIMSU
PROCESSOR = Flute
PROCESSOR_RTL = $(REPO)/bluespec-processors/P2/$(PROCESSOR)/src_SSITH_P2/Verilog_RTL
TOPNAME   = mkP2_Core
WD_ID     = 6
SOC_MAP_SUFFIX = _Veril
INCLUDE_TANDEM_VERIF = no
