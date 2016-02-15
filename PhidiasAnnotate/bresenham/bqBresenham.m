function polyline = bqBresenham(pts)
    x = [];
    y = [];
    
    for i = 1 : size(pts,1)-1
        [tx ty] = bresenham(pts(i,1),pts(i,2),pts(i+1,1),pts(i+1,2));
        x = [x;tx(1:end-1)];
        y = [y;ty(1:end-1)];
    end
    
    x = [x;pts(end,1)];
    y = [y;pts(end,2)];
    polyline = [x y];
end