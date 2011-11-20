function PCAmat2feat(curdir,codedir,MatListFile,FeatListFile,reduceDim,bUseSavedPCAfeatMatrix,LogfileExt)

path(path,codedir);

MaxMatList=2000;

%bUseSavedPCAfeatMatrix=str2num(bUseSavedPCAFlag);
%###PCAfeat###
if bUseSavedPCAfeatMatrix==1
	disp('WARNING: PCAfeatmodel loaded from file PCAfeatmodel.mat !!! (see PCAmat2feat.pl)');
	load([curdir,'/PCAfeatmodel.mat'],'PCAfeatmodel');
else
%###PCAfeat###
	disp('CALCULATING PCAfeatmodel from MaxMatList random entries in MatListFile');
	COVA=GetScatterMatrix(MatListFile,curdir,MaxMatList);
	PCAfeatmodel=pca_cov(COVA,reduceDim);
	save([curdir,'/PCAfeatmodel.mat'],'PCAfeatmodel');
	disp('PCAfeatmodel saved in file PCAfeatmodel.mat saved in current dir');
end

PCAmatrixW=PCAfeatmodel.W;
ProjectData(PCAmatrixW,MatListFile,FeatListFile,curdir)

fid_LogfileExt=fopen(LogfileExt,'w');
fprintf(fid_LogfileExt,'%s\n',[LogfileExt,' done!']);
fclose(fid_LogfileExt);
