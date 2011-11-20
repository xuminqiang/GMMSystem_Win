function [score_mat] = SVM_multilabel(Xtr, Xte, train_label, lambda, gamma)

addpath('F:\code\gmmsystem_win\matlab\large_scale_2nsvm');

if nargin < 5
    gamma = [];
end

train_label(train_label~=1) = -1;

nclass = size(train_label,1);
for i=1:nclass
    [w, b] = li2nsvm_lbfgs(Xtr, train_label(i,:)', lambda,gamma);
    [C Y] = li2nsvm_fwd(Xte, w, b);
    score_mat(i,:) = Y;
end

score_mat;
