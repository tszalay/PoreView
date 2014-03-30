classdef SignalData < handle
    %SIGNALDATA Class wrapper for streaming signals (esp. abfs)
    %   Allows caching and whatnot
    
    % make it so these don't get screwed up
    properties (SetAccess=immutable)
        filename    % filename we are working with
        ndata       % number of points
        nsigs       % number of signals (not including time)
        datared     % subsampled data, in min-max form (3D array)
        nred        % number of points to store in the reduced array
        si          % sampling interval
        tstart      % start time of file, set to 0
        tend        % end time of file
        header      % original abf info header
    end
    
    % can't change these from the outside
    properties (SetAccess=private, Hidden=true)
        cstart      % starting point of loaded cached data
        cend        % endpoint of loaded cached data
        dcache      % cached data that we're working with
        
        nvsigs      % how many virtual signals?
        vnames      % cell array names of virtual signals
        vfuns       % cell array functions for virtual signals
        vsrcs       % cell arr, which columns get processed by each one
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
            
            % clear virtual signal parts
            obj.nvsigs = 0;
            obj.vnames = {};
            obj.vfuns = {};
            obj.vsrcs = {};
            
            obj.header = h;
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
                
                % trim off extra points
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
    end
    
    methods
        % returns reduced or full data in a specified time range
        % with the full one being returned once it would be few enough pts
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
            
            % reduced sampling interval
            redsi = (obj.tend-obj.tstart)/obj.nred;
            % number of points from reduced set we'd use
            nr = dt/redsi;
            % number of points from full set we would be using
            nfull = dt/obj.si;
            % only use reduced one if it wouldn't be visible (nr>1500)
            % and if there would be too many regular points (nfull>nred)
            if nfull > obj.nred && nr > 1500
                % use reduced
                inds = floor(trange/redsi);
                d = obj.datared(1+inds(1):inds(2),:);
            else
                % use full, if we have virtual signals the array will
                % be bigger and stuff and junk
                pts = floor(trange/obj.si);
                d = obj.getData(pts(1),pts(2));
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
                [T, d] = evalc('abfload(obj.filename,''start'',obj.cstart*obj.si,''stop'',(obj.cend+1)*obj.si);');
                %fprintf('Loaded %d points (%d-%d) into the cache\n   ',size(obj.dcache,1),floor(obj.cstart),floor(obj.cend));
                
                % make empty cache
                obj.dcache = zeros(size(d,1),1+obj.nsigs*(1+obj.nvsigs));
                
                % add time data on to cache, as first col
                npts = size(obj.dcache,1);
                ts = obj.si*((1:npts)-1+obj.cstart);
                % set, along with loaded data
                obj.dcache(:,1:obj.nsigs+1) = [ts' d];
                
                % now call virtual signal functions
                for i=1:obj.nvsigs
                    % which columns to write to?
                    dst = 1+obj.nsigs*i+(1:obj.nsigs);
                    % and which to read from
                    src = obj.vsrcs{i};
                    fun = obj.vfuns{i};
                    % and execute it
                    obj.dcache(:,dst) = fun(obj.dcache(:,src));
                end
            end
            % now we definitely have the points
            % +1 for Matlab's 1-indexed arrays ugh
            pts = int64(ptstart - obj.cstart+1);
            pte = int64(ptend - obj.cstart+1);
            
            d = obj.dcache(pts:pte,:);
        end
    
        % this is how to access the data from the outside
        % because overwriting subsref is dumb and slow, even if it is cute
        % calling this as data(1:10) is same as data([1,10])
        function d = data(obj,pts,sigs)
            if nargin < 3
                sigs = ':';
            end
            % get the data, including time
            d = obj.getData(min(pts),max(pts));
            % return only requested signals
            d = d(:,sigs);
        end
        
        % or this one, can call as getByTime([t0 t1]) or getByTime(t0,t1)
        function d = getByTime(obj,t0,t1)
            if nargin == 3
                t0 = [t0 t1];
            end
            pts = floor(t0/obj.si);
            d = obj.getData(min(pts),max(pts));
        end
        
        % now let's have some fun! virtual signals start here
        % give it a function, the name of the function, and which columns
        % to pass to the function (including virtual ones!)
        % if name already exists, it gets overwritten
        function addVirtualSignal(obj, fun, src)
            % if we didn't specify source, do time + orig. signals
            if (nargin < 3)
                src = 1:obj.nsigs+1;
            end
            % and save the data
            obj.nvsigs = obj.nvsigs + 1;
            i = obj.nvsigs;
            obj.vfuns{i} = fun;
            obj.vsrcs{i} = src;
        end
    end
end

