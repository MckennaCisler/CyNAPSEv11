data = csvread("ConductanceLIFNeuronUnit_tb_out.csv");

inputSet = data(:,1);
ExWeightSum = data(:,2);
InWeightSum = data(:,3);
Vmem = data(:,4);
gex = data(:,5);
gin = data(:,6);
RefVal = data(:,7);
Spikes = data(:,8);

numPlots = 7;
plotNum = 1;
figure(1,"position",get(0,"screensize"));
hold on;

subplot(numPlots,1,plotNum++);
plot(ExWeightSum);
title("input excitatory weight sum (input spikes)");

subplot(numPlots,1,plotNum++);
plot(gex);
title("gex (leak current)");

subplot(numPlots,1,plotNum++);
plot(InWeightSum);
title("input inhibitory weight sum (input spikes)");

subplot(numPlots,1,plotNum++);
plot(gin);
title("gin (leak current)");

subplot(numPlots,1,plotNum++);
plot(Vmem);
title("Vmem (membrane potential)");

subplot(numPlots,1,plotNum++);
plot(RefVal);
title("Tref (time left in refactory period)");

subplot(numPlots,1,plotNum++);
plot(Spikes)
title("Output spikes");

pause;