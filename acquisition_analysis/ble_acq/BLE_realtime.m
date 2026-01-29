%% MATLAB BLE plot
warning('off','all')

%% Initialization
clear; clc;
sensor = 'earEEG';
device_name = 'NXP_QPP'; % BLE device name
% device_address = '208BD1497F58'; % BLE device address (ver.1 board)
device_address = '208BD1497F5B'; % BLE device address (ver.2 board)
save_name = 'ble_test.csv';
packet_size = 216; % MAX 244;

packet_num = 3250;
%packet_num = 500;

sampling_frequency = 64e3/64;
data_per_batch = 1080;
batch_interval = data_per_batch / sampling_frequency;
time_window = 120;
max_data_points = time_window * sampling_frequency;
n = 1;

LSB = 1/2^12;
OSR = 64;
fs = sampling_frequency;

total_time_passed = 0;
x_data = [];
y_data = [];
new_data = [];

out_total_ch1 = [];
out_total_ch2 = [];
out_total = [];

yupper_p = [];
ylower_p = [];
yupper_r = [];
ylower_r = [];

figure;
h = plot(nan, nan, LineWidth=0.8, Color="blue"); hold on
hu = plot(nan, nan, LineWidth=1.2, Color="red"); hold on
hl = plot(nan, nan, LineWidth=1.2, Color="red");
xlabel('Time(s)');
ylabel('Voltage(V)');
title('Real-Time Alpha Response Plotting');
grid on;
xlim([0, 120]);
% ylim([-0.01 0.01]);
ylim([-100*10^(-6) 100*10^(-6)]);
% set(gcf,'position',[1600, 200, 1150, 550]);


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
data_ble_ch1 = zeros(36,1);
data_ble_ch2 = zeros(36,1);
out_ble_ch1 = [];
out_ble_ch2 = [];


for i = 1:packet_num
    [bledata, timestamp] = read(nxp,'oldest');
    [~, ~, s] = hms(timestamp);
    for j = 1:packet_size
        vals(i,j+1) = bledata(j);
    end
    vals(i,1) = s;

    % 2-channel 3-Byte sorting
    for k = 1:packet_size/6
        data_ble_ch1(k) = hex2dec(strcat(dec2hex(bledata(6*(k-1)+1),2), dec2hex(bledata(6*(k-1)+2),2), dec2hex(bledata(6*(k-1)+3),2)));
        data_ble_ch2(k) = hex2dec(strcat(dec2hex(bledata(6*(k-1)+4),2), dec2hex(bledata(6*(k-1)+5),2), dec2hex(bledata(6*(k-1)+6),2)));
    end

    % data conversion
    out_ble_ch1 = (data_ble_ch1.*LSB/(2^(2*log2(OSR))));
    out_ble_ch2 = (data_ble_ch2.*LSB/(2^(2*log2(OSR))));
    
    % zero removal
    % for w = 1:length(out_ble_ch1)
    %     if ((out_ble_ch1(w) == 0) || (out_ble_ch1(w) == 1))
    %         if (w == 1)
    %             out_ble_ch1(w) = out_ble_ch1(w+1);
    %         else
    %             out_ble_ch1(w) = out_ble_ch1(w-1);
    %         end
    %     end
    % end

    for w = 1:length(out_ble_ch2)
        if ((out_ble_ch2(w) == 0) || (out_ble_ch2(w) == 1))
            if (w == 1)
                out_ble_ch2(w) = out_ble_ch2(w+1);
            else
                out_ble_ch2(w) = out_ble_ch2(w-1);
            end
        end
    end

    out_ble_diff = out_ble_ch1 - out_ble_ch2;
    
    out_total_ch1 = [out_total_ch1; out_ble_ch1];
    out_total_ch2 = [out_total_ch2; out_ble_ch2];
    out_total = [out_total; out_ble_diff];

    new_data = [new_data; out_ble_diff];
    
    % real-time plot
    if length(new_data) == data_per_batch * n
        [b,a] = butter(4,[7 15]/(fs/2),'bandpass');
        new_data_filt = filter(b,a,new_data);
        % new_data_filt = new_data;
        
        new_time = (total_time_passed + (0:data_per_batch-1) / sampling_frequency);
        total_time_passed = total_time_passed + batch_interval;
        x_data = [x_data, new_time];
        y_data = [y_data; new_data_filt(data_per_batch*(n-1)+1: end)];
        
        n = n+1;
        % if length(x_data) > max_data_points
        %     x_data = x_data(end-max_data_points+1:end);
        %     y_data = y_data(end-max_data_points+1:end);
        % end

        if (n < 18)
            [yupper_p1,ylower_p1] = envelope(y_data,500,'peak');
            [yupper_r1,ylower_r1] = envelope(y_data,500,'rms');
            yupper_p = yupper_p1;
            ylower_p = ylower_p1;
            yupper_r = yupper_r1;
            ylower_r = ylower_r1;
        else
            [yupper_p2,ylower_p2] = envelope(y_data,2000,'peak');
            [yupper_r2,ylower_r2] = envelope(y_data,2000,'rms');
            yupper_p = [yupper_p1; yupper_p2(17281:length(yupper_p2))];
            ylower_p = [ylower_p1; ylower_p2(17281:length(ylower_p2))];
            yupper_r = [yupper_r1; yupper_r2(17281:length(yupper_r2))];
            ylower_r = [ylower_r1; ylower_r2(17281:length(ylower_r2))];
        end

        % [yupper_p,ylower_p] = envelope(y_data,2000,'peak');
        % [yupper_r,ylower_r] = envelope(y_data,2000,'rms');

        
        if total_time_passed > time_window
            set(h, 'XData', x_data, 'YData', y_data);
            %set(hu, 'XData', x_data, 'YData', (2*yupper_p+yupper_r)/3);
            %set(hl, 'XData', x_data, 'YData', (2*ylower_p+ylower_r)/3);
            % xlim([x_data(1), x_data(end)]);
            xlim([x_data(1), 120]); 
        else
            set(h, 'XData', x_data, 'YData', y_data);
            %set(hu, 'XData', x_data, 'YData', (2*yupper_p+yupper_r)/3);
            %set(hl, 'XData', x_data, 'YData', (2*ylower_p+ylower_r)/3);
            % xlim([0 total_time_passed]);
            xlim([0 120]);
        end

        % pause(batch_interval);
    end
  
end


%% Disconnect
unsubscribe(nxp) % disconnect
disp("Disconnect!");

filename = 'BLE_EEG0_rt.xlsx';
data2excel = [out_total_ch1, out_total_ch2, out_total];
writematrix(data2excel,filename);
