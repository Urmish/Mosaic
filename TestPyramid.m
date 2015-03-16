%To run this script do the following steps -
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
img = ReadImagesFromFolder('Images/','.JPG');
size(img)
cylindricalImage = {};
Mask = {};
for i=1:size(img,4)
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

images = cylindricalImage; 
image_masks = Mask; 
homographies = HomographyMatrix;

for i = 1: length(HomographyMatrix)
    HomographyMatrix{i}(:, 1:2) = [1 0; 0 1; 0 0];
    
    % Translation from i to i + 1
    translations(1:2, i + 1) = HomographyMatrix{i}(1:2, end);
end

numImages = length(HomographyMatrix);
% Get offset of images with respect to panorama frame
global_offsets = cumsum(-translations(:, 1:end - 1), 2);

% Make sure all translations are positive
for dim = 1: 2
    global_offsets(dim, :) = global_offsets(dim, :) - min(global_offsets(dim, :));
end

% Translate
for i = 1 : numImages
    offset = global_offsets(:, i)';
    imtranslateds{i} = imtranslate(cylindricalImage{i}, offset, 'OutputView', 'full');
end

%% Erode images so that we don't get black artifacts at the border after stitching
for i = 1 : numImages    
    % Mask that's 1 at the pixels we allow to survive after cropping
    % We need to pad array with 1 pixel of zeros otherwise positive values
    % at the border will not be eroded.
    maskBefore = padarray(rgb2gray(imtranslateds{i}) > 0, [1  1]);
    maskAfter = imerode(maskBefore, strel('square', 3));
    maskAfter = maskAfter(2:end-1, 2:end-1);  % remove pads that we added
    
    % Zero everything outside mask
    imtranslateds{i}(~repmat(maskAfter, [1, 1, 3])) = 0;

end


%%
% Add black pixels to bottom and right of each translated so that they're
% all the same size
for i = 1 : numImages
    sizes(i, :) = size(imtranslateds{i});
end
maxHeight = max(sizes(:, 1));
maxWidth = max(sizes(:, 2));
for i = 1 : numImages
    currSize = size(imtranslateds{i});
    imtranslateds{i} = padarray(imtranslateds{i}, [maxHeight maxWidth] - currSize(1:2), ...
        0, 'post');
end

translated_mask = {};
for i = 1 : numImages
    currSize = size(imtranslateds{i});
    translated_mask{i} = im2bw(imtranslateds{i},0);
end

pan_image = imtranslateds{2};
pan_mask = translated_mask{2};

for i=3:numImages-1
    sprintf('Stitching image %d',i)
    temp_pan_image = imtranslateds{i};
    temp_pan_mask = translated_mask{i};
               
    temp_Mask = zeros(size(pan_mask, 1), size(pan_mask, 2), 3);   
    temp_Mask(:,:,1) = pan_mask(:,:); temp_Mask(:,:,2) = pan_mask(:,:); temp_Mask(:,:,3) = pan_mask(:,:);
        
    temp_Mask_2 = zeros(size(temp_pan_mask, 1), size(temp_pan_mask, 2), 3); 
    temp_Mask_2(:,:,1) = temp_pan_mask(:,:); temp_Mask_2(:,:,2) = temp_pan_mask(:,:); temp_Mask_2(:,:,3) = temp_pan_mask(:,:);
              
    compMask = temp_Mask+temp_Mask_2;
    overlapMask = temp_Mask & temp_Mask_2;
    diffMask = xor(compMask, overlapMask);
    pan_image = im2double(pan_image)+im2double(temp_pan_image);
    pan_image = im2double(pan_image).*diffMask;
    overlap_image = im2double(temp_pan_image).*overlapMask;

    blendedImg = pyr(pan_image, overlap_image, diffMask, overlapMask, 5, 3.75);
    pan_image = blendedImg;
    pan_image = imresize(pan_image, [size(temp_pan_image, 1) size(temp_pan_image, 2)]);
    pan_mask = compMask(:,:,1);
end
