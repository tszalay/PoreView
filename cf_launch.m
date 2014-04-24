function cf = cf_launch()
    % CF_LAUNCH()
    %   This is a 'launcher' file for CrampFit. It is designed to start an
    %   instance of CrampFit in a specified folder and to give it the 
    %   keyboard callback behavior you want.

    % this sets the default directory for File->Open
	cf = CrampFit('C:\Axon\Nanopores');
    
    % variable to hold the ranges we are trimming
    ranges = [];
    
    function keyFn(e)
        % do nothing if we don't have data loaded yet
        if isempty(cf.data)
            return
        end
        
        % to figure out what the keys are called, uncomment this line
        function d=fakeevent(d)
                inds = find(and(d(:,1) > 1.0, d(:,1) < 1.0001));
                d(inds,2:end) = d(inds,2:end) + 0.1;
                % also create some fake noise
                n = randn(size(d,1),1);
                nf = fft(n);
                nf = nf./sqrt(1:length(nf))';
                n = fft(nf)/length(nf);
                d(:,2) = d(:,2) + 10*real(n);
        end
        
        function d=lpfwd(d)
            si = d(2,1)-d(1,1);
            wn = 2*500*si;    
            if (wn > 1)
                return
            end
            [b a] = butter(2, wn, 'low');
            for i=2:size(d,2)
                m = mean(d(:,i));
                d(:,i) = filter(b,a,d(:,i));
            end
        end
        
        function d=medfwd(d)
            d = filt_med(d,13);
            d(:,2:end) = circshift(d(:,2:end),[7,1]);
        end
        
        function d=cusum(d)
            S = 0;
            for i=1:size(d,1)
                S = max(0,S+d(i,3)-d(i,2)-0.07);
                d(i,2) = d(i,3)-d(i,2);
                d(i,3) = S;
            end
        end
            
        if strcmp(e.Character,'k')
            % remove a range of points between cursors
            xlim = cf.getCursors();
            if isempty(xlim)
                % cursors are invisible
                return
            end
            
            % get average of endpoints, in a narrow range around them
            y0s = mean(cf.data.getByTime(xlim(1),xlim(1)+0.001));
            y1s = mean(cf.data.getByTime(xlim(2),xlim(2)-0.001));
            % and their average
            yave = mean([y0s; y1s]);
            % and add it to ranges
            ranges(end+1,:) = [xlim yave(2:cf.data.nsigs+1)];
            % update virtual signal
            cf.data.addVirtualSignal(@(d) filt_rmrange(d,ranges),'Range-edited');
            % and refresh visible points
            cf.refresh();
            % and display some stuff
            fprintf('Removed %f to %f\n',xlim(1),xlim(2));
            
        elseif strcmp(e.Character,'f')
            % create the requisite virtual signals
            
            
            
            ff = cf.data.addVirtualSignal(@fakeevent,'Fake');
            fl = cf.data.addVirtualSignal(@lpfwd,'LP',ff);
            fc = cf.data.addVirtualSignal(@cusum,'Cusum',[fl ff]);
            %cf.data.addVirtualSignal(@(d) medfwd(lpfwd(d)),'LP->Med',ff);
            %cf.data.addVirtualSignal(@(d) lpfwd(medfwd(d)),'Med->LP',ff);
            
            % also set which signals to draw in each panel, you can play
            % with this all you like
            %cf.setSignalPanel(1, f_rm(1));
            
            % draw both median-filtered panels
            %cf.addSignalPanel(f_med);

            disp('Filters added')
        
        elseif strcmp(e.Character,'n')
            % display a noise plot!
            
            % if cursors, do those
            tr = cf.getCursors();
            if isempty(tr)
                % otherwise, do the full view
                tr = cf.getView();
            end
            % then make a noise plot
            plot_noise(cf.data,tr,[cf.psigs.sigs]);
        end
    end

    % and set our all-important keyboard callback
    cf.setKeyboardCallback(@keyFn);
end

