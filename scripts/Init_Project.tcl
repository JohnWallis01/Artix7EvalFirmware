# build settings
set fpga_part "xc7a50tftg256-1"
set project_name "DDR2_TEST_Project"
set script_dir [file normalize [file dirname [info script]]]
set project_dir [file normalize "${script_dir}/../build/${project_name}"]

file delete -force $project_dir
create_project $project_name $project_dir -part $fpga_part

# set reference directories for source files
set src_dir [file normalize "${script_dir}/../sources"]


#setup the block design
create_bd_design "main_bd"
open_bd_design [file normalize "${script_dir}/build/DDR2_TEST_Project/DDR2_TEST_Project.srcs/sources_1/bd/main_bd/main_bd.bd"]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0
endgroup


#now we configure the MIG IP
set_property CONFIG.BOARD_MIG_PARAM {Custom} [get_bd_cells mig_7series_0]
set_property CONFIG.MIG_DONT_TOUCH_PARAM {Custom} [get_bd_cells mig_7series_0]
set_property CONFIG.RESET_BOARD_INTERFACE {Custom} [get_bd_cells mig_7series_0]
set_property CONFIG.XML_INPUT_FILE [file normalize "${src_dir}/mig_a.prj"] [get_bd_cells mig_7series_0]


#connect the JTAG AXI to the MIG
connect_bd_intf_net [get_bd_intf_pins jtag_axi_0/M_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]


#configure the reset blocks and the clocking wizard and whatnot





# place and route
# opt_design
# place_design
# route_design

# write bitstream
# write_bitstream -force "${origin_dir}/${arch}/${design_name}.bit"