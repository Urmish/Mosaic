%% Blend two images using alpha blending
% The weight given to a pixel is falls linearly with its distance from the center of gravity
% of the image

im1 = double(imtranslateds{1});
im2 = double(imtranslateds{2});

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
    weights{i} = (distance - maxDistance) / maxDistance;
    
end

w1 = repmat(weights{1}, [1 1 3]);
w2 = repmat(weights{2}, [1 1 3]);
imblended = (w1.*im1 + w2.*im2) ./ (w1 + w2);


figure;imshow(im1);
figure;imshow(im2);