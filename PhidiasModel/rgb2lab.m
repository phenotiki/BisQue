function Lab = rgb2lab(rgb)
% RGB2LAB RGB to L*a*b* colour space conversion.
%
% Usage: Lab = rgb2lab(rgb)
%
% This function wraps up calls to MAKECFORM and APPLYCFORM in a convenient
% form.  Note that if the image is of type uint8 this function casts it to
% double and divides by 255 so that the transformed image can have the
% proper negative values for a and b.  (If the image is left as uint8 MATLAB
% will shift the values into the range 0-255)

% Copyright (c) 2009 Peter Kovesi
% School of Computer Science & Software Engineering
% The University of Western Australia
% pk at csse uwa edu au
% http://www.csse.uwa.edu.au/

% PK May 2009

% Convert from the sRGB to the L*a*b* color space
cform = makecform('srgb2lab');
if strcmp(class(rgb), 'uint8')
    rgb = double(rgb) / 255;
end
% L* lies between 0 and 100, and a* and b* lie between -110 and 110
Lab = applycform(rgb, cform);

end