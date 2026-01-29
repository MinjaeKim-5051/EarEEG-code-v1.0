%% Initialization
clear; clc;

startTime = datetime('now');
disp(['[START] ' datestr(startTime)])

sensor = 'earEEG';
device_name = 'NXP_QPP'; % BLE device name
% device_address = '208BD1497F58'; % BLE device address (ver.1 board)
device_address = '208BD1497F5B'; % BLE device address (ver.2 board)
save_name = 'ble_test.csv';
packet_size = 216;

% packet_num = 3000;
packet_num =1170000*2*1.5;

try
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

    t = NaT(packet_num,1);
    
    % receive BLE data
    for i = 1:packet_num
        [bledata, timestamp] = read(nxp,'oldest');
        t(i) = timestamp;
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

        % disp(['[pNum] = ' num2str(i)])
        if mod(i, 1625) == 0
            fprintf('%d min', i/1625);
        end
    end

catch ME
    crashTime = datetime('now');
    disp(['[CRASH] ' datestr(crashTime)])
    disp(['[MESSAGE] ' ME.message])
    
    elapsed_C = crashTime - startTime;
    disp(['[ELAPSED_C] ' char(elapsed_C)])

end

%%
elapsed_s = seconds(t(end) - t(1));    
total_bytes = packet_num * packet_size;
bps = (total_bytes * 8) / elapsed_s; 
fprintf("Throughput: %.1f bps \n", bps);

%% Disconnect
unsubscribe(nxp) % disconnect
disp("Disconnect!");

endTime = datetime('now');
disp(['[END] ' datestr(endTime)])

elapsed = endTime - startTime;
disp(['[ELAPSED] ' char(elapsed)])
