p1 = [116, 2509];
p2 = [11970, 2081];

%%
dp = (2509-2081)/(11970-116);
tform = maketform('affine',[1 dp 0; 0 1 0; 0 0 1]);
imDst = imtransform(imPanorama,tform);
figure('name', 'Panorama after shear'), imshow(imDst)