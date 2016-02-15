function output = analysis_perimeter(L)
% Perimeter: number of boundary pixels.

output = [];
for k = 1:max(L(:))
    BW = false(size(L));
    BW(L == k) = true;
    stats = regionprops(BW, 'FilledImage');
    p = 0;
    for obj_n = 1:length(stats)
        p = p + sum(sum(bwperim(stats(obj_n).FilledImage)));
    end
    output = [output p];
end

end