function [AGR, RGR] = analysis_growth_rate(Area, deltaT)
% Absolute Growth Rate (AGR) and Relative Growth Rate (RGR) to study individual plant growth.
%
% Input:
%        Area - measured plant areas
%      deltaT - elapsed time between calculations of plant area
%
% Output:
%         AGR - Absolute growth rate
%         RGR - Relative growth rate

% AGR = (A2 - A1)/(t2 - t1)
AGR = diff(Area) ./ repmat(deltaT, [1 size(Area,2)]);

% RGR = (log(A2) - log(A1))/(t2 - t1)
RGR = log(Area(2:end,:) ./ Area(1:end-1,:)) ./ repmat(deltaT, [1 size(Area,2)]);

end