function [posedge, negedge] = edge_detector(varargin)
%edge_detector (digital 신호 edge 검출기)
%     입력인수 #1 : plot_opt (false 또는 ture), plot 표시 여부
%     입력인수 #2 : data (vector), 데이터
%     입력인수 #3 : mid_point (scalar), 데이터 중간값
%
%     [posedge, negedge] = our_SNDR_func(plot_opt, data)

try
    narginchk(2,3);
catch
    msg = fprintf('Received %d and required 2 (or 3) inputs\n', length(varargin));
    error(msg);
end

switch nargin
    case 2
        plot_opt = varargin{1};
        data = varargin{2};
        mid_point = 0;
    case 3
        plot_opt = varargin{1};
        data = varargin{2};
        mid_point = varargin{3};
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
half = (data > mid_point);
token = half(1);
idx_p = 1;
idx_n = 1;

negedge = nan(1,length(data));
posedge = nan(1,length(data));
idx_neg = 1;
idx_pos = 1;

while true
    if (token == 1)
        idx_n = find(half(idx_p:end) == 0,1) + idx_p - 1;
        if (isempty(idx_n))
            break;
        else
%             negedge = [negedge, idx_n];
            negedge(idx_neg) = idx_n;
            idx_neg = idx_neg + 1;
        end
    end
    
    idx_p = find(half(idx_n:end) == 1,1) + idx_n - 1;
    if (isempty(idx_p))
        break;
    end
%     posedge = [posedge, idx_p];
    posedge(idx_pos) = idx_p;
    idx_pos = idx_pos + 1;
    
    token = 1;
end

negedge = negedge(~isnan(negedge));
posedge = posedge(~isnan(posedge));
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (plot_opt)
    figure; hold on; grid on;
    plot(data,'-o','MarkerIndices',posedge,'Markerfacecolor','g','MarkerSize',5);
    plot(data,'-o','MarkerIndices',negedge,'Markerfacecolor','r','MarkerSize',5);
end