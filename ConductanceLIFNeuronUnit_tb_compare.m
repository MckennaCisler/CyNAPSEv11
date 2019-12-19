data_bline = csvread("ConductanceLIFNeuronUnit_tb_out_baseline.csv");
data_opt = csvread("ConductanceLIFNeuronUnit_tb_out_opt.csv");

bline_ExWeightSum = data_bline(:,1);
bline_InWeightSum = data_bline(:,2);
bline_Vmem = data_bline(:,3);
bline_gex = data_bline(:,4);
bline_gin = data_bline(:,5);
bline_RefVal = data_bline(:,6);
bline_Spikes = data_bline(:,7);

opt_ExWeightSum = data_opt(:,1);
opt_InWeightSum = data_opt(:,2);
opt_Vmem = data_opt(:,3);
opt_gex = data_opt(:,4);
opt_gin = data_opt(:,5);
opt_RefVal = data_opt(:,6);
opt_Spikes = data_opt(:,7);

%% Plotting %%
numPlots = 7;
plotNum = 1;
fig = figure("position",get(0,"screensize"));

subplot(numPlots,1,plotNum);
plotNum=plotNum+1;
hold on;
plot(bline_ExWeightSum);
plot(opt_ExWeightSum);
title("Input excitatory weight sum (input spikes)");
legend('Baseline','Optimized');

subplot(numPlots,1,plotNum);
plotNum=plotNum+1;
hold on;
plot(bline_gex);
plot(opt_gex);
title("Gex (excitatory leak current)");

subplot(numPlots,1,plotNum);
plotNum=plotNum+1;
hold on;
plot(bline_InWeightSum);
plot(opt_InWeightSum);
title("Input inhibitory weight sum (input spikes)");

subplot(numPlots,1,plotNum);
plotNum=plotNum+1;
hold on;
plot(bline_gin);
plot(opt_gin);
title("Gin (inhibitory leak current)");

subplot(numPlots,1,plotNum);
plotNum=plotNum+1;
hold on;
plot(bline_Vmem);
plot(opt_Vmem);
title("Vmem (membrane potential)");

subplot(numPlots,1,plotNum);
plotNum=plotNum+1;
hold on;
plot(bline_RefVal);
plot(opt_RefVal);
title("Tref (time left in refactory period)");

subplot(numPlots,1,plotNum);
plotNum=plotNum+1;
hold on;
plot(bline_Spikes);
plot(opt_Spikes)
title("Output spikes");

saveas(fig, "ConductanceLIFNeuronUnit_tb_compare.png", "png");

%% Analysis %%
fprintf("\nRMS Errors:\n");
Vmem_rms_error = sqrt(mean((bline_Vmem-opt_Vmem).^2))
gex_rms_error = sqrt(mean((bline_gex-opt_gex).^2))
gin_rms_error = sqrt(mean((bline_gin-opt_gin).^2))
RefVal_rms_error = sqrt(mean((bline_RefVal-opt_RefVal).^2))

fprintf("\nAverage Relative Errors:\n");
Vmem_rel_error = mean(bline_Vmem-opt_Vmem)
gex_rel_error = mean(bline_gex-opt_gex)
gin_rel_error = mean(bline_gin-opt_gin)
RefVal_rel_error = mean(bline_RefVal-opt_RefVal)

fprintf("\nNormalized Average Relative Errors:\n");
Vmem_rel_error = mean((bline_Vmem-opt_Vmem)./bline_Vmem)
gex_rel_error = mean((bline_gex-opt_gex)./bline_gex)
gin_rel_error = mean((bline_gin-opt_gin)./bline_gin)
RefVal_rel_error = mean((bline_RefVal-opt_RefVal)./bline_RefVal)

fprintf("\nAverage Absolute Errors:\n");
Vmem_abs_error = mean(abs(bline_Vmem-opt_Vmem))
gex_abs_error = mean(abs(bline_gex-opt_gex))
gin_abs_error = mean(abs(bline_gin-opt_gin))
RefVal_abs_error = mean(abs(bline_RefVal-opt_RefVal))

fprintf("\nNormalized Average Absolute Errors:\n");
Vmem_abs_error_norm = mean(abs((bline_Vmem-opt_Vmem)./bline_Vmem))
gex_abs_error_norm = mean(abs((bline_gex-opt_gex)./bline_gex))
gin_abs_error_norm = mean(abs((bline_gin-opt_gin)./bline_gin))
RefVal_abs_error_norm = mean(abs((bline_RefVal-opt_RefVal)./bline_RefVal))

fprintf("\nSpike Output Errors:\n");
Spikes_hamming_dist = sum(abs(bline_Spikes-opt_Spikes)) % abs diff equivalent to hamming dist
Spikes_hamming_dist_norm = Spikes_hamming_dist/length(bline_Spikes)

pause;