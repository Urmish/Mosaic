function [ cylindricalImage, Mask ] = CylindricalProjections( img, f, k1, k2 )
width = size(img,2);
height = size(img,1);

%figure, imshow(img);
for y=1:height
    for x=1:width
        %This is reverse mapping. You know your projected image plane.
        %Assume it to be unwarped cylinder. We know xsquiggle = ftheta +
        %xcylsquiggle
        
        theta = (x - width / 2) / f;
        h = (height / 2 - y) / f;
        
        %get cylindrical coordinates
        xcyl = sin(theta);
        ycyl = h;
        zcyl = cos(theta);
        
        %Steps to correct radial distortion - Normalize Image Coordinate,
        %Apply Radial Distortion
        xdist = xcyl / zcyl;
        ydist = ycyl / zcyl;

        r_sqr = xdist^2 + ydist^2;
        radDist = (1 + k1 * r_sqr + k2 * r_sqr^2);
        xd = xdist/radDist;
        yd = ydist/radDist;
        

        
        %Convert to cylindrical image coordinates
        xCylImg = floor(width / 2 + (f * xd));
        yCylImg = floor(height / 2 - (f * yd));
        
        if yCylImg > 0 && yCylImg <= height && xCylImg > 0 && xCylImg <= width
            cylindricalImage(y, x, 1) = uint8(img(yCylImg, xCylImg, 1));
            %disp('1')
            cylindricalImage(y, x, 2) = uint8(img(yCylImg, xCylImg, 2));
            %disp('2')
            cylindricalImage(y, x, 3) = uint8(img(yCylImg, xCylImg, 3));            
            %disp('3')
            Mask(y,x) = 1;
            %disp('4')
        end
    end
end
%figure, imshow(cylImg);
%size(cylindricalImage)
%size(Mask)
end