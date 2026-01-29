clear; clc;
rng default;
%% Data Load

DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\ASSR\overall\";

Signal_list = [1:8];
nSignals = length(Signal_list);

V2Hz_all = [];
SNR_all = [];

for i = Signal_list
    FILE_NAMES = string(['BLE_EEG_assr_' num2str(i) '.xlsx']);
    
    idx_file = 1;   
    fsam = 62.5e3/64;
    fcomp = fsam;
    disp("File #" + num2str(i) + " is started");
    DATA_LOC = DIR+FILE_NAMES(idx_file);

    opts = detectImportOptions(DIR+FILE_NAMES(idx_file));
    Data = readmatrix(DATA_LOC,opts);

    NFFT = size(Data,1);
    t = (0:NFFT-1).*(1/fcomp)*1e3; %unit = msec
    t = t(:);
    
    ch1 = Data(1:NFFT,2);
    ch2 = Data(1:NFFT,3);
    ch_diff_nw = ch1-ch2;
    
    L = length(ch_diff_nw);
    N=length(t);
    
    w = hann(L);
    CG = sum(w)/L;
    ch_diff = ch_diff_nw .* w;

    S_diff = abs(fft(ch_diff)/N*2); 
    S_diff = S_diff(1:N/2); 
    f_diff = (0:length(S_diff)-1) /N;
    S_diff = S_diff ./ CG;

    freqN = f_diff*fsam;
    del_f = freqN(2)-freqN(1);
    del_N = round(1/del_f);

    V2Hz = (N/(2*fsam)) * (S_diff.^2);
    nBlock = floor(length(V2Hz) / del_N);
    V2Hz_cut = V2Hz(1:nBlock*del_N);
    
    V2Hz_mat = reshape(V2Hz_cut, del_N, nBlock);
    V2Hz_1Hz = (mean(V2Hz_mat, 1))';
    
    V2Hz_all = [V2Hz_all V2Hz_1Hz];
    
    
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

    SNR_all = [SNR_all SNR];

end
V2Hz_all = V2Hz_all';
ASSR = mean(V2Hz_all);

freq_1 = 0:nBlock-1;

figure();
for k = 1:nSignals
    % figure();
    p = semilogy(freq_1,V2Hz_all(k,1:end), 'LineWidth', 0.7, 'Color', [0.8 0.8 0.8]); hold on; % grid on;
    p.Color(4) = 0.6;
end

semilogy(freq_1,ASSR, 'LineWidth', 1, 'Color', [0 0 0]); hold on;
% xlim([10 50]); ylim([0.8*10^(-12) 2*10^(-10)]);
xlabel('Frequency (Hz)');
ylabel('PSD (V^{2}/Hz)');


SNR_mean = mean(SNR_all)
SNR_std = std(SNR_all)
