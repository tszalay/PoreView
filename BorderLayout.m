function output = ...
        BorderLayout(layoutParent, northHeight, southHeight, eastWidth, westWidth)
% BORDERLAYOUT Create a border layout manager.
%    BORDERLAYOUT(PARENT, NORTHHEIGHT, SOUTHHEIGHT, EASTWIDTH, WESTWIDTH)
%    creates a new layout manager that mimics Java's BorderLayout.  It
%    creates up to five new uipanels, which are returned in a struct, 
%    output, as North, South, East, West, and Center.  These new uipanels
%    are parented to PARENT (which may be either a figure or another
%    uipanel) and are laid out as follows:
%
%    +-----------------------------------------------------------+
%    |                        output.North                       |
%    +-----------------------------------------------------------+
%    |     |                                               |     |
%    |     |                                               |     |
%    |  o  |                                               |  o  |
%    |  u  |                                               |  u  |
%    |  t  |                                               |  t  |
%    |  p  |                                               |  p  |
%    |  u  |                                               |  u  |
%    |  t  |                  output.Center                |  t  |
%    |  .  |                                               |  .  |
%    |  W  |                                               |  E  |
%    |  e  |                                               |  a  |
%    |  s  |                                               |  s  |
%    |  t  |                                               |  t  |
%    |     |                                               |     |
%    |     |                                               |     |
%    +-----------------------------------------------------------+
%    |                        output.South                       |
%    +-----------------------------------------------------------+
%
%    The panels are sized as follows:
%    - output.North is given a static pixel height equal to NORTHHEIGHT.
%    - output.South is given a static pixel height equal to SOUTHHEIGHT.
%    - output.East is given a static pixel width equal to EASTWIDTH.
%    - output.West is given a static pixel width equal to WESTWIDTH.
%    - output.Center occupies the space left over after the other panels
%      are laid out.
%
%    If any of the static pixel sizes are 0, then the corresponding uipanel
%    is not created.  output.Center, however, is always created.
%
%    As PARENT resizes, output.North, output.South, output.East,
%    output.West, and output.Center will all be resized appropriately.
%    Since PARENT may be either a figure or another uipanel, BORDERLAYOUT
%    can be used multiple times within the same figure window, and
%    BORDERLAYOUTs may be nested inside each other to create professional
%    looking GUIs.
%
%   Example:
%       f = figure;
%       panels = BorderLayout(f, 0, 50, 100, 0);
%       ax = axes('Parent', panels.Center);
%       ui1 = uicontrol('Parent', panels.South);
%       ui2 = uicontrol('Parent', panels.East);
%
%    See also UIPANEL.
%
% Copyright 2008-2011 The MathWorks, Inc.
        
    % Check input parameters
    parentType = get(layoutParent, 'Type');
    if (~strcmp(parentType, 'figure') && ~strcmp(parentType, 'uipanel'))
        error('layoutParent must be either a figure or a uipanel.')
    end
    if (~isscalar(northHeight) || ...
        ~isscalar(southHeight) || ...
        ~isscalar(eastWidth)   || ...
        ~isscalar(westWidth))
        error('Panel sizes must be scalars.')
    end
    if (northHeight < 0 || ...
        southHeight < 0 || ...
        eastWidth   < 0 || ...
        westWidth   < 0)
        error('Panel sizes must be non-negative.')
    end

    % Cache the dimensions into the parent
    dimensions.northHeight = northHeight;
    dimensions.southHeight = southHeight;
    dimensions.eastWidth   = eastWidth;
    dimensions.westWidth   = westWidth;
    set(layoutParent, 'UserData', dimensions);
    
    % Create the border panels
    northPanel  = CreatePanel(layoutParent, @NorthPanelResizeFcn, northHeight);
    southPanel  = CreatePanel(layoutParent, @SouthPanelResizeFcn, southHeight);
    eastPanel   = CreatePanel(layoutParent, @EastPanelResizeFcn,  eastWidth);
    westPanel   = CreatePanel(layoutParent, @WestPanelResizeFcn,  westWidth);

    centerPanel = uipanel('Parent', layoutParent, 'ResizeFcn', @CenterPanelResizeFcn);
    CenterPanelResizeFcn(centerPanel, []);
    
    if (~isempty(northPanel))
        output.North = northPanel;
    end
    if (~isempty(southPanel))
        output.South = southPanel;
    end
    if (~isempty(eastPanel))
        output.East = eastPanel;
    end
    if (~isempty(westPanel))
        output.West = westPanel;
    end
    output.Center = centerPanel;
    

function panel = CreatePanel(panelParent, resizeFcn, size)
    if (size > 0)
        panel = uipanel('Parent', panelParent, 'ResizeFcn', resizeFcn, 'UserData', size);
        resizeFcn(panel, []);
    else
        panel = [];
    end
    
function [dimensions parentPosition] = GetPositionInformation(panel)
    
    % Fetch the panel dimensions and parent position from the parent
    panelParent = get(panel, 'Parent');
    dimensions  = get(panelParent, 'UserData');
    parentUnits = get(panelParent, 'Units');
    set(panelParent, 'Units', 'pixels');
    parentPosition = get(panelParent, 'Position');
    set(panelParent, 'Units', parentUnits);

function validPosition = ValidatePosition(parentPosition, newPosition)
    validPosition = newPosition;
    
    % Validate width
    if (newPosition(3) > parentPosition(3))
        validPosition(3) = parentPosition(3);
        validPosition(1) = 0;
    end
    if (validPosition(3) <= 0)
        validPosition(3) = 1;
    end
    
    % Validate height
    if (newPosition(4) > parentPosition(4))
        validPosition(4) = parentPosition(4);
        validPosition(2) = 0;
    end
    if (validPosition(4) <= 0)
        validPosition(4) = 1;
    end
    
    % Guard against fleeting Infs and NaNs
    if (isnan(validPosition(1)) || isinf(validPosition(1)))
        validPosition(1) = 0;
    end
    if (isnan(validPosition(2)) || isinf(validPosition(2)))
        validPosition(2) = 0;
    end
    if (isnan(validPosition(3)) || isinf(validPosition(3)))
        validPosition(3) = 1;
    end
    if (isnan(validPosition(4)) || isinf(validPosition(4)))
        validPosition(4) = 1;
    end
    
function UpdatePosition(panel, newPosition, parentPosition)
    newPosition = ValidatePosition(parentPosition, newPosition);
    set(panel, 'Units', 'pixels', 'Position', newPosition);
    set(panel, 'Units', 'normalized');
    
function NorthPanelResizeFcn(o,e) %#ok
    [dimensions parentPosition] = GetPositionInformation(o);
    newPosition = [0,                                        ...
                   parentPosition(4)-dimensions.northHeight, ...
                   parentPosition(3),                        ...
                   dimensions.northHeight];
    UpdatePosition(o, newPosition, parentPosition);
    
function SouthPanelResizeFcn(o,e) %#ok
    [dimensions parentPosition] = GetPositionInformation(o);
    newPosition = [0,                 ...
                   0,                 ...
                   parentPosition(3), ...
                   dimensions.southHeight];
    UpdatePosition(o, newPosition, parentPosition);
    
function EastPanelResizeFcn(o,e) %#ok
    [dimensions parentPosition] = GetPositionInformation(o);
    newPosition = [parentPosition(3)-dimensions.eastWidth, ...
                   dimensions.southHeight,                 ...
                   dimensions.eastWidth,                   ...
                   parentPosition(4)-dimensions.northHeight-dimensions.southHeight];
    UpdatePosition(o, newPosition, parentPosition);
   
function WestPanelResizeFcn(o,e) %#ok
    [dimensions parentPosition] = GetPositionInformation(o);
    newPosition = [0,                      ...
                   dimensions.southHeight, ...
                   dimensions.westWidth,   ...
                   parentPosition(4)-dimensions.northHeight-dimensions.southHeight];
    UpdatePosition(o, newPosition, parentPosition);
    
function CenterPanelResizeFcn(o,e) %#ok
    [dimensions parentPosition] = GetPositionInformation(o);
    newPosition = [dimensions.westWidth,                                        ...
                   dimensions.southHeight,                                      ...
                   parentPosition(3)-dimensions.eastWidth-dimensions.westWidth, ...
                   parentPosition(4)-dimensions.northHeight-dimensions.southHeight];
    UpdatePosition(o, newPosition, parentPosition);
