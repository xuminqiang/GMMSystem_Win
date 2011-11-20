
%% in this script, 'speaker' also means 'language' :)

function [eigs_vecs,eigs_mags] = FindWCCN(supervec,labels,K_largest,output)

tic; % Start the Matlab timer

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Configuration Settings       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bPair= 0;
t = 0.5;

lst.num_seg = length( labels );    % Check how many unique utterances we will load
[dim nsample] = size(supervec);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Subtract out the speaker mean  %
% for each session of that speaker %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp( '** Session vectors normalised by their mean **' );

% Find the mean for each speaker label
models.spk_mean = zeros( dim, max(labels) );
for i = 1 : max(labels)
    ind = find( labels == i );
    if length(ind) > 0,
        models.spk_mean(:,i) = mean(supervec(:,ind),2);
        if bPair ~= 1,
            supervec(:,ind) = supervec(:,ind) - models.spk_mean(:,i)*ones(1,length(ind));
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Finding Eigenvectors       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp( '** Calculating eigenvectors **' );

if bPair == 1,
    LABEL = kron(double(labels'),ones(1,lst.num_seg));
    W = exp(-((LABEL-LABEL').^2/(t^2)));
    L = diag(sum(W)) - W;

    dsupervec = double(supervec);
    weight_supervec = dsupervec*L*dsupervec';
    weight_supervec = (weight_supervec + weight_supervec') / 2;
else
%    dsupervec = double(supervec);
    if dim <= nsample,
        weight_supervec = supervec*supervec';
    else
        weight_supervec = supervec'*supervec;
    end
    weight_supervec = double(weight_supervec);
%    clear dsupervec;
end

sum_mags = sum(diag(weight_supervec));

opts.tol = 1e-20;
[eigs_vecs, eigs_mags] = eigs( weight_supervec, K_largest, 'LR', opts );

if dim > nsample,
    eigs_vecs = supervec*eigs_vecs;
    for i=1:size(eigs_vecs,2)
        eigs_vecs( :, i ) = eigs_vecs( :, i ) ./ norm( eigs_vecs( :, i ) );
    end
end

%************??
%%eigs_mags = eigs_mags / sum_mags * size(eigs_vecs,1);
eigs_mags = diag( max(1, diag(eigs_mags) / sum_mags * size(eigs_vecs,1)) );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          Saving Result           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist('output','var')
    tmpfn = [output '_' num2str(i)];
    if bPair == 1,
        tmpfn = [tmpfn '_Pair_' num2str(t)];
    end

    % Save the eigenvectors used for the subspace removal
    fprintf('save %s\n', tmpfn);
    save(tmpfn, 'eigs_vecs', 'eigs_mags');
    disp('** Saved eigenvectors **');
end

% for i=start_dim:inter_dim:length(out_mags)
%     tmpfn = [output '_' num2str(i)];
%     if bPair == 1,
%         tmpfn = [tmpfn '_Pair_' num2str(t)];
%     end
% 
%     tmp_vecs = out_vecs(:,1:i);
%     tmp_mags = out_mags(1:i,1:i);
% 
%     fprintf( 'save %s\n', tmpfn );
% 
%     % Save the eigenvectors used for the subspace removal
%     save( [tmpfn '_vecs'], 'tmp_vecs', '-ascii', '-double' );
%     save( [tmpfn '_mags'], 'tmp_mags', '-ascii', '-double' );
% end
% 
% disp( '** Saved eigenvectors **' );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up large memory allocations %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear models;

toc    % Output how long this process took
