data = csvread("ConductanceLIFNeuronUnit_tb_out.csv");

ExWeightSum = data(:,1);
Vmem = data(:,2);
gex = data(:,3);
gin = data(:,4);
RefVal = data(:,5);
Spikes = data(:,6);

numPlots = 5;

figure(1,"position",get(0,"screensize"));
hold on;

subplot(numPlots,1,1);
plot(ExWeightSum);
title("input weight sum (input spikes)");

subplot(numPlots,1,2);
plot(gex);
%plot(gin);
title("gex/gin (leak current)");

subplot(numPlots,1,3);
plot(Vmem);
title("Vmem (membrane potential)");

subplot(numPlots,1,4);
plot(RefVal);
title("Tref (time left in refactory period)");

subplot(numPlots,1,5);
plot(Spikes)
title("Output spikes");

pause;