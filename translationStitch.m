

%% Force homographies to be translation only
% for i = 1: length(HomographyMatrix)
%     HomographyMatrix{i}(:, 1:2) = [1 0; 0 1; 0 0];
%     
%     % Translation from i to i + 1
%     translations(1:2, i + 1) = HomographyMatrix{i}(1:2, end);
% end

%% Manually change Homography for tenner image at 640x426 resolution

% First row is xy1 of cylinder image 1 and 2
% Second row is xy1 of cylinder image 2 and 3
% Factor in front of expression is to account for large or small
% resolutions that we're working on.

% Corresponding pairs for 640 pixel height resolution
xy1xy2 =  size(img, 1) / 640 *[369.2500  300.7500 62.3172  311.4988;
      391.6983  358.7676  105.0842  370.7724;
        342.1786  358.0173   24.0520  367.0209;
          358.6852  265.7306   35.3065  275.4845;
  349.6816  302.4952   46.5609  307.7473
      ];
 
% Corresponding pairs for 4000 pixel height resolution
xy1xy2 =  size(img, 1) / 4000 * [2296.125       1874.875      381.46039      1942.0718;
    2373.1641      1909.1897      593.08412      1991.9419;
2142.1212      2158.5024      164.63429      2218.0859;
2217.4971      1995.9466      201.11342      2048.5435;
2132.1638      1894.1269      245.24848      1924.8308;
    ];

for i = 1 : size(xy1xy2, 1)
    translations(:, i + 1) = xy1xy2(i, 3:4) - xy1xy2(i, 1:2);
end

%% Force tail images to be at the same height if inputs are 360 deg
% NOTE: this part isn't well tested.
if exist('is360', 'var') && is360
    disp(translations);
    disp(translations(2, end))
    translations(2, 1:end-1) = translations(2, 1:end-1) - ...
        linspace(0, translations(2, end), size(translations, 2) - 1);
    disp(translations);
end

%% Translate images

% Get offset of images with respect to panorama frame
global_offsets = cumsum(-translations(:, 1:numImages), 2);

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

%% Equalize image exposures to reduce sharp changes in brightness when stitching

% equalizeExposures;
 
%% Perform stitching by alpha blending input images 1 by 1 to panorama
imPanorama = imtranslateds{1};
for i = 2 : numImages
    fprintf('Stitching in image %i of %i\n', i, numImages);
    imtranslated = imtranslateds{i};
    imPanorama = alphaBlendSmooth(imPanorama, imtranslated);
end

%% Crop panorama by hill-climbing

imPanoramaCropped = removeBlackPixels(imPanorama);

%% Display results

% Display translated images in a single figure
figure('name', 'translated images');montage(cat(4, imtranslateds{:}));

figure('name', 'Stitched image'); imshow(imPanorama);
figure('name', 'Stitched > cropped'); imshow(imPanoramaCropped);

% Show difference between all input images together in one figure
imDifference = imtranslateds{1};
for i = 2 : numImages
    imDifference = imfuse(imDifference, imtranslateds{i}, 'diff');
end
figure('name', 'Difference image'); imshow(imDifference);

% Show difference between consecutive image pairs
for i = 1 : numImages - 1
    imDiffPair = imfuse(imtranslateds{i}, imtranslateds{i + 1}, 'diff');
    figure('name', sprintf('Image %i - %i', i, i + 1));
    imshow(imDiffPair);
end