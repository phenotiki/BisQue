function output = analysis_diameter(L)
% Feret's diameter (or caliper diameter): the longest distance between any two points on the
% boundary of the plant object.

output = [];
for k = 1:max(L(:))
    BW = false(size(L));
    BW(L == k) = true;
    d = bw_diameter(BW, false);
    output = [output d];
end

end

function d = bw_diameter(BW, display)
% Euclidean distance between the two farthest points on the perimeter of an object.
% Calculated as the maximum of the set of all distances between pairs of points in the object.
% Diam(B) = max_{i,j}[D(p_i,p_j)]
%
% Input:
%            BW - binary image (0 = background, 1 = foreground)
%       display - show image BW and overlay main axis
%
% Output:
%             d - diameter of object in BW

B = bwboundaries(BW, 'noholes');
B_all = [];
for obj_n = 1:length(B)
    B_all = [B_all; B{obj_n}];
end
D = pdist(B_all, 'euclidean');
d = max(D);

if display
    Z = squareform(D);
    [~, ind] = max(Z(:));
    [p1, p2] = ind2sub(size(Z), ind);
    p1_y_x = B_all(p1,:);
    p2_y_x = B_all(p2,:);
    %sqrt((p1_xy-p2_xy)*(p1_xy-p2_xy)')
    
    figure, imagesc(BW); colormap gray; axis image
    hold on
    line([p1_y_x(2) p2_y_x(2)], [p1_y_x(1) p2_y_x(1)], 'LineWidth', 2 , 'Color', 'r')
end

end