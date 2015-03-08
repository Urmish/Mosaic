function [ imBlended ] = alphaBlendSmooth( imInput1, imInput2 )
%% Smooth blending of two images using alpha blending
% The weight given to a pixel of im1 is a function of the pixel's distance
% from the border between (im1 & im2) and (im1 & ~im2)

im1 = double(imInput1); im2 = double(imInput2);
mask1 = rgb2gray(im1) > 0;  % 1 where im1 has intensity values
mask2 = rgb2gray(im2) > 0;
overlap =  mask1 & mask2;

% Get weights of two images
masks = {mask1, mask2};
for i = 1 : length(masks)
    
    mask = masks{i};  % 1 where input image isn't black
    
    % Get the 1 pixel thick border where the overlapping part meets the
    % rest of the image
    border = mask & (imdilate(overlap, [0 1 0; 1 1 1; 0 1 0]) & ~overlap);
    
    % Distance transform from the border
    distances{i} = bwdist(border) + 0.1;  % add episilon to prevent division by zero errors
end

%%

% Fill-in image that's not in the overlapping portion
overlap = repmat(overlap, [1 1 3]);
imBlended = im1 .* (im1 > 0 & ~overlap) + im2 .* (im2 > 0 & ~overlap);

% Create overlapping part (later we'll exclude everything outside
% overlapping region)
dist1 = repmat(distances{1}, [1 1 3]);
dist2 = repmat(distances{2}, [1 1 3]);
imAND = (dist2 .* im1 + dist1 .* im2) ./ (dist2 + dist1);

% Fill-in overlapping region
imBlended(overlap) = imAND(overlap);

% Cast output image to make it same as inputs
imBlended = cast(imBlended, 'like', imInput1);