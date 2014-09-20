function cf = cf_launch(s)
    % CF_LAUNCH()
    %   This is a 'launcher' file for CrampFit. It is designed to start an
    %   instance of CrampFit in a specified folder and to give it the 
    %   keyboard callback behavior you want.

    % this sets the default directory for File->Open
    if nargin < 1
        s = 'C:\Minion';
    end
	cf = CrampFit(s);
    
    % variable to hold the ranges we are trimming
    ranges = [];
    
    function keyFn(e)
        % do nothing if we don't have data loaded yet
        if isempty(cf.data)
            return
        end
        
        % to figure out what the keys are called, uncomment this line
        disp(e);
        
        if strcmp(e.Character,'f')
            % create the requisite virtual signals (filters)

            % just add a nice low-pass filter
            cf.data.addVirtualSignal(@(d) filt_lp(d,4,200),'Low-pass');
            
            % and add them to each signal panel
            for i=1:numel(cf.psigs)
                cf.psigs(i).sigs = [cf.psigs(i).sigs cf.psigs(i).sigs + cf.data.nsigs];
            end
            
            cf.refresh();


            disp('Filters added')

        elseif strcmp(e.Character,'n')
            % display a noise plot, a la ClampFit

            % if cursors, do those
            tr = cf.getCursors();
            if isempty(tr)
                % otherwise, do the full view
                tr = cf.getView();
            end
            % then make a noise plot
            plot_noise(cf.data,tr);

        elseif strcmp(e.Character,'s')
            % select channels (in a fast5 file)

            if ~strcmp(cf.data.ext,'.fast5')
                return
            end

            % pop up input box to enter desired channels
            val = inputdlg('Enter channels to view, separated by commas:      ','CrampFit');
            if isempty(val) || isempty(val{1})
                return
            end
            chans = str2num(val{1});
            chans = chans(and(chans >= cf.data.header.minChan, chans <= cf.data.header.maxChan));
            if isempty(chans)
                errordlg('Invalid channel numbers entered!','CrampFit');
                return
            end
            % reload with appropriate channels
            cf.data = SignalData(cf.data.filename,'Channels',chans);
            % remove any signals that exist no more
            for i=1:numel(cf.psigs)
                cf.psigs(i).sigs = cf.psigs(i).sigs(cf.psigs(i).sigs <= numel(chans));
            end
            cf.refresh();
        end
    end

    % and set our all-important keyboard callback
    cf.setKeyboardCallback(@keyFn);
end

