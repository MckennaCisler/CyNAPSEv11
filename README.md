# Approximate CyNAPSEv11 Spiking Neural Network Architecture
See [README-orig.md](README-orig.md) for the original CyNAPSEv11 project and paper information.

This fork of [CyNAPSEv11](https://github.com/saunak1994/CyNAPSEv11) was a final project for the Brown Engineering course ENGN 2911Q (Advanced Digital Design). The project was centered around applying approximate computing to a spiking neural network (SNN) architecture. 

It was found that replacing select arithmetic units in the CyNAPSEv11 ConductanceLIFNeuronUnit (multipliers and dividers) with approximate equivalents resulted in significant area and power reductions of the neuron unit (62% and 77%, respectively) with very minimal impact on the accuracy of the neuron model (less than 3% error across metrics).

The Verilog files for the approximate neuron unit are suffixed with `_approxDiv.v`. The approximate arithmetic is centered around the [DRUM approximate multiplier](https://github.com/scale-lab/DRUM), and is combined with a reciprocal divider.

An accuracy comparison can be produced using the `CLIFNU_compare.sh` and `CLIFNU_tb_compare.m` scripts utilizing ICARUS Verilog, while an area and power comparison can be obtained using the Genus RC command scripts `rc_commands_ConductanceLIFNeuronUnit.tcl` and `rc_commands_ConductanceLIFNeuronUnit_approxDiv.tcl`

Fork by Mckenna Cisler and Andrew Duncombe.

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
