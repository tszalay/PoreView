classdef CrampFit < handle
    %CRAMPFIT Analysis suite for streaming signal data
    
    properties
        data
        fig
        panels
        xaxes
        sigs
        
        hcmenu
        sigmenus
        cursig
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
            
            % start making GUI objects
            obj.fig = figure('Name','CrampFit!!!1111','MenuBar','none',...
                'NumberTitle','off','DockControls','off');
            
            % how we load a new file
            function openFileFcn(~,~)
                % get a filename from dialog box
                [FileName,PathName] = uigetfile('*.abf');
                % and load (or attempt to)
                obj.loadFile([PathName FileName]);
            end
            
            % make the menu bar
            f = uimenu('Label','File');
            uimenu(f,'Label','Open','Callback',@openFileFcn,'Accelerator','O');
            uimenu(f,'Label','Quit','Callback',@(~,~) delete(obj.fig),'Accelerator','Q');
            
            % and the context menus
            obj.hcmenu = uicontextmenu();
            obj.sigmenus = [];
            
            sa = uimenu(obj.hcmenu,'Label','Add Signal');
            sr = uimenu(obj.hcmenu,'Label','Remove Signal');
            snew = uimenu(obj.hcmenu,'Label','Add Panel','Separator','on',...
                'Callback',@(~,~) obj.addSignalPanel(obj.sigs(obj.cursig).sigs));
            srem = uimenu(obj.hcmenu,'Label','Remove Panel',...
                'Callback',@(~,~) obj.removeSignalPanel(obj.cursig));
            
            % populate signals submenu function
            function addsig(sig)
                % append sig to the list of this signal panel's signals
                obj.sigs(obj.cursig).sigs = [obj.sigs(obj.cursig).sigs sig];
                % and redraw
                obj.refresh();
            end
            function rmsig(sig)
                % remove sig from the list of this signal panel's signals
                ss = obj.sigs(obj.cursig).sigs;
                obj.sigs(obj.cursig).sigs = ss((1:length(ss)) ~= find(ss == sig,1));
                % and redraw
                obj.refresh();
            end
            function popSigMenuFcn(~,~)
                % delete the old ones
                delete(obj.sigmenus);
                % get signal list, if we have one
                slist = obj.data.getSignalList();
                
                obj.sigmenus = [];
                % create the menus
                for i=1:length(slist)
                    obj.sigmenus(end+1) = uimenu(sa,'Label',slist{i});
                    set(obj.sigmenus(end),'Callback',@(~,~) addsig(i+1));
                end
                
                % and one for each of this guy's active signals
                ss = obj.sigs(obj.cursig).sigs;
                for j=1:length(ss)
                    obj.sigmenus(end+1) = uimenu(sr,'Label',slist{ss(j)-1});
                    set(obj.sigmenus(end),'Callback',@(~,~) rmsig(ss(j)));
                end
            end
            
            set(obj.hcmenu,'Callback',@popSigMenuFcn);
            
            obj.cursig = 0;
            
            % the main layout components
            obj.panels = [];
            obj.panels.Middle = uipanel('Parent',obj.fig,'Position',[0 0.5 1 0.5],'Units','Pixels');
            obj.panels.Bottom = uipanel('Parent',obj.fig,'Position',[0 0.5 1 0.5],'Units','Pixels');
            
            set(obj.panels.Bottom,'BorderType','none');
            set(obj.panels.Middle,'BorderType','none');
            
            % handles the resizing of the main panels
            function mainResizeFcn(~,~)
                sz = getPixelPos(obj.fig);

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
                'callback', @(~,~) obj.setView());
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
                % and tick length
                s = 6/max(sz(3:4));
                set(obj.xaxes,'TickLength',s*[1 1]);
            end
            % set the resize function
            set(obj.panels.Bottom, 'ResizeFcn', @resizeFcn);
            % and call it to set default positions
            resizeFcn
            
            % create drag/drop functions, etc
            obj.setMouseCallbacks();
            % and a dummy keyboard callback
            obj.setKeyboardCallback(@(e) []);
            
            % load data if we were called with a filename
            % this also creates default signal panels
            obj.data = [];
            if (nargin > 0)
                obj.loadFile(fname);
            end
        end
        
        % loads the specified file, and initializes the signal panels
        function loadFile(obj, fname)
            % attempt to load data
            d = SignalData(fname);
            
            if d.ndata < 0
                return
            end
            % set internal data
            obj.data = d;
            
            % first, delete all panels
            while ~isempty(obj.sigs)
                obj.removeSignalPanel();
            end
            % then, create right number of panels
            for i=1:obj.data.nsigs
                obj.addSignalPanel(i+1);
            end
            
            % and reset view
            obj.setView();
        end

        % Creates mouse callback interface, by defining a ton of fns
        function setMouseCallbacks(obj)
            % point-rectangle hit test utility function
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
                        obj.cursig = ind;
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
                        obj.cursig = ind;
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
                    obj.cursig = 0;
                    return;
                end
                hnd = -1;
                ind = -1;
                pt = [];
                s = '';
                obj.cursig = 0;
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
        
        % and let the outside user set the keyboard behavior
        function setKeyboardCallback(obj, fun)
            % define our own internal keyboard function
            function keyboardFcn(~,e)
                if e.Character == 'a'
                    % autoscale axes
                    for i=1:length(obj.sigs)
                        obj.sigs(i).resetY();
                    end
                end
                
                % and then pass it on
                fun(e);
            end
            set(obj.fig,'WindowKeyPressFcn',@keyboardFcn);
        end
        
        % adding and removing signal panels...
        function addSignalPanel(obj, sigs)
            % make a new one at the end
            i = length(obj.sigs)+1;
            if (i==1)
                obj.sigs = obj.makeSignalPanel();
            else
                obj.sigs(i) = obj.makeSignalPanel();
            end
            % save which signals we want to draw
            obj.sigs(i).sigs = sigs;
            % and redo their sizes
            obj.sizeSignalPanels()
            % and refresh the view, without changing x-limits
            if i==1
                % or just reset, if it's the first panel
                % (which it really shouldn't be?)
                obj.setView();
            else
                obj.refresh();
            end
            % autoset the y-limits
            obj.sigs(i).resetY();
        end
        function removeSignalPanel(obj, sig)
            % just remove the topmost one if none specified
            if (nargin < 2)
                sig = 1;
            end
            % no more to remove!
            if (isempty(obj.sigs))
                return
            end
            % otherwise, delete the panel object
            delete(obj.sigs(sig).panel);
            % and remove it from the array
            obj.sigs = obj.sigs((1:length(obj.sigs))~=sig);
            % and resize!
            obj.sizeSignalPanels();
        end
        function sizeSignalPanels(obj)
            % this guy just sets the sizes of the panels
            np = length(obj.sigs);
            for i=1:np
                set(obj.sigs(i).panel,'Position',[0 (np-i)/np 1 1/np]);
            end
        end
        
        % this makes a single panel. positioning/tiling has to be taken
        % care of externally after creation
        function sig = makeSignalPanel(obj)
            % create and ultimately return a struct containing panel info
            sig = [];
            
            % which data to view? (none by default)
            sig.sigs = [];
            
            % make a panel to hold the entire thing
            sig.panel = uipanel('Parent',obj.panels.Middle,'Position',[0 0 1 1],'Units','Normalized');
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
            % let's bind the context menu here as well
            set(sig.axes,'uicontextmenu',obj.hcmenu);
            % and gridify it
            grid;
            evalc('hold(sig.axes)');

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
                % now do some ticklength calcs
                s = 5/max(sz(3:4));
                set(sig.yaxes,'TickLength',s*[1 1]);
            end
            % set the resize function
            set(sig.panel, 'ResizeFcn', @resizeFcn);
            % and call it to set default positions
            resizeFcn
        end
        
        % just refresh the view
        function refresh(obj)
            obj.setView(obj.getView());
        end
        
        % returns x-limits of current screen
        function xlim=getView(obj)
            xlim = get(obj.xaxes,'XLim');
        end
        
        % sets the x-limits (with bounding, of course)
        function setView(obj,rng)
            % if we don't have anything loaded, get outta here
            if isempty(obj.data)
                return
            end
            
            % also, check if we got a range at all or not
            if (nargin < 2)
                range = [obj.data.tstart obj.data.tend];
            else
                range = rng;
            end
            
            % are we too zoomed-out?
            dr = range(2)-range(1);
            if (dr > obj.data.tend)
                range = [obj.data.tstart obj.data.tend];
                dr = obj.data.tend;
            end
            % or too zoomed-in?
            if (dr == 0)
                return
            end
            
            % are we too far to the left?
            if (range(1) < 0)
                % then shift back
                range = range - range(1);
            end
            % or too far to the right?
            if (range(2) > obj.data.tend)
                range = [-dr 0] + obj.data.tend;
            end
            
            % now we can set all the xlims properly
            set(obj.xaxes,'XLim',range);
            set([obj.sigs.axes],'XLim',range);
            
            % get the data
            d = obj.data.getViewData(range);
            
            % and replot everything
            for i=1:length(obj.sigs)
                % get the y-limit
                ylim = obj.sigs(i).getY();
                cla(obj.sigs(i).axes);
                % plot the selected signals
                if isempty(obj.sigs(i).sigs)
                    continue
                end
                plot(obj.sigs(i).axes,d(:,1),d(:,obj.sigs(i).sigs));

                if (nargin < 2)
                    % if we did setView(), reset Y
                    obj.sigs(i).resetY();
                else
                    % otherwise, keep it where it was
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