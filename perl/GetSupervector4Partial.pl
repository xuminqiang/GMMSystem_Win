#!/usr/bin/perl
use strict;

#mySys("perl $code_dir/perl/getsupervec4partial.pl ${ubmfn}_bin $gmmfea_scp $output_vecs $pcaflag ${rootdir}/nap/PCA_${ubmfile}_${pca_dim} $max_items4pca $i $supervectype $code_dir $current_dir");

my $ubmfn			= $ARGV[0];
my $gmmfea_scp		= $ARGV[1];
my $output_mat		= $ARGV[2];
my $pcaflag			= $ARGV[3];
my $pcafile			= $ARGV[4];
my $num4pca			= $ARGV[5];
my $nn				= $ARGV[6];
my $supervectype	= $ARGV[7];
my $code_dir		= $ARGV[8];
my $current_dir		= $ARGV[9];

my $Logfile			= "$current_dir\\matlab.GetSupervector4Partial.$nn.out";
my $LogfileExt		= "$current_dir\\matlab.GetSupervector4Partial.$nn.out.ext";

open(FILE,">GetSupervector4Partial_${nn}_run.m") || die @_;

print FILE "path(path,\'$code_dir\\matlab\');\n\n";

print FILE "if str2num(\'$supervectype\')==1,\n";
print FILE "GetSuperVector4ClusterPartial(\'$ubmfn\',\'$gmmfea_scp\',\'$output_mat\',$pcaflag,\'$pcafile\',$num4pca,$nn);\n";
print FILE "else\n";
print FILE "GetSuperVector4WeightPartial2(\'$ubmfn\',\'$gmmfea_scp\',\'$output_mat\',$nn);\n";
print FILE "end";

print FILE "\n\nfid_LogfileExt=fopen(\'$LogfileExt\',\'w\');\n";
print FILE "fprintf(fid_LogfileExt,\'%s\\n\',[\'$LogfileExt\',\' done!\']);\n";
print FILE "fclose(fid_LogfileExt)\n";
print FILE "exit";

system("matlab -nosplash -nodesktop -r GetSupervector4Partial_${nn}_run -logfile $Logfile");

