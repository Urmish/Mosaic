%% Equalize image exposures to reduce sharp changes in brightness when stitching
% Assumes there is a imtranslateds cell array which we'll equalize

if ~exist('imtranslateds', 'var')
    error('Script expects a cell array imtranslateds');
end

% Find the average brightness of each image compared to some global
% standard
ratios = 1;
for i = 1 : numImages - 1
   im1 = rgb2gray(imtranslateds{i});
   im2 = rgb2gray(imtranslateds{i + 1});
   overlap = im1 > 0 & im2 > 0;
   ratio = sum(im2(overlap)) / sum(im1(overlap));
   ratios(i + 1) = ratio;
end
global_exposures = cumprod(ratios);  % low value means image too dark
 
% Set median exposure to be 1 so that average exposure isn't too bright or
% dark
global_exposures = global_exposures / median(global_exposures);
% global_exposures = global_exposures / min(global_exposures);
 
% Equalize exposure individually
for i = 1 : numImages
      % Average ratio with 1 so that we don't make the compensation too
      % extreme. Results seem better if we don't go all out with
      % global_exposures(i)
    divisor = (global_exposures(i) + 1) / 2;
    imtranslateds{i} = uint8(double(imtranslateds{i}) / divisor);
end