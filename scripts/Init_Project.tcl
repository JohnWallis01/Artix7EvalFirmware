# build settings
set fpga_part "xc7a50tftg256-1"
set project_name "DDR2_TEST_Project"
set script_dir [file normalize [file dirname [info script]]]
set project_dir [file normalize "${script_dir}/../build/${project_name}"]

file delete -force $project_dir
create_project $project_name $project_dir -part $fpga_part

# set reference directories for source files
set src_dir [file normalize "${script_dir}/../source"]

# place and route
# opt_design
# place_design
# route_design

# write bitstream
# write_bitstream -force "${origin_dir}/${arch}/${design_name}.bit"