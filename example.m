function vout = example(  )

    % load a file
    %c = CrampFit('C:\Axon\Nanopores\14301033.abf');
    c = CrampFit('C:\AxoData\14301033.abf');
    
    ranges = [];
    
    function keyFn(e)
        disp(e)
        if ~strcmp(e.Character,'k')
            return
        end
        
        xlim = c.getCursors();
        % get average of endpoints
        y0s = mean(c.data.getByTime(xlim(1),xlim(1)+0.001));
        y1s = mean(c.data.getByTime(xlim(2),xlim(2)-0.001));
        % and their average
        yave = mean([y0s; y1s]);
        % and add it to ranges
        ranges(end+1,:) = [xlim yave(2:c.data.nsigs+1)];
        % update virtual signal
        c.data.addVirtualSignal(@(d) filt_rmrange(d,ranges),'Range-edited');
        % and refresh
        c.refresh();
    end

    c.setKeyboardCallback(@keyFn);

    % add virtual signals
    % subselected data filter, remove nothing yet
    s = c.data.addVirtualSignal(@(d) filt_rmrange(d,ranges),'Range-edited');
    % high pass acts on subselected data
    hp = c.data.addVirtualSignal(@(d) filt_hp(d,4,100),'High-pass',[1 s]);
    % tell median to act on high-passed data
    c.data.addVirtualSignal(@(d) filt_med(d,13),'Median',[1 hp]);
    
    % this sets which signals to draw in each panel
    c.psigs(1).sigs = 4;
    c.psigs(2).sigs = 5;
    
    % and draw a rectangle
    r = rectangle('Position',[100, -4, 1, 8],'Parent',c.psigs(1).axes,'EdgeColor','r');
    l = line([50 50],[-4 4],'Parent',c.psigs(1).axes,'Color','g');
    
    vout = c;
end

