function [ outputImage, outputImageMask ] = PasteImage( inputImage, inputImageMask ,global_rows, global_cols, homography, globalMinRow, globalMinCol)
%PASTEIMAGE - Take the image and place it on the final canvas using homography

min_rows = 1;
min_cols = 1;
max_rows = 0;
max_cols = 0;

outputImage = zeros(global_rows,global_cols,3);
outputImageMask = zeros(global_rows,global_cols);

[rows, cols, notNeeded] = size(inputImage);
point1 = [1 1 1]';
point2 = [cols 1 1]';
point3 = [1 rows 1]';
point4 = [cols rows 1]';
p_before = [point1 point2 point3 point4];
%dummyImage = zeros(size(inputImage));
%size(inputImageMask)
%imshow(inputImage)

for j=1:4
    p = homography*p_before(:,j);
    
    if (p(1) < min_cols)
        min_cols = single(floor(p(1)));
    end
    if (p(1) > max_cols)
        max_cols = single(ceil(p(1)));
    end
    if (p(2) < min_rows)
        min_rows = single(floor(p(2)));
    end
    if (p(2) > max_rows)
        max_rows = single(ceil(p(2)));
    end
    
end

min_cols = ceil(min_cols);
min_rows = ceil(min_rows);
max_cols = ceil(max_cols);
max_rows = ceil(max_rows);

%The min values are negative here!!! But the final image values are
%positive...
rowOffset = 1 - globalMinRow;
colOffset = 1 - globalMinCol;

min_rows = min_rows + rowOffset;
max_rows = max_rows + rowOffset;
min_cols = min_cols + colOffset;
max_cols = max_cols + colOffset;
count=0;
for y = min_rows:max_rows
    for x = min_cols:max_cols
        p = [x-colOffset; y-rowOffset; 1];
        p = homography\p;
        if (round(p(1)) >= 1 && round(p(1)) <= size(inputImage,2) && round(p(2)) >=1 && round(p(2)) <= size(inputImage,1))
            if (inputImageMask(round(p(2)),round(p(1))) > 0)
                outputImage(y,x,1) = inputImage(round(p(2)),round(p(1)),1);
                outputImage(y,x,2) = inputImage(round(p(2)),round(p(1)),2);
                outputImage(y,x,3) = inputImage(round(p(2)),round(p(1)),3);
                outputImageMask(y,x) = 1;
                %dummyImage(round(p(2)),round(p(1)),:) = inputImage(round(p(2)),round(p(1)),:);
                count=count+1;
            end
        end
    end
end
%figure, imshow(outputImage);
%figure, imshow(dummyImage);
%figure, imshow(outputImageMask);
%count
end

