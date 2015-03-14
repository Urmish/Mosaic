%% Calculate gamma correction required to match exposure of two images

% Function for gamma correction
gcorr = @(im, gamma) uint8(255 * (double(im)/255).^gamma);

for i = 1 : numImages - 1
   im1 = rgb2gray(imtranslateds{i});
   im2 = rgb2gray(imtranslateds{i + 1});
   overlap = im1 > 0 & im2 > 0;
   
   pixels1 = (im1(overlap));
   pixels2 = (im2(overlap));
   figure;imhist(pixels1);
   figure;imhist(pixels2);

   options = statset('Display','final');
   gmm1 = fitgmdist(double(pixels1), 10, 'Options', options);
   disp(gmm1.mu);
   break;
   heatmap = hist3(double([im1(overlap) im2(overlap)]), 101 * [1 1]);
   heatmap = heatmap ./ repmat(sum(heatmap), [size(heatmap, 1), 1]);
   figure('name', sprintf('%i and %i', i, i+1));
   imshow(heatmap, []);
   axis equal;
   colorbar;
   disp(sum(overlap(:)));
   disp(sum(overlap(:)));
   break;

   ratio = sum(im2(overlap)) / sum(im1(overlap));
   ratios(i + 1) = ratio;
end


%% Manually tune gamma correction for images 6 to 10

% for i = linspace(.7, 1.5, 8);
%     foo = gcorr(imtranslateds{5}, i);
%     figure('name', num2str(i));
%     imshow(alphaBlendSmooth(foo, imtranslateds{4}));
% end

gammas = [2, 1, 0.93, 1.5 * .93, .85 * 1.5 * .93];
% gammas = ones(1, numImages);
imPanoramaManual = [];
for i = 1 : numImages
    gamma = gammas(i);
    imCurr = gcorr(imtranslateds{i}, gamma);
    if isempty(imPanoramaManual);
        imPanoramaManual = imCurr;
    else
        imPanoramaManual = alphaBlendSmooth(imPanoramaManual, imCurr);
    end
end

figure;imshow(imPanoramaManual)
gamma1 = 1.5;  % c.f. 2
gamma2 = 1;
gamma3 = 0.93;   %c.f.2
gamma4 = 1.5;  % c.f. 3
gamma5 = .85;  % c.f. 4