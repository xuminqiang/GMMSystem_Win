function [fullsiftArr fullposition] = genDenseSift(I, gridSpacing, patchSizes)

% %% example input
% I = '/cworkspace/ifp-32-2/hasegawa/zhenli3/database/VOC2007/trainval/JPEGImages/003154.jpg';
% I = imread(I);
% gridSpacing = 4;
% patchSizes = [16 24 32];

%% parameters

if ~exist('gridSpacing','var')
    gridSpacing = 8;
end

if ~exist('patchSizes','var')
    patchSizes = 16;
end

minPatchNum = 500;
maxPatchNum = 10000;

%% Preprocessing

if ndims(I) == 3
    I = im2double(rgb2gray(I));
else
    I = im2double(I);
end

%I = imresize(I,[250 300]);

[hgt wid] = size(I);

fullsiftArr = [];
fullposition = [];
for i=1:length(patchSizes)
    patchSize = patchSizes(i);

    npatches = floor((wid-patchSize)/gridSpacing+1) * floor((hgt-patchSize)/gridSpacing+1);

    if npatches > maxPatchNum
        I = imresize(I, sqrt(maxPatchNum/npatches), 'bicubic');
        fprintf('original size %d x %d, resizing to %d x %d\n', ...
            wid, hgt, size(I,2), size(I,1));
        [hgt wid] = size(I);
    end

    if npatches < minPatchNum
        I = imresize(I, sqrt(minPatchNum/npatches), 'bicubic');
        fprintf('original size %d x %d, resizing to %d x %d\n', ...
            wid, hgt, size(I,2), size(I,1));
        [hgt wid] = size(I);
    end

    %% make grid (coordinates of upper left patch corners)
    remX = mod(wid-patchSize,gridSpacing);
    offsetX = floor(remX/2)+1;
    remY = mod(hgt-patchSize,gridSpacing);
    offsetY = floor(remY/2)+1;

    [gridX,gridY] = meshgrid(offsetX:gridSpacing:wid-patchSize+1, offsetY:gridSpacing:hgt-patchSize+1);

    fprintf('wid %d, hgt %d, grid size: %d x %d, %d patches\n', ...
        wid, hgt, size(gridX,2), size(gridX,1), numel(gridX));

    %% find SIFT descriptors
    siftArr = sp_find_sift_grid(I, gridX, gridY, patchSize, 0.8);
    siftArr = sp_normalize_sift(siftArr);

    position = [gridX(:), gridY(:)] + floor(patchSize/2);
    
    fullsiftArr = [fullsiftArr; siftArr];
    fullposition = [fullposition; position];
end
