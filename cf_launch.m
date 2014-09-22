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
        %disp(e);
        
        if strcmp(e.Character,'f')
            % ask user what filters they want to add

            str = inputdlg('Enter desired filter and frequency/param:','CrampFit',1,{'lp 10000'});
            
            strs = strsplit(str{1});
            
            if numel(strs) < 2
                return
            end
            
            param = str2double(strs{2});
            if isnan(param) || param <= 0
                return
            end

            switch strs{1}
                case 'lp'
                    filtname = sprintf('Low-pass (%d Hz)', param);
                    fsigs = cf.data.addVirtualSignal(@(d) filt_lp(d,4,param),filtname);
                case 'hp'
                    filtname = sprintf('High-pass (%d Hz)', param);
                    fsigs = cf.data.addVirtualSignal(@(d) filt_hp(d,4,param),filtname);
                case 'med'
                    filtname = sprintf('Median (%d pts)', param);
                    fsigs = cf.data.addVirtualSignal(@(d) filt_med(d,param),filtname);
                otherwise
                    return
            end            
            
            % and replace original signals with new ones
            % uh trust me on this one
            for i=1:numel(cf.psigs)
                s = cf.psigs(i).sigs;
                s(s<=cf.data.nsigs+1) = s(s<=cf.data.nsigs+1) + fsigs(1) - 2;
                cf.psigs(i).sigs = s;
            end
            
            cf.refresh();

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

