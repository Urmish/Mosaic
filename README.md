# Mosaic
To stitch a series of images into a panorama,

1. Download sample images (http://pages.cs.wisc.edu/~jiaxu/misc/testing-images.zip)
2. Install VLFEAT (http://www.vlfeat.org/)
3. On MATLAB command, run

<b></b>

    >> runMosaic; translationStitch;

Note - You would have to change the focal length, k1 and k2 parameters according to the camera being used in the function CylindricalProjections( img, f, k1, k2 ) 
