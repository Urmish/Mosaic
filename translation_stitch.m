
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
    
    % Remove overlapping part of panorama
    imPanorama(imPanorama ~= 0 & imtranslateds{i} ~= 0) = 0;
    % Add incoming image to panorama
    imPanorama = imPanorama + imtranslateds{i};
end

figure;imshow(imPanorama);

%%

for i = 1 : numImages
    figure;imshow(imtranslateds{i});
end
% for i = 1 : length(cylindricalImage)
%     figure;imshow(cylindricalImage{i});
% end