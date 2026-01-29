clear; clc;
rng default;
%% 
%%% Data Load
DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\CGX\CGX_actual\ASSR\";

CGX_ASSR_F = [];
for j = 1:8

    FILE_NAMES = string(['ASSR00' num2str(j) '.xlsx']);

    idx_file = 1;
    fsam = 500;
    fcomp = fsam;
    disp("File #" + string(j) + " is started");
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

    CGX_nw = [F7 Fp1 Fp2 F8 F3 Fz F4 C3 Cz P8 P7 Pz P4 T3 P3 O1 O2 C4 T4];
    %% 
    % FFT analysis

    L = length(CGX_nw(:,1));
    N = length(t);

    w = hann(L);
    CG = sum(w)/L;

    CGX = CGX_nw .* w;

    V2Hz_CGX = [];
    SNR_CGX_all = []; 

    for i = (1:length(CGX_nw(1,:)))
        S_CGX = abs(fft(CGX(:,i))/N*2); 
        S_CGX = S_CGX(1:N/2); 
        f_CGX = (0:length(S_CGX)-1) /N;
        S_CGX = S_CGX ./ CG;

        freqN = f_CGX*fsam;
        del_f = freqN(2)-freqN(1);
        del_N = round(1/del_f);

        V2Hz = (N/(2*fsam)) * (S_CGX.^2);
        nBlock = floor(length(V2Hz) / del_N);
        V2Hz_cut = V2Hz(1:nBlock*del_N);

        V2Hz_mat = reshape(V2Hz_cut, del_N, nBlock);
        V2Hz_1Hz = (mean(V2Hz_mat, 1))';

        V2Hz_CGX = [V2Hz_CGX V2Hz_1Hz];


        freq_N = freqN(1:del_N:end-del_N);
        time_idx_s = (freq_N >= 40 & freq_N < 41);
        time_idx_n1 = (freq_N >= 35 & freq_N < 40);
        time_idx_n2 = (freq_N >= 41 & freq_N < 46);
        time_idx_n = time_idx_n1 + time_idx_n2;

        sig_pow = V2Hz_1Hz(logical(time_idx_s));
        noi_pow = V2Hz_1Hz(logical(time_idx_n));

        sig_pow_sum = sum(sig_pow) / length(sig_pow);
        noise_pow_sum = sum(noi_pow) / length(noi_pow);

        SNR = 10*log10(sig_pow_sum / noise_pow_sum);
        SNR_CGX_all = [SNR_CGX_all SNR];

    end

    SNR_CGX = (SNR_CGX_all([1,4,14,19,11,10,16,17]))';
    % SNR_CGX = SNR_CGX_all(:);
    CGX_ASSR_F = [CGX_ASSR_F SNR_CGX];
    
end

names = {'F7','Fp1','Fp2','F8','F3','Fz','F4','C3','Cz','T6','T5','Pz','P4','T3','P3','O1','O2','C4','T4'};
rowNames = names([1,4,14,19,11,10,16,17]);
% rowNames = names;

nCol = size(CGX_ASSR_F,2);

T = array2table(CGX_ASSR_F, 'VariableNames', compose("Cond%d", 1:nCol), 'RowNames', rowNames);

% colMax = max(T{:,:}, [], 1);
% meanMax = mean(colMax);
% stdMax  = std(colMax);
% 
% newRow = array2table(colMax, 'VariableNames', T.Properties.VariableNames);
% newRow.Properties.RowNames = {'MaxCh'};
% T = [T; newRow];

T.Mean = mean(T{:,:}, 2);
T.Std  = std(T{:,:}, 0, 2);

order = {'O1','O2','T5','T6','T3','T4','F7','F8'};
T = T(order, :);

%% 

nCh = height(T);
x_ch = 1:nCh;
x_ear = nCh + 1.2;
mean_ear = 8.81;
std_ear = 4.37;

figure; 
hold on;

nn = length(CGX_ASSR_F);
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
xtickangle(45); ylim([0 11]); ylabel('Value'); xlim([0.3, 10])
title('ASSR');
% grid on; set(gca,'GridAlpha',0.15);

hold off;

%%

T_disp = T;
T_disp.Mean = string(sprintfc('%.2f', T.Mean));
T_disp.Std  = string(sprintfc('%.2f', T.Std));
T_disp.SE  = string(sprintfc('%.2f', T.SE));
disp(T_disp)

save('CGX_ASSR.mat','T');
