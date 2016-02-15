function output = analysis_compactness(L)
% Compactness (or solidity): as the ratio of plant area to the area of the smallest convex region
% enclosing the plant object (i.e. its convex hull). Compactness equals 1 for a perfectly solid
% object and is less than 1 for objects with irregular boundaries or holes.

stats = regionprops(L, 'Area', 'ConvexArea');
output = [stats.Area]./[stats.ConvexArea];

end