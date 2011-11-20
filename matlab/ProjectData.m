function ProjectData(PCAmatrixW,MatListFile,FeatListFile,curdir)

MatList=textread(MatListFile,'%s');
FeatList=textread(FeatListFile,'%s'); %those subdirectories involved must exist
load(MatList{1});
%[pathstr, varname, ext, versn] = fileparts(char(MatList(1)));
%varname=regexprep(varname,'\.','_'); %replacing all dots in filenameOnly
Data=DataF;
DataDim=size(Data,1);

for ii=1:length(MatList)
    load(MatList{ii});
%    [pathstr, varname, ext, versn] = fileparts(char(MatList(ii)));
%    varname=regexprep(varname,'\.','_'); %replacing all dots in filenameOnly
	Data=DataF;

    pcaData=PCAmatrixW'*Data;
    writehtk(FeatList{ii}, pcaData, 0.02, 9);
    clear DataF
end


