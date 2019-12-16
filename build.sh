#!/usr/bin/env bash
iverilog Top_tb.v Top.v SinglePortNeuronRAM.v SinglePortOffChipRAM.v NeuronUnit.v InputFIFO.v InputRouter.v InternalRouter.v SysControl.v ConductanceLIFNeuronUnit.v GexLeakUnit.v  GinLeakUnit.v VmemLeakUnit.v EPSCUnit.v IPSCUnit.v ThresholdUnit.v SynapticIntegrationUnit.v -o cynapse
