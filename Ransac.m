function [ finalHomography, finalMatches ] = Ransac( feature1, desc1, feature2, desc2 )
% Uses the VL_Feat library to match points in two images, then uses the RANSAC algorithm as discussed in class to calculate homography
[matches, scores] = vl_ubcmatch(desc1, desc2) ;

MaxInlierCount = -1;
numIterations = 500;
numMatches = size(matches,2) ;
ErrorThreshold = 4;
%X1 = f1(1:2,matches(1,:)) ; X1(3,:) = 1 ;
%X2 = f2(1:2,matches(2,:)) ; X2(3,:) = 1 ;
numOfRandPoints = 4;
A = zeros(2*numOfRandPoints,2*numOfRandPoints);
b = zeros (2*numOfRandPoints,1);

for t=1:numIterations
    PreviousIndex = zeros(numOfRandPoints);
    index = 1;
    A = zeros(2*numOfRandPoints,2*numOfRandPoints);
    b = zeros (2*numOfRandPoints,1);
    for nor = 1:numOfRandPoints
        RandomNumber = randi(size(matches,2));
        while (ismember(RandomNumber,PreviousIndex))
                RandomNumber = randi(size(matches,2));
        end
        PreviousIndex(nor) = RandomNumber;
        % Using slide 29 of
        % http://www.cse.psu.edu/~rcollins/CSE486/lecture16.pdf to help
        % setup equation
        
        %F = VL_SIFT(I) computes the SIFT frames [1] (keypoints) F of the image I. 
        %I is a gray-scale image in single precision. 
        %Each column of F is a feature frame and has the format [X;Y;S;TH], 
        %where X,Y is the (fractional) center of the frame, S is the scale 
        %and TH is the orientation (in radians).
        
        y1 = feature1(2,matches(1,RandomNumber));
        x1 = feature1(1,matches(1,RandomNumber));

        y1p = feature2(2,matches(2,RandomNumber));
        x1p = feature2(1,matches(2,RandomNumber));

        A(index,:) = [x1 y1 1 0 0 0 (-x1p*x1) (-x1p*y1)];
        b(index,1) = x1p;
        
        A(index+1,:) = [0 0 0 x1 y1 1 (-y1p*x1) (-y1p*y1)];
        b(index+1,1) = y1p;
        index = index + 2;
    end
    h = A\b;
    homographyMatrix = [h(1) h(2) h(3);h(4) h(5) h(6);h(7) h(8) 1];
    
    inlierCount = 0;
    inliers = [];
    for j=1:numMatches
        p1 = [feature1(1,matches(1,j)); feature1(2,matches(1,j)); 1];
        p1 = homographyMatrix*p1;
            
        p2 = [feature2(1,matches(2,j)); feature2(2,matches(2,j)); 1];
            
        if ( ((p1(1)-p2(1))^2 + (p1(2)-p2(2))^2) <= ErrorThreshold)
            inlierCount = inlierCount + 1;
            inliers = [inliers; matches(1,j) matches(2,j)];
        end
    end
        
    if (inlierCount > MaxInlierCount)
        finalMatches = inliers;
        MaxInlierCount = inlierCount;
        finalHomography = homographyMatrix;
    end
end

