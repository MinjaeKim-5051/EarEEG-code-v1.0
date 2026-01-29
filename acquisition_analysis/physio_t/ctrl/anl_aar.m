clear; clc;
rng default;
%% 
%%% Data Load
DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\CGX\CGX_actual\Alpha\";

AMI_F = [];

for j = 1:12

    FILE_NAMES = string(['AAR' num2str(j) '.xlsx']);

    idx_file = 1;    
    fsam = 500;
    fcomp = fsam;
    disp("File #" + num2str(j) + " is started");
    DATA_LOC = DIR+FILE_NAMES(idx_file);

    opts = detectImportOptions(DIR+FILE_NAMES(idx_file));
    Data = readmatrix(DATA_LOC,opts);

    NFFT = size(Data,1);
    t = (0:NFFT-1).*(1/fcomp)*1e3; %unit = msec
    t = t(:);

    F7  = Data(1:NFFT,2);
    Fp1 = Data(1:NFFT,3);
    Fp2 = Data(1:NFFT,4);
    F8  = Data(1:NFFT,5);
    F3  = Data(1:NFFT,6);
    Fz  = Data(1:NFFT,7);
    F4  = Data(1:NFFT,8);
    C3  = Data(1:NFFT,9);
    Cz  = Data(1:NFFT,10);
    P8  = Data(1:NFFT,11);
    P7  = Data(1:NFFT,12);
    Pz  = Data(1:NFFT,13);
    P4  = Data(1:NFFT,14);
    T3  = Data(1:NFFT,15);
    P3  = Data(1:NFFT,16);
    O1  = Data(1:NFFT,17);
    O2  = Data(1:NFFT,18);
    C4  = Data(1:NFFT,19);
    T4  = Data(1:NFFT,20);

    CGX = [F7 Fp1 Fp2 F8 F3 Fz F4 C3 Cz P8 P7 Pz P4 T3 P3 O1 O2 C4 T4];
    %% 

    AMI_total = [];
    for i = (1:length(CGX(1,:)))
        [pp,fp,tp] = pspectrum(CGX(:,i), fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1);

        df = fp(2) - fp(1);
        psd = pp ./ df;

        band_idx = (fp >= 8 & fp <= 13);    
        band_power_sum = sum(psd(band_idx, :) * df, 1);
        band_power_sum = band_power_sum(15:206); % ini removal

        LL= length(band_power_sum);
        os = 2;
        open_1 = sum(band_power_sum(1+os:LL/4-os));
        closed_1 = sum(band_power_sum(LL/4+1+os:LL/2-os));
        open_2 = sum(band_power_sum(LL/2+1+os:3*LL/4-os));
        closed_2 = sum(band_power_sum(3*LL/4+1+os:LL-os));

        AMI_1 = closed_1 / open_1;
        AMI_2 = closed_2 / open_2;
        AMI_3 = closed_1 / open_2;
        AMI_4 = closed_2 / open_1;
        AMI = max([AMI_1; AMI_2; AMI_3; AMI_4]);
        % AMI = mean([AMI_1; AMI_2; AMI_3; AMI_4]);
        AMI_total = [AMI_total; AMI];
    end
    
    AMI_F = [AMI_F AMI_total([1,4,14,19,11,10,16,17])];
    
end

names = {'F7','Fp1','Fp2','F8','F3','Fz','F4','C3','Cz','T6','T5','Pz','P4','T3','P3','O1','O2','C4','T4'};
rowNames = names([1,4,14,19,11,10,16,17]);
rowMean = mean(AMI_F, 2);
rowStd  = std(AMI_F, 0, 2);

nCol = size(AMI_F,2);

T = array2table(AMI_F, 'VariableNames', compose("Cond%d", 1:nCol), 'RowNames', rowNames);
T.Mean = rowMean; T.Mean = round(T.Mean, 2);
T.Std  = rowStd; T.Std  = round(T.Std, 2);

order = {'O1','O2','T5','T6','T3','T4','F7','F8'};
T = T(order, :);

%%

nCh = height(T);
x_ch = 1:nCh;
x_ear = nCh + 1.2;
mean_ear = 1.82;
std_ear = 0.33;

figure; 
hold on;

nn = length(AMI_F);
T.SE = T.Std ./ sqrt(nn);

b1 = bar(x_ch, T.Mean);
b1.BarWidth = 0.5; b1.FaceColor = [0.7 0.7 0.7];
errorbar(x_ch, T.Mean, T.SE, 'k', 'LineStyle','none', 'LineWidth',1);

b2 = bar(x_ear, mean_ear);
b2.BarWidth = 0.5;
b2.FaceColor = [0.1 0.45 0.75];
b2.EdgeColor = 'k';
b2.LineWidth = 1.2;
errorbar(x_ear, mean_ear, std_ear ./ sqrt(nn), 'k', 'LineStyle','none', 'LineWidth',1.2);

set(gca,'XTick',[x_ch x_ear]);
set(gca,'XTickLabel',[T.Properties.RowNames; {'In-Ear'}]);
xtickangle(45); ylim([0 9]); ylabel('Value'); xlim([0.3, 10])
title('Alpha band modulation');
% grid on; set(gca,'GridAlpha',0.15);

hold off;

%%

T_disp = T;
T_disp.Mean = string(sprintfc('%.2f', T.Mean));
T_disp.Std  = string(sprintfc('%.2f', T.Std));
T_disp.SE  = string(sprintfc('%.2f', T.SE));
disp(T_disp)

save('CGX_AAR.mat','T');
