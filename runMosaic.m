rng(0);  % Seed RNG for repeatability

img = ReadImagesFromFolder('tenner_full/','.jpg');
% img = ReadImagesFromFolder('tenner_large/','.jpg');
% img = ReadImagesFromFolder('tenner/','.jpg');
% img = ReadImagesFromFolder('Images/','.JPG');
size(img)
cylindricalImage = {};
Mask = {};

% Subsample the number of images
img = img(:, :, :, 1:4);
img = uint8(img);
numImages = size(img, 4);

% numImages = 4;
sprintf('Input %i images\n', numImages');

%%  Cylindrical projection

% k1 and k2 of s110 at 4000x2664 is 3.5194684435329394e-02 -3.2228975511502600e-01
% focal length of s110 at 4000x2664 is 2.8704516949460021e+03
% k1 = -0.15; k2 = 0.0;  % camera parameters for radial distortion (Jia's
% test images)
k1 = 3.5194684435329394/100; k2 = -3.2228975511502600/10;
focalLength = 2.8704516949460021*10^3;
factor = size(img, 1) / 4000;  % how much large this image set is c.f. 640

% Correct parameters for difference in resolution
focalLength = focalLength * factor;

fprintf('k1 = %.2f, k2 = %.2f, focal length = %1f\n', k1, k2, focalLength);

for i=1:numImages
    [cylindricalImageTemp, MaskTemp] = CylindricalProjections( img(:,:,:,i), focalLength, k1, k2 );
    cylindricalImage{i} = cylindricalImageTemp;
    Mask{i} = MaskTemp;
end

figure('name', 'cylindrical images'); montage(cat(4, cylindricalImage{:}));

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
