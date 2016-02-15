% Load system options
config;

input_images = dir([options.data_path '*_label.png']);
[~, idx] = sortrows(char(input_images.name));
input_images = input_images(idx);

% Initialize CSV files with headers
dlmwrite([options.data_path 'time.csv'], 1:options.plant_n);
dlmwrite([options.data_path 'pla.csv'], 1:options.plant_n);
dlmwrite([options.data_path 'perimeter.csv'], 1:options.plant_n);
dlmwrite([options.data_path 'compactness.csv'], 1:options.plant_n);
dlmwrite([options.data_path 'stockiness.csv'], 1:options.plant_n);
dlmwrite([options.data_path 'diameter.csv'], 1:options.plant_n);
dlmwrite([options.data_path 'intensity.csv'], reshape(repmat(1:options.plant_n, [3 1]), 1, 3*options.plant_n));

timestamps = [];
for i = 1:numel(input_images)
    I_filename = input_images(i).name;
    fprintf('(%d) Extracting phenotypes from ''%s'' ...\n', i, I_filename);
    I = imread([options.data_path strrep(I_filename, '_label', '')]);
    L = imread([options.data_path I_filename]);
    timestamps = [timestamps; datevec(I_filename(5:end-10), 'yyyy-mm-dd_HH-MM')];
    dlmwrite([options.data_path 'pla.csv'], analysis_pla(L), '-append');
    dlmwrite([options.data_path 'perimeter.csv'], analysis_perimeter(L), '-append');
    dlmwrite([options.data_path 'compactness.csv'], analysis_compactness(L), '-append');
    dlmwrite([options.data_path 'stockiness.csv'], analysis_stockiness(L), '-append');
    dlmwrite([options.data_path 'diameter.csv'], analysis_diameter(L), '-append');
    dlmwrite([options.data_path 'intensity.csv'], analysis_intensity(I, L), '-append');
end
dlmwrite([options.data_path 'time.csv'], timestamps);

Area = dlmread([options.data_path 'pla.csv']); % pixels
deltaT = etime(timestamps(2:end,:), timestamps(1:end-1,:))/3600; % hours
[AGR, RGR] = analysis_growth_rate(Area(2:end,:), deltaT);
dlmwrite([options.data_path 'agr.csv'], AGR);
dlmwrite([options.data_path 'rgr.csv'], RGR);