classdef SignalData < handle
    %SIGNALDATA Class wrapper for streaming signals (esp. abfs)
    %   Allows caching and whatnot
    
    properties (SetAccess = public)
        filename    % filename we are working with
        ndata       % number of points
        nsigs       % number of signals (not including time)
        datared     % subsampled data, in min-max form (3D array)
        nred        % number of points to store in the reduced array
        si          % sampling interval
        tstart      % start time of file
        tend        % end time of file
        cstart      % starting point of loaded cached data
        cend        % endpoint of loaded cached data
        dcache      % cached data that we're working with
    end
    
    methods
        function obj = SignalData(fname)
            % start working!
            obj.filename = fname;
            % try to load file, see if we got it right
            try
                % first, load some info on the file
                [d,si,h]=abfload(obj.filename,'info');
            catch
                fprintf(2,'Failed to load file!\n')
                return
            end
            obj.si = si*1e-6;
            obj.ndata = h.dataPtsPerChan;
            obj.tstart = 0; % dunno how to get actual start from abf
            obj.tend = obj.si*obj.ndata;
            obj.nsigs = h.nADCNumChannels;
            
            % set cache to default values
            obj.cstart = 0;
            obj.cend = 0;
            obj.dcache = [];

            % try to load subsampled file
            try
                tmp = load([obj.filename  '_red.mat'],'red');
                obj.datared = tmp.red;
                obj.nred = size(obj.datared,1);
                fprintf('\nLoaded reduced data from %s_red.mat.\n',obj.filename);
            catch
                % CHANGE THIS LINE TO CHANGE HOW MANY REDUCED POINTS WE
                % HAVE WHEEEEEE
                obj.nred = 5e5;
                
                fprintf('\n\nBuilding reduced data with %d points -  0%%',obj.nred);
                obj.datared = zeros(obj.nred,obj.nsigs+1);
 
                % go through entire file and build it
                % this function returns index into full data of ith point
                fullIndex = @(ind) floor((obj.ndata-1)*ind/obj.nred);
                obj.datared(:,1) = obj.si*fullIndex(1:obj.nred);
                % full points per reduced point
                dind = floor(obj.ndata/obj.nred);
                % number of red. points to do per file loading step
                % load ~ 4 sec at a time, should be an even number
                nstepred = 2*floor(2/obj.si/dind);
                
                ired = 0;
                
                while (ired < obj.nred)
                    % current index and next index
                    inext = ired + nstepred;
                    if (inext > obj.nred)
                        inext = obj.nred;
                    end
                    
                    % load next data slice
                    d = obj.getData(fullIndex(ired),fullIndex(inext));
                    % generate array of indices - each el corresponds to
                    % reduced point index (yeah this is a bit hacky oh well)
                    % eg. this array ends up as [1 1 1 1 1 2 2 2 2 2 3 etc]
                    inds = floor(linspace(1,0.999+(inext-ired)*0.5,size(d,1)))';
                    
                    % get the min and max values for each signal
                    for i=1:obj.nsigs
                        mins = accumarray(inds,d(:,i),[nstepred/2,1],@min);
                        maxs = accumarray(inds,d(:,i),[nstepred/2,1],@max);
                        np = 2*size(mins,1);
                        % make alternating min-max data
                        % and write it to output array
                        obj.datared(ired+1:ired+np,i+1) = reshape([mins maxs]',[np 1]);
                    end
                                        
                    ired = ired + nstepred;
                    
                    % display percent loaded something something foo
                    fprintf('\b\b\b%2d%%',floor(100*ired/obj.nred));
                end
                
                obj.datared = obj.datared(1:obj.nred,:);
                
                % and save the data
                try
                    red = obj.datared;
                    save([obj.filename  '_red.mat'],'red');
                    fprintf('\nDone, saved to %s_red.mat.\n',obj.filename);
                catch
                    fprintf(2,'Could not save reduced data to %s_red.mat!\n',obj.filename);
                end
            end
        end
        
        % returns reduced or full data in a specified time range
        % with the full only being returned if reduced would be <1000 pts
        function d = getViewData(obj,trange)
            dt = trange(2)-trange(1);
            if (trange(1) < 0)
               trange(1) = 0;
            end
            if (trange(2) < 0)
               trange(2) = 0;
            end
            if (trange(1) > obj.tend)
                trange(1) = obj.data.tend;
            end
            if (trange(2) > obj.tend)
                trange(2) = obj.tend;
            end
            
            redsi = (obj.tend-obj.tstart)/obj.nred;
            % number of points from reduced set we would be using
            nr = dt/redsi;
            if nr > 1000
                inds = floor(trange/redsi);
                d = obj.datared(1+inds(1):inds(2),:);
            else
                pts = floor(trange/obj.si);
                d = obj.getFullData(pts(1),pts(2));
            end
        end
        
        % returns data in the specified point range
        % loads it if it isn't loaded yet
        function d = getData(obj, ptstart, ptend)
            % check bounds first thing
            if (ptstart < 0 || ptend > obj.ndata-1 || ptend<ptstart)
                fprintf(2,'Invalid points %d:%d requested\n',int64(ptstart),int64(ptend));
            end
            ptstart = max(0,ptstart);
            % keep one point away from end, cause this is actually one too
            % many points, and we can't really request it
            ptend = min(obj.ndata-1,ptend);
            
            if (ptstart < obj.cstart || ptend > obj.cend)
                % cache miss, load a new cache
                % size range requested
                dpt = (ptend-ptstart);
                % conservatively load a million points (or more if needed)
                if (dpt < 1e6)
                    % extend loading range to ~1 million
                    obj.cstart = round(ptstart - (1e6-dpt)/2);
                    obj.cend = round(ptend + (1e6-dpt)/2);
                else
                    % or just by 10 each way to avoid indexing errors etc
                    obj.cstart = ptstart-10;
                    obj.cend = ptend+10;
                end
                % and check bounds
                obj.cstart = max(obj.cstart,0);
                obj.cend = min(obj.cend,obj.ndata);
                
                % load file, add in a 'cheat point' at the end just to make
                % sure we get everything
                [T, obj.dcache] = evalc('abfload(obj.filename,''start'',obj.cstart*obj.si,''stop'',(obj.cend+1)*obj.si);');
                %fprintf('Loaded %d points (%d-%d) into the cache\n   ',size(obj.dcache,1),floor(obj.cstart),floor(obj.cend));
            end
            % now we definitely have the points
            % +1 for Matlab's 1-indexed arrays ugh
            pts = int64(ptstart - obj.cstart+1);
            pte = int64(ptend - obj.cstart+1);
            
            d = obj.dcache(pts:pte,:);
        end
        
        % returns data with time added on
        function d = getFullData(obj,ptstart,ptend)
            d = obj.getData(ptstart,ptend);
            npts = size(d,1);
            ts = obj.si*((1:npts)-1+ptstart);
            d = [ts' d];
        end
        
        % subsref lets us overwrite MATLAB's parens indexing, for niceness
        function b = subsref(obj,index)
            switch index(1).type
                case '()'
                    % Handle parenthesis indexing
                    inds = index(1).subs{1};
                    
                    b = obj.getFullData(min(inds),max(inds));
                    
                    if (length(index(1).subs) > 1)
                        if (index(1).subs{2} ~= ':')
                            b = b(:,index(1).subs{2});
                        end
                    end
                    
                case '.'
                    % Keep the default behavior for .
                    if (length(index) == 1) % property access
                        b = eval(['obj.' index(1).subs]);
                    else
                        b = eval(['obj.' index(1).subs '(index(2).subs{1})']);
                    end
                    
                case '{}'
                    % Load by times instead
                    ts = [index(1).subs{1} index(1).subs{2}];
                    
                    % convert to indices
                    inds = floor(ts/obj.si);
                    
                    % and load!
                    d = obj.getData(inds(1),inds(2));
                    b = d;
            end
        end
    end
end

