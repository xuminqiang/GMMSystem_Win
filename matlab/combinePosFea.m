function combinePosFea( featurelist, coef )

%% sample input
% featurelist = 'd:\work\scene15/scp/feature_sift.scp';
% coef = 0.1;

if ~exist('coef','var')
    coef = 1;
end

%% main routing
feafns = textread(featurelist,'%s');

for i=1:length(feafns)
    sift = readhtk(feafns{i});
    
    pos = readhtk([feafns{i} '.pos']);
    coor = [sift pos*coef];
    writehtk([feafns{i} '.co'],coor',0.02,9);%
end

