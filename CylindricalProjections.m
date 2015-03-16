function [ cylindricalImage, mask ] = CylindricalProjections( img, f, k1, k2 )
% Calculates the inverse cylindrical projections of the image & corrects radial distortion
% Note - Change the f,k1 & k2 value according to the camera being used
width = size(img,2);
height = size(img,1);

%figure, imshow(img);
[x, y] = meshgrid(1:width, 1:height);


theta = (x - width / 2) / f;
h = (height / 2 - y) / f;
        
%get cylindrical coordinates
xcyl = sin(theta);
ycyl = h;
zcyl = cos(theta);

%Steps to correct radial distortion - Normalize Image Coordinate,
%Apply Radial Distortion
xdist = xcyl ./ zcyl;
ydist = ycyl ./ zcyl;

r_sqr = xdist.^2 + ydist.^2;
radDist = (1 + k1 * r_sqr + k2 * r_sqr.^2);
xd = xdist ./ radDist;
yd = ydist ./ radDist;

%Convert to cylindrical image coordinates
xCylImg = floor(width / 2 + (f * xd));
yCylImg = floor(height / 2 - (f * yd));

% 1 where pixel assignment is legal
mask = yCylImg > 0 & yCylImg <= height & xCylImg > 0 & xCylImg <= width;

src_sub = sub2ind([height, width], yCylImg(mask), xCylImg(mask));
dst_sub = sub2ind([height, width], y(mask), x(mask));
for dim = 1 : size(img, 3)
    
    % Create empty color channel
    dst_channel = zeros([height, width], 'like', img);
    
    % Grab one channel of source image
    src_channel = img(:, :, dim);
    
    % Copy pixel values
    dst_channel(dst_sub) = src_channel(src_sub);
    
    % Assign channel to returned color image
    cylindricalImage(:, :, dim) = dst_channel;
    
end

%figure, imshow(cylindricalImage);
end
