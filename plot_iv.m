function [Vs, Is] = plot_iv(filename)
%PLOT_IV Plots IV curves from the file in filename

    try
        % try to load the entire file
        [d,si,h]=abfload(filename);
    catch
        fprintf(2,'Failed to load file %s as I-V!\n',filename);
        return
    end

    if (h.lEpisodesPerRun == 1)
        fprintf(2,'%s is not an IV curve.\n',filename);
        return
    end
    
    sz = size(d);
    
    Vs = linspace(-200,200,sz(3))';
    
    % hwo much of the data do we want to use?
    % start with last 1/4, for now
    indst = floor(sz(1)*0.75);
    Is = reshape(mean(d(indst:end,:,:),1),sz(2:3))';
    
    figure('Name',sprintf('I-V Plot of %s',filename),'NumberTitle','off');
    
    ax = axes('Position',[0.01 0.01 0.98 0.9],'Box','off','NextPlot','add');
    plts = plot(ax,Vs,Is,'Marker','o','MarkerSize',2,'MarkerEdgeColor','black');
    for i=1:length(plts)
        set(plts(i),'MarkerFaceColor',get(plts(i),'Color'));
    end
    title('Quick I-V Plot');
    set(ax,'XTickLabel','','YTickLabel','','XColor',0.8*[1 1 1],'YColor',0.8*[1 1 1]);
    grid on
    % now manually make axes, cuz matlab is dumb
    set(ax,'XLimMode','manual','YLimMode','manual');
    xlim = 1.1*get(ax,'XLim');
    ylim = 1.1*get(ax,'YLim');
    set(ax,'XLim',xlim);
    set(ax,'YLim',ylim);
    
    % draw outer box
    rectangle('Position',[xlim(1) ylim(1) (xlim(2)-xlim(1)), (ylim(2)-ylim(1))],...
        'Clipping','off','EdgeColor','black');

    % and labels
    dV = 40; % mV
	% V ticks, step from 20 to end-ish
    Vts = dV:dV:Vs(end);
    tickX = [-flip(Vts) Vts];
    
    % tick spacing in Y, do a clever thing
    dy = ylim(2)/4;
    ly = floor(log10(dy));
    dy = dy/10^ly;
    % dy is now between 1 and 10
    % so pick spacing to be sensible numbers only (1, 2.5, 5, 10)
    if (dy < 1.5)
        dy = 1;
    elseif (dy < 3.5)
        dy = 2.5;
    elseif (dy < 7.5)
        dy = 5;
    else
        dy = 10;
    end
    dy = dy * 10^ly;
    
    tickY = dy:dy:ylim(2);
    tickY = [-flip(tickY) tickY];
    
    set(ax,'XTick',tickX,'YTick',tickY);
    
    % now draw the labels
    for i=1:length(tickX)
        text(tickX(i),0,{'','',num2str(tickX(i))},'VerticalAlignment','middle',...
            'HorizontalAlignment','center','FontSize',8,'Parent',ax);
    end
    for i=1:length(tickY)
        text(0,tickY(i),['    ' num2str(tickY(i),'%#4.3g')],'VerticalAlignment','middle',...
            'HorizontalAlignment','left','FontSize',8,'Parent',ax);
    end
    
    % and add a bit to the lines
    tickX = [2*tickX(1) tickX 2*tickX(end)];
    tickY = [2*tickY(1) tickY 2*tickY(end)];
    plot(ax,tickX,0*tickX,'black','Marker','+');
    plot(ax,0*tickY,tickY,'black','Marker','+');
    
    % also display best-fit lines, while we're at it
    xs = [tickX(1) tickX(end)];
    hs = [];
    for i=1:sz(2)
        coeffs = polyfit(Vs,Is(:,i),1);
        % draw the line
        ys = coeffs(1)*xs + coeffs(2);
        hs(end+1) = plot(ax,xs,ys,'LineStyle','-.','Color',get(plts(i),'Color'));
        % and set the legend
        set(hs(end),'DisplayName',sprintf('\\sigma = %4.4g nS',100*coeffs(1)));
    end
    
    % now move original lines to the top
    uistack(flip(plts),'top');
    
    % get their names
    M = get(hs,'DisplayName');
    
    legend(hs,M,'Location','NorthWest');
    legend('show');
    
    Vs = 0.01*Vs;
end

