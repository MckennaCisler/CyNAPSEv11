## Possible minor changes
- Consolidate ESPCUnit+IPSCUnit and GexLeakUnit/GinLeakUnit
- Clean up unused or route-in,route-out inputs (Top.v)
- Check that x mod 2\*y are being correctly converted to masks? I.e. x mod 2\*y = x & {width-y 0s, y 1s}
- Factor out range checks
- Why do inhibitory and excitatory signals need to be different everywhere they are?
  - Consider methods to cut down on the amount of copied code that is based on whether the neuron is inhibitory or excitatory. I.e. where is the one place it matters, so that we can only mux there? Is it possible all this redundancy is being reflected in the hardware?

## Documentation TODOs
- Create a diagram mapping the SinglePortNeuronRam contents per neuron
  - Note the way physical/logical are organized
- Note: weights are set per-neuron because we want to update the particular dendritic connection coming out of (or into?) that neuron
  - Look into this more