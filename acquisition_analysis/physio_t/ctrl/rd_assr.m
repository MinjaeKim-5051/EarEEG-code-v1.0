% close all;
clear; clc;
rng default;
%% 

%%% Data Load
DIR = "C:\Users\mjkim\OneDrive\Desktop\CGX_actual\ASSR\";
FILE_NAMES = "ASSR008.xlsx";
    
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

CGX_nw = [F7 Fp1 Fp2 F8 F3 Fz F4 C3 Cz P8 P7 Pz P4 T3 P3 O1 O2 C4 T4];
%% 

L = length(CGX_nw(:,1));
N=length(t);

w = hann(L);
CG = sum(w)/L;

CGX = CGX_nw .* w;

V2Hz_CGX = [];

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
end
V2Hz_CGX = V2Hz_CGX';

freq_1 = 0:nBlock-1;

names = {'F7','Fp1','Fp2','F8','F3','Fz','F4','C3','Cz','P8','P7','Pz','P4','T3','P3','O1','O2','C4','T4'};
figure();
for k = [1,4,11,10,14,19,16,17]
    % figure();
    p = semilogy(freq_1,V2Hz_CGX(k,1:end)*10^(-12), 'LineWidth', 1); hold on; % grid on;
    p.Color(4) = 0.6;
    legend(names([1,4,11,10,14,19,16,17]))
end
xlim([10 50]); ylim([0.8*10^(-12) 2*10^(-10)]);
