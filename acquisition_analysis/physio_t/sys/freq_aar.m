clear; clc;
rng default;
%% Data Load

DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\Alpha\overall\";

Signal_list = [1:12];
nSignals = length(Signal_list);

V2Hz_closed_t = [];
S_closed_t = [];

for i = Signal_list
    FILE_NAMES = string(['BLE_EEG0_realtime_' num2str(i) '.xlsx']);
    
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
    
    ch1 = Data(1:NFFT,1);
    ch2 = Data(1:NFFT,2);
    ch_diff = ch1-ch2;
    ch_diff = ch_diff(:);
    
    L = length(ch_diff);
    ch_diff_open_nw = [ch_diff(1:L/4) ; ch_diff(2*L/4+1:3*L/4)];
    ch_diff_closed_nw = [ch_diff(L/4+1:2*L/4) ; ch_diff(3*L/4+1:L)];
    
    N=length(t)/2;
    
    L_closed = length(ch_diff_closed_nw);
    w = hann(L_closed);
    CG = sum(w)/(L_closed);
    ch_diff_closed = ch_diff_closed_nw(:) .* w;
    
    S_closed = abs(fft(ch_diff_closed)/N*2);
    S_closed = S_closed(1:N/2); 
    f_closed = (0:length(S_closed)-1) /N;
    S_closed = S_closed ./ CG;
    
    freqN_closed = f_closed*fsam;
    del_f_closed = freqN_closed(2)-freqN_closed(1);
    del_N_closed = round(0.5/del_f_closed);
    
    V2Hz_closed = (N/(2*fsam)) * (S_closed.^2);
    nBlock_closed = floor(length(V2Hz_closed) / del_N_closed);
    V2Hz_cut_closed = V2Hz_closed(1:nBlock_closed*del_N_closed);
    
    V2Hz_mat_closed = reshape(V2Hz_cut_closed, del_N_closed, nBlock_closed);
    V2Hz_closed_0p5Hz = (mean(V2Hz_mat_closed, 1))';
        
    V2Hz_closed_t = [V2Hz_closed_t V2Hz_closed_0p5Hz];
  
end

CLOSED = mean((V2Hz_closed_t(:,:))');
freq_0p5 = (0:nBlock_closed-1) * 0.5;

figure();
p = semilogy(freq_0p5,CLOSED); hold on;
% xlim([3 30]); ylim([1*10^(-12) 3*10^(-11)]);
p.Color = "blue";
p.LineWidth = 1.5;
grid on;
xlabel('Frequency (Hz)');
ylabel('PSD (V^(2)/Hz)');
