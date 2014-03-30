function [ filtdata ] = filt_med( data, n )
%FILT_MED Runs a median filter on event data, with window size n

% copy to output
filtdata = data;
% then run medfilt1 with block size 1e4 to avoid out-of-memory errors
for i=2:size(data,2)
    filtdata(:,i) = medfilt1(data(:,i),n,1e3);
end

filtdata = filtdata(:,2:end);

end

