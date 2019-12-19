#!/usr/bin/env bash
MATLAB=0

# config
BASELINE_FILES="ConductanceLIFNeuronUnit_tb.v ConductanceLIFNeuronUnit.v GexLeakUnit.v GinLeakUnit.v VmemLeakUnit.v EPSCUnit.v IPSCUnit.v ThresholdUnit.v SynapticIntegrationUnit.v"
OPT_FILES_1="ConductanceLIFNeuronUnit_tb.v ConductanceLIFNeuronUnit.v GexLeakUnit_approxMult.v GinLeakUnit_approxMult.v VmemLeakUnit_approxMult.v EPSCUnit_approxMult.v IPSCUnit_approxMult.v ThresholdUnit_approxMult.v SynapticIntegrationUnit_approxMult.v DRUM8_64_64_s.v"

# change to set which implementation to compare with the baseline 
OPT_FILES=$OPT_FILES_1

# change to change the weigth sums used as input
# WTSUM_FILE="test_data\/CLIFN_tb_wtSums_periodic_alternating.csv"
WTSUM_FILE="test_data\/CLIFN_tb_wtSums_random_both.csv" 

# constants; need to correspond with scripts
TB_OUTFILE="ConductanceLIFNeuronUnit_tb_out.csv"
TB_OUTFILE_BASELINE="ConductanceLIFNeuronUnit_tb_out_baseline.csv"
TB_OUTFILE_OPT="ConductanceLIFNeuronUnit_tb_out_opt.csv"
COMPARE_SCRIPT_FIG="ConductanceLIFNeuronUnit_tb_compare.png"

cd test_data/
./generate_CLIFN_tb_wtSums.py
cd ..

sed "s/localparam WTSUM_FILE = \".*\"/localparam WTSUM_FILE = \"$WTSUM_FILE\"/" ConductanceLIFNeuronUnit_tb.v -i

iverilog $BASELINE_FILES -o baseline_neuron_tb
iverilog $OPT_FILES -o optimized_neuron_tb

./baseline_neuron_tb
mv $TB_OUTFILE $TB_OUTFILE_BASELINE

./optimized_neuron_tb
mv $TB_OUTFILE $TB_OUTFILE_OPT

if [ $MATLAB == "1" ]
then
    matlab -nodesktop -nodisplay -nosplash -r "run('$(pwd)/ConductanceLIFNeuronUnit_tb_compare.m')"
else
    octave ConductanceLIFNeuronUnit_tb_compare.m
fi