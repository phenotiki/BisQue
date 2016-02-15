function seeds = kmeans_seeds(img, X)
%KMEANS_SEEDS Calculates foreground/background seeds for k-means clustering.
%
% Input:
%     img - RGB image
%       X - features
%
% Output:
%   seeds - foreground/background seeds

% Trasform the RGB to Excess Green (ExG) domain
img_double = double(img);
ExG = 2*img_double(:,:,2) - img_double(:,:,1) - img_double(:,:,3);

% Segment ExG image into 2 classes by means of Otsu's N-thresholding method
[Idx, ~] = otsu(ExG(:), 2);

% K-means seeds for a* and b* components in L*a*b* colour space
% Seeds are found by averaging foreground and background pixels, respectively
seeds = [mean(X(Idx == 2, :)); mean(X(Idx == 1, :))];

end