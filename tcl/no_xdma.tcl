#-----------------------------------------------------------
# Vivado v2019.1 (64-bit)
# SW Build 2552052 on Fri May 24 14:47:09 MDT 2019
# IP Build 2548770 on Fri May 24 18:01:18 MDT 2019
# Start of session at: Thu Jan  9 17:57:45 2020
# Process ID: 2167
# Current directory: /home/chauck/stoy_gfe-83rebase/vivado
# Command line: vivado soc_bluespec_p2/soc_bluespec_p2.xpr
# Log file: /home/chauck/stoy_gfe-83rebase/vivado/vivado.log
# Journal file: /home/chauck/stoy_gfe-83rebase/vivado/vivado.jou
#-----------------------------------------------------------
#start_gui
#open_project soc_bluespec_p2/soc_bluespec_p2.xpr
#open_bd_design {soc_bluespec_p2/soc_bluespec_p2.srcs/sources_1/bd/design_1/design_1.bd}
# (comment out above three lines eventually)

delete_bd_objs [get_bd_nets gfe_subsystem/util_ds_buf_0_IBUF_OUT] [get_bd_nets gfe_subsystem/xdma_0_pci_exp_txp] [get_bd_nets gfe_subsystem/pci_exp_rxp_0_1] [get_bd_nets gfe_subsystem/xdma_0_interrupt_out] [get_bd_nets gfe_subsystem/xdma_0_interrupt_out_msi_vec32to63] [get_bd_nets gfe_subsystem/util_ds_buf_0_IBUF_DS_ODIV2] [get_bd_nets gfe_subsystem/xdma_0_pci_exp_txn] [get_bd_nets gfe_subsystem/pci_exp_rxn_0_1] [get_bd_nets gfe_subsystem/xdma_0_axi_ctl_aresetn] [get_bd_nets gfe_subsystem/xdma_0_interrupt_out_msi_vec0to31] [get_bd_intf_nets gfe_subsystem/axi_interconnect_0_M03_AXI] [get_bd_intf_nets gfe_subsystem/S05_AXI_1] [get_bd_intf_nets gfe_subsystem/axi_interconnect_0_M04_AXI] [get_bd_cells gfe_subsystem/xdma_0]
delete_bd_objs [get_bd_nets gfe_subsystem/IBUF_DS_P_0_1] [get_bd_nets gfe_subsystem/IBUF_DS_N_0_1] [get_bd_cells gfe_subsystem/util_ds_buf_0]
delete_bd_objs [get_bd_nets IBUF_DS_N_0_1] [get_bd_pins gfe_subsystem/fmc_pcie_clk_n]
delete_bd_objs [get_bd_nets IBUF_DS_P_0_1] [get_bd_pins gfe_subsystem/fmc_pcie_clk_p]
delete_bd_objs [get_bd_nets pci_exp_rxp_0_1] [get_bd_pins gfe_subsystem/fmc_pcie_rxp]
delete_bd_objs [get_bd_nets pci_exp_rxn_0_1] [get_bd_pins gfe_subsystem/fmc_pcie_rxn]
delete_bd_objs [get_bd_nets gfe_subsystem_pci_exp_txn_0] [get_bd_pins gfe_subsystem/fmc_pcie_txn]
delete_bd_objs [get_bd_nets gfe_subsystem_pci_exp_txp_0] [get_bd_pins gfe_subsystem/fmc_pcie_txp]
#write_bd_tcl -force del_xdma.tcl
delete_bd_objs [get_bd_ports fmc_pcie_clk_p] [get_bd_ports fmc_pcie_rxn] [get_bd_ports fmc_pcie_clk_n] [get_bd_ports fmc_pcie_rxp]
delete_bd_objs [get_bd_ports fmc_pcie_txn] [get_bd_ports fmc_pcie_txp]
#write_bd_tcl -force del_xdma.tcl
#reset_run design_1_s04_regslice_0_synth_1
#reset_run design_1_m01_regslice_4_synth_1
#save_bd_design
#reset_run synth_1
#launch_runs synth_1 -jobs 4
connect_bd_net [get_bd_pins gfe_subsystem/xlconstant_0/dout] [get_bd_pins gfe_subsystem/axi_interconnect_0/M03_ACLK]
connect_bd_net [get_bd_pins gfe_subsystem/axi_interconnect_0/M04_ARESETN] [get_bd_pins gfe_subsystem/axi_interconnect_0/M03_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins gfe_subsystem/axi_interconnect_0/M04_ARESETN] [get_bd_pins gfe_subsystem/xlconstant_0/dout]
#save_bd_design
#launch_runs synth_1 -jobs 4
