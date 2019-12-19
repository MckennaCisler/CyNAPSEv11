#!/usr/bin/env bash
MATLAB=0

# config
BASELINE_FILES="ConductanceLIFNeuronUnit_tb.v ConductanceLIFNeuronUnit.v GexLeakUnit.v GinLeakUnit.v VmemLeakUnit.v EPSCUnit.v IPSCUnit.v ThresholdUnit.v SynapticIntegrationUnit.v"
OPT_FILES_MULT="ConductanceLIFNeuronUnit_tb.v ConductanceLIFNeuronUnit.v GexLeakUnit_approxMult.v GinLeakUnit_approxMult.v VmemLeakUnit_approxMult.v EPSCUnit_approxMult.v IPSCUnit_approxMult.v ThresholdUnit_approxMult.v SynapticIntegrationUnit_approxMult.v DRUM8_64_64_s.v"
OPT_FILES_DIV="ConductanceLIFNeuronUnit_tb.v ConductanceLIFNeuronUnit.v GexLeakUnit_approxDiv.v GinLeakUnit_approxDiv.v VmemLeakUnit_approxDiv.v EPSCUnit_approxDiv.v IPSCUnit_approxDiv.v ThresholdUnit_approxDiv.v SynapticIntegrationUnit_approxDiv.v DRUMk_n_m_s.v fixed_point_recip.v"

# change to set which implementation to compare with the baseline 
# OPT_FILES=$OPT_FILES_MULT
OPT_FILES=$OPT_FILES_DIV

# constants; need to correspond with scripts
WTSUM_FILE="test_data\/CLIFNU_tb_wtSums.csv"
TB_OUTFILE="CLIFNU_tb_out.csv"
TB_OUTFILE_BASELINE="CLIFNU_tb_out_baseline.csv"
TB_OUTFILE_OPT="CLIFNU_tb_out_opt.csv"
COMPARE_SCRIPT_FIG="CLIFNU_tb_compare.png"

# modify this file to change what the generated input sequences look like
cd test_data/
./generate_CLIFNU_tb_wtSums.py
cd ..

sed "s/localparam WTSUM_FILE = \".*\"/localparam WTSUM_FILE = \"$WTSUM_FILE\"/" ConductanceLIFNeuronUnit_tb.v -i

iverilog $BASELINE_FILES -o baseline_neuron_tb
iverilog $OPT_FILES -o optimized_neuron_tb

./baseline_neuron_tb
mv $TB_OUTFILE $TB_OUTFILE_BASELINE

./optimized_neuron_tb
mv $TB_OUTFILE $TB_OUTFILE_OPT

# if [ $MATLAB == "1" ]
# then
#     matlab -nodesktop -nodisplay -nosplash -r "run('$(pwd)/CLIFNU_tb_compare.m')"
# else
#     octave CLIFNU_tb_compare.m
# fi