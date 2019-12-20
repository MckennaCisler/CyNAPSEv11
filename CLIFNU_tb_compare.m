close all;

data_bline = csvread("CLIFNU_tb_out_baseline.csv");
data_opt = csvread("CLIFNU_tb_out_opt.csv");
results_file = fopen('CLIFNU_tb_compare_out.txt','w');

[
    bline_inputSet, ...
    bline_ExWeightSum, ...
    bline_InWeightSum, ...
    bline_Vmem, ...
    bline_gex, ...
    bline_gin, ...
    bline_RefVal, ...
    bline_Spikes, ...
] = extract_fields(data_bline);

[
    opt_inputSet, ...
    opt_ExWeightSum, ...
    opt_InWeightSum, ...
    opt_Vmem, ...
    opt_gex, ...
    opt_gin, ...
    opt_RefVal, ...
    opt_Spikes, ...
] = extract_fields(data_opt);

%% Analysis %%
plot_results("CLIFNU_tb_compare.png", data_bline, data_opt);

assert(all(unique(bline_inputSet) == unique(opt_inputSet)));

for set = unique(bline_inputSet)'
    indicies = data_bline(:,1) == set;
    report_results(results_file, data_bline(indicies,:), data_opt(indicies,:));
end
report_results(results_file, data_bline, data_opt);

%% Helpers %%
function [inputSet, ExWeightSum, InWeightSum, Vmem, gex, gin, RefVal, Spikes] = extract_fields(data)
    inputSet = data(:,1);
    ExWeightSum = data(:,2);
    InWeightSum = data(:,3);
    Vmem = data(:,4);
    gex = data(:,5);
    gin = data(:,6);
    RefVal = data(:,7);
    Spikes = data(:,8);
end

function plot_results(outfile, data_bline, data_opt)
    [
        bline_inputSet, ...
        bline_ExWeightSum, ...
        bline_InWeightSum, ...
        bline_Vmem, ...
        bline_gex, ...
        bline_gin, ...
        bline_RefVal, ...
        bline_Spikes, ...
    ] = extract_fields(data_bline);

    [
        opt_inputSet, ...
        opt_ExWeightSum, ...
        opt_InWeightSum, ...
        opt_Vmem, ...
        opt_gex, ...
        opt_gin, ...
        opt_RefVal, ...
        opt_Spikes, ...
    ] = extract_fields(data_opt);

    numPlots = 7;
    plotNum = 1;
    fig = figure;
    %fig = figure("position",get(0,"screensize"));

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

    saveas(fig, outfile, "png");
end

function report_results(res_f, data_bline, data_opt)
   [
        bline_inputSet, ...
        bline_ExWeightSum, ...
        bline_InWeightSum, ...
        bline_Vmem, ...
        bline_gex, ...
        bline_gin, ...
        bline_RefVal, ...
        bline_Spikes, ...
    ] = extract_fields(data_bline);

    [
        opt_inputSet, ...
        opt_ExWeightSum, ...
        opt_InWeightSum, ...
        opt_Vmem, ...
        opt_gex, ...
        opt_gin, ...
        opt_RefVal, ...
        opt_Spikes, ...
    ] = extract_fields(data_opt);
    
    fprintf(res_f,"\n\n=========== Results for input set(s):  ===========\n");
    fprintf(res_f,"%d\n", unique(bline_inputSet));
    assert(all(unique(bline_inputSet) == unique(opt_inputSet)));

    fprintf(res_f,"\n===== RMS Errors =====\n");
    fprintf(res_f,"Vmem: %d\n", sqrt(mean((bline_Vmem-opt_Vmem).^2)));
    fprintf(res_f,"gex: %d\n", sqrt(mean((bline_gex-opt_gex).^2)));
    fprintf(res_f,"gin: %d\n", sqrt(mean((bline_gin-opt_gin).^2)));
    fprintf(res_f,"RefVal: %d\n", sqrt(mean((bline_RefVal-opt_RefVal).^2)));

    fprintf(res_f,"\n===== Average Relative Errors =====\n");
    fprintf(res_f,"Vmem: %d\n", mean(bline_Vmem-opt_Vmem));
    fprintf(res_f,"gex: %d\n", mean(bline_gex-opt_gex));
    fprintf(res_f,"gin: %d\n", mean(bline_gin-opt_gin));
    fprintf(res_f,"RefVal: %d\n", mean(bline_RefVal-opt_RefVal));

    fprintf(res_f,"\n===== Normalized Average Relative Errors =====\n");
    fprintf(res_f,"Vmem: %d\n", mean((bline_Vmem-opt_Vmem)./bline_Vmem));
    fprintf(res_f,"gex: %d\n", mean((bline_gex-opt_gex)./bline_gex));
    fprintf(res_f,"gin: %d\n", mean((bline_gin-opt_gin)./bline_gin));
    fprintf(res_f,"RefVal: %d\n", mean((bline_RefVal-opt_RefVal)./bline_RefVal));

    fprintf(res_f,"\n===== Average Absolute Errors =====\n");
    fprintf(res_f,"Vmem: %d\n", mean(abs(bline_Vmem-opt_Vmem)));
    fprintf(res_f,"gex: %d\n", mean(abs(bline_gex-opt_gex)));
    fprintf(res_f,"gin: %d\n", mean(abs(bline_gin-opt_gin)));
    fprintf(res_f,"RefVal: %d\n", mean(abs(bline_RefVal-opt_RefVal)));

    fprintf(res_f,"\n===== Normalized Average Absolute Errors =====\n");
    fprintf(res_f,"Vmem: %d\n", mean(abs((bline_Vmem-opt_Vmem)./bline_Vmem)));
    fprintf(res_f,"gex: %d\n", mean(abs((bline_gex-opt_gex)./bline_gex)));
    fprintf(res_f,"gin: %d\n", mean(abs((bline_gin-opt_gin)./bline_gin)));
    fprintf(res_f,"RefVal: %d\n", mean(abs((bline_RefVal-opt_RefVal)./bline_RefVal)));

    fprintf(res_f,"\n===== Spike Output Errors =====\n");
    % abs diff equivalent to hamming dist
    Spikes_hamming_dist = sum(abs(bline_Spikes-opt_Spikes));
    fprintf(res_f,"Hamming distance: %d\n", Spikes_hamming_dist); 
    fprintf(res_f,"Hamming distance (normalized): %d\n", Spikes_hamming_dist/length(bline_Spikes));
end