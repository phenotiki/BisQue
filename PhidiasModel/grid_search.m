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

% Load grid search specifications
grid_search_config;

% Load system options
config_test_grid_search;

options.data_path = init.data_path;

diary([init.data_path filesep 'log.txt'])
fprintf('\nTimestamp: %s\n', datestr(now, 'yyyy-mm-dd_HH-MM'));

%n = 3;

% Create the arrays for Input Parameters
small_size = init.small_size_lower:init.small_size_step:init.small_size_upper;
lambda = init.lambda_lower:init.lambda_step:init.lambda_upper;
appearance = false; % [false,true];

% Create the grid with all parameter combinations
grid = allcomb(small_size, lambda, appearance);

input_images = dir([options.data_path filesep options.input_files]);
[~, idx] = sortrows(char(input_images.name));
input_images = input_images(idx);

%parameters = zeros(2,1);

D = zeros(size(grid,1),1);

for k = 1:size(grid,1)
    fprintf('\n--------- Grid Search Iteration: (%d) ---------\n', k);
    %parameters(1,1) = grid(k,1);
    %parameters(2,1) = grid(k,2);
    options.enable_appearance_model = grid(k,3);
    
    %fprintf('options.small_size = %d\noptions.lambda = %.2f\noptions.enable_appearance_model = %d\n', parameters, options.enable_appearance_model);
    fprintf('options.small_size = %d\noptions.lambda = %.2f\noptions.enable_appearance_model = %d\n', grid(k,:));
    formatSpec = 'options.small_size = %d;\noptions.lambda = %.3f;\noptions.enable_appearance_model = %d;\npar.iteration = %d;';
    [fid, msg] = fopen('parConfig.m', 'wt');
    if fid == -1
        error(msg)
    end
    %fprintf(fid,formatSpec,parameters, options.enable_appearance_model,k);
    fprintf(fid,formatSpec,grid(k,:),k);
    fclose(fid);
    
    isFirst = true;
    plant_centroids = [];
    cluster_center = [];
    prev_name = '';
    
    if ~isfield(options, 'palette')
        palette = [0 0 0; hsv(options.plant_n)];
    else
        palette = [0 0 0; options.palette(randperm(length(options.palette)),:)/255];
    end
    % Initialize CSV file of PLA
    dlmwrite([options.data_path filesep 'pla.csv'], 1:options.plant_n);
    
    % For each image in the specified path call pipeline function
    for i = 1:numel(input_images)
        filename = input_images(i).name;
        fprintf('\n----- (%d) -----\n', i);
        fprintf('Image: ''%s''\n', filename);
        tStart = tic;
        try
            [plant_centroids, cluster_center, prev_name] = pipeline([options.data_path filesep filename], options.plant_n, plant_centroids, cluster_center, prev_name, isFirst, options.display, palette);
        catch exception
            fprintf('\n******** Pipeline Execution Failed!!! ********\n');
            error = getReport(exception);
            fprintf(error);
            continue
        end
        tElapsed = toc(tStart);
        fprintf('\nTotal elapsed time (s): %.3f\n', tElapsed);
        if options.enable_appearance_model
            isFirst = false;
        end
    end
    
    D(k) = grid_search_dsc(k);
    
    delete([options.data_path filesep '*.mat'], [options.data_path filesep '*_init.png']);
end

[d_max, k_max] = max(D);
fprintf('\nThe best set of parameters was found at iteration %d (DSC = %.2f)\n', k_max, d_max);
fprintf('\toptions.small_size = %d\n', grid(k_max, 1));
fprintf('\toptions.lambda = %.3f\n', grid(k_max, 2));
fprintf('\toptions.enable_appearance_model = %d\n', grid(k_max, 3));

diary off
