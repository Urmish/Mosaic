function [ stitchedImage ] = StitchEmUp( images, image_masks, homographies )

center = ceil(length(images)/2);
%This is for panorama
min_x = 1;
min_y = 1;
max_x = -1;
max_y = -1;

H_stitch{center} = [1 0 0;0 1 0;0 0 1];
for i=(center-1):-1:1
    H_stitch{i} = H_stitch{i+1}*homographies{i};
    %TODO - Should the scale factor be 1?
    H_stitch{i} = H_stitch{i}/H_stitch{i}(3,3);
end

for i=(center+1):length(images)
    H_stitch{i} = H_stitch{i-1}/homographies{i-1};
    %TODO - Should the scale factor be 1?
    H_stitch{i} = H_stitch{i}/H_stitch{i}(3,3);
end

%Now, we need to create this huge image where we can keep putting the
%images one after the other. But How do I do that?
%There should be some way to determine the size of the frame
%Using this to help me out http://www.mathworks.com/help/vision/examples/feature-based-panoramic-image-stitching.html



end

