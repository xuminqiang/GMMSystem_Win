function COVA=GetScatterMatrix(MatListFile,curdir,MaxMatList)
MatList=textread(MatListFile,'%s');
%ONLY WORK ON 5000 random-selected MatFiles
%MaxMatList=5000;
MatListLength = length( MatList );
if( MaxMatList > 0 && MaxMatList < MatListLength )
    xx = rand(MatListLength,1);
    [mx,mi] = sort(xx);
    MatList = MatList(mi(1:MaxMatList));
end

%Get Data Dimensionality (must be consistent across all mat files)
load(MatList{1});
%[pathstr, varname, ext, versn] = fileparts(char(MatList(1)));
%varname=regexprep(varname,'\.','_'); %replacing all dots in filenameOnly
    if (~exist('DataF','var'))
        disp(['var DataF not exist']);
        return;
    end
Data=DataF;
%eval(['Data = ' varname ';']); %first dim is vec length, second #frames
DataDim=size(Data,1);

%Initialization
FrameCount=zeros(1,length(MatList));
SaveMean=zeros(DataDim,length(MatList));

%Process Each File
for ii=1:length(MatList)
    load(MatList{ii});
%    [pathstr, varname, ext, versn] = fileparts(char(MatList(ii)));
%    varname=regexprep(varname,'\.','_'); %replacing all dots in filenameOnly
    CurDataDim=size(DataF);
        if (~exist('DataF','var')||CurDataDim(1)~=DataDim||CurDataDim(2)<1)
            disp(['var DataF not exist or dim error' CurDataDim(1) '~=' DataDim 'or frame <1 as ' CurDataDim(2) ': for ' ii 'th mat file']);
            return;
        end
    Data = DataF;
    
	%find mean vector
	SaveMean(:,ii)=mean(Data,2);
    FrameCount(ii)=size(Data,2);


end

AllMean=sum(SaveMean.*(kron(ones(DataDim,1),FrameCount)),2)/sum(FrameCount);
COVA=zeros(DataDim,DataDim);

for ii=1:length(MatList)
    load(MatList{ii});
%    [pathstr, varname, ext, versn] = fileparts(char(MatList(ii)));
%    varname=regexprep(varname,'\.','_'); %replacing all dots in filenameOnly
    Data=DataF;

    COVA=COVA+(Data-kron(AllMean,ones(1,size(Data,2))))*(Data-kron(AllMean,ones(1,size(Data,2))))';
end
COVA=COVA/sum(FrameCount);

