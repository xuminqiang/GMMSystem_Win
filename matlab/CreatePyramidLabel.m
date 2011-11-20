function CreatePyramidLabel( poslistfn, nPiece )

%poslistfn = '/workspace/ifp-32-2/hasegawa/xizhou2/Trecvid/DenseSift/scp/feature.scp';
%nPiece = 4;


baklist = textread(poslistfn,'%s');
totalnum = length(baklist);


for i=1:totalnum
%    curpos = htkread(baklist{i},'b');
    curpos = readhtk(baklist{i});
    curpos = curpos(:,end-1:end);
    minpos = min(curpos);
    maxpos = max(curpos);
        
    totalPiece = 1 + sum([2:nPiece].^2);
    
    idxs = zeros(totalPiece,length(curpos));
    idxs(1,:) = 1;
    curp = 1;
    for np = 2:nPiece
        range = (maxpos-minpos) / np;
        for j=1:np^2
            [nx,ny] = ind2sub([np np],j);
            idxs(j+curp, find( curpos(:,1) >= (nx-1)*range(1) + minpos(1)   ...
                            & curpos(:,1) <= nx * range(1) + minpos(1) ...
                            & curpos(:,2) >= (ny-1)*range(2) + minpos(2) ...
                            & curpos(:,2) <= ny * range(2) + minpos(2) ) ) = 1;
        end
        curp = curp + np^2;
    end   
    writehtk([baklist{i} '.pyramid'], idxs, 0.02, 9);
end


