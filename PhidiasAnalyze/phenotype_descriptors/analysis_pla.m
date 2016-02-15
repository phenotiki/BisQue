function output = analysis_pla(L)
% Projected leaf area (PLA), area of the plant object in a 2D projection (e.g., top view),
% calculated as the number of plant pixels in the image.

stats = regionprops(L, 'Area');
output = [stats.Area];

end