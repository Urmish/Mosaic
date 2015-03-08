function [ imCropped ] = removeBlackPixels( imInput )
%REMOVEBLACKPIXELS Crop image by removing black pixels
% This procedures uses hill-climbing and does not guarantee that all black
% pixels are removed.

imGray = imInput;
if size(imInput, 3) > 1
    imGray = rgb2gray(imGray);
end
mask = imGray == 0;  % 1 where panorama is black

% Perform hill-climbing until we get the best crop
[y2, x2] = size(mask);
bestRect = [1, 1, x2, y2];  % start with full crop
bestValue = -sum(sum(mask));  % value is negative of no. of black pixels
while (1)
    
    % Try shrinking crop rectangle in all four directions
    actions = diag([1 1 -1 -1]);
    for i = 1 : 4
        action = actions(:, i)';
        neighbor = bestRect + action;
        croppedMask = imcrop(mask, [neighbor(1:2) neighbor(3:4) - neighbor(1:2)]);
        
        neighbors(i, :) = neighbor;
        values(i) = -sum(croppedMask(:));
    end
    
    if max(values) <= bestValue  % Terminate if no neighbor improves value
        break
    else
        [~, bestInd] = max(values);  % Select neighbor of best value
        bestValue = values(bestInd);
        bestRect = neighbors(bestInd, :);
    end;
    
    
end

imCropped = imcrop(imInput, [bestRect(1:2) bestRect(3:4) - bestRect(1:2)]);
end

