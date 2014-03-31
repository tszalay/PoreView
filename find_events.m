function DNAevent = find_events(cf)
%FIND_EVENTS Finds and returns an array of DNAevent structs

    DNAevent = [];

    thresh = 0.07;
    
    sig = cf.psigs(2).sigs;

    % maximum range to check for events at any one time (set by memory)
    % maybe 100ms or so would be a good number for this
    maxpts = 1e5;
    
    % loop through entire file, a bit at a time
    curind = 0;
    
    while 1
        % next chunk of data
        data = cf.data.get(curind:curind+maxpts,sig);
        
        % if we have overstepped our bounds, aka are done with the file
        if isempty(data)
            return
        end
        
        % find next data exceeding threshold
        ind = find(data > thresh,1,'first');
        
        % if we didn't find any, skip to next range
        if isempty(ind)
            curind = curind + maxpts;
            continue
        end
        
        % move current index to here
        curind = curind + ind - 1;
        
        % ok now let's process it
        % see how we don't have to worry about overflows here?
        imin = curind;
        imax = curind + 400;

        % find the end of the event
        imax = find(cf.data.get(imin:imax,sig) > 0.75*thresh,1,'last');
        % make sure we have an end for the event
        if (isempty(imax))
            continue
        end
        % offset it to global
        imax = imax + imin - 1;

        % shift by one sample in each directon
        imin = imin-1;
        imax = imax+1;
        
        % and move curind too
        curind = imax;
        
        % event? maybe event?
        ts = [cf.data.get(imin,1), cf.data.get(imax,1)];
        % time range to view, extended past the event a bit
        viewt = [ts(1)-0.001, ts(2)+0.001];
        
        % we've decided we have a possibly good event, then
        dna = [];
        
        % store the data we want, including times
        dna.data = cf.data.get(imin:imax,[1 sig]);

        % and the start and end times for the event
        dna.tstart = ts(1);
        dna.tend = ts(2);

        % the average current blockage
        dna.blockage = abs(mean(dna.data(:,2)));
        
        % now query on-screen, see what we think
        % first, zoom in
        cf.setView(viewt);
        % then, draw some stuff
        h = cf.getAxes(2);
        plot(h, [viewt(1) ts(1) ts(1) ts(2) ts(2) viewt(2)],...
            [0 0 dna.blockage dna.blockage 0 0],'r');
        % this line ignores the stuff you drew, in case you're wondering
        cf.autoscaleY();
        % do this just for shits
        cf.setCursors(ts);
        
        k = cf.waitKey();
        % clear, and force a redraw
        cf.clearAxes();
        pause(0.01);
        
        if (k == 'q')
            return
        elseif (k ~= 'y')
            continue
        end
        
        % stupid matlab structs bug
        if isempty(DNAevent)
            DNAevent = dna;
        else
            DNAevent(end+1) = dna;
        end
    end
end

