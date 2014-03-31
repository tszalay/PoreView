function cf = example_basic()

    % load a file
    %cf = CrampFit('C:\Axon\Nanopores\14301033.abf');
    cf = CrampFit('C:\AxoData\14301033.abf');
    
    ranges = [];
    
    function keyFn(e)
        if strcmp(e.Character,'k')
            xlim = cf.getCursors();
            % get average of endpoints, in a narrow range around them
            y0s = mean(cf.data.getByTime(xlim(1),xlim(1)+0.001));
            y1s = mean(cf.data.getByTime(xlim(2),xlim(2)-0.001));
            % and their average
            yave = mean([y0s; y1s]);
            % and add it to ranges
            ranges(end+1,:) = [xlim yave(2:cf.data.nsigs+1)];
            % update virtual signal
            cf.data.addVirtualSignal(@(d) filt_rmrange(d,ranges),'Range-edited');
            % and refresh
            cf.refresh();
        end
    end

    cf.setKeyboardCallback(@keyFn);

    % add virtual signals
    % subselected data filter, remove nothing yet
    f_rm = cf.data.addVirtualSignal(@(d) filt_rmrange(d,ranges),'Range-edited');
    % high pass acts on subselected data
    f_hp = cf.data.addVirtualSignal(@(d) filt_hp(d,4,100),'High-pass',[1 f_rm]);
    % tell median to act on high-passed data
    f_med = cf.data.addVirtualSignal(@(d) filt_med(d,13),'Median',[1 f_hp]);
    
    % this sets which signals to draw in each panel
    cf.psigs(1).sigs = f_rm(1);
    cf.psigs(2).sigs = f_rm(2);
    % draw both median-filtered panels
    cf.addSignalPanel(f_med);
end

