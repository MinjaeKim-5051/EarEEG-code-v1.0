%% MATLAB BLE RX

%% Initialization
clear; clc;
sensor = 'earEEG';
device_name = 'NXP_QPP'; % BLE device name
% device_address = '208BD1497F58'; % BLE device address (ver.1 board)
device_address = '208BD1497F5B'; % BLE device address (ver.2 board)
save_name = 'ble_test.csv';
packet_size = 216; % MAX 244;

packet_num =3250;
% packet_num =300;


%% BLE Connection
blelist
ble_nxp = ble(device_address); % set service name
ble_nxp.Characteristics;
nxp = characteristic(ble_nxp,"FEE9","D44BC439-ABFD-45A2-B575-925416129601");
% (characteristic param, SrvUUID, CharUUID)


%% BLE Main
subscribe(nxp); % connect
disp("Connect!");

vals = zeros(packet_num,packet_size+1);
data_dup_ch1 = zeros(packet_num*36,1);
data_dup_ch2 = zeros(packet_num*36,1);
% data_ble_ch1 = [];
% data_ble_ch2 = [];

% receive BLE data
for i = 1:packet_num
    [bledata, timestamp] = read(nxp,'oldest');
    [~, ~, s] = hms(timestamp);
    for j = 1:packet_size
        vals(i,j+1) = bledata(j);
    end

    vals(i,1) = s;

    % 2-channel 3-Byte sorting
    for k = 1:packet_size/6
        data_dup_ch1((i-1)*(packet_size/6)+k) = hex2dec(strcat(dec2hex(bledata(6*(k-1)+1),2), dec2hex(bledata(6*(k-1)+2),2), dec2hex(bledata(6*(k-1)+3),2)));
        data_dup_ch2((i-1)*(packet_size/6)+k) = hex2dec(strcat(dec2hex(bledata(6*(k-1)+4),2), dec2hex(bledata(6*(k-1)+5),2), dec2hex(bledata(6*(k-1)+6),2)));
    end

end

% zero remove
data_dup_ch1 = nonzeros(data_dup_ch1);
data_dup_ch2 = nonzeros(data_dup_ch2);

data_ble_ch1 = data_dup_ch1;
data_ble_ch2 = data_dup_ch2;

data_ble_ch1_hex = dec2hex(data_ble_ch1,6);
data_ble_ch2_hex = dec2hex(data_ble_ch2,6);

bit_time_diff = diff(vals(1:end,1));

LSB = 1/2^12;
OSR = 64;
fs = 64e3/64;

out_ble_ch1 = (data_ble_ch1.*LSB/(2^(2*log2(OSR))));
out_ble_ch2 = (data_ble_ch2.*LSB/(2^(2*log2(OSR))));

overR = find(out_ble_ch1>0.3);
out_ble_ch1(overR) = [];
out_ble_ch2(overR) = [];

out_ble_diff = out_ble_ch1 - out_ble_ch2;

NFFT = size(out_ble_ch2);
t = (0:NFFT-1).*(1/fs)*1e3;
t = t(:);


%% Plot
figure
subplot(2,1,1)
plot(t,out_ble_ch1);
subplot(2,1,2)
plot(t,out_ble_ch2);

figure
plot(t,out_ble_diff);



%% Filtered data
[filtered_ch1,~] = brick_wall_filter(out_ble_ch1,[50 inf],fs,true);
[filtered_ch2,~] = brick_wall_filter(out_ble_ch2,[50 inf],fs,true);
[filtered_diff,~] = brick_wall_filter(out_ble_diff,[50 inf],fs,true);


%% Disconnect
unsubscribe(nxp) % disconnect
disp("Disconnect!");


%% Export data to excel
filename = 'BLE_EEG0.xlsx';
data2excel = [t, out_ble_ch1, out_ble_ch2, out_ble_diff];
writematrix(data2excel,filename);
