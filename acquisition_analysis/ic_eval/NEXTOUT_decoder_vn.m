clear;
clc;
rng default;

%% Set Variables & Data Load
%%% Data Load
DIR = "C:\Users\minjaeKim\Desktop\earEEGpaper\Experiment\Noise\Overall_noise\";
FILE_NAMES = "NOUT0_noise_withBuffer_5.csv"; % 256kHz ~ 16kHz

idx_file = 1;
fsam = 64e3;
fcomp = fsam;
disp("File #" + string(idx_file) + " is started");
DATA_LOC = DIR+FILE_NAMES(idx_file);

opts = detectImportOptions(DIR+FILE_NAMES(idx_file));
Data = readmatrix(DATA_LOC,opts);

NFFT = size(Data,1);
t = (0:NFFT-1).*(1/fcomp);
t = t(:);

% ch1 = Data(1:NFFT,1); % data
% ch2 = Data(1:NFFT,5); % data
% ch3 = Data(1:NFFT,9); % data
ch4 = Data(1:NFFT,13); % data


%% Decode
%%% Plot Decoded Signals
% [parsedVal1,~] = parseChan_Limit_1ch(ch1);
% [parsedVal2,~] = parseChan_Limit_1ch(ch2);
% [parsedVal3,~] = parseChan_Limit_1ch(ch3);
[parsedVal4,~] = parseChan_Limit_1ch(ch4);

N=length(t);
fs = 64e3;

% S_1 = abs(fft(parsedVal1)/N*2); 
% S_1 = S_1(1:N/2); 
% f_1 = (0:length(S_1)-1) /N;
% 
% S_2 = abs(fft(parsedVal2)/N*2); 
% S_2 = S_2(1:N/2); 
% f_2 = (0:length(S_2)-1) /N;
% 
% S_3 = abs(fft(parsedVal3)/N*2); 
% S_3 = S_3(1:N/2); 
% f_3 = (0:length(S_3)-1) /N;

S_4 = abs(fft(parsedVal4)/N*2); 
S_4 = S_4(1:N/2); 
f_4 = (0:length(S_4)-1) /N;


% fs_1 = 10;  % signal: 10Hz
fx_1 = 1;   % f_low
fx_2 = 100;  % f_high

% 주파수 대역 찾기
bn_1 = N*fx_1/fs + 1; %f_low
bn_2 = N*fx_2/fs + 1; %f_high 

% total_power_1 = sum(S_1(bn_1:bn_2).^2);
% noise_dB_1 = 10*log10(total_power_1);
% noise_rms_1 = (10^(noise_dB_1/20)/sqrt(2)*1e6)
% 
% total_power_2 = sum(S_2(bn_1:bn_2).^2);
% noise_dB_2 = 10*log10(total_power_2);
% noise_rms_2 = (10^(noise_dB_2/20)/sqrt(2)*1e6)
% 
% total_power_3 = sum(S_3(bn_1:bn_2).^2);
% noise_dB_3 = 10*log10(total_power_3);
% noise_rms_3 = (10^(noise_dB_3/20)/sqrt(2)*1e6)
% 
total_power_4 = sum(S_4(bn_1:bn_2).^2);
noise_dB_4 = 10*log10(total_power_4);
noise_rms_4 = (10^(noise_dB_4/20)/sqrt(2)*1e6)


freqN = f_4*fs;
del_f = freqN(2)-freqN(1);
del_N = round(1/del_f);

% V2Hz_1 = (S_1.^2)/del_f;
% V2Hz_2 = (S_2.^2)/del_f;
% V2Hz_3 = (S_3.^2)/del_f;
% V2Hz_4 = (S_4.^2)/del_f;
V2Hz_4 = (N/(2*fs)) * (S_4.^2);
% V2Hz_44 = (S_44.^2)/del_f;

df = fs / N;
noise_rms_4_recal = sqrt( sum( V2Hz_4(bn_1:bn_2) * df ) ) * 1e6;


nBlock_4 = floor(length(V2Hz_4) / del_N);
V2Hz_cut_4 = V2Hz_4(1:nBlock_4*del_N);

V2Hz_mat_4 = reshape(V2Hz_cut_4, del_N, nBlock_4);
V2Hz_4_1Hz = mean(V2Hz_mat_4, 1);


% VrtHz_1 = sqrt(V2Hz_1_1Hz');
% VrtHz_2 = sqrt(V2Hz_2_1Hz');
% VrtHz_3 = sqrt(V2Hz_3_1Hz');
VrtHz_4 = sqrt(V2Hz_4_1Hz');

% InRef_1 = VrtHz_1;
% InRef_2 = VrtHz_2;
% InRef_3 = VrtHz_3;
InRef_4 = VrtHz_4;


figure;
xlabel('Frequency (Hz)]');
ylabel('Noise Density (V/\surdHz)');

% loglog(freqN(1:del_N:end),InRef_1); hold on;
% xlim([0.5 500]);
% 
% loglog(freqN(1:del_N:end),InRef_2); hold on;
% xlim([0.5 500]);
% 
% loglog(freqN(1:del_N:end),InRef_3); hold on;
% xlim([0.5 500]);

p = loglog(freqN(1:del_N:end),InRef_4); hold on;
xlim([0.5 500]); ylim([5*10^(-8) 5*10^(-6)]);
p.Color = "blue";
p.LineWidth = 1.5;
grid on;

f_1Hz = (0:nBlock_4-1)';
loglog(f_1Hz,InRef_4);
