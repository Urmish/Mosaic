function [ stitchedImage ] = StitchEmUp( images, image_masks, homographies )

center = ceil(length(images)/2);
%This is for panorama
min_cols = 1;
min_rows = 1;
max_cols = -1;
max_rows = -1;

H_stitch{center} = [1 0 0;0 1 0;0 0 1];
for i=(center+1):length(images)
    H_stitch{i} = H_stitch{i-1}/homographies{i-1};
    %TODO - Should the scale factor be 1?
    H_stitch{i} = H_stitch{i}/H_stitch{i}(3,3);
end
for i=(center-1):-1:1
    H_stitch{i} = H_stitch{i+1}*homographies{i};
    %TODO - Should the scale factor be 1?
    H_stitch{i} = H_stitch{i}/H_stitch{i}(3,3);
end

endHomography = H_stitch{length(images)}/homographies{length(images)};
endHomography = endHomography/endHomography(3,3);
clear homographies;

%Now, we need to create this huge image where we can keep putting the
%images one after the other. But How do I do that?
%There should be some way to determine the size of the frame
%Using this to help me out http://www.mathworks.com/help/vision/examples/feature-based-panoramic-image-stitching.html
% 
for i=1:length(images)
    %tempImage = zeros(size(images,1),size(images,2));
    %for x=1:size(images{i},1)
        %for y=1:size(images{i},2)
        %No need to loop through all the points, the four corners would give
        %the four limits
    [rows, cols, notNeeded] = size(images{i});
    point1 = [1 1 1]';
    point2 = [cols 1 1]';
    point3 = [1 rows 1]';
    point4 = [cols rows 1]';
    p_before = [point1 point2 point3 point4];
    for j=1:4
            p = H_stitch{i}*p_before(:,j);
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
end
min_cols = ceil(min_cols);
min_rows = ceil(min_rows);
max_cols = ceil(max_cols);
max_rows = ceil(max_rows);

%Need to initialize output image
output_rows = max_rows - min_rows;
output_cols = max_cols - min_cols;
output_image = zeros(output_rows,output_cols,3);
output_image_masks = zeros(output_rows,output_cols);
%Question - How do I map the negative index like min_cols to the ouput rows
%and cols??

%Call PasteImage to place all images in the global expanded image, then
%after each call, blend previous and new image. -- I cannot think of any
%other method to do so
for i=1:length(images)
%    temp_output_image = zeros(output_rows,output_cols,3);
%    temp_output_image_masks = zeros(output_rows,output_cols);
    [temp_output_image, temp_output_image_masks] = PasteImage(im2double(images{i}),image_masks{i},output_rows,output_cols,H_stitch{i},min_rows,min_cols);
    
    if (i == 1)
        output_image = temp_output_image;
        output_image_masks = temp_output_image_masks;
    else
        %There should be some blending happening here
        output_image = output_image+temp_output_image;
        output_image_masks = output_image_masks+temp_output_image_masks;
    end
    figure, imshow(output_image)
end

end


