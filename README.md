CrampFit
========

An open source Matlab alternative to pClamp's ClampFit utility, along with a cached file loader for greatly
simplified file access.



Installation
============

Extract and copy to a folder, or fork the project via git. It is recommended that you add the folder to your Matlab
path to avoid any issues.



Quick Start
===========

# CrampFit

CrampFit is the GUI program that lets you view and manipulate large datafiles efficiently, as well as add dynamic
filters and superimpose plot objects.

## Starting:



## Adjusting View:

    %CRAMPFIT: Analysis suite for streaming signal data
    %
    % ---------------------------------------------------------------------
    %
    % CRAMPFIT Usage:
    %   Adjusting view
    %       - Scrolling over a plot zooms the x-axis about the cursor position. 
    %       - Scrolling over a y-axis zooms that y axis about the cursor position.
    %       - Middle-click and drag pans the plot.
    %       - Right-clicking brings up the signal context menu.
    %       - Left-click and drag on axes to zoom.
    %       - Press 'a' to autoscale all axes.
    %
    %   Cursors
    %       - Double-click to bring cursors.
    %       - Click and drag cursors to move them.
    %       - Press 'c' to show/hide cursors.
    %
    %   Press 'Escape' to quit at any time.
    %
    % ---------------------------------------------------------------------
    %
    % CRAMPFIT Methods:
    %   CrampFit(fname) - Starts CrampFit. Filename can be empty, a
    %       filename, or a directory where your files are stored.
    %   loadFile(fname) - Loads a file, if it can find it. If IV curve is
    %       selected, forwards to plot_iv. Creates default signal panels.
    %
    %   setKeyboardCallback(fun) - Sets the keyboard callback function for
    %       user code. fun should take one argument, a struct, containing
    %       the key information.
    %   waitKey() - Blocks until a key is pressed. Returns character of the
    %       key (not a struct), eg 'k'.
    %
    %   addSignalPanel(sigs) - Add a signal panel, at the bottom, that
    %       displays the signals specified in sigs. Can be [].
    %   removeSignalPanel(panel) - Remove signal panel indexed by panel
    %   setSignalPanel(panel,sigs) - Sets panel to display signals sigs.
    %
    %   getAxes(pan) - Get the axes object handle for a given panel
    %   clearAxes() - Clear all user-drawn objects from all axes
    %
    %   autoscaleY() - Rescale Y-axes on all panels
    %
    %   getCursors() - Return cursor positions, or [] if hidden
    %   setCursors(trange) - Sets cursor positions and makes them visible
    %   toggleCursors() - Toggles visibility of cursors
    %
    %   refresh() - Redraws all plot displays.
    %   getView() - Returns time range visible in window.
    %   setView(trange) - Sets visible time range (clipping appropriately) and redraws.
    %
    % ---------------------------------------------------------------------
    %
    % CRAMPFIT Properties:
    %   data - Internal SignalData class, or [] if not loaded
    %   fig - Handle to figure object of program
    %   psigs - Struct array with signal panel information. Click for more.
    %
    % ---------------------------------------------------------------------
    %
    %
    %


    %SIGNALDATA: Class wrapper for streaming signals (specifically abfs)
    %
    % ---------------------------------------------------------------------
    %
    % SignalData Methods:
    %   SignalData(fname) - Initialize class on a file, if it exists
    %   getViewData(trange) - Return reduced or full data in a time range
    %   get(inds,sigs) - Return full data in specified index range
    %   getByTime(t0,t1) - Return full data in specified time range
    %   addVirtualSignal(fun,name,srcs) - Add a virtual signal function
    %   getSignalList() - Get names of all accessible signals
    %   findNext(fun,istart) - Find next instance of logical 1
    %   findPrev(fun,istart) - Find previous instance of logical 1
    %
    % ---------------------------------------------------------------------
    %
    % SignalData Properties:
    %   filename - Loaded name of file
    %   ext - File type (extension), eg. '.abf' or '.fast5'
    %   ndata - Number of data points (per signal)
    %   nsigs - Number of signals in file
    %   si - Sampling interval, seconds
    %   tstart - Start time of file, set to 0
    %   tend - End time of file
    %   header - Header struct from abf file
    %
    % ---------------------------------------------------------------------
    %
    % About Data:
    %   All data, always, anywhere, returned or used by SignalData, always
    %   has columns [time, sig1, sig2, ...], where the signals represent
    %   the different pieces of data present in the file (or added via
    %   virtual signals, see below). So, column/signal 1 is always Time.
    %   This is useful for backing out the absolute time/index of data that
    %   you are processing in a small chunk:
    %   
    %       d = obj.get(5000:5050,:);       % same as obj.get(5000:5050)
    %       ind = do_some_processing(d);    % ind is 1...50 since d has 50 points
    %       t = d(ind,1);                   % t is the absolute time of event in ind
    %                                
    % About Reduced Data:
    %   The reduced data calculated by SignalData subsamples the entire
    %   file to generate a reduced version consisting of 500k points. The
    %   subsampled (reduced) data is a series of points that alternate
    %   between the min and max value of the points they replace. In other
    %   words, reduced pt. 1 is eg. min(1:1000) and pt. 2 is max(1:1000).
    %   This way, features such as events aren't lost through subsampling.
    %   The reason min and max are alternated is so that the full range is
    %   visible when subsampled data is plotted (which appears in a lighter
    %   color). The reduced data is saved to a file, if possible, so that
    %   the next time you load a data file, the reduced data appears right
    %   away.
    % 
    % About Caching:
    %   Accessing the data using obj.get and obj.getByTime give you the
    %   full (non-reduced) data in a given range. SignalData keeps a
    %   certain amount of data (1 million points or so) in memory (called a
    %   'cache'), so if you access the points 5000:5050 and then 5050:5100,
    %   it will not read any data from disk the second time, only when you
    %   request points outside of what is loaded into memory (say, 1e6:1e6+50). 
    %   This way, you can access the file as if it were all loaded, without
    %   having to worry about accessing the disk every time.
    %   You can request as many points as you like, if you want to load
    %   more than the cache normally holds - it is up to you to ensure that 
    %   you don't request the entire file by accident.
    %   
    % About Virtual Signals: 
    %   A virtual signal is a filter you have written that acts on data
    %   with columns [time, sig1, sig2, ...], returing an array of the same
    %   form but processed by the filter. The virtual signal is applied to
    %   the full data whenever it is loaded in from the cache, and appears
    %   as a new signal column whenever you access the data (eg. obj.get()).
    %   Basically, a virtual signal is a filter that will appear as if you
    %   have a filtered version of the entire file. What function you apply
    %   is up to you, whether it is a high/low/bandpass filter, or median
    %   filter, or one that replaces a time range of points with their
    %   average.
    %   One important note is that the program attempts to apply the filters
    %   to the reduced data as well, which can give funny results depending
    %   on how well the filters are suited to taking such data (for
    %   example, highpass and lowpass work fine, but median filters make
    %   short events completely disappear).
    %
    % ---------------------------------------------------------------------
    %
    %
    %
