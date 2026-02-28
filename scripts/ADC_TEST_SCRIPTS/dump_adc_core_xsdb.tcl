
set program_script "C:/Users/John/workspace/ADC_test_system/_ide/scripts/debugger_adc_test-default.tcl"
set log_file "E:/Libraries/Documents/LAB_VNA/EVAL_BOARDS/artix_eval/Rev_A/FirmwareSource/scripts/ADC_TEST_SCRIPTS/dump_adc_core.log"
# exec xsdb $program_script
# after 5000

#connect to the
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target 
current_hw_device [get_hw_devices xc7a50t_0]
refresh_hw_device [lindex [get_hw_devices xc7a50t_0] 0]


reset_hw_axi [get_hw_axis hw_axi_1]

# #check if there are any existing transactions and delete them
if {[llength [get_hw_axi_txns *]] > 0} {
    delete_hw_axi_txn [get_hw_axi_txns *]
}

set MIG_BASE_ADDR 0x80000000
set CURRENT_ADDR $MIG_BASE_ADDR

set log [open $log_file "w"]

for {set i 0} {$i < 1000} {incr i} {
    create_hw_axi_txn read_txn [get_hw_axis hw_axi_1] -type READ -address [format "0x%08X" $CURRENT_ADDR] -len 256
    run_hw_axi [get_hw_axi_txns read_txn]
    set data [report_hw_axi_txn [get_hw_axi_txns read_txn]]
    puts $log $data
    set CURRENT_ADDR [expr {$CURRENT_ADDR + 256*4}]
    puts "Read transactions $i completed, address: [format "0x%08X" $CURRENT_ADDR]"
    delete_hw_axi_txn [get_hw_axi_txns read_txn]
}

close $log