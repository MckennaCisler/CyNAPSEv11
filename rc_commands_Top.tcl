#Start###################################################################
#’puts’ command just prints what is in its argument.
puts "================="
puts "Synthesis Started"
date
puts "================="
#Include TCL utility scripts.
include load_etc.tcl
#Set up variables.
#set DESIGN <Your_module_name>
set DESIGN Top_syn_tb
#set SYN_EFF <Required_synthesis_effort>
set SYN_EFF medium
#set MAP_EFF <Required_mapping_effort>
set MAP_EFF medium
#set SYN_PATH <Required_working_directory>
set SYN_PATH "."
#set the PDK’s path as a variable ‘PDKDIR’
#set PDKDIR $::env(PDKDIR)
#shortcut for setting report output dir
set OUT_DIR "./genus_out"
######################################################################
#set the search path for the ".lib’ files provided with the PDK.
#set_attribute lib_search_path $PDKDIR/gsclib045_all_v4.4/gsclib045/timing
set_db lib_search_path ./
#select the needed .lib files.
set_db library { gscl45nm.lib }
######################################################################
#This command is to read in your RTL code.
##Verilog##
read_hdl Top_syn_tb.v
read_hdl Top.v 
read_hdl InputFIFO.v
read_hdl InputRouter.v
read_hdl InternalRouter.v
read_hdl NeuronUnit.v
read_hdl SysControl.v
read_hdl GexLeakUnit.v
read_hdl GinLeakUnit.v
read_hdl VmemLeakUnit.v
read_hdl EPSCUnit.v
read_hdl IPSCUnit.v
read_hdl ThresholdUnit.v
read_hdl SynapticIntegrationUnit.v
read_hdl ConductanceLIFNeuronUnit.v
##SystemVerilog##
#read_hdl -sv ./in/UP_COUNTER.sv
#Elaboration validates the syntax.
elaborate $DESIGN
#Reports the time and memory used in the elaboration.
puts "Runtime & Memory after ‘read_hdl'"
timestat Elaboration
#return problems with your RTL code.
check_design -unresolved
#Read in your clock difinition and timing constraints
read_sdc Top_syn_tb.sdc
######################################################################
#Synthesizing to generic cell (not related to the used PDK)
synthesize -to_generic -eff $SYN_EFF
puts "Runtime & Memory after ‘synthesize -to_generic'"
timestat GENERIC
#Synthesizing to gates from the used PDK
synthesize -to_mapped -eff $MAP_EFF -no_incr
puts "Runtime & Memory after ‘synthesize -to_map -no_incr'"
timestat MAPPED
#Incremental Synthesis
synthesize -to_mapped -eff $MAP_EFF -incr
#Insert Tie Hi and Tie low cells
insert_tiehilo_cells
puts "Runtime & Memory after incremental synthesis"
timestat INCREMENTAL
######################################################################
#write output files and generate reports
report area > ./${OUT_DIR}/${DESIGN}_area.rpt
report gates > ./${OUT_DIR}/${DESIGN}_gates.rpt
report timing > ./${OUT_DIR}/${DESIGN}_timing.rpt
report power > ./${OUT_DIR}/${DESIGN}_power.rpt
#generate the verilog file with actual gates-> to be used in Encounter and ModelSim
##Verilog##
write_hdl -mapped > ./${OUT_DIR}/${DESIGN}_map.v
##SystemVerilog##
write_hdl -mapped > ./${OUT_DIR}/${DESIGN}_map.sv
#generate the constaraints file–> to be used in Encounter
write_sdc > ./${OUT_DIR}/${DESIGN}_map.sdc
#generate the delays file–> to be used in ModelSim
write_sdf > ./${OUT_DIR}/${DESIGN}_map.sdf
puts "Final Runtime & Memory."
timestat FINAL
#THE END
puts "====================="
puts "Synthesis Finished :)"
puts "====================="
#Exit RTL Compiler
quit
