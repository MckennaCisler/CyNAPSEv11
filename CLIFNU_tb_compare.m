close all;

data_bline = csvread("CLIFNU_tb_out_baseline.csv");
data_opt = csvread("CLIFNU_tb_out_opt.csv");
results_file = fopen('CLIFNU_tb_compare_out.txt','w');

bline = extract_fields(data_bline);
opt = extract_fields(data_opt);

assert(all(unique(bline.inputSet) == unique(opt.inputSet)));

%% Analysis %%
plot_results("CLIFNU_tb_compare.png", data_bline, data_opt);

report_results(results_file, data_bline, data_opt);

sets = unique(bline.inputSet)';
clear set_results;
for i = 1:length(sets)
    indicies = data_bline(:,1) == sets(i);
    set_results(i) = report_results(results_file, data_bline(indicies,:), data_opt(indicies,:));
end

fig = figure;
hold on;
plot([set_results.Taumem], [set_results.Vmem_rms_error]);
plot([set_results.Taumem], [set_results.gex_rms_error]);
plot([set_results.Taumem], [set_results.gin_rms_error]);

%% Helpers %%
function fields = extract_fields(data)
    fields = struct;
    fields.inputSet = data(:,1);
    fields.Taumem = data(:,2);
    fields.Taugex = data(:,3);
    fields.Taugin = data(:,4);
    fields.ExWeightSum = data(:,5);
    fields.InWeightSum = data(:,6);
    fields.Vmem = data(:,7);
    fields.gex = data(:,8);
    fields.gin = data(:,9);
    fields.RefVal = data(:,10);
    fields.Spikes = data(:,11);
end

function plot_results(outfile, data_bline, data_opt)
    bline = extract_fields(data_bline);
    opt = extract_fields(data_opt);

    numPlots = 7;
    plotNum = 1;
    fig = figure;
    %fig = figure("position",get(0,"screensize"));

    subplot(numPlots,1,plotNum);
    plotNum=plotNum+1;
    hold on;
    plot(bline.ExWeightSum);
    plot(opt.ExWeightSum);
    title("Input excitatory weight sum (input spikes)");
    legend('Baseline','Optimized');

    subplot(numPlots,1,plotNum);
    plotNum=plotNum+1;
    hold on;
    plot(bline.gex);
    plot(opt.gex);
    title("Gex (excitatory leak current)");

    subplot(numPlots,1,plotNum);
    plotNum=plotNum+1;
    hold on;
    plot(bline.InWeightSum);
    plot(opt.InWeightSum);
    title("Input inhibitory weight sum (input spikes)");

    subplot(numPlots,1,plotNum);
    plotNum=plotNum+1;
    hold on;
    plot(bline.gin);
    plot(opt.gin);
    title("Gin (inhibitory leak current)");

    subplot(numPlots,1,plotNum);
    plotNum=plotNum+1;
    hold on;
    plot(bline.Vmem);
    plot(opt.Vmem);
    title("Vmem (membrane potential)");

    subplot(numPlots,1,plotNum);
    plotNum=plotNum+1;
    hold on;
    plot(bline.RefVal);
    plot(opt.RefVal);
    title("Tref (time left in refactory period)");

    subplot(numPlots,1,plotNum);
    plotNum=plotNum+1;
    hold on;
    plot(bline.Spikes);
    plot(opt.Spikes)
    title("Output spikes");

    saveas(fig, outfile, "png");
end

function results = report_results(res_f, data_bline, data_opt)
    bline = extract_fields(data_bline);
    opt = extract_fields(data_opt);
    
    results = struct;
    results.Taumem = bline(1).Taumem(1);
    results.Taugex = bline(1).Taugex(1);
    results.Taugin = bline(1).Taugin(1);
    
    fprintf(res_f,"=========== Results for input set(s):  ===========\n");
    results.input_sets = unique(bline.inputSet);
    fprintf(res_f,"%d\n", results.input_sets);
    assert(all(unique(bline.inputSet) == unique(opt.inputSet)));
    
    fprintf(res_f,"\n===== RMS Errors =====\n");
    results.Vmem_rms_error = sqrt(mean((bline.Vmem-opt.Vmem).^2));
    results.gex_rms_error = sqrt(mean((bline.gex-opt.gex).^2));
    results.gin_rms_error = sqrt(mean((bline.gin-opt.gin).^2));
    results.RefVal_rms_error = sqrt(mean((bline.RefVal-opt.RefVal).^2));
    fprintf(res_f,"Vmem: %d\n", results.Vmem_rms_error);
    fprintf(res_f,"gex: %d\n", results.gex_rms_error);
    fprintf(res_f,"gin: %d\n", results.gin_rms_error);
    fprintf(res_f,"RefVal: %d\n", results.RefVal_rms_error);

    fprintf(res_f,"\n===== Average Relative Errors =====\n");
    results.Vmem_rel_error = mean(bline.Vmem-opt.Vmem);
    results.gex_rel_error = mean(bline.gex-opt.gex);
    results.gin_rel_error = mean(bline.gin-opt.gin);
    results.RefVal_rel_error = mean(bline.RefVal-opt.RefVal);
    fprintf(res_f,"Vmem: %d\n", results.Vmem_rel_error);
    fprintf(res_f,"gex: %d\n", results.gex_rel_error);
    fprintf(res_f,"gin: %d\n", results.gin_rel_error);
    fprintf(res_f,"RefVal: %d\n", results.RefVal_rel_error);

    fprintf(res_f,"\n===== Normalized Average Relative Errors =====\n");
    results.Vmem_rel_error_norm = mean((bline.Vmem-opt.Vmem)./bline.Vmem);
    results.gex_rel_error_norm = mean((bline.gex-opt.gex)./bline.gex);
    results.gin_rel_error_norm = mean((bline.gin-opt.gin)./bline.gin);
    results.RefVal_rel_error_norm = mean((bline.RefVal-opt.RefVal)./bline.RefVal);
    fprintf(res_f,"Vmem: %d\n", results.Vmem_rel_error_norm);
    fprintf(res_f,"gex: %d\n", results.gex_rel_error_norm);
    fprintf(res_f,"gin: %d\n", results.gin_rel_error_norm);
    fprintf(res_f,"RefVal: %d\n", results.RefVal_rel_error_norm);

    fprintf(res_f,"\n===== Average Absolute Errors (x100%%) =====\n");
    results.Vmem_abs_error = mean(abs(bline.Vmem-opt.Vmem));
    results.gex_abs_error = mean(abs(bline.gex-opt.gex));
    results.gin_abs_error = mean(abs(bline.gin-opt.gin));
    results.RefVal_abs_error = mean(abs(bline.RefVal-opt.RefVal));
    fprintf(res_f,"Vmem: %d\n", results.Vmem_abs_error);
    fprintf(res_f,"gex: %d\n", results.gex_abs_error);
    fprintf(res_f,"gin: %d\n", results.gin_abs_error);
    fprintf(res_f,"RefVal: %d\n", results.RefVal_abs_error);

    fprintf(res_f,"\n===== Normalized Average Absolute Errors (x100%%) =====\n");
    results.Vmem_abs_error_norm = mean(abs((bline.Vmem-opt.Vmem)./bline.Vmem));
    results.gex_abs_error_norm = mean(abs((bline.gex-opt.gex)./bline.gex));
    results.gin_abs_error_norm = mean(abs((bline.gin-opt.gin)./bline.gin));
    results.RefVal_abs_error_norm = mean(abs((bline.RefVal-opt.RefVal)./bline.RefVal));
    fprintf(res_f,"Vmem: %d\n", results.Vmem_abs_error_norm);
    fprintf(res_f,"gex: %d\n", results.gex_abs_error_norm);
    fprintf(res_f,"gin: %d\n", results.gin_abs_error_norm);
    fprintf(res_f,"RefVal: %d\n", results.RefVal_abs_error_norm);

    fprintf(res_f,"\n===== Spike Output Errors =====\n");
    % abs diff equivalent to hamming dist
    results.Spikes_hamming_dist = sum(abs(bline.Spikes-opt.Spikes));
    results.Spikes_hamming_dist_norm = results.Spikes_hamming_dist/length(bline.Spikes);
    fprintf(res_f,"Hamming distance: %d\n", results.Spikes_hamming_dist); 
    fprintf(res_f,"Hamming distance (normalized, x100%%): %d\n", results.Spikes_hamming_dist_norm);
    fprintf(res_f,"\n\n");
end