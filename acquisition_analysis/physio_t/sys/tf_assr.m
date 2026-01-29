clear;clc;

DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\ASSR\overall\";

Signal_list = [1:2];
nSignals = length(Signal_list);

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
    
    [pp,fp,tp] = pspectrum(ch_diff_nw, fsam, 'spectrogram', 'FrequencyLimits',[1, 50],'FrequencyResolution',1);
    df = fp(2) - fp(1);
    
    if i == 1
        psd_noASSR = sqrt(pp);
    elseif i == 2
        psd_ASSR = sqrt(pp);
    end

end

figure();

subplot(2,1,1);
imagesc(tp, fp, psd_noASSR*1e6);
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Average Spectrogram');
colorbar;
% ylim([30 50]); xlim([0 120]); caxis([1 12]);

subplot(2,1,2);
imagesc(tp, fp, psd_ASSR*1e6);
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Average Spectrogram');
colorbar;
% ylim([30 50]); xlim([0 120]); caxis([1 12]);
