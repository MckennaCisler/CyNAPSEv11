#current_design [module name]
#create_clock [get_ports {clk_name }]  -name clk_name -period clk_period(ns) -waveform {rise fall}
current_design DRUM8_64_64_s
create_clock [get_ports {Clock}]  -name Clock -period 100 -waveform {0 50}
