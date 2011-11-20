function [result result2 result3 result4] = Reg_Super_Score_traintest_multi(train_score,test_score,rootdir,nCur,bNN,ENum)

if ~exist('ENum','var')
    ENum = 30;
end

ttlabel = textread([rootdir '/traintest_label_' num2str(nCur)]);
classlabel = textread([rootdir '/class_label_' num2str(nCur)],'%d');

train_label = classlabel( find(ttlabel == 1) );
test_label = classlabel( find(ttlabel == 2) );

[uni_train_label,tt,trl] = unique(train_label);
[tf,loc] = ismember(test_label,uni_train_label);

%% Load in the training scoring file
score_mat = double(train_score);

[ma,mi] = max(score_mat);

if bNN == 1,
    acc_train = length( find( train_label(mi) == train_label ) ) / size( score_mat, 2 )
elseif bNN == 2,
    pae_train = (mi'-trl);
    mae_train = mean(abs((uni_train_label(mi'))-(uni_train_label(trl))))

    for i=1:size(score_mat,2)
        tm = mean(score_mat(:,i));
        ts = std(score_mat(:,i));
        score_mat(:,i) = (score_mat(:,i)-tm) / ts;
    end


    nscore = exp(ENum*score_mat);
    for i=1:size(score_mat,2)
        nscore(:,i) = nscore(:,i) ./ sum(nscore(:,i));
    end
    nscore(end+1,:) = 1;

    alpha1 = pinv(nscore*nscore' + 0.0*eye(size(nscore,1))) * nscore * (uni_train_label(trl));
    %save alpha1.mat alpha1;
    %plot(alpha1);

    Hyp = nscore' * alpha1;
    err_tr_reg = mean(abs((uni_train_label(trl)) - Hyp))
else
    acc_train = length( find( mi' == trl ) ) / size( score_mat, 2 )
end


%% Load in the test scoring file
score_mat = double(test_score);

[ma,mi] = max(score_mat);

if bNN == 1,
    acc_test = mean(train_label(mi)==test_label)
    acc_test_perclass = mean(accumarray(loc,train_label(mi)==test_label,[],@mean))
    result = acc_test;
    result2 = acc_test_perclass;
        
elseif bNN == 2,
    pae_test = (mi'-loc);
    mae_test = mean(abs((uni_train_label(mi'))-(test_label)))
    
    for i=1:size(score_mat,2)
        tm = mean(score_mat(:,i));
        ts = std(score_mat(:,i));
        score_mat(:,i) = (score_mat(:,i)-tm) / ts;
    end

    nscore = exp(ENum*score_mat);
    for i=1:size(score_mat,2)
        nscore(:,i) = nscore(:,i) ./ sum(nscore(:,i));
    end
    nscore(end+1,:) = 1;

    Hyp = nscore' * alpha1;
    %save(['Hyp',num2str(nCur)],'Hyp','test_label');
    err_reg = mean(abs((test_label)-Hyp))
    result = err_reg;
    result2 = mae_test;
else
    mi = mi';
    acc_test = mean(mi==loc)
    acc_test_perclass = mean(accumarray(loc,mi==loc,[],@mean))
    result = acc_test;
    result2 = acc_test_perclass;
end
