classdef CrampFit < handle
    %CRAMPFIT Analysis suite for streaming signal data
    
    properties
        data
        fig
        panels
        xaxes
        sigs
    end
    properties
        DEFS
    end
    
    methods
        function obj = CrampFit(fname)
            % some UI defs
            obj.DEFS = [];
            obj.DEFS.LEFTWID        = 60;
            obj.DEFS.BOTHEIGHT      = 60;
            obj.DEFS.BUTWID         = 20;
            obj.DEFS.BUTLEFT        = 3;
            obj.DEFS.BUTBOT         = 3;
            
            % for now, let's just load data as we open program
            obj.data = SignalData(fname);
            % start making GUI objects
            obj.fig = figure('Name','CrampFit!!!1111','MenuBar','none',...
                'NumberTitle','off');
            
            % the main layout components
            obj.panels = [];
            obj.panels.Middle = uipanel('Parent',obj.fig,'Position',[0 0.5 1 0.5],'Units','Pixels');
            obj.panels.Bottom = uipanel('Parent',obj.fig,'Position',[0 0.5 1 0.5],'Units','Pixels');
            
            % give it an invisible padded border, so the axes that live 
            % in it are automatically lined up with the ones above it
            %set(obj.panels.Bottom,'BorderType','line','BorderWidth',1);
            %set(obj.panels.Bottom,'HighlightColor',get(obj.panels.Bottom,'BackgroundColor'));
            set(obj.panels.Bottom,'BorderType','none');
            set(obj.panels.Middle,'BorderType','none');
            
            % handles the resizing of the main panels
            function mainResizeFcn(o,e)
                sz = getPixelPos(obj.fig);

                % 
                set(obj.panels.Bottom,'Position',[1,0,sz(3)+2,obj.DEFS.BOTHEIGHT]);
                % set this guy outside the edges of the figure by one pixel
                % horizontally, to hide the border on the sides
                set(obj.panels.Middle,'Position',[0,obj.DEFS.BOTHEIGHT,sz(3)+2,sz(4)-obj.DEFS.BOTHEIGHT]);
            end
            set(obj.fig,'ResizeFcn',@mainResizeFcn);
            mainResizeFcn
            
            % ========== X AXIS CODE ===========
            % make an x-axis for display porpoises only. this will need to
            % get resized correctly later, sadly :-/
            hxaxes = axes('Parent',obj.panels.Bottom,'TickDir','out',...
                'Position',[0 1 1 0.01],'YTickLabel','');
            
            obj.xaxes = hxaxes;
            
            % again, screw scroll bars
            function shiftX(zoom,offset)
                xlim = get(hxaxes,'XLim');
                dx = xlim(2)-xlim(1);
                xm = mean(xlim);
                xlim = xm+zoom*(xlim-xm);
                xlim = xlim+dx*offset;
                obj.setView(xlim);
            end
            
            % now make the buttons
            nbut = 5;
            buts = zeros(nbut,1);
            
            buts(1) = uicontrol('Parent', obj.panels.Bottom, 'String','<html>-</html>',...
                'callback', @(~,~) shiftX(2,0));
            buts(2) = uicontrol('Parent', obj.panels.Bottom, 'String','<html>&larr;</html>',...
                'callback', @(~,~) shiftX(1,-0.25));
            buts(3) = uicontrol('Parent', obj.panels.Bottom, 'String','<html>R</html>',...
                'callback', @(~,~) obj.setView([]));
            buts(4) = uicontrol('Parent', obj.panels.Bottom, 'String','<html>&rarr;</html>',...
                'callback', @(~,~) shiftX(1,0.25));
            buts(5) = uicontrol('Parent', obj.panels.Bottom, 'String','<html>+</html>',...
                'callback', @(~,~) shiftX(0.5,0));
            
            % how to move buttons when thingy gets resized
            function resizeFcn(~,~)
                % get height of panel in pixels
                sz = getPixelPos(obj.panels.Bottom);
                % figure out where the middle is
                mid = sz(3)/2;
                for i=1:nbut
                    % position the buttons
                    set(buts(i),'Position',[mid+(i-nbut/2-1)*obj.DEFS.BUTWID,obj.DEFS.BUTBOT,obj.DEFS.BUTWID,obj.DEFS.BUTWID]);
                end
                % also need to resize x-axis labels
                set(obj.xaxes,'Units','Pixels');
                set(obj.xaxes,'Position',[sz(1)+obj.DEFS.LEFTWID,sz(4)+2,sz(3)-obj.DEFS.LEFTWID,1]);
            end
            % set the resize function
            set(obj.panels.Bottom, 'ResizeFcn', @resizeFcn);
            % and call it to set default positions
            resizeFcn
            
            % ========== SIGNALS CODE ===========
            obj.sigs = obj.makeSignalPanel(obj.panels.Middle);
            obj.sigs(2) = obj.makeSignalPanel(obj.panels.Middle);
            
            set(obj.sigs(1).panel,'Position',[0,0.5,1,0.5]);
            set(obj.sigs(2).panel,'Position',[0,0,1,0.5]);
            
            obj.setMouseCallbacks();
            
            % now that it's all made, set the view to a default value
            obj.setView([]);
        end
        
        function setMouseCallbacks(obj)
            % Creates mouse callback interface, by defining a ton of fns
            
            % point-rectangle hit test
            function b = isIn(pos,p)
                b = false;
                if (pos(1) > p(1) && pos(1) < (p(1)+p(3)) &&...
                            pos(2) > p(2) && pos(2) < (p(2)+p(4)))
                    b = true;
                end
            end
            % function that steps through all relevant objects to figure
            % out which one is at a given position
            function [hnd,ind,pt,s] = getHandleAt(pos)
                % pos should be in pixels
                if nargin < 1
                    pos = get(obj.fig,'CurrentPoint');
                end
                % first, let's check signals
                nsig = length(obj.sigs);
                for i=1:nsig
                    ind = i;
                    % did we click on a plot?
                    if isIn(pos,getpixelposition(obj.sigs(i).axes,true))
                        hnd = obj.sigs(i).axes;
                        pt = get(hnd,'CurrentPoint');
                        pt = pt(1,1:2);
                        s = 'a';
                        return;
                    end
                    % are we over the y axis part?
                    if (isIn(pos,getpixelposition(obj.sigs(i).panel,true)) &&...
                            pos(1) > 0.6*obj.DEFS.LEFTWID)
                        % return the handle to the main axes anyway, s'more
                        % useful that way
                        hnd = obj.sigs(i).axes;
                        pt = get(hnd,'CurrentPoint');
                        pt = pt(1,1:2);
                        s = 'y';
                        return;
                    end
                end
                % ok, not signals, so let's check x-axis
                if (isIn(pos,getpixelposition(obj.panels.Bottom)) &&...
                        pos(2) > 0.6*obj.DEFS.BOTHEIGHT)
                    hnd = obj.xaxes;
                    ind = -1;
                    pt = get(hnd,'CurrentPoint');
                    pt = pt(1,1:2);
                    s = 'x';
                    return;
                end
                hnd = -1;
                ind = -1;
                pt = [];
                s = '';
            end
            % handles scrolling zoom in-out
            function scrollCallback(~,e)
                % figure out what we are over, if anything
                [hnd,ind,pt,s] = getHandleAt();
                
                % quit if found nothing
                if (hnd==-1)
                    return
                end
                
                if (s == 'y')
                    % we're scrolling inside a y-axis, scroll y-lims
                    pty = pt(2);
                    ylim = obj.sigs(ind).getY();
                    s = 0.5*e.VerticalScrollCount;
                    ylim = sort(pty + (1+s)*(ylim-pty));
                    obj.sigs(ind).setY(ylim);
                elseif (s == 'a' || s == 'x')
                    % we're scrolling in a plot, scroll the time axis
                    ptx = pt(1);
                    xlim = get(obj.xaxes,'XLim');
                    s = 0.5*e.VerticalScrollCount;
                    xlim = sort(ptx + (1+s)*(xlim-ptx));
                    obj.setView(xlim);
                end
            end
            
            function mouseMoveX(r)
                % get start and current point
                pt0 = get(obj.xaxes,'UserData');
                pt1 = get(obj.xaxes,'CurrentPoint');
                % convert to x-range
                xr = sort([pt0(1) pt1(1,1)]);
                % update the line
                set(r,'YData',[0,0],'XData',xr,'LineWidth',8);
            end
            function mouseMoveY(r,ind)
                % get start and current point
                pt0 = get(obj.sigs(ind).yaxes,'UserData');
                pt1 = get(obj.sigs(ind).yaxes,'CurrentPoint');
                % y-range, sorted
                yr = sort([pt0(2) pt1(1,2)]);
                % set x limits of y-line
                xl = get(obj.sigs(ind).yaxes,'XLim');
                % and update the line
                set(r,'XData',[xl(1),xl(1)],'YData',yr,'LineWidth',5);
            end
            function mouseUpX(r)
                % kill the line
                delete(r);
                % get the x-range one last time
                pt0 = get(obj.xaxes,'UserData');
                pt1 = get(obj.xaxes,'CurrentPoint');
                xrange = sort([pt0(1) pt1(1,1)]);
                % make sure we zoomed at all
                if xrange(1)==xrange(2)
                    return
                end
                % then update the view
                obj.setView(xrange);
                % and clear callbacks
                set(obj.fig,'WindowButtonUpFcn','');
                set(obj.fig,'WindowButtonMotionFcn','');
            end
            function mouseUpY(r,ind)
                % kill the line
                delete(r);
                % y-range as usual
                pt0 = get(obj.sigs(ind).yaxes,'UserData');
                pt1 = get(obj.sigs(ind).yaxes,'CurrentPoint');
                yrange = sort([pt0(2) pt1(1,2)]);
                if yrange(1)==yrange(2)
                    return
                end
                % zoom in
                obj.sigs(ind).setY(yrange);
                % and clear callbacks
                set(obj.fig,'WindowButtonUpFcn','');
                set(obj.fig,'WindowButtonMotionFcn','');
            end
            function mouseMovePan(ind)
                % this is the doozy
                pt0 = get(obj.sigs(ind).yaxes,'UserData');
                pt1 = get(obj.sigs(ind).axes,'CurrentPoint');
                pt1 = pt1(1,1:2);
                % so we want to get pt0 and pt1 equal
                % to get that guy under the mouse
                dpt = pt1-pt0;
                % and x axis
                xl = get(obj.xaxes,'XLim');
                obj.setView(xl - dpt(1));
                % now update y-axis
                yl = obj.sigs(ind).getY();
                obj.sigs(ind).setY(yl-dpt(2));
            end
            function mouseUpPan()
                % clear callbacks
                set(obj.fig,'WindowButtonUpFcn','');
                set(obj.fig,'WindowButtonMotionFcn','');
            end
            function mouseDown(~,~)
                % figure out what we are over, if anything
                [hnd,ind,pt,s] = getHandleAt();
                
                sel = get(obj.fig,'SelectionType');
                if (hnd == -1)
                    return
                end
                
                % see if we are dragging on x or y axes
                if (s == 'x' && strcmp(sel,'normal'))
                    % make a line
                    r = line();
                    set(r,'Parent',obj.xaxes);
                    % store the drag start point
                    set(obj.xaxes,'UserData',pt);
                    % and set appropriate callbacks, with line as data
                    set(obj.fig,'WindowButtonUpFcn',@(~,~) mouseUpX(r));
                    set(obj.fig,'WindowButtonMotionFcn',@(~,~) mouseMoveX(r));
                elseif (s == 'y' && strcmp(sel,'normal'))
                    % make a line
                    r = line();
                    set(r,'Parent',obj.sigs(ind).yaxes);
                    % store the drag start point
                    set(obj.sigs(ind).yaxes,'UserData',pt);
                    % and set appropriate callbacks, with line as data
                    set(obj.fig,'WindowButtonUpFcn',@(~,~) mouseUpY(r, ind));
                    set(obj.fig,'WindowButtonMotionFcn',@(~,~) mouseMoveY(r, ind));
                elseif (s == 'a' && strcmp(sel,'extend'))
                    % store the drag start point
                    set(obj.sigs(ind).yaxes,'UserData',pt);
                    % and set the callbacks
                    set(obj.fig,'WindowButtonUpFcn',@(~,~) mouseUpPan());
                    set(obj.fig,'WindowButtonMotionFcn',@(~,~) mouseMovePan(ind));
                end
            end
            
            % set global figure callbacks
            set(obj.fig,'WindowScrollWheelFcn',@scrollCallback);
            set(obj.fig,'WindowButtonDownFcn',@mouseDown);
        end
        
        function sig = makeSignalPanel(obj, parent)
            % create and ultimately return a struct containing panel info
            sig = [];
            
            % make a panel to hold the entire thing
            sig.panel = uipanel('Parent',parent,'Position',[0 0 1 1],'Units','Normalized');
            % give it a stylish border
            set(sig.panel,'BorderType','line','BorderWidth',1);
            set(sig.panel,'HighlightColor','black');
            
            % first make a fake axes object that just displays the label
            sig.yaxes = axes('Parent',sig.panel,'Position',[0 0 1 1],...
                'TickDir','out','Box','off','XLimMode','manual');
            % and then the main axes object for showing data
            sig.axes = axes('Parent',sig.panel,'Position',[0 0 1 1],...
                'XTickLabel','','YTickLabel','',...
                'XColor', 0.8*[1 1 1],'YColor', 0.8*[1 1 1],'GridLineStyle','-','Box','on');
            % and gridify it
            grid
            hold(sig.axes)

            % magic function to make Y-axes consistent, saving me some
            % bookkeeping headaches and stuff
            linkprop([sig.yaxes sig.axes],{'YLim','Position'});
            
            % screw scroll bars, you never need to scroll the current trace
            % so we'll just do buttons instead
            % the callback scales the y limits of things
            function ylim = getY()
                ylim = get(sig.axes,'YLim');
            end
            function setY(ylim)
                set(sig.axes,'YLimMode','manual');
                set(sig.axes,'YLim',ylim);
            end
            function resetY()
                set(sig.axes,'YLimMode','auto');
                ylim = getY();
                setY(ylim);
                set(sig.axes,'YLimMode','manual');
            end
            function shiftY(zoom,offset)
                ylim = getY();
                dy = ylim(2)-ylim(1);
                ym = mean(ylim);
                ylim = ym+zoom*(ylim-ym);
                ylim = ylim+dy*offset;
                
                setY(ylim);
            end
            % save the y-limit functions to our little struct
            sig.shiftY = @shiftY;
            sig.setY = @setY;
            sig.resetY = @resetY;
            sig.getY = @getY;
            
            
            % now make the buttons
            nbut = 5;
            % store the handles in a little array
            buts = zeros(nbut,1);
            % buts isn't getting put in sig, because we don't need to
            % touch it from the outside...
            
            buts(1) = uicontrol('Parent', sig.panel, 'String','<html>-</html>',...
                'callback', @(~,~) sig.shiftY(2,0));
            buts(2) = uicontrol('Parent', sig.panel, 'String','<html>&darr;</html>',...
                'callback', @(~,~) sig.shiftY(1,-0.25));
            buts(3) = uicontrol('Parent', sig.panel, 'String','<html>A</html>',...
                'callback', @(~,~) sig.resetY());
            buts(4) = uicontrol('Parent', sig.panel, 'String','<html>&uarr;</html>',...
                'callback', @(~,~) sig.shiftY(1,0.25));
            buts(5) = uicontrol('Parent', sig.panel, 'String','<html>+</html>',...
                'callback', @(~,~) sig.shiftY(0.5,0));
            
            % how to move buttons when thingy gets resized
            function resizeFcn(~,~)
                % get height of panel in pixels
                sz = getPixelPos(sig.panel);
                % figure out where the middle is
                mid = sz(4)/2;
                for i=1:nbut
                    % position the buttons
                    set(buts(i),'Position',...
                        [obj.DEFS.BUTLEFT,mid+(i-nbut/2-1)*obj.DEFS.BUTWID,obj.DEFS.BUTWID,obj.DEFS.BUTWID]);
                end
                % now position the axes objects too
                set(sig.axes,'Units','Pixels');
                set(sig.yaxes,'Units','Pixels');
                sz(1) = sz(1) + obj.DEFS.LEFTWID;
                sz(3) = sz(3) - obj.DEFS.LEFTWID;
                % set bottom to 1
                sz(2) = 1;
                set(sig.axes,'Position',sz);
                set(sig.yaxes,'Position',sz);
            end
            % set the resize function
            set(sig.panel, 'ResizeFcn', @resizeFcn);
            % and call it to set default positions
            resizeFcn            
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
            if (dr == 0)
                return
            end
            
            if (range(1) < 0)
                range = range - range(1);
            end
            if (range(2) > obj.data.tend)
                range = [-dr 0] + obj.data.tend;
            end
            
            set(obj.xaxes,'XLim',range);
            for h=[obj.sigs.axes]
                set(h,'XLim',range);
            end
            
            d = obj.data.getViewData(range);
            for i=1:2
                h = obj.sigs(i).axes;
                ylim = get(h,'YLim');
                cla(h);
                plot(obj.sigs(i).axes,d(:,1),d(:,i+1));
                if (size(d,2) > 3)
                    plot(obj.sigs(i).axes,d(:,1),d(:,i+3),'r');
                end
                if (wasempty)
                    obj.sigs(i).resetY();
                else
                    obj.sigs(i).setY(ylim);
                end
            end
        end
    end
    
end

% some useful helper functions
function sz = getPixelPos(hnd)
    old_units = get(hnd,'Units');
    set(hnd,'Units','Pixels');
    sz = get(hnd,'Position');
    set(hnd,'Units',old_units);
end