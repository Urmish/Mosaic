rng(0);  % Seed RNG for repeatability

%% Read images

if ~exist('imageFolder', 'var')
    error('Image folder "imageFolder" not specified.');
end

% img = ReadImagesFromFolder('tenner_full/','.jpg');
% img = ReadImagesFromFolder('tenner_large/','.jpg');
img = ReadImagesFromFolder(imageFolder);
% img = ReadImagesFromFolder('Images/','.JPG');

img = uint8(img);  % img is supposed to be uint8 upon loading but it's not. Oh well.

% Subsample the number of images
% img = img(:, :, :, 1:2);
numImages = size(img, 4);

% numImages = 4;
sprintf('Input %i images\n', numImages');

%% Read camera parameters

% Expect a text file of the format
% <k1>, <k2>, <focal length>
if ~exist('paramFile', 'var');
    error('Camera parameter filename "paramFile" not specified.');
end
IS_S110 = strcmp(paramFile, 'data/s110Params.txt');

% k1 and k2 of s110 at 4000x2664 is 3.5194684435329394e-02 -3.2228975511502600e-01
% focal length of s110 at 4000x2664 is 2.8704516949460021e+03
% k1 = -0.15; k2 = 0.0;  % camera parameters for radial distortion (Jia's test images)
% focalLength = 595;  % Jia's test image
params = dlmread(paramFile);
k1 = params(1); k2 = params(2); focalLength = params(3);

if IS_S110
    factor = size(img, 1) / 4000;  % how much large this image set is c.f. 640

    % Correct parameters for difference in resolution
    focalLength = focalLength * factor;
end

fprintf('k1 = %.2f, k2 = %.2f, focal length = %1f\n', k1, k2, focalLength);

%%  Cylindrical projection

cylindricalImage = {};
Mask = {};
for i=1:numImages
    [cylindricalImageTemp, MaskTemp] = CylindricalProjections( img(:,:,:,i), focalLength, k1, k2 );
    cylindricalImage{i} = cylindricalImageTemp;
    Mask{i} = MaskTemp;
end

figure('name', 'cylindrical images'); montage(cat(4, cylindricalImage{:}));

%% Corresponding pairs for 4000 pixel height resolution

% size(img, 1) / 4000 * 
correspondenceMatrices =  {
    [2296.125       1874.875      381.46039      1942.0718;
           2280.7         2280       355.64       2347.6],
    [2373.1641      1909.1897      593.08412      1991.9419;
             2186       1156.6       425.74         1244],
    [2142.1212      2158.5024      164.63429      2218.0859],
    [2217.4971      1995.9466      201.11342      2048.5435],
    [2132.1638      1894.1269      245.24848      1924.8308]
    };



%% Get transformations

for i = 1 : length(correspondenceMatrices)
    fixedPoints = correspondenceMatrices{i}(:, 1 : 2);
    movingPoints = correspondenceMatrices{i}(:, 3 : 4);
    tform = fitgeotrans(movingPoints, fixedPoints, 'NonreflectiveSimilarity');

    % Compute T(1) * ... * T(n-1) * T(n)
    tforms(i) = tform;
    if i ~= 1
        tforms(i).T = tforms(i-1).T * tforms(i).T;
    end
    
    if i == 2; break; end;

end


%% Create blank panorama canvas

imageSize = size(cylindricalImage{1});

for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(2)], [1 imageSize(1)]);
end

% Find the minimum and maximum output limits
xMin = min([1; xlim(:)]);
xMax = max([imageSize(2); xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([imageSize(1); ylim(:)]);

% Width and height of panorama.
width  = round(xMax - xMin);
height = round(yMax - yMin);

% Initialize the "empty" panorama.
imPanorama = padarray(cylindricalImage{1}, [height - imageSize(1), width - imageSize(2)], 0, 'post');


%% Apply transformations

% Create a 2-D spatial reference object defining the size of the panorama.
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoramaView = imref2d([height width], xLimits, yLimits);

for i = 2 : 2 + length(tforms) - 1
    fprintf('Stitching in image %i\n', i);
    tform = tforms(i - 1);
    warpedImage = imwarp(cylindricalImage{i}, tform, 'OutputView', panoramaView);
    
    imPanorama = alphaBlendSmooth(imPanorama, warpedImage);
    figure;imshow(imPanorama);
end
disp('Done stitching');