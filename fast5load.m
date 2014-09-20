function [ d, h ] = fast5load(filename, range, channels)
%FAST5LOAD Loads an Oxford Nanopore fast5-generated file

% important header fields:
    % si
    % ndata
    % tstart
    % tend
    % nsigs
    % also include: channels
    % (which are the 'valid' channels from requested)

    d = [];
    
    % unlike other ones, we're only returning header here if info requested
    % otherwise, we assume channels and range is valid...!
    if strcmp(range,'info')
        % header request
        h = [];
        % check the channels
        numpts = 0;
        chans = [];
        for chan = 1:512
            chanstr = ['/Raw/Channel_', num2str(chan), '/Signal'];
            try
                s = h5info(filename, chanstr);
            catch
                % this channel isn't present, so skip it
                continue
            end
            % channel exists
            chans(end+1) = chan;
            numpts = s.Dataspace.Size;
        end
        
        h.numPts = numpts;
        % min and max channels in the original file
        h.minChan = min(chans);
        h.maxChan = max(chans);
        
        samplerate = h5readatt(filename, ['/Raw/Channel_', num2str(chan), '/Meta'], 'sample_rate');
        
        h.si = 1.0/samplerate;
        
        return;
    end

    % no header, just return data
    d = zeros(range(2)-range(1),numel(channels));
    
    for i=1:numel(channels)
        chan = channels(i);
        chanstr = ['/Raw/Channel_', num2str(chan), '/Signal'];
        % read corresponding channel's points
        d(:,i) = h5read(filename, chanstr, range(1)+1, range(2)-range(1));
    end
end

