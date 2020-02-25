# Approximate CyNAPSEv11 Spiking Neural Network Architecture
See [README-orig.md](README-orig.md) for the original CyNAPSEv11 project and paper information.

This fork of [CyNAPSEv11](https://github.com/saunak1994/CyNAPSEv11) was a final project for the Brown Engineering course ENGN 2911Q (Advanced Digital Design). The project was centered around applying approximate computing to a spiking neural network (SNN) architecture. 

It was found that replacing select arithmetic units in the CyNAPSEv11 ConductanceLIFNeuronUnit (multipliers and dividers) with approximate equivalents resulted in significant area and power reductions of the neuron unit (62% and 77%, respectively) with very minimal impact on the accuracy of the neuron model (less than 3% error across metrics).

The Verilog files for the approximate neuron unit are suffixed with `_approxDiv.v`. The approximate arithmetic is centered around the [DRUM approximate multiplier](https://github.com/scale-lab/DRUM), and is combined with a reciprocal divider.

Fork by Mckenna Cisler and Andrew Duncombe.

## Performing flow & generating results & figures
### Performing full flow
- The full flow is performed using the Genus RC tool.
- The Genus RC command scripts for different models are:
  - baseline: `rc_commands_ConductanceLIFNeuronUnit.tcl`
  - optimized: `rc_commands_ConductanceLIFNeuronUnit_approxDiv.tcl`
  - baseline (complete CyNAPSE unit): `rc_commands_Top.tcl`
  - optimized (complete CyNAPSE unit): `rc_commands_Top_approxDiv.tcl`
- Notes on command scripts:
  - They can be run at the `genus` command line using `source <tcl file>`.
  - They will output to a directory associated with the particular command file (see the OUT_DIR variable).
  - Various settings, such as synthesis effort, can be configured in the files.
- Some other `rc_commands_*` scripts exist for performing full flows on other components.

### Accuracy comparison
This repository contains a pipeline of scripts to perform accuracy comparisons between the baseline and optimized neuron models. The filenames shared between scripts are standardized, so be mindful when modifying them (some scripts automatically sync filenames, for example within the testbench).

The pipeline requires the following to be installed:
- Python, with numpy
- ICARUS Verilog (`iverilog`)
- Matlab or Octave (with some modification) for analysis

The pipeline is as follows:
  1. `test_data/generate_CLIFNU_tb_wtSums.py`: python script generating neuron input waveforms.
     - To configure which waveforms are presented as input to the pipeline, check out the `Configuration` section of this file.
  2. `CLIFNU_compare.sh`: shell script which runs the entire simulation and result collection sequence.
     - This script does the following:
         1. Runs `generate_CLIFNU_tb_wtSums.py` to generate the testbench inputs.
         2. Compiles the `ConductanceLIFNeuronUnit_tb.v` for the baseline and optimized neurons, and executes them using `iverilog` after reconfiguring the input data filename.
         3. Renames the output data files to produce the files expected by `CLIFNU_tb_compare.m`.
  3. `CLIFNU_tb_compare.m`: matlab script which analyzes data output by `CLIFNU_compare.sh` and produces plots.

## Glossary/Acronyms
- BT: Biological Time(step)
- NID: Neuron Address
- AER: Address Event Representation = (BT, NID)
- Theta = Vth = VT: neuron spike threshold (voltage threshold?)
- IP: Input (neurons) 
- PSC: Post-Synaptic Current
- Vmem: neuron membrane potential
- SPNR: Single Port Neuron RAM
- UN: Update Enable
- InRe: Input Route Enable
- IntRe: Internal Route Enable
- IRIS: Input Route Input Select
