
function [train_score,test_score] = Process_LT_multilabel(ttlabel,classlabel,AllImgs,wccn_dim,cur_random,bNN)

% consider the situation that each sample may belonging to multiple
% categories

if isa( AllImgs, 'char' )
    load('-mat',AllImgs,'AllImgs');
%     load('-mat',AllImgs,'AllVars');
%     AllImgs = AllVars;
%    load('-mat',AllImgs,'AllImgs','AllVars');
%    AllImgs = [AllImgs;AllVars];
%    clear AllVars;
end
AllImgs = single(AllImgs);

% ttlabel = textread(traintest_label);
% 
% nclass = length(class_labels);
% for i=1:length(class_labels)
%     [tmp classlabel(i,:)] = textread(class_labels{i},'%s%d');
% end

if ~exist('bNN','var')
    bNN = 0;  % NC
end

classlabel(classlabel~=1) = 0;
nclass = size(classlabel,1);

train_label = classlabel(:,ttlabel==1);
test_label = classlabel(:,ttlabel==2);

train_imgs = AllImgs(:,ttlabel==1);
test_imgs = AllImgs(:,ttlabel==2);
clear AllImgs;

mdls = zeros(size(train_imgs,1),nclass,'single');

disp( 'map adapt models' );
tic;

for i = 1:nclass
    ind = (train_label(i,:) == 1);
    if any(ind)
        mdls(:,i) = mean(train_imgs(:,ind),2);
    end
end

train_score = -L2_distance(mdls,train_imgs);
test_score = -L2_distance(mdls,test_imgs);
toc;

if wccn_dim>0
    
    bSoft = 1;
    
    [proj_eigs_vecs,eigs_mags] = FindWCCN_multilabel(train_imgs,train_label,wccn_dim);
    
    ptrain = proj_eigs_vecs' * train_imgs;
    ptest = proj_eigs_vecs' * test_imgs;
    if bNN~=1
        pmdls = proj_eigs_vecs' * mdls;
    end
    
    if bSoft == 1,
        eigs_weights = diag(eigs_mags);
        eigs_weights = (eigs_weights-1) ./ eigs_weights;
        weights_mat = diag(eigs_weights);
        
        if bNN~=1
            train_wccnscore = -sqrt((-train_score).^2 - L2_distance_soft(pmdls,ptrain,eigs_weights.^(1/2)) .^ 2);
            test_wccnscore = -sqrt((-test_score) .^ 2 - L2_distance_soft(pmdls,ptest,eigs_weights.^(1/2)) .^ 2);
        else
            train_wccnscore = -sqrt((-train_score).^2 - L2_distance_soft(ptrain,ptrain,eigs_weights.^(1/2)) .^ 2);
            test_wccnscore = -sqrt((-test_score) .^ 2 - L2_distance_soft(ptrain,ptest,eigs_weights.^(1/2)) .^ 2);
        end
    else
        if bNN~=1
            train_wccnscore = -sqrt((-train_score).^2 - L2_distance(pmdls,ptrain) .^ 2);
            test_wccnscore = -sqrt((-test_score) .^ 2 - L2_distance(pmdls,ptest) .^ 2);
        else
            train_wccnscore = -sqrt((-train_score).^2 - L2_distance(ptrain,ptrain) .^ 2);
            test_wccnscore = -sqrt((-test_score) .^ 2 - L2_distance(ptrain,ptest) .^ 2);
        end
    end
    
    % Note: rewrite train_score and test_score for saving
    train_score = train_wccnscore;
    test_score = test_wccnscore;
end

