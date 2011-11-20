function GetSuperVector4ClusterPartial(ubmfn, gmmlistfn, outputmat, pcaflag, pcafile, num4pca,curpartial)

%%
%pcaflag > 0, estimate pca matrix inside and save it in pcafile
%pcaflag = 0, load pca matrix from pcafile
%pcaflag < 0, without pca

% ubmfn = '/cworkspace/ifp-32-2/hasegawa/xizhou2/Trecvid/DenseSift/mdl/hmm_all_refined_1_512_bin';
% gmmlistfn = '/cworkspace/ifp-32-2/hasegawa/xizhou2/Trecvid/DenseSift/tmp/gmmfea_partial.lst';
% outputmat = '/cworkspace/ifp-32-2/hasegawa/xizhou2/Trecvid/DenseSift/class/partial';
% pcaflag = 1000;
% pcafile = '/cworkspace/ifp-32-2/hasegawa/xizhou2/Trecvid/DenseSift/nap/partialpca_pyramid';
% num4pca = 1200;
% partiallist = [0];
% nargin = 7;

if nargin<3
    error('GetSuperVect:TooFewInputs');
end
if nargin<4
    pcaflag = -1;
end
if nargin < 5 && pcaflag == -1,
    error('GetSuperVect:PCA file is needed');
end
if nargin < 6,
    num4pca = 2000;
end
if num4pca < pcaflag,
    error( 'the dim of pca cannot beyond the number of images used for pca' );
end

tic;

global gPrior;

U = loadbingmmset( ubmfn, 'l' );
U.num_cpts = size( U.Mean, 2 );
U.num_fea  = size( U.Mean, 1 );
U.feaXcpts = U.num_fea * U.num_cpts;   % Number of features by the number of Gaussian cpts
gPrior = U.Prior.^(1/2);

srcdim = U.feaXcpts;

if U.bInvCovar == 1,
    U.Cov(U.Cov>1e+6)=1e+6;
    U.inv_std_dev = (U.Cov).^0.5;
else
    U.Cov(U.Cov<1e-6)=1e-6;
    U.inv_std_dev = (U.Cov).^(-0.5);
end
gmmlist = textread(gmmlistfn,'%s');

% pcaflag > 0 means PCA projection
supervec = [];
PVec = [];
if pcaflag > 0
    if num4pca < length( gmmlist ),
        ridx = randperm( length( gmmlist ) );

        supervec = zeros( num4pca, srcdim, 'single' );  
        AllPrior = zeros( num4pca, srcdim, 'single' );

        for i=1:num4pca
            [supervec(i,:) AllPrior(i,:)] = ...
                NormlizedSuperVec( U, [gmmlist{ ridx(i) } '.' num2str(curpartial) ] );
        end
    else
        supervec = zeros( length(gmmlist), srcdim, 'single' );  
        AllPrior = zeros( length(gmmlist), srcdim, 'single' );
        for i=1:length(gmmlist)
            [supervec(i,:)  AllPrior(i,:)] = ...
                NormlizedSuperVec( U, [gmmlist{i} '.' num2str( curpartial ) ] );
        end
    end
  
    [PVec, S, m] = pca2( supervec, pcaflag );
    save( [pcafile '.' num2str( curpartial )], 'PVec' );
    
elseif pcaflag == 0,
    load( [pcafile '.' num2str( curpartial )] );
end

toc;

disp('begin supervec calculation');
if pcaflag >= 0,
    % PCA doesn't use all the data, reload all the data
    AllImgs = [];
    AllPrior= [];
    if size(supervec,1) ~= length(gmmlist),
        blocknum = ceil(length(gmmlist) / 200);

        for i=1:blocknum
            tmpsuper = zeros( min( 200, length(gmmlist) - (i-1)*200 ), srcdim, 'single' );
            tmpprior = zeros( min( 200, length(gmmlist) - (i-1)*200 ), srcdim, 'single' );
            
            for j=(i-1)*200+1:min(i*200,length(gmmlist))
                [tmpsuper(mod(j-1,200)+1,:) tmpprior(mod(j-1,200)+1,:)] = ...
                    NormlizedSuperVec( U, [gmmlist{j} '.' num2str(curpartial)]);
            end
            
            AllImgs = [AllImgs (tmpsuper * PVec)'];
            AllPrior = [AllPrior (tmpprior * PVec)'];
        end
    else
        AllImgs = (supervec * PVec)';
        AllPrior = (AllPrior * PVec)';
    end
else
    AllImgs = zeros( srcdim, length(gmmlist), 'single' );
    AllPrior = zeros( srcdim, length(gmmlist), 'single' );
    AllVars = zeros( srcdim, length(gmmlist), 'single');
    for i=1:length(gmmlist)
        [AllPrior(:,i) AllImgs(:,i) AllVars(:,i)] = NormlizedSuperVec( U, [gmmlist{i} '.' num2str(curpartial)]);
    end
end

save( [outputmat '.' num2str( curpartial )], 'AllPrior','AllImgs', 'AllVars', '-mat' );
toc;


function [vecprior,vec,vecvar] = NormlizedSuperVec( U, mdlfn )
global gPrior;

readorder = 'l';
tmpmodel = loadbingmmset( mdlfn, readorder );
tmpmodel.norm_mean_dif = (tmpmodel.Mean - U.Mean) .* U.inv_std_dev;
if tmpmodel.bInvCovar == 1,
    tmpmodel.inv_cov = (tmpmodel.Cov);
else
    tmpmodel.inv_cov= 1/(tmpmodel.Cov);
end
tmpmodel.norm_cov = U.inv_std_dev.*U.inv_std_dev./(tmpmodel.inv_cov)-1;
tmpprior = tmpmodel.Prior .^ (1/2);
lprior = (tmpprior * ones(1, U.num_fea))';
tmpmodel.result        = tmpmodel.norm_mean_dif .* lprior;%(gPrior * ones(1, U.num_fea))';
tmpmodel.result_var = tmpmodel.norm_cov.*lprior*sqrt(0.5);
vec = tmpmodel.result(:);
vecprior = lprior(:);
vecvar = tmpmodel.result_var(:);



