function imOutput = projectToCylinder(imInput, focalLength, interpolation)
% Project an image to a cylinder of radius focalLength
% `interpolation` interpolation method permissible by interp2 function

if ~exist('interpolation', 'var')
    interpolation = 'nearest';
end

%%
width = size(imInput,2);
height = size(imInput,1);

[xmesh, ymesh] = meshgrid(1:width, 1:height);

% We multiple by f because we want the cylinder to be of size f.
% If it's unit size it'll be too small a cylinder and you get a tiny image.
ftheta = (xmesh - width / 2);  % x-coordinate of output image
h = (ymesh - height / 2);  % y-coordinate of output image (height of the cylinder of radius f)

x = focalLength * tan(ftheta / focalLength);
y = sqrt(x.^2 + focalLength^2) / focalLength .* h;

imOutput = zeros(size(imInput), 'like', imInput);
for dim = 1 : size(imInput, 3)
    imOutput(:, :, dim) = interp2(ftheta, h, double(imInput(:, :, dim)), x, y, interpolation);
end