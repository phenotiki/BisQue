function mask_final = pipeline(image, plant_num, display, session, Gmm, small_size, lambda, enable_appearance_model)
%PIPELINE Plant image analysis pipeline.
%
%   Author(s): Massimo Minervini, Fabiana Zollo
%   Contact:   massimo.minervini@imtlucca.it
%   Version:   1.0
%   Date:      --
%
%   Copyright (C) 2016 Massimo Minervini
%
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
%   BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
%   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

% Load system options
% config;

scale_factor = session.mex.findValue('//tag[@name="inputs"]/tag[@name="scale_factor"]');
iter = session.mex.findValue('//tag[@name="inputs"]/tag[@name="iter"]');
noMedian = session.mex.findValue('//tag[@name="inputs"]/tag[@name="noMedian"]');
sigma = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigma"]');
Sigma_P = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigma_P"]');
crop_x1 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_x1"]');
crop_x2 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_x2"]');
crop_y1 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_y1"]');
crop_y2 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_y2"]');
lambda_out = session.mex.findValue('//tag[@name="inputs"]/tag[@name="lambda_out"]');

crop_x1 = min(max(1, crop_x1), size(image, 2));
crop_x2 = max(max(crop_x1, crop_x2), size(image, 2));
crop_y1 = min(max(1, crop_y1), size(image, 1));
crop_y2 = max(max(crop_y1, crop_y2), size(image, 1));
    
crop_x = crop_x1:crop_x2;
crop_y = crop_y1:crop_y2;

border = 5;

%% Feature extraction

fprintf('\n-> Feature extraction ...\n');
tStart = tic;

%img_fullres = imread(filename);
img_fullres = image;
[nrows_fullres_original, ncols_fullres_original, ~] = size(img_fullres);
img_fullres = img_fullres(crop_y,crop_x,:);
[nrows_fullres, ncols_fullres, ~] = size(img_fullres);

F_fullres = extract_features(img_fullres, session);

% Once the features have been extracted from the full resolution image, the
% image may be scaled according to the specified scale_factor
F = imresize(F_fullres, scale_factor);
feature_n = size(F,3);

% Create X as a M-by-N matrix, where M = nrows_fullres*ncols_fullres rows and N = feature_n
X = reshape(F, nrows_fullres*ncols_fullres, feature_n);

img = imresize(img_fullres, scale_factor);
[nrows, ncols, ~] = size(img);

if display && false
    figure('Name', 'img'), imshow(img);
end

tElapsed = toc(tStart);
fprintf('Elapsed time (s): %.3f\n', tElapsed);


%% Pixel classification based on prior knowledge
% The multi-dimensional distribution of the feature space is learned using
% a multivariate Gaussian mixture model formulation

fprintf('\n-> Pixel classification ...\n');
tStart = tic; 
    
    % Get a probabilistic map of pixels belonging to a plant
    P = pdf(Gmm, X);
    P = reshape(P, nrows, ncols);
    
    if display
        figure('Name', 'P'), imagesc(P); axis image; colormap gray
    end

tElapsed = toc(tStart);
fprintf('Elapsed time (s): %.3f\n', tElapsed);


%% Plant localization

fprintf('\n-> Plant localization ...\n');
tStart = tic;

% Initial centroids are calculated from histogram tresholding in the ExG color space
seeds = kmeans_seeds(img, X);

% K-means clustering with K=2, squared euclidean distance, and seeds as
% matrix of starting locations.
[pixel_labels, cluster_center] = kmeans(X, 2, 'distance', 'sqEuclidean', 'start', seeds);
if display
    fprintf('Cluster centroid locations:\n');
    disp(cluster_center)
end

mask = ~(reshape(pixel_labels, nrows, ncols) - 1);

% Morphological post processing. Remotion of H-connected pixels, spur pixels and objects having fewer than 30 px
% The output is a binary mask serving as an approximate plant segmentation
mask = bwmorph(mask, 'hbreak');
mask = bwmorph(mask, 'spur');
mask = bwareaopen(mask, small_size);

if display
    figure('Name', 'mask'), imagesc(mask);
end

tElapsed = toc(tStart);
fprintf('Elapsed time (s): %.3f\n', tElapsed);


%% Plant labelling
% The goal is to assign a unique label to pixels of the same plant

fprintf('\n-> Plant labelling ...\n');
tStart = tic;

% Get foreground pixel coordinates
[I, J] = ind2sub([nrows, ncols], 1:nrows*ncols);
allPixels = [J(mask)', I(mask)'];

% if exist('options', 'var') && isfield(options, 'user_centroids')
%     plant_locations = options.user_centroids;
% else
    % Find the centroids of the plant_num largest connected components to
    % initialize the k-means clustering
stats = regionprops(mask, 'Area', 'Centroid');
[~, Idx] = sort([stats.Area]);
allCentroids = cat(1, stats.Centroid);
allCentroids_sorted = allCentroids(Idx',:);
largest_CC_centroids = round(allCentroids_sorted(end-plant_num+1:end,:));
plant_locations = largest_CC_centroids;
%end
%plant_locations = sortrows(plant_locations, [2 1]);

% adjust for cropping
%plant_locations = plant_locations - [ones(plant_num,1)*crop_x(1)-1 ones(plant_num,1)*crop_y(1)-1];

if display
    figure('Name', 'mask + plant_locations'), imagesc(mask);
    hold on
    plot(plant_locations(:,1), plant_locations(:,2), 'kx', 'MarkerSize', 10, 'LineWidth', 1);
    plot(plant_locations(:,1), plant_locations(:,2), 'ko', 'MarkerSize', 10, 'LineWidth', 1);
    hold off
end

% K-means clustering on the foreground pixel coordinates with K = plant_num
[plant_idx, plant_centroids] = kmeans(allPixels, plant_num, 'distance', 'sqEuclidean', ...
    'start', plant_locations);

if display
    figure('Name', 'mask + plant_positions + plant_centroids'), imagesc(mask);
    hold on
    plot(plant_centroids(:,1), plant_centroids(:,2), 'kx', 'MarkerSize', 10, 'LineWidth', 1);
    plot(plant_centroids(:,1), plant_centroids(:,2), 'ko', 'MarkerSize', 10, 'LineWidth', 1);
    hold off
end

% Generate 2D map of plant locations
labelled_mask = uint8(zeros(nrows, ncols));
labelled_mask(mask) = plant_idx;

% Smallest rectangles containing each connected component in the binary mask
plant_positions = regionprops(labelled_mask, 'BoundingBox');

if display
    figure('Name', 'labelled_mask + plant_positions + plant_centroids'), imagesc(labelled_mask);
    hold on
    plot(plant_centroids(:,1), plant_centroids(:,2), 'kx', 'MarkerSize', 10, 'LineWidth', 1);
    plot(plant_centroids(:,1), plant_centroids(:,2), 'ko', 'MarkerSize', 10, 'LineWidth', 1);
    for i = 1:numel(plant_positions)
        rectangle('Position', plant_positions(i).BoundingBox, 'LineWidth', 2, 'LineStyle', '--', 'EdgeColor', 'k');
    end
    hold off
end

tElapsed = toc(tStart);
fprintf('Elapsed time (s): %.3f\n', tElapsed);


%% Plant segmentation at full resolution

fprintf('\n-> Plant segmentation ...\n');
tStart = tic;

% Upscale labelled mask and bounding boxes to full resolution size
labelled_mask_fullres = imresize(labelled_mask, [nrows_fullres, ncols_fullres], 'nearest');
plant_positions_fullres = plant_positions;
for i = 1:numel(plant_positions)
    plant_positions_fullres(i).BoundingBox = round(plant_positions(i).BoundingBox / scale_factor);
end

if enable_appearance_model
    % Upscale P to full resolution
    P_fullres = imresize(P, [nrows_fullres, ncols_fullres]);
    
    % Gaussian smoothing of P with Sigma_P = 1.5
    KernelSize_P = 2 * round(2 * Sigma_P) + 1;
    P_fullres = conv2(P_fullres, fspecial('gaussian', KernelSize_P, Sigma_P), 'same');
    
    % Normalize to range [0,1]
    P_fullres = normalize(P_fullres);
    
    % Save P to file
    % imwrite(P_fullres, [pathstr filesep name '_P.png'], 'png');
    
    % Save thresholded P to file
    % All pixels above threshold = 0.5 are considered as foreground
    P_fullres_init = zeros(size(P_fullres));
    P_fullres_init(P_fullres > 0.5) = 1;
    
    if display && true
        figure('Name', 'P'), imagesc(P_fullres);
    end
end

% Initialize the segmentation mask (output of the level set)
labelled_mask_fullres_ls = uint8(zeros(nrows_fullres, ncols_fullres));

for i = 1:length(plant_positions_fullres)
    
    % Enlarge the bounding box according to the border size
    left = ceil(plant_positions_fullres(i).BoundingBox(1)) - border;
    top = ceil(plant_positions_fullres(i).BoundingBox(2)) - border;
    width = plant_positions_fullres(i).BoundingBox(3) + 2 * border;
    height = plant_positions_fullres(i).BoundingBox(4) + 2 * border;
    
    % Make sure that the bounding box is inside the image
    a1 = max(1, top);
    a2 = min(nrows_fullres, top + height);
    a3 = max(1, left);
    a4 = min(ncols_fullres, left + width);
    
    % Crop plant features
    img_plant = img_fullres(a1:a2, a3:a4, :);
    F_plant = F_fullres(a1:a2, a3:a4, :);
    [nrows_plant, ncols_plant, ~] = size(F_plant);
    
    ls_init = zeros(nrows_plant, ncols_plant) - 1;
    if ~enable_appearance_model
        % Initialize the level set with the plant contour from plant localization
        labelled_mask_plant = labelled_mask_fullres(a1:a2, a3:a4, :);
        ls_init(labelled_mask_plant == i) = 1;
    else
        % Initialize the level set with the probabilistic map
        P_plant = P_fullres(a1:a2, a3:a4, :);
        ls_init(P_plant > 0.5) = 1;
    end
    
    % Proposed level set segmentation
    if ~enable_appearance_model

        mask_plant = uint8(levelset(img_plant, F_plant, iter, sigma, ls_init, display, noMedian, lambda, lambda_out));
    else
        mask_plant = uint8(levelset(img_plant, F_plant, iter, sigma, ls_init, display, noMedian, lambda, lambda_out, P_plant));
    end
    mask_plant(mask_plant == 1) = i;
    
    % Recompose the segmentation map and handle overlapping frames
    labelled_mask_fullres_ls(a1:a2, a3:a4) = ...
        max(mask_plant,labelled_mask_fullres_ls(a1:a2, a3:a4));
end

% Binary segmentation mask
mask_fullres_ls = zeros(size(labelled_mask_fullres_ls));
mask_fullres_ls(labelled_mask_fullres_ls > 0) = 1;

% (optionally) Segmentation mask post processing
% mask_fullres_ls = bwmorph(mask_fullres_ls, 'hbreak');
% mask_fullres_ls = bwmorph(mask_fullres_ls, 'spur');
% mask_fullres_ls = bwareaopen(mask_fullres_ls, 20);

% Assign to each connected component the most frequently occurring label
CC = bwconncomp(mask_fullres_ls);
for i = 1:CC.NumObjects
    Idx = cell2mat(CC.PixelIdxList(i));
    labelled_mask_fullres_ls(Idx) = mode(double(labelled_mask_fullres_ls(Idx)));
end

% Remove small objects from the labelled mask
labelled_mask_fullres_ls = labelled_mask_fullres_ls .* uint8(mask_fullres_ls);

if display
    figure('Name', 'labelled_mask_fullres_ls'), imagesc(labelled_mask_fullres_ls);
end

% Save labelled_mask_fullres_ls as an indexed PNG
%maskname = sprintf('mask_%d.png', int8(iter));
mask_final = zeros(nrows_fullres_original, ncols_fullres_original, 'uint8');
mask_final(crop_y,crop_x,:) = labelled_mask_fullres_ls;
%imwrite(mask_final, palette, fullfile(pathstr, [name '_label.png']), 'png');
%imwrite(labelled_mask_fullres_ls, [0 0 0; hsv(plant_num)], [pathstr filesep name '_mask.png'], 'png');

tElapsed = toc(tStart);
fprintf('Elapsed time (s): %.3f\n', tElapsed);

end
