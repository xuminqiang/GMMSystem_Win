function model=loadgmmset(fname,mtype)

%fname = '/cworkspace/ifp-32-2/hasegawa/xizhou2/Trecvid/DenseSift/mdl/ubm_bin';
%mtype = 'l';

fid = fopen(fname,'rb');
if fid < 0,
    error( sprintf('Unable to read from file %s', fname) );
end

nSamp = fread(fid,1,'int32',mtype);
sampPeriod = fread(fid,1,'int32',mtype);
sampSize = fread(fid,1,'int16',mtype);
HTKCode = fread(fid,1,'int16',mtype);
%ss = fread(fid,1,'int16',mtype);

ncomp = nSamp;
dim = sampSize;
bInvCovar = HTKCode;

model.Mean = zeros(ncomp,dim);
model.Cov = zeros(ncomp,dim);
model.Prior = zeros(ncomp,1);

%read data
model.Prior = fread( fid, [ncomp 1], 'double', mtype );
model.Mean = fread( fid, [dim ncomp], 'double', mtype );
model.Cov = fread( fid, [dim ncomp], 'double', mtype );
model.bInvCovar = bInvCovar;

fclose( fid );

