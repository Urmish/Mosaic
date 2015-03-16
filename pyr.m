function blended = pyr( img1,img2, mask1, mask2, level, a )
%TODO - If the original image measures 2N + 1 by 2N + 1, then the pyramid will have N + 1 levels
gKernel = fspecial('gauss',30,15);
mask1 = imfilter(mask1,gKernel,'replicate');
mask2 = imfilter(mask2,gKernel,'replicate');
%figure, imshow(mask1(:,:,1));
%figure, imshow(mask2(:,:,1));

lapPyr1 = generatePyramid(img1,level); % the Laplacian pyramid
lapPyr2 = generatePyramid(img2,level);

%blend and combine pyramids
combinedPyr = cell(1,level); 
for p = 1:level
	[rows1 cols1 dontuse1] = size(lapPyr1{p});
    [rows2 cols2 dontuse2] = size(lapPyr2{p});
	maskResize1 = imresize(mask1,[rows1 cols1]);
	maskResize2 = imresize(mask2,[rows2 cols2]);
    appliedMask1 = lapPyr1{p}.*maskResize1;
    appliedMask2 = lapPyr2{p}.*maskResize2;

	combinedPyr{p} = appliedMask1 + appliedMask2;
end

blended = combinePyramid(combinedPyr);
%figure,imshow(blended);
end

%% GeneratePyramid
function  pyr = generatePyramid( img, level)
pyr = cell(1,level);
pyr{1} = img;

%Build Gaussian pyramid
for p = 2:level
    img = pyr{p-1};
    %figure, imshow(pyr{p});
    kernel = fspecial('gauss',5,1);
    reducedImage = [];
    [rows cols dontuse] = size(img);
    for i = 1:size(img,3)
        temp = img(:,:,i);
        filtered = imfilter(temp,kernel,'replicate','same');
        %imgout(:,:,p) = imresize(blurredImg, [ceil(M/2), ceil(N/2)]);
        reducedImage(:,:,i) = filtered(1:2:rows,1:2:cols);
    end
    pyr{p} = reducedImage;
end

%TODO - Ideally this should not be used, but I am getting some very wierd
%errors for dimensionality. Need to iron out the issue
for p = level-1:-1:1
	expandedTierSize = 2*size(pyr{p+1})-1;
	pyr{p} = pyr{p}(1:expandedTierSize(1),1:expandedTierSize(2),:);
end

for p = 1:level-1
    %size(pyr{p})
	pyr{p} = pyr{p}-expandPyramid(pyr{p+1});
    %figure, imshow(pyr{p});
end
end



%% Expand Image
function expandedImage = expandPyramid( img)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%The below implementation works but it is very very slow%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% kernelwidth = 5; 
% kernel = fspecial('gauss',kernelwidth,1)*4; 
% m = [-2:2];n=m;
% 
% 
% img = im2double(img);
% [rows, cols] = size(img(:,:,1));
% rows = 2*rows;
% cols = 2*cols;
% 
% expandedImage = zeros(rows-1, cols-1, size(img,3));
% imgOutTemp = zeros(rows, cols, size(img,3));
% 
% 
%     I1 = img(:,:,1);
%     dim1 = size(I1);
%     I1 = [ I1(1,:) ;  I1 ;  I1(dim1(1),:) ];  % Pad the top and bottom rows.
%     I1 = [ I1(:,1)    I1    I1(:,dim1(2)) ];  % Pad the left and right columns.
%     
%     I2 = img(:,:,2);
%     dim2 = size(I2);
%     I2 = [ I2(1,:) ;  I2 ;  I2(dim2(1),:) ];  % Pad the top and bottom rows.
%     I2 = [ I2(:,1)    I2    I2(:,dim2(2)) ];  % Pad the left and right columns.
%     
%     I3 = img(:,:,3);
%     dim3 = size(I3);
%     I3 = [ I3(1,:) ;  I3 ;  I3(dim3(1),:) ];  % Pad the top and bottom rows.
%     I3 = [ I3(:,1)    I3    I3(:,dim3(2)) ];  % Pad the left and right columns.
%     
%     for i = 0 : rows - 1
%         for j = 0 : cols - 1
%             pixeli = (i - m)/2 + 2;  idxi = find(floor(pixeli)==pixeli);
%             pixelj = (j - m)/2 + 2;  idxj = find(floor(pixelj)==pixelj);
%             A1 = I1(pixeli(idxi),pixelj(idxj)) .* kernel(m(idxi)+3,m(idxj)+3);
%             %imgOutTemp(i + 1, j + 1,p)= 4 * sum(A(:));
%             imgOutTemp(i + 1, j + 1,1)= sum(A1(:));
%             
%             A2 = I2(pixeli(idxi),pixelj(idxj)) .* kernel(m(idxi)+3,m(idxj)+3);
%             imgOutTemp(i + 1, j + 1,2)= sum(A2(:));
%             A3 = I3(pixeli(idxi),pixelj(idxj)) .* kernel(m(idxi)+3,m(idxj)+3);
%             imgOutTemp(i + 1, j + 1,3)= sum(A3(:));
%         end
%     end
%     expandedImage(:,:,1) = imresize(imgOutTemp(:,:,1),[rows-1 cols-1]);
%     expandedImage(:,:,2) = imresize(imgOutTemp(:,:,2),[rows-1 cols-1]);
%     expandedImage(:,:,3) = imresize(imgOutTemp(:,:,3),[rows-1 cols-1]);
% 
% size(expandedImage)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Faster implementation - Inspired by http://www.mathworks.com/matlabcentral/fileexchange/30790-image-pyramid-gaussian-and-laplacian-/content/pyr_expand.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This implementation is based on the observation that while expanding each
% pixel, the kernel that gets executed to find values on the right, botton
% and diagnol of a pixel is repetetive in the "integer pixel" values that
% it uses to calculate (given by - kernel(m(idxi)+3,m(idxj)+3)) (Not - not all values used here)
%%% The original implementation takes 25 minutes to stitch 2 images!!!!
%%% This reduces computations as one can use matrix convolution directly
%%% rather than going pixel by pixel.
%kw = 5; % default kernel width
%cw = .375; % kernel centre weight, same as MATLAB func impyramid. 0.6 in the Paper
%ker1d = [.25-cw/2 .25 cw .25 .25-cw/2];
%kernel = kron(ker1d,ker1d')*4;
kernelwidth = 5; 
kernel = fspecial('gauss',kernelwidth,1)*4; %%Note - If we use this we
% get images with white pixels in few blended regions
ker00 = kernel(1:2:kernelwidth,1:2:kernelwidth); % 3*3
ker01 = kernel(1:2:kernelwidth,2:2:kernelwidth); % 3*2
ker10 = kernel(2:2:kernelwidth,1:2:kernelwidth); % 2*3
ker11 = kernel(2:2:kernelwidth,2:2:kernelwidth); % 2*2

img = im2double(img);
[rows, cols] = size(img(:,:,1));
rows = 2*rows-1;
cols = 2*cols-1;

expandedImage = zeros(rows, cols, size(img,3));

for p = 1:size(img,3)
 	temp = img(:,:,p);
    %Need this pad for filtering operation. Border case handling
 	colPad = padarray(temp,[0 1],'replicate','both'); % horizontally padded
 	rowPad = padarray(temp,[1 0],'replicate','both'); % vertically padded
	
	img00 = imfilter(temp,ker00,'replicate','same');
	img01 = conv2(rowPad,ker01,'valid'); %imfilter does not allow valid flag
	img10 = conv2(colPad,ker10,'valid');
	img11 = conv2(temp,ker11,'valid');
	
	expandedImage(1:2:rows,1:2:cols,p) = img00;
    expandedImage(1:2:rows,2:2:cols,p) = img01;
	expandedImage(2:2:rows,1:2:cols,p) = img10;
	expandedImage(2:2:rows,2:2:cols,p) = img11;
end
end

%%CombinePyramid
function imgOut  = combinePyramid( pyr)

for p = length(pyr)-1:-1:1
    pyr{p} = pyr{p}+expandPyramid(pyr{p+1});
end
imgOut = pyr{1};

end
