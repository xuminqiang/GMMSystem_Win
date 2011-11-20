
%% in this script, 'speaker' also means 'language' :)

function RandomSelectScp(InputScp,Max_items,OutputScp)

% Load in the list file
flist = textread( InputScp, '%s' );

% Only collect statistics on the first 'Max_items' items
lst.num_seg = length( flist );
if( Max_items > 0 && Max_items < lst.num_seg )
    xx = rand(lst.num_seg,1);
    [mx,mi] = sort(xx);
    flist = flist(mi(1:Max_items));
end

fid = fopen(OutputScp,'w');
for i=1:length(flist)
    fprintf(fid,'%s\n',flist{i});
end
fclose(fid);
