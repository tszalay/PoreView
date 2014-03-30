function [ do ] = rmrange( d, range )
%RMRANGE Summary of this function goes here
%   Detailed explanation goes here

rng = repmat((d(:,1) > range(2)) + (d(:,1) < range(1)),[1,2]);
do = d(:,2:3).*rng;
pt0 = find((1-rng),1,'first');
pt1 = find(1-rng,1,'last');
do(pt0:pt1,1:2) = repmat(mean(d(pt0,pt1),2:3),[pt1-pt0+1,1);

end

