function dout = filt_rmrange(d, range)
%FILT_RMRANGE Removes ranges of points

    rng = repmat((d(:,1) > range(2)) + (d(:,1) < range(1)),[1,2]);
    dout = d(:,2:3).*rng;
    pt0 = find((1-rng),1,'first');
    pt1 = find(1-rng,1,'last');
    dout(pt0:pt1,1:2) = repmat(mean(d(pt0,pt1),2:3),[pt1-pt0+1,1);
end

