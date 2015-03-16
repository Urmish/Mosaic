# Mosaic

This project explores panorama stitching techniques. To stitch a series of images into a panorama,

1. Install [VLFEAT](http://www.vlfeat.org/).
2. Unzip [test images](http://pages.cs.wisc.edu/~jiaxu/misc/testing-images.zip) into an `Images` folder.
3. On MATLAB command, run

<b></b>

    >> close all; clear all;
    >> imageFolder='Images'; paramFile='data/testParams.txt';
    >> runMosaic; translationStitch;
    
See project wiki for more details.
