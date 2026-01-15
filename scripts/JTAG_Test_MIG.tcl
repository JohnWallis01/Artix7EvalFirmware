
reset_hw_axi [get_hw_axis hw_axi_1]

create_hw_axi_txn write_txn [get_hw_axis hw_axi_1] -type WRITE -address 00000000 -len 4 -data {11111111_22222222_33333333_44444444}
run_hw_axi [get_hw_axi_txns write_txn]

create_hw_axi_txn read_txn [get_hw_axis hw_axi_1] -type READ -address 00000000 -len 4
run_hw_axi [get_hw_axi_txns read_txn]
report_hw_axi_txn [get_hw_axi_txns read_txn]
report_property [get_hw_axi_txns read_txn]