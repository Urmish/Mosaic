

%% Force homographies to be translation only
for i = 1: length(HomographyMatrix) - 1
    HomographyMatrix{i}(:, 1:2) = [1 0; 0 1; 0 0];
    disp(HomographyMatrix{i})
    
    % Translation from i to i + 1
    translations(1:2, i + 1) = HomographyMatrix{i}(1:2, end);
end

% Get offset of images with respect to panorama frame
global_offsets = cumsum(-translations, 2);

% Make sure all translations are positive
for dim = 1: 2
    global_offsets(dim, :) = global_offsets(dim, :) - min(global_offsets(dim, :));
end

% Translate
for i = 1 : numImages
    offset = global_offsets(:, i)';
    imtranslateds{i} = imtranslate(cylindricalImage{i}, offset, 'OutputView', 'full');
end

% Erode images so that we don't get black artifacts at the border after stitching
for i = 1 : numImages    
    % Mask that's 1 at the pixels we allow to survive after cropping
    mask = imerode(imtranslateds{i} > 0, strel('square', 5));
    % Zero everything outside mask
    imtranslateds{i}(~mask) = 0;
end



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

%% Perform stitching by removing overlapping portion of one image in pair
imPanorama = imtranslateds{1};
for i = 2 : numImages
    
    imtranslated = imtranslateds{i};
    
    % Binary mask that's 1 at the overlapping portion
    overlap = imPanorama ~= 0 & imtranslated ~= 0;
    
    % Half intensities of both images at the overlap
    imPanorama(overlap) = imPanorama(overlap) / 2;
    imtranslated(overlap) = imtranslated(overlap) / 2;
    
    % Add incoming image to panorama
    imPanorama = imPanorama + imtranslated;
end

figure;imshow(imPanorama);

%%

for i = 1 : numImages
    figure;imshow(imtranslateds{i});
end
% for i = 1 : length(cylindricalImage)
%     figure;imshow(cylindricalImage{i});
% end