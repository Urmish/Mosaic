function [ relpaths ] = get_rel_path_of_images( folder, extension )
%GET_REL_PATH_OF_IMAGES Summary of this function goes here
%   Get relative path of images in a folder
%   If extension is not specified, tries to look for common image
%   extensions.
%   Example: If folder is '../exposures' and extension is 'jpg',
%   returns {'../exposures/001.jpg', '../exposures/002.jpg', etc}

switch nargin
    case 2
        % Get filenames (without folder)
        glob = fullfile(folder, ['*.' extension]);
        filenames = dir(glob);
    case 1
        
        % Try several common extensions
        extensions = {'jpg', 'jpeg'};
        filenames = [];
        for ei = 1 : numel(extensions)
            extension = extensions{ei};
            filenames = [filenames; ...
                dir(fullfile(folder, ['*.' extension])); ...
                dir(fullfile(folder, ['*.' upper(extension)])) ...
                ];
        end
    otherwise
        error('Require 1 or 2 arguments!')
end

% Add folder to filenames
relpaths = cell(numel(filenames, 1));
for i = 1 : numel(filenames)
    relpaths{i} = fullfile(folder, filenames(i).name);
end

end

