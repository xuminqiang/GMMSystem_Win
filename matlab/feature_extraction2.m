function feature_extraction2(scp,nn,codedir,curdir,reduction,reduceDim,bPatchSift,bIncludeBlank,nOx,nOy,nPatchSize,LogfileExt,ROI_file)

path(path,[codedir,'/matlab']);

nPatchSize = str2num(nPatchSize);

if nargin == 12
    ROI_file = [];
end
    
if ~isempty(ROI_file)
    [ROI_imgnames ROI_x ROI_y ROI_w ROI_h] = textread(ROI_file,'%s %d %d %d %d','delimiter',':');
    ROI_rect = [ROI_x ROI_y ROI_w ROI_h];
end

flist = textread([scp '.' num2str(nn)],'%s');

fid_featlist=fopen([curdir,'/reallists/realfeatlist.',num2str(nn),'.scp'],'w');
fid_matlist=fopen([curdir,'/reallists/realmatlist.',num2str(nn),'.scp'],'w');


disp('processing each file');

for i=1:length(flist)/2
    disp(['========== ' flist{i*2-1}]);
    tmpimg = imread(flist{i*2-1});
    if size(tmpimg, 3) == 3,
        CurrIm = im2double(rgb2gray(tmpimg));
    else
        CurrIm = im2double(tmpimg);
    end
    
    if exist('ROI_imgnames','var')
        idx = find(strcmp(flist{i*2-1},ROI_imgnames));
        if ~isempty(idx)
            disp('ROI = ')
            disp(ROI_rect(idx(1),:))
            try
                CurrIm = imcrop(CurrIm, ROI_rect(idx(1),:));
            catch
                fprintf('Cropping ROI failed on image %s\n',flist{i*2-1});
            end
        end
    end
    
    switch(bPatchSift)
        case -1
            try
                size(CurrIm)
                CurrIm = histeq(CurrIm);
                CurrIm = imresize(CurrIm, [32 32]);
                DataF = patchDCT(CurrIm,nOx,nOy,nPatchSize);
            catch
                disp(['patchDCT fail on file ' flist{i*2-1} 'nOx' num2str(nOx) 'nOy' num2str(nOy) 'nPsize' num2str(nPatchSize)]);
            end
            
        case 0
            [image, descrips, locs] = sift(flist{i*2-1},nn,curdir);
            DataF = descrips'; %first dim is vec length, second #frames
            
        case 1
            try
                [DataF,Position] = patchsift(CurrIm,nOx,nOy,nPatchSize,bIncludeBlank);
            catch
                disp(['patchsift fail on file ' flist{i*2-1}])
            end
            
        case 2
            try
                [DataF,Position] = genDenseSift(CurrIm,nOx,nPatchSize);
                DataF = DataF';
                Position = Position';
            catch
                disp(['genDenseSift fail on file ' flist{i*2-1}])
            end
            
        case 9
            try
                DataF = color_moment_local(flist{i*2-1},nOx,nOy);
            catch
                disp(['color_moment_local fail on file ' flist{i*2-1}])
            end
            
        otherwise
            disp('Error Unknown bPatchSift value!');
            return;
    end
    
    if size(DataF,2) > 0
        if bPatchSift==1 || bPatchSift==2
            writehtk([flist{i*2} '.pos'], Position, 0.02, 9);
        end
        
        switch(reduction)
            case 0
                writehtk(flist{i*2}, DataF, 0.02, 9);
            case 1
                dctDataF = dct(DataF);
                writehtk(flist{i*2}, dctDataF(1:reduceDim,:), 0.02, 9);
            case 2
                [pathstr, varname, ext, versn] = fileparts(char(flist{i*2-1}));
                pathstr=regexprep((regexprep(regexprep(pathstr,':',''),'/','_')),'\','_');
                matfilename = [regexprep(regexprep(pathstr,filesep,'_'),'-','_') '_' varname '.mat'];
                matfilename(1) = 'M';
                save([curdir,'/feature_mat/' matfilename],'DataF');
                disp([curdir,'/feature_mat/' matfilename ' saved!']);
                fprintf(fid_matlist,'%s\n',[curdir,'/feature_mat/' matfilename]);
            otherwise
                disp(['reduction is set to ' reduction 'UNKNOWN!! Error Aborted']);
                return;
        end
        fprintf(fid_featlist,'%s\n',flist{i*2});
        
    else
        disp(['skipping ' flist{i*2-1}]);
    end
    
end

fclose(fid_featlist);
fclose(fid_matlist);

fid_LogfileExt=fopen(LogfileExt,'w');
fprintf(fid_LogfileExt,'%s\n',[LogfileExt,' done!']);
fclose(fid_LogfileExt);
