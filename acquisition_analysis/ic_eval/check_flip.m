function [modulated_sig, rmse] = check_flip(varargin)
%check_flip
%     입력인수 #1 : signal 1
%     입력인수 #2 : signal 2
%     modulated_sig = check_flip(sig1. sig2)
%     [modulated_sig, rmse] = check_flip(sig1. sig2)
% 
%     sig1 : 벡터
%     sig2 : 벡터

narginchk(2,2); % 입력 인수 개수 확인 2개 이상 5개 이하

sig1 = varargin{1};
sig2 = varargin{2};

rmse1 = rms(sig1 - sig2);
rmse2 = rms(sig1 - flip(sig2,1));
rmse3 = rms(sig1 + sig2);
rmse4 = rms(sig1 + flip(sig2,1));

if min([rmse1,rmse2,rmse3,rmse4]) == rmse1
    modulated_sig = sig2;
    rmse = rmse1;
elseif min([rmse1,rmse2,rmse3,rmse4]) == rmse2
    modulated_sig = flip(sig2,1);
    rmse = rmse2;
elseif min([rmse1,rmse2,rmse3,rmse4]) == rmse3
    modulated_sig = -sig2;
    rmse = rmse3;
else
    modulated_sig = -flip(sig2,1);
    rmse = rmse4;
end

% grad1 = sig1(1) - sig1(100);
% grad2 = sig2(1) - sig2(100);
% grad3 = sig2(end) - sig2(end-100);
% 
% if abs(grad1 - grad2) < abs(grad1 - grad3)
%     idx = sig2;
% else
%     idx = flip(sig2,1);
% end
