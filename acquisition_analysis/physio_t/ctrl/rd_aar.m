% close all;
clear; clc;
rng default;
%% 

%%% Data Load
DIR = "C:\Users\mjkim\OneDrive\Desktop\CGX_actual\Alpha\";
FILE_NAMES = "AAR0002.xlsx"; % 256kHz ~ 16kHz

idx_file = 1;    
fsam = 500;
fcomp = fsam;
% disp("File #" + string(idx_file) + " is started");
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

names = {'F7','Fp1','Fp2','F8','F3','Fz','F4','C3','Cz','P8','P7','Pz','P4','T3','P3','O1','O2','C4','T4'};

T = table(AMI_total([1,4,11,10,14,19,16,17]), 'RowNames', names([1,4,11,10,14,19,16,17]));
disp(T)


%% Alpha band modulation (eye open/closed)

figure;
pspectrum(F7, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("F7"); caxis([-5 15]);

figure;
pspectrum(Fp1, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("Fp1"); caxis([-5 15]);

figure; 
pspectrum(Fp2, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("Fp2"); caxis([-5 15]);

figure; 
pspectrum(F8, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("F8"); caxis([-5 15]);

figure;
pspectrum(F3, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("F3"); caxis([-5 15]);

figure; 
pspectrum(Fz, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("Fz"); caxis([-5 15]);

figure; 
pspectrum(F4, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("F4"); caxis([-5 15]);

figure; 
pspectrum(C3, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("C3"); caxis([-5 15]);

figure; 
pspectrum(Cz, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("Cz"); caxis([-5 15]);

figure; 
pspectrum(C4, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("C4"); caxis([-5 15]);

figure; 
pspectrum(P3, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("P3"); caxis([-5 15]);

figure; 
pspectrum(Pz, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("Pz"); caxis([-5 15]);

figure; 
pspectrum(P4, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("P4"); caxis([-5 15]);

figure; 
pspectrum(P7, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("P7"); caxis([-5 15]);

figure;
pspectrum(O1, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("O1"); caxis([-5 15]);

figure; 
pspectrum(O2, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("O2"); caxis([-5 15]);

figure;
pspectrum(P8, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("P8"); caxis([-5 15]);

figure; 
pspectrum(T3, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("T3"); caxis([-5 15]);

figure; 
pspectrum(T4, fsam, 'spectrogram', 'FrequencyLimits',[6, 20],'FrequencyResolution',1)
title("T4"); caxis([-5 15]);
