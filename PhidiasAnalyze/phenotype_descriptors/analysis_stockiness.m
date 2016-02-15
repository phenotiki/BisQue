function output = analysis_stockiness(L)
% Stockiness (or form factor): ratio between rosette area and its perimeter. Stockiness ranges
% between 0 and 1, where 1 is achieved for a perfectly circular object.

stats = regionprops(L, 'Area');
perim = analysis_perimeter(L);
output = 4*pi*[stats.Area]./(perim.^2);

end