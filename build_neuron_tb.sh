#!/usr/bin/env bash
iverilog ConductanceLIFNeuronUnit_tb.v ConductanceLIFNeuronUnit.v GexLeakUnit.v  GinLeakUnit.v VmemLeakUnit.v EPSCUnit.v IPSCUnit.v ThresholdUnit.v SynapticIntegrationUnit.v -o cynapse_neuron_tb
