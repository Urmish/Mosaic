function [ imBlended ] = alpha_blend( imInput1, imInput2 )
%% Blend two images using alpha blending
% The weight given to a pixel is falls linearly with its distance from the center of gravity
% of the image
% im1 and im2 are color images of the same size. imBlended is the blended
% image with the same size as im1 and im2.

im1 = double(imInput1); im2 = double(imInput2);

% Get weights of two images
imInputs = {im1, im2};
for i = 1 : length(imInputs)
    
    imInput = imInputs{i};
    mask = rgb2gray(imInput) > 0;  % 1 where input image isn't black
    
    % Get center of mass of image
    [x, y] = meshgrid(1:size(imInput, 2), 1:size(imInput, 1));
    yCOG = sum(y(mask)) / sum(mask(:));
    xCOG = sum(x(mask)) / sum(mask(:));
    
    % Weight each pixel by its distance from COG
    % Weight is 1 at COG and at the furthest point of the mask
    distance = sqrt((x-xCOG).^2 + (y-yCOG).^2);
    maxDistance = max(distance(mask));
    weights{i} = (-distance + maxDistance) / maxDistance;
    
end

% Fill-in image that's not in the overlapping portion
overlap = im1 > 0 & im2 > 0;
imBlended = im1 .* (im1 > 0 & ~overlap) + im2 .* (im2 > 0 & ~overlap);

% Create overlapping part (later we'll exclude everything outside
% overlapping region)
w1 = repmat(weights{1}, [1 1 3]);
w2 = repmat(weights{2}, [1 1 3]);
imAND = (w1.*im1 + w2.*im2) ./ (w1 + w2);

% Fill-in overlapping region
imBlended(overlap) = imAND(overlap);

% Cast output image to make it same as inputs
imBlended = cast(imBlended, 'like', imInput1);