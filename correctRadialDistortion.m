function imOutput = correctRadialDistortion(imInput, k1, k2, focalLength, interpolation)
%Correct an image's radial distortion
%xcorr = x * r_polynomial, where xcorr is the corrected x-coordinate and x
%is the x-coordinate of the distorted image
% `interpolation` interpolation method permissible by interp2 function

if ~exist('interpolation', 'var')
    interpolation = 'nearest';
end

width = size(imInput,2);
height = size(imInput,1);

[xmesh, ymesh] = meshgrid(1:width, 1:height);

xcorr = (xmesh - width / 2) / focalLength;
ycorr = (ymesh - height / 2) / focalLength;
        
r_sqr = sqrt(xcorr.^2 + ycorr.^2);
r_polynominal = 1 + k1 * r_sqr + k2 * r_sqr.^2;
x = xcorr ./ r_polynominal;
y = ycorr ./ r_polynominal;

imOutput = zeros(size(imInput), 'like', imInput);
for dim = 1 : size(imInput, 3)
    imOutput(:, :, dim) = interp2(xcorr, ycorr, double(imInput(:, :, dim)), x, y, interpolation);
end