clear;clc;

filename = 'white-noise.mp3'
[y, Fs] = audioread(filename);
y = vertcat(y, y, y, y, y, y, y);
%sound(y,Fs)

Fc = 40;

ASSR = ammod(y,Fc,Fs)

audiowrite('40Hz_AM_WGN.wav',ASSR,Fs);
sound(ASSR,Fs);

% sadsb = spectrumAnalyzer(SampleRate=Fs, PlotAsTwoSidedSpectrum=false, YLimits=[-60 30]);