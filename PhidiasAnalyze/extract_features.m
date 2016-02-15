function F = extract_features(I, session)
% EXTRACT_FEATURES Extract features of interest (a*, b* and texture) 
% from image I. The RGB to L*a*b* colour space conversion is performed 
% to eliminate issues of non uniform illumination

sigmaH = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigmaH"]');
sigmaL = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigmaL"]');
radius = session.mex.findValue('//tag[@name="inputs"]/tag[@name="radius"]');
falloff = session.mex.findValue('//tag[@name="inputs"]/tag[@name="falloff"]');

% Load system options
% config;

% a* and b* colour components
I_lab = rgb2lab(I);
F(:,:,1) = I_lab(:,:,2);
F(:,:,2) = I_lab(:,:,3);

% The response of a pillbox filter is linearly combined with a DoG filter.
% The filtered output F is defined as:
F(:,:,3) = imfilter(I_lab(:,:,2), fspecial('disk', radius), 'replicate', 'conv') + ...
    imfilter(I_lab(:,:,1), fspecial('gaussian', 2 * round(2 * sigmaH) + 1, sigmaH) - fspecial('gaussian', 2 * round(2 * sigmaH) + 1, sigmaL), 'replicate', 'conv');

% The response of the texture from blurring (TFB) filter is:
F(:,:,3) = exp(-falloff*abs(F(:,:,3)));

end