function GetSuperVector4WeightPartial2(ubmfn, gmmlistfn, outputmat, curpartial)

if nargin<4
    error('GetSuperVect:TooFewInputs');
end

tic;

U = loadbingmmset( ubmfn, 'l' );
U.num_cpts = size( U.Mean, 2 );
srcdim = U.num_cpts;

gmmlist = textread(gmmlistfn,'%s');

AllImgs = zeros( srcdim, length(gmmlist), 'single' );
for i=1:length(gmmlist)
    tmpmodel = loadbingmmset( [gmmlist{i} '.' num2str(curpartial)], 'l' );
    AllImgs(:,i) = tmpmodel.Prior;
end

save( [outputmat '.' num2str( curpartial )], 'AllImgs', '-mat' );

toc;

