%% Define the starting conditions for the grid search algorithm

% % File path of the test image data
init.data_path = fullfile('data', 'test_grid_search');

% You can set the range of values for the parameters (i.e., the lower and upper bound)
% and the number of parts in which you want to divide this set

%% Plant Localization

% Threshold (pixels) of small object removal.
init.small_size_lower = 100;
init.small_size_upper = 300;
init.small_size_step = 100;

%% Active contour model

% Image-based term
init.lambda_lower = 0.4;
init.lambda_upper = 0.6;
init.lambda_step = 0.1;