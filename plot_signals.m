function plot_signals(cf)
%PLOT_SIGNALS Makes a normal Matlab-style plot that copies currently
%   visible CrampFit window, without all the UI junk
%   plot_signals(cf)
    
    % create the figure
    fig = figure('Name','CrampFit Signals','NumberTitle','off');
    
    % set its position
    set(fig,'Units','normalized');
    set(fig,'Position',[0.1,0.1,0.8,0.8]);
    
    % set the axes color maps to be lighter if using reduced
    CO = get(cf.fig, 'DefaultAxesColorOrder');
    
    % now create subplots and copies of the panels and stuff
    npanels = numel(cf.psigs);
    
    hxax = cf.xaxes;
    
    signames = cf.data.getSignalList();
    
    for i=1:npanels
        % copy the original axes from crampfit
        hax = copyobj(cf.getAxes(i),fig);
        set(hax,'Units','Normalized');
        set(hax,'XColor',0.92*[1 1 1],'YColor',0.92*[1 1 1]);
        set(hax,'XTick',get(hxax,'XTick'),'YTick',get(cf.psigs(i).yaxes,'YTick'));
                
        % create axes object to show labels and titles, but no curves
        ax2 = axes('Units','Normalized','OuterPosition',[0 (npanels-i)/npanels 1 1/npanels],...
            'Color','none','Box','on','TickDir','in','Parent',fig, ...
            'XTickLabel',get(hxax,'XTickLabel'),'YTickLabel',get(cf.psigs(i).yaxes,'YTickLabel'), ...
            'XTick',get(hxax,'XTick'),'YTick',get(cf.psigs(i).yaxes,'YTick'), ...
            'XLim',get(hxax,'XLim'),'YLim',get(cf.psigs(i).yaxes,'YLim'),...
            'FontSize',12);
        
        set(ax2,'LooseInset',[0.07,0.2,0.02,0.13])
        
        % set their labels and stuff
        title(ax2,signames{cf.psigs(i).sigs(1)},'FontSize',14);
        xlabel(ax2,'Time (s)')
        ylabel(ax2,'Current (nA)')
        
        set(hax,'ActivePosition','OuterPosition');
        
        % and lock position of inner plot to outer plot
        set(hax,'UserData',linkprop([ax2 hax],'Position'));
    end
    
    % also make a close callback, cause I'm spoiled and used to this
    function keyFun(~,e)
        if strcmp(e.Key,'escape')
            close(fig);
            return
        end
    end
    set(fig,'WindowKeyPressFcn',@keyFun);
    
end

