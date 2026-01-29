function [ dataOut,scMat ] = parseChan_Limit_1ch( dataIn )
% Special thanks to Jaeouk Cho
dat_len=length(dataIn);
dataOut = zeros(dat_len,1);
scMat = zeros(dat_len,1);
% dataOut(:,1) = dataIn(:,1);
minScale = 2^-(12);
maxScale = 2^(-5);
%VREF = 0.806;
VREF = 1;

    
    % vectorize each channel
    dataCh = dataIn;
    
    %initialization
    y = zeros(1,5);
    y(5) = 1;
    y(3) = 1;
    scale = minScale;
       
    for inner = 1:numel(dataCh)-1 %inner: time
        % shift the histories out
        y(2:end) = y(1:end-1);
        y(1) = round(dataCh(inner));
        
        % now do a check on the histories and update scale;
        
        % if all the Y's are the same
        if ( all( y == y(1) ))
            scale = scale*2;
        %if all the three y's are not the same
        elseif (  (y(1) ~= y(2)) && (y(2) ~= y(3)) )
            scale = scale/2;
        end
        if (scale > maxScale)
            scale = maxScale;
        elseif (scale < minScale)
            scale = minScale;
        end
        
        % data value = previous value + (+/-)1* scale;
        delta = (sign(y(1)-0.5))*scale*2*VREF;
        temp = dataOut(inner) + delta;
        if (temp >= 1) %VREF
            dataOut(inner+1) = dataOut(inner);
        elseif (temp < -1) % VREF
            dataOut(inner+1) = dataOut(inner);
        else
            dataOut(inner+1) = temp;
        end
        
        scMat(inner+1) = scale;

    end
    
end


