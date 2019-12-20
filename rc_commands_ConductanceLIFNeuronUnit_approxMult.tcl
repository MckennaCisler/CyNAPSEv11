puts "================="
puts "Synthesis Started"
date
puts "================="

# config
#--------------
set DESIGN ConductanceLIFNeuronUnit
set OUT_DIR "./genus_out_CLIFNU_approxMult"
set_db stdout_log $OUT_DIR/genus_CLIFNU.log
set_db command_log $OUT_DIR/genus_CLIFNU.cmd
# effort to use in synthesis; express = fastest, medium = default
set_db syn_global_effort express

#load the library
#------------------------------
set_db library { gscl45nm.lib }

#load and elaborate the design
#------------------------------
read_hdl ConductanceLIFNeuronUnit.v
read_hdl GexLeakUnit_approxMult.v
read_hdl GinLeakUnit_approxMult.v
read_hdl VmemLeakUnit_approxMult.v
read_hdl EPSCUnit_approxMult.v
read_hdl IPSCUnit_approxMult.v
read_hdl ThresholdUnit_approxMult.v
read_hdl SynapticIntegrationUnit_approxMult.v
read_hdl DRUM8_64_64_s.v

elaborate $DESIGN
check_design $DESIGN -unresolved
timestat Elaboration

#specify timing and design constraints
#--------------------------------------
read_sdc $DESIGN.sdc

#synthesize the design
#---------------------
# map to generic gates
syn_generic $DESIGN              
timestat SynGeneric
# map to library gates
syn_map $DESIGN                 
timestat SynMap
# optimize
syn_opt $DESIGN                 
timestat SynOpt

#analyze design
#------------------
report area > ./${OUT_DIR}/${DESIGN}_area.rpt
report gates > ./${OUT_DIR}/${DESIGN}_gates.rpt
report timing > ./${OUT_DIR}/${DESIGN}_timing.rpt
report power > ./${OUT_DIR}/${DESIGN}_power.rpt

#export design
#-------------
write_hdl -mapped > ./${OUT_DIR}/${DESIGN}_syn.v
write_sdc > ./${OUT_DIR}/${DESIGN}_syn.sdc
write_script > ./${OUT_DIR}/${DESIGN}_syn_constraints.g

timestat FINAL

puts "====================="
puts "Synthesis Finished :)"
date
puts "====================="
quit
