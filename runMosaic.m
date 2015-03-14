rng(0);  % Seed RNG for repeatability

img = ReadImagesFromFolder('tenner_large/','.jpg');
% img = ReadImagesFromFolder('Images/','.JPG');
size(img)
cylindricalImage = {};
Mask = {};

% Subsample the number of images
% img = img(:, :, :, 6:10);
numImages = size(img, 4);

% numImages = 4;
sprintf('Input %i images\n', numImages');

%%  Cylindrical projection

k1 = -0.15; k2 = 0.0;  % camera parameters for radial distortion
focalLength = 595;
factor = size(img, 1) / 640;  % how much large this image set is c.f. 640

% Correct parameters for difference in resolution
k1 = k1 / factor^2; k2 = k2 / factor^4;
focalLength = focalLength * factor;
for i=1:numImages
    [cylindricalImageTemp, MaskTemp] = CylindricalProjections( img(:,:,:,i), focalLength, k1, k2 );
    cylindricalImage{i} = cylindricalImageTemp;
    Mask{i} = MaskTemp;
end

%% Compute SIFT descriptors

disp('Computing SIFT Descriptors');
grayImages = {};
siftFeatures = {};
siftDescriptors = {};

for i=1:length(cylindricalImage)
    grayImages{i} = single(rgb2gray(cylindricalImage{i})); %as vl_sift expects a single matrix
    [siftFeatures{i} siftDescriptors{i}] = vl_sift(grayImages{i});
end


%% Compute homography from SIFT descriptors
HomographyMatrix = {};
HomographyMatches = {};
for i=1:length(cylindricalImage)-1
    [HomographyMatrix_temp, HomographyMatches_temp] = Ransac(siftFeatures{i}, siftDescriptors{i},siftFeatures{i+1}, siftDescriptors{i+1});
    sprintf('Ransac for %d & %d image is over',i,i+1)
    HomographyMatches{i} = HomographyMatches_temp;
    HomographyMatrix{i} = HomographyMatrix_temp;
end
[HomographyMatrix_temp, HomographyMatches_temp] = Ransac(siftFeatures{length(cylindricalImage)}, siftDescriptors{length(cylindricalImage)},siftFeatures{1}, siftDescriptors{1});
sprintf('Ransac for %d & %d image is over',length(cylindricalImage),1)
HomographyMatches{length(cylindricalImage)} = HomographyMatches_temp;
HomographyMatrix{length(cylindricalImage)} = HomographyMatrix_temp;

%Code for stitching goes here
%panImg = StitchEmUp(cylindricalImage, Mask, HomographyMatrix);
