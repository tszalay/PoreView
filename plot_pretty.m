function plot_pretty(cf)
%PLOT_PRETTY Makes a print-worthy plot that copies current CrampFit window
%   plot_pretty(cf)
    
    fig = figure('Name','CrampFit Plot','NumberTitle','off');
    %'MenuBar','none',...
    %    'NumberTitle','off','DockControls','off');
    
    % get the data, and whether we're looking at reduced
    d = cf.data.getViewData(range);
    
    % set the axes color maps to be lighter if using reduced
    CO = get(cf.fig, 'DefaultAxesColorOrder');
    
    % now create subplots and panels and stuff
    npanels = numel(cf.psigs);
    
    % create axes
    ax = [];
    
    for i=1:npanels
        subplot(npanels,1,i);
        ax = axes();
    end
    
    copyobj copyobj copyobj!!!!

    % and replot everything
    for i=1:npanels
        % now, don't clear everything (using cla)
        % instead, just delete the lines we drew previous
        delete(findobj(obj.psigs(i).axes,'Tag','CFPLOT'));

        % plot the selected signals, if any
        if isempty(obj.psigs(i).sigs)
            continue
        end
        % set the axes color order
        set(obj.psigs(i).axes,'ColorOrder',CO);

        % get the plot handles
        hps = plot(obj.psigs(i).axes,d(:,1),d(:,obj.psigs(i).sigs));
        % and tag them to clear them next time, also make them
        % non-clickable
        set(hps,'Tag','CFPLOT','HitTest','off');
        % and move the plotted lines to the bottom of axes
        % this line slows it down a bit, but oh well...
        uistack(flipud(hps),'bottom');

        if (nargin < 2)
            % if we did setView(), reset Y
            obj.psigs(i).resetY();
        end
    end
    
    xlabel('Time (s)','FontSize',28)
    ylabel('Current (pA)','FontSize',28)
end

