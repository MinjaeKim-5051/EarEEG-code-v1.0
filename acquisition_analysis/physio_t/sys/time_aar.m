clear; clc;
rng default;
%% Data Load

DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\Alpha\overall\";

asd_rms = [];
asd_dB = [];
out_rms = [];
out_dB = [];
psdSum = [];

ch_filt = [];
AMI_total = [];

Signal_list = [1:12];
nSignals = length(Signal_list);

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
    
    [b,a] = butter(4,[8 13]/(fsam/2), 'bandpass');
    filt_time = filter(b,a,ch_diff);
    ch_filt = [ch_filt filt_time];

end

%% Alpha band plot

ch_alpha = ch_filt';
ch_total = mean(ch_alpha);

figure();
plot(t, ch_total, 'LineWidth', 1, 'Color', 'blue');
% xlim([0 10*1e3]); ylim([-6*10^(-6) 6*10^(-6)]);
