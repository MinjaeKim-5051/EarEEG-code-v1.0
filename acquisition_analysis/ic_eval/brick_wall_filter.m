function [data_filt, noise_filt] = brick_wall_filter(varargin)
%brick_wall_filter (fft한 후 필요없는 주파수 제거하고(값을 0으로 바꿈) ifft해서 반환)
%     입력인수 #1 : data (vector), 데이터
%     입력인수 #2 : [a,b], 지울 주파수 범위
%     입력인수 #3 : sampling rate
%     입력인수 #4 : DC 제거
%
%     data_filt = brick_wall_filter(data, [a b], fs, DC_off)

try
    narginchk(3,4);
catch
    msg = fprintf('Received %d and required 3 (+ optional 1) inputs\n', length(varargin));
    error(msg);
end

data = varargin{1};
noise_rng = varargin{2};
fs = varargin{3};
switch nargin % nargin은 따로 설정해주지않아도 자동으로 지정됨, argument 개수
    case 3
        DC_off = true;
    case 4
        DC_off = varargin{4};
end

data = data(:);
L = length(data);

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
P1 = fft(data);
P2 = P1(1:floor(L/2)+1);

df = fs/L;
idx = ceil(noise_rng/df)+1;
idx(1) = max(1,idx(1));
idx(2) = min(length(P2),idx(2));

P2_noise = P2;
if (DC_off)
    P2(1) = 0;
end
% P2(idx(1):idx(2)) = 0;
P2(idx(1):idx(2)) = interp1([idx(1),idx(2)], ...
                            [P2(idx(1)),P2(idx(2))], ...
                            (idx(1):idx(2)),"spline");

P2_noise = P2_noise - P2;

if (mod(L,2))
    P1 = [P2;conj(flip(P2(2:end)))];
    P1_noise = [P2_noise;conj(flip(P2_noise(2:end)))];
else
    P1 = [P2;conj(flip(P2(2:end-1)))];
    P1_noise = [P2_noise;conj(flip(P2_noise(2:end-1)))];
end

data_filt = ifft(P1);
noise_filt = ifft(P1_noise);
end