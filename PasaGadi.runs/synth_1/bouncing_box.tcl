# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
set_param xicom.use_bs_reader 1
create_project -in_memory -part xc7a100tcsg324-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir Z:/CS-373-1/PasaGadi/PasaGadi.cache/wt [current_project]
set_property parent.project_path Z:/CS-373-1/PasaGadi/PasaGadi.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
set_property board_part digilentinc.com:nexys4_ddr:part0:1.1 [current_project]
set_property ip_output_repo z:/CS-373-1/PasaGadi/PasaGadi.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_vhdl -library xil_defaultlib {
  Z:/CS-373-1/PasaGadi/PasaGadi.srcs/sources_1/imports/sources_1/new/Synchronizer.vhd
  Z:/CS-373-1/PasaGadi/PasaGadi.srcs/sources_1/imports/sources_1/imports/bouncing_box_with_background_and_btn/vga_sync.vhd
  Z:/CS-373-1/PasaGadi/PasaGadi.srcs/sources_1/imports/new/x7seg_top.vhd
  Z:/CS-373-1/PasaGadi/PasaGadi.srcs/sources_1/imports/sources_1/imports/bouncing_box_with_background_and_btn/bouncing_box.vhd
}
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc Z:/CS-373-1/PasaGadi/PasaGadi.srcs/constrs_1/imports/CS-373-1/Nexys4DDR_Master.xdc
set_property used_in_implementation false [get_files Z:/CS-373-1/PasaGadi/PasaGadi.srcs/constrs_1/imports/CS-373-1/Nexys4DDR_Master.xdc]

set_param ips.enableIPCacheLiteLoad 0
close [open __synthesis_is_running__ w]

synth_design -top bouncing_box -part xc7a100tcsg324-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef bouncing_box.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file bouncing_box_utilization_synth.rpt -pb bouncing_box_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
