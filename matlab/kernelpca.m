function [evecs,evals]=kernelpca(K,dim)

K = (K+K') / 2;
%[evecs, evals] = eigs(double(K+1.0e-10*eye(length(K))),dim,'LM');
[evecs, evals] = eig(double(K+1.0e-10*eye(length(K))));

evals = real(diag(evals));  %eig decomposition

rank = sum(evals>1e-10);
if rank >= dim
    evals = evals(end-dim+1:end);
    evecs = evecs(:,end-dim+1:end);
else
    disp('warning: rank of kernel matrix is less than required dim!!!');
    disp('dim is set to rank of the matrix.');
    evals = evals(end-rank+1:end);
    evecs = evecs(:,end-rank+1:end);
end
evecs=evecs./repmat(sqrt(evals)',size(evecs,1),1);  %normalize
