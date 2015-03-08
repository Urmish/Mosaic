rng(0);  % Seed RNG for repeatability

img = ReadImagesFromFolder('Images/','.JPG');
size(img)
cylindricalImage = {};
Mask = {};
numImages = size(img, 4);
% numImages = 4;
sprintf('Input %i images\n', numImages');

for i=1:numImages
    [cylindricalImageTemp, MaskTemp] = CylindricalProjections( img(:,:,:,i), 595, -0.15, 0.0 );
    cylindricalImage{i} = cylindricalImageTemp;
    Mask{i} = MaskTemp;
end

disp('Computing SIFT Descriptors');
grayImages = {};
siftFeatures = {};
siftDescriptors = {};

for i=1:length(cylindricalImage)
    grayImages{i} = single(rgb2gray(cylindricalImage{i})); %as vl_sift expects a single matrix
    [siftFeatures{i} siftDescriptors{i}] = vl_sift(grayImages{i});
end

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