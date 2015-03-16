function [ images ] = ReadImagesFromFolder( folder, extensions )
%READIMAGESFROMFOLDER Summary
%   Reads Images from a folder and returns a matrix of image values

images = [];
exposures = [];

if nargin == 2
    filenames = get_rel_path_of_images(folder, extensions);
elseif nargin == 1
    filenames = get_rel_path_of_images(folder);
else
    error('Require 1 or 2 arguments!')
end

if isempty(filenames); return; end;

NOI = length(filenames); %Represents the number of images in the folder

%disp (exposures);
instanceFile = filenames{1};
image_info = imfinfo(instanceFile);
%disp(image_info.DigitalCamera.ExposureTime) %DigitalCamera has the field ExposureTime in
%it
images = zeros(image_info.Height, image_info.Width, image_info.NumberOfSamples, NOI); %NumberOfSamples 
%is the number of color channels

for i = 1:NOI
    filename = filenames{i};
	img = imread(filename);
	images(:,:,:,i) = img;
	image_i_info = imfinfo(filename);
end

end

