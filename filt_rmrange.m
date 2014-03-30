function dout = filt_rmrange(d, range)
%FILT_RMRANGE Removes ranges of points

    dout = d(:,2:end);
    % check every row of range
    for i=1:size(range,1)
        % do we have any points in the range?
        pts = and(d(:,1)>range(i,1),d(:,1)<range(i,2));
        if ~any(pts)
            continue
        end
        for j=1:size(dout,2)
            dout(pts,j) = range(i,j+2);
        end
    end
end

