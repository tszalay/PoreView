classdef CrampFit < handle
    %CRAMPFIT Analysis suite for streaming signal data
    
    properties
        data
        fig
        panels
        xaxis
        sigs
    end
    
    methods
        function obj = CrampFit(fname)
            % for now, let's just load data as we open program
            obj.data = SignalData(fname);
            % start making GUI objects
            obj.fig = figure('Name','CrampFit!!!1111','MenuBar','none',...
                'NumberTitle','off');
            
            % the main border layout container, top bar, bottom bar, and
            % middle signal panels
            obj.panels = BorderLayout(obj.fig,50,60,0,0);
            % give it a padded border, so the axes that live in it are
            % lined up with the ones above it
            set(obj.panels.South,'BorderType','line','BorderWidth',1);
            set(obj.panels.South,'HighlightColor',get(obj.panels.South,'BackgroundColor'));
            set(obj.panels.Center,'BorderType','none');
            
            function b = isIn(pos,p)
                if (pos(1) > p(1) && pos(1) < (p(1)+p(3)) &&...
                            pos(2) > p(2) && pos(2) < (p(2)+p(4)))
                    b = 1;
                else
                    b = 0;
                end
            end
            function [h ind]=getHandle(pos)
                for i=1:2
                    p = getpixelposition(obj.sigs(i).haxes,true);
                    if isIn(pos,p)
                        h = obj.sigs(i).haxes;
                        ind = i;
                        return;
                    end
                end
                h = -1;
                ind = -1;
            end
            function scrollCallback(h,e)
                pos = get(obj.fig,'CurrentPoint');
                [h ind] = getHandle(pos);
                if (h==-1)
                    return
                end
                pt = get(obj.sigs(ind).haxes,'CurrentPoint');
                pty = pt(1,2);
                ylim = obj.sigs(ind).getY();
                s = 0.5*e.VerticalScrollCount;
                ylim = sort(pty + (1+s)*(ylim-pty));
                obj.sigs(ind).setY(ylim);
            end
            function mouseMoveX(h,e,r)
                pt0 = get(obj.xaxis,'UserData');
                pt1 = get(obj.xaxis,'CurrentPoint');
                xr = sort([pt0(1) pt1(1,1)]);

                set(r,'Parent',obj.xaxis);
                set(r,'YData',[0,0],'XData',xr,'LineWidth',8);
            end
            function mouseMoveY(h,e,ind,r)
                pt0 = get(obj.sigs(ind).hyaxis,'UserData');
                pt1 = get(obj.sigs(ind).hyaxis,'CurrentPoint');
                yr = sort([pt0(2) pt1(1,2)]);

                set(r,'Parent',obj.sigs(ind).hyaxis);
                set(r,'XData',[0,0],'YData',yr,'LineWidth',5);
            end
            function mouseUpX(h,e,r)
                delete(r);
                pt0 = get(obj.xaxis,'UserData');
                set(obj.xaxis,'UserData','');
                pt1 = get(obj.xaxis,'CurrentPoint');
                xrange = sort([pt0(1) pt1(1,1)]);
                if xrange(1)==xrange(2)
                    return
                end
                obj.setView(xrange);
                set(obj.fig,'WindowButtonUpFcn','');
                set(obj.fig,'WindowButtonMotionFcn','');
            end
            function mouseUpY(h,e,ind,r)
                delete(r);
                pt0 = get(obj.sigs(ind).hyaxis,'UserData');
                set(obj.sigs(ind).hyaxis,'UserData','');
                pt1 = get(obj.sigs(ind).hyaxis,'CurrentPoint');
                yrange = sort([pt0(2) pt1(1,2)]);
                if yrange(1)==yrange(2)
                    return
                end
                obj.sigs(ind).setY(yrange);
                set(obj.fig,'WindowButtonUpFcn','');
                set(obj.fig,'WindowButtonMotionFcn','');
            end
            function mouseDown(h,e)
                pos = get(obj.fig,'CurrentPoint');
                % check if it's within x-region
                conts = [obj.sigs(1).handle.West,obj.sigs(2).handle.West,obj.panels.South];
                axs = [obj.sigs(1).haxes,obj.sigs(2).haxes,obj.xaxis];
                ind = -1;
                for i=1:3
                    p = getpixelposition(conts(i),true);
                    if (i < 3)
                        p(1) = p(1) + 30;
                        p(3) = p(3) - 30;
                    else
                        p(2) = p(2) + 30;
                        p(4) = p(4) - 30;
                    end
                    if isIn(pos,p)
                        ind = i;
                        break;
                    end
                end
                if (ind == -1)
                    return
                end
                pt = get(axs(ind),'CurrentPoint');
                set(axs(ind),'UserData',pt(1,1:2));
                r = line();
                if (ind < 3)
                    set(obj.fig,'WindowButtonUpFcn',{@mouseUpY, ind, r});
                    set(obj.fig,'WindowButtonMotionFcn',{@mouseMoveY, ind, r});
                else
                    set(obj.fig,'WindowButtonUpFcn',{@mouseUpX, r});
                    set(obj.fig,'WindowButtonMotionFcn',{@mouseMoveX, r});
                end
            end
            
            set(obj.fig,'WindowScrollWheelFcn',@scrollCallback);
            set(obj.fig,'WindowButtonDownFcn',@mouseDown);
            
            sig1p = uipanel('Parent',obj.panels.Center,'Position',[0 0.5 1 0.5]);
            set(sig1p,'BorderType','line','BorderWidth',1);
            set(sig1p,'HighlightColor','black');

            sig2p = uipanel('Parent',obj.panels.Center,'Position',[0 0 1 0.5]);
            set(sig2p,'BorderType','line','BorderWidth',1);
            set(sig2p,'HighlightColor','black');
            
            obj.sigs = obj.sigPanel(sig1p);
            obj.sigs(2) = obj.sigPanel(sig2p);
            
            % make a dummy panel to hold the buttons, so we can set its
            % resize function to move the buttons around
            butpanel = uipanel('Parent',obj.panels.South,'Position',[0 0 1 1],'BorderType','none');
            
            % make an x-axis for display porpoises only. this will need to
            % get resized correctly later, sadly :-/
            hxaxis = axes('Parent',obj.panels.South,'TickDir','out',...
                'Position',[0 1 1 0.01],'YTickLabel','');
            
            obj.xaxis = hxaxis;
            
            % again, screw scroll bars
            function butFcn(h,o,e)
                xlim = get(hxaxis,'XLim');
                dx = xlim(2)-xlim(1);
                switch(e)
                    case 1
                        xm = mean(xlim);
                        xlim = xm+2*(xlim-xm);
                    case 2
                        xlim = xlim-dx/8;
                    case 3
                        % zoom all the way out, for this one
                        xlim = [];
                    case 4
                        xlim = xlim+dx/8;
                    case 5
                        xm = mean(xlim);
                        xlim = xm+0.5*(xlim-xm);
                end
                obj.setView(xlim);
            end
            % now make the buttons
            nbut = 5;
            buts = zeros(nbut,1);
            
            buts(1) = uicontrol('Parent', butpanel, 'String','<html>-</html>',...
                'callback', {@butFcn, 1});
            buts(2) = uicontrol('Parent', butpanel, 'String','<html>&larr;</html>',...
                'callback', {@butFcn, 2});
            buts(3) = uicontrol('Parent', butpanel, 'String','<html>A</html>',...
                'callback', {@butFcn, 3});
            buts(4) = uicontrol('Parent', butpanel, 'String','<html>&rarr;</html>',...
                'callback', {@butFcn, 4});
            buts(5) = uicontrol('Parent', butpanel, 'String','<html>+</html>',...
                'callback', {@butFcn, 5});
            
            % how to move buttons when thingy gets resized
            function resizeFcn(o,e)
                % get height of panel in pixels
                set(butpanel,'Units','pixels');
                sz = get(butpanel,'Position');
                set(butpanel,'Units','normalized');
                % figure out where the middle is
                mid = sz(3)/2;
                for i=1:nbut
                    % position the buttons
                    set(buts(i),'Position',[mid+(i-nbut/2-1)*20,3,20,20]);
                end
                % also need to resize x-axis labels
                set(hxaxis,'Units','Pixels');
                set(hxaxis,'Position',[sz(1)+60,sz(4)+2,sz(3)-60,1]);
            end
            % set the resize function
            set(butpanel, 'ResizeFcn', @resizeFcn);
            % and call it to set default positions
            resizeFcn
            
            % and set the view to a default value
            obj.setView([]);
        end
        
        function setView(obj,range)
            %SETVIEW sets the x-limits (with bounding, of course)
            
            wasempty = 0;
            if (isempty(range))
                range = [obj.data.tstart obj.data.tend];
                wasempty = 1;
            end
            
            dr = range(2)-range(1);
            if (dr > obj.data.tend)
                dr = obj.data.tend;
            end
            
            if (range(1) < 0)
                range = range - range(1);
            end
            if (range(2) > obj.data.tend)
                range = [-dr 0] + obj.data.tend;
            end
            
            set(obj.xaxis,'XLim',range);
            for h=[obj.sigs.haxes]
                set(h,'XLim',range);
            end
            
            d = obj.data.getViewData(range);
            for i=1:2
                h = obj.sigs(i).haxes;
                ylim = get(h,'YLim');
                cla(h);
                plot(obj.sigs(i).haxes,d(:,1),d(:,i+1));
                if (wasempty)
                    obj.sigs(i).resetY();
                else
                    obj.sigs(i).setY(ylim);
                end
            end
        end
        
        function sig = sigPanel(obj,parent)
            %SIGPANEL creates panel for a single current trace
            
            % make a panel to hold the entire thing
            % we're doing this so we don't have to overwrite any resize
            % functions in our parents
            panel = uipanel('Parent',parent,'Position',[0 0 1 1],'BorderType','none');
                        
            % make a main axis object to hold the data
            
            hyaxes = axes('Parent',panel,'Position',[0 0 1 1],...
                'TickDir','out','Box','off');
            haxes = axes('Parent',panel,'Position',[0 0 1 1],...
                'XTickLabel','','YTickLabel','',...
                'XColor', 0.8*[1 1 1],'YColor', 0.8*[1 1 1],'GridLineStyle','-','Box','on');
            % and gridify it
            grid
            hold(haxes)

            % magic function to make Y-axes consistent
            linkprop([hyaxes haxes],{'YLim','Position'});
            
            % screw scroll bars, you never need to scroll the current trace
            % so we'll just do buttons instead
            % the callback scales the y limits of things
            function ylim = getY()
                ylim = get(haxes,'YLim');
            end
            function setY(ylim)
                set(haxes,'YLimMode','manual');
                set(haxes,'YLim',ylim);
            end
            function resetY()
                set(haxes,'YLimMode','auto');
                ylim = getY();
                setY(ylim);
                set(haxes,'YLimMode','manual');
            end
            function shiftY(zoom,offset)
                ylim = getY();
                dy = ylim(2)-ylim(1);
                ym = mean(ylim);
                ylim = ym+zoom*(ylim-ym);
                ylim = ylim+dy*offset;
                
                setY(ylim);
            end
            
            function butFcn(h,o,e)
                switch(e)
                    case 1
                        shiftY(2,0);
                    case 2
                        shiftY(1,-0.25);
                    case 3
                        resetY();
                    case 4
                        shiftY(1,0.25);
                    case 5
                        shiftY(0.5,0);
                end
            end
            % now make the buttons
            nbut = 5;
            buts = zeros(nbut,1);
            
            buts(1) = uicontrol('Parent', panel, 'String','<html>-</html>',...
                'callback', {@butFcn, 1});
            buts(2) = uicontrol('Parent', panel, 'String','<html>&darr;</html>',...
                'callback', {@butFcn, 2});
            buts(3) = uicontrol('Parent', panel, 'String','<html>A</html>',...
                'callback', {@butFcn, 3});
            buts(4) = uicontrol('Parent', panel, 'String','<html>&uarr;</html>',...
                'callback', {@butFcn, 4});
            buts(5) = uicontrol('Parent', panel, 'String','<html>+</html>',...
                'callback', {@butFcn, 5});
            
            % how to move buttons when thingy gets resized
            function resizeFcn(o,e)
                % get height of panel in pixels
                set(panel,'Units','pixels');
                sz = get(panel,'Position');
                set(panel,'Units','normalized');
                % figure out where the middle is
                mid = sz(4)/2;
                for i=1:nbut
                    % position the buttons
                    set(buts(i),'Position',[3,mid+(i-nbut/2-1)*20,20,20]);
                end
                % now position the axes object too
                set(haxes,'Units','Pixels');
                set(hyaxes,'Units','Pixels');
                sz(1) = sz(1) + 60;
                sz(3) = sz(3) - 60;
                set(haxes,'Position',sz);
                set(hyaxes,'Position',sz);
            end
            % set the resize function
            set(panel, 'ResizeFcn', @resizeFcn);
            % and call it to set default positions
            resizeFcn
            
            sig = [];
            sig.handle = panel;
            sig.haxes = haxes;
            sig.shiftY = @shiftY;
            sig.setY = @setY;
            sig.resetY = @resetY;
            sig.getY = @getY;
        end
    end
    
end

