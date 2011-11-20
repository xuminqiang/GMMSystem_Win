function [train_score,test_score] = Process_LT(rootdir,AllImgs,wccn_dim,cur_random,bNN,max4wccn)

if isa( AllImgs, 'char' )
    load('-mat',AllImgs,'AllImgs');
    %load('-mat',AllImgs);
    %AllImgs = [AllImgs;AllVars];
    %AllImgs = AllVars;
end
if ~isa( AllImgs, 'single' )
    AllImgs = single(AllImgs);
end

if ~exist('cur_random','var')
    ttlabel = textread([rootdir '/traintest_label']);
    classlabel = textread([rootdir '/class_label'],'%d');
else
    ttlabel = textread([rootdir '/traintest_label_' num2str(cur_random)]);
    classlabel = textread([rootdir '/class_label_' num2str(cur_random)],'%d');
end

if ~exist('bNN','var')
    bNN = 0;  % NC
end

if ~exist('max4wccn','var')
    max4wccn = inf;
end

% train_label = classlabel(ttlabel==1);
% test_label = classlabel(ttlabel==2);
% 
% train_imgs = AllImgs(:,ttlabel==1);
% test_imgs = AllImgs(:,ttlabel==2);

train_label = classlabel(ttlabel==1);
test_label = classlabel(ttlabel==2);

train_imgs = AllImgs(:,ttlabel==1);
test_imgs = AllImgs(:,ttlabel==2);

wccn_label= classlabel(ttlabel==0);
wccn_imgs = AllImgs(:,ttlabel==0);

clear AllImgs

[uni_train_label,tt,tl] = unique(train_label);

mdls = zeros(size(train_imgs,1),length(uni_train_label),'single');

disp( 'map adapt models' );
tic;

if bNN ~= 1
    if bNN == 2  % regression
        label_offset = 1;
        for i = 1:length(uni_train_label)
            curlabel = uni_train_label(i);
            ind = (train_label <= curlabel+label_offset) & (train_label >= curlabel-label_offset);
            if any(ind)
                mdls(:,i) = mean(train_imgs(:,ind),2);
            end
        end
        
    else  % NC
        for i = 1:length(uni_train_label)
            ind = (train_label == uni_train_label(i));
            if any(ind)
                mdls(:,i) = mean(train_imgs(:,ind),2);
            end
        end
    end
    
    train_score = -L2_distance(mdls,train_imgs);
    test_score = -L2_distance(mdls,test_imgs);
    
else   % NN
   
    train_score = -L2_distance(train_imgs,train_imgs);
    test_score = -L2_distance(train_imgs,test_imgs);
end
toc;

if wccn_dim>0
    
    bSoft = 1;
    
    [uni_wccn_label,wccn_tt,wccn_tl] = unique(wccn_label);
    
    if size(train_imgs,2) > max4wccn && max4wccn > 0
        idx = crossvalind('HoldOut', wccn_tl, 1-max4wccn/size(wccn_imgs,2));
        [proj_eigs_vecs,eigs_mags] = FindWCCN(wccn_imgs(:,idx),wccn_tl(idx),wccn_dim);
    else
        [proj_eigs_vecs,eigs_mags] = FindWCCN(wccn_imgs,wccn_tl,wccn_dim);
    end
%     if size(train_imgs,2) > max4wccn && max4wccn > 0
%         idx = crossvalind('HoldOut', tl, 1-max4wccn/size(train_imgs,2));
%         [proj_eigs_vecs,eigs_mags] = FindWCCN(train_imgs(:,idx),tl(idx),wccn_dim);
%     else
%         [proj_eigs_vecs,eigs_mags] = FindWCCN(train_imgs,tl,wccn_dim);
%     end
    
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
    
    %save demos.mat mdls pmdls proj_eigs_vecs eigs_weights uni_train_label
end

