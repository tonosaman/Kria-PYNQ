set paths [get_property ip_repo_paths [current_project]]
set_property ip_repo_paths [lappend paths "./ip"] [current_project]
update_ip_catalog

set list_check_ips "\
xilinx.com:hls:img_flip:1.0\
xilinx.com:ip:smartconnect:1.0\
"
common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."
set list_ips_missing ""
foreach ip_vlnv $list_check_ips {
    set ip_obj [get_ipdefs -all $ip_vlnv]
    if { $ip_obj eq "" } {
        lappend list_ips_missing $ip_vlnv
    }
}
if { $list_ips_missing ne "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
    common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
}

proc create_hier_cell_img_flip { parentCell nameHier } {
  variable script_folder
  set fname [info level [info level]]
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "${fname}() - Empty argument(s)!"}
     return
  }
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
  set oldCurInst [current_bd_instance .]

  # Create cell and set as current instance
  current_bd_instance $parentObj
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  #
  set axi_interconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1]
  set_property -dict [ list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {2} \
  ] $axi_interconnect

  set img_flip [ create_bd_cell -type ip -vlnv xilinx.com:hls:img_flip:1.0 img_flip ]

  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_0
  connect_bd_intf_net [get_bd_intf_pins img_flip/m_axi_gmem] [get_bd_intf_pins smartconnect_0/S00_AXI]

  connect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins img_flip/s_axi_ctrl]
  connect_bd_net [get_bd_pins aclk] [get_bd_pins img_flip/ap_clk]
  connect_bd_net [get_bd_pins aclk] [get_bd_pins smartconnect_0/aclk]
  connect_bd_net [get_bd_pins aclk] [get_bd_pins axi_interconnect_1/ACLK]
  connect_bd_net [get_bd_pins aclk] [get_bd_pins axi_interconnect_1/S00_ACLK]
  connect_bd_net [get_bd_pins aclk] [get_bd_pins axi_interconnect_1/M00_ACLK]
  connect_bd_net [get_bd_pins aclk] [get_bd_pins axi_interconnect_1/S01_ACLK]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_interconnect_1/ARESETN]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_interconnect_1/S00_ARESETN]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_interconnect_1/M00_ARESETN]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_interconnect_1/S01_ARESETN]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins img_flip/ap_rst_n]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins smartconnect_0/aresetn]

  # Configure top level settings
  set_property -dict [list \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__M_AXI_GP1 {1} \
    CONFIG.PSU__USE__S_AXI_GP0 {1} \
  ] [get_bd_cells /zynq_ultra_ps_e_0]
  connect_bd_net [get_bd_pins /zynq_ultra_ps_e_0/pl_clk2] \
    [get_bd_pins /zynq_ultra_ps_e_0/saxihpc0_fpd_aclk] \
    [get_bd_pins /zynq_ultra_ps_e_0/maxihpm1_fpd_aclk] \
    [get_bd_pins /zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] \
    [get_bd_pins /${nameHier}/aclk]
  connect_bd_net [get_bd_pins /rst_ps8_0_299M/peripheral_aresetn] [get_bd_pins /${nameHier}/aresetn]
  connect_bd_intf_net [get_bd_intf_pins /zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins axi_interconnect_1/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins /zynq_ultra_ps_e_0/M_AXI_HPM1_FPD] [get_bd_intf_pins axi_interconnect_1/S01_AXI]
  connect_bd_intf_net [get_bd_intf_pins /zynq_ultra_ps_e_0/S_AXI_HPC0_FPD] [get_bd_intf_pins smartconnect_0/M00_AXI]

  # Create address segments
  assign_bd_address -target_address_space [get_bd_addr_spaces img_flip/Data_m_axi_gmem] [get_bd_addr_segs /zynq_ultra_ps_e_0/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -target_address_space [get_bd_addr_spaces /zynq_ultra_ps_e_0/Data] [get_bd_addr_segs img_flip/img_flip/s_axi_ctrl/Reg] -force

  # Restore current instance
  current_bd_instance $oldCurInst
}

create_hier_cell_img_flip [current_bd_instance .] img_flip
validate_bd_design
save_bd_design
