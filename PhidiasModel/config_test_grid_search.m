%% Define the options for the system

% Set true to visualize the results for each phase
options.display = false;

% Number of plants in the scene
options.plant_n = 24;

% File path of the image data
options.data_path = 'data/test_grid_search/';

% Input filename pattern (regular expression)
options.input_files = '*00.png';

% Plant localization may be performed on a downscaled image, to increase speed.
% Specify the scale factor
options.scale_factor = 1;

% Pixel size (mm) -- 60 pixel = 1 cm
options.pixel_size = 1/60;


%% Texture descriptor for feature extraction

% Standard deviation of the Gaussian kernel H
options.SigmaH = 4;

% Standard deviation of the Gaussian kernel L
options.SigmaL = 1;

% Radius of kernel H
options.Radius = 3;

% Decrease rate
options.falloff = 1/50;


%% Plant localization

% Crop size
options.crop_x = 1:3108;
options.crop_y = 201:2324;

% Threshold (pixels) of small object removal
options.small_size = 190;


%% Plant labelling

% User defined plant locations
options.user_centroids = [...
    279,471;
    764,487;
    1285,445;
    1824,463;
    2345,471;
    2835,528;
    261,990;
    769,977;
    1308,982;
    1796,1021;
    2324,1005;
    2796,1052;
    292,1482;
    738,1503;
    1231,1511;
    1762,1493;
    2319,1547;
    2796,1531;
    297,1998;
    741,1988;
    1259,2009;
    1747,2011;
    2257,1990;
    2755,2019;];

% Custom color palette
options.palette = [...
    252 233  79; % Butter 1
    237 212   0; % Butter 2
    196 160   0; % Butter 3
    138 226  52; % Chameleon 1
    115 210  22; % Chameleon 2
    78 154   6; % Chameleon 3
    252 175  62; % Orange 1
    245 121   0; % Orange 2
    206  92   0; % Orange 3
    114 159 207; % Sky Blue 1
    52 101 164; % Sky Blue 2
    32  74 135; % Sky Blue 3
    173 127 168; % Plum 1
    117  80 123; % Plum 2
    92  53 102; % Plum 3
    233 185 110; % Chocolate 1
    193 125  17; % Chocolate 2
    143  89   2; % Chocolate 3
    239  41  41; % Scarlet Red 1
    204   0   0; % Scarlet Red 2
    164   0   0; % Scarlet Red 3
    238 238 236; % Aluminium 1
    211 215 207; % Aluminium 2
    186 189 182; % Aluminium 3
    136 138 133; % Aluminium 4
    85  87  83; % Aluminium 5
    46  52  54]; % Aluminium 6

options.group(1).name = 'col-0'; options.group(1).subjects = [5 7 18 20 23]; options.group(1).color = [115 210  22];
options.group(2).name = 'ein2';  options.group(2).subjects = [1 3 8 11 15];  options.group(2).color = [245 121   0];
options.group(3).name = 'pgm';   options.group(3).subjects = [2 6 13 21 24]; options.group(3).color = [52 101 164];
options.group(4).name = 'ctr';   options.group(4).subjects = [4 9 12 16 19]; options.group(4).color = [117  80 123];
options.group(5).name = 'adh1';  options.group(5).subjects = [10 14 17 22];  options.group(5).color = [204   0   0];


%% Active contour model

% Set parameter for Gaussian smoothing of P in plant segmentation
% at full resolution phase
options.Sigma_P = 1.5;

% Set border size for cropping for the plant segmentation at full
% resolution phase
options.border = 5;

% Set number of iterations
options.iter = 80;

% Set the value of Sigma
options.sigma = 1.5;

% Set to true to not use median for the active contour model
options.noMedian = false;

% Weights of the background channels
options.lambda_out = 10^-2;

% Image-based featured term
options.lambda = 0.6;


%% Incremental learning

% Use plant appearance model
options.enable_appearance_model = false;

% Update the plant appearance model, or use the same for all images
options.GMM_update = false;
