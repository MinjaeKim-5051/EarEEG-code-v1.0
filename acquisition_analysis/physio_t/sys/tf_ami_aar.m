clear; clc;
rng default;
%% Data Load

DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\Alpha\overall\";

asd_rms = [];
psd_dB = [];
psd_all_dB = [];
out_rms = [];
out_dB = [];
psdSum = [];

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
     
    % spectrogram
    [pp,fp,tp] = pspectrum(ch_diff, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1);
    
    % power plot
    % [pp,fp,tp] = pspectrum(ch_diff, fsam, 'spectrogram', 'FrequencyLimits',[5, 30],'FrequencyResolution',1);
    
    df = fp(2) - fp(1);
    psd = pp ./ df;
    
    band_idx = (fp >= 8 & fp <= 13);
    band_power = mean(pp(band_idx, :), 1)
    
    band_all_power = mean(pp(:,:), 1); 
    
%     power_rms_new = band_power * 1e12;
%     psd_dB_new = 10 * log10(power_rms_new);
%     
%     power_all_rms_new = band_all_power * 1e12;
%     psd_all_dB_new = 10 * log10(power_all_rms_new);

    power_rms_new = band_power * 1e12;
    power_all_rms_new = band_all_power * 1e12;
    psd_dB_new = 10 * log10(power_rms_new./power_all_rms_new);
    psd_dB = [psd_dB; psd_dB_new];


    band_power_sum = sum(psd(band_idx, :) * df, 1);
    
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
    
    if isempty(psdSum)
        psdSum = pp(:,:);
    else
        psdSum = psdSum + pp(:,:);
    end

end
psdAvg = sqrt(psdSum ./ nSignals);

%% Alpha band plot

figure();
imagesc(tp, fp, psdAvg*1e6);
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Average Spectrogram');
colorbar;
% ylim([6 20]); caxis([2.5 6]); xlim([0 120]);

figure();
plot(tp, prctile(psd_dB,20), 'LineWidth', 0.3, 'Color', [0.678 0.847 0.902]); hold on;
plot(tp, prctile(psd_dB,80), 'LineWidth', 0.3, 'Color', [0.678 0.847 0.902]); hold on;
plot(tp, mean(psd_dB), 'LineWidth', 2, 'Color', 'blue');
% ylim([-3 5]);


AMI_mean = mean(AMI_total);
AMI_std = std(AMI_total);
