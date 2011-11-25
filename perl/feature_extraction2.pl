#!/usr/bin/perl

$scp             = $ARGV[0];
$nn              = $ARGV[1];
$codedir         = $ARGV[2];
$curdir          = $ARGV[3];
$reduction       = $ARGV[4];
$reduceDim       = $ARGV[5];
$bPatchSift      = $ARGV[6];
$bIncludeBlank   = $ARGV[7];
$nOx             = $ARGV[8];
$nOy             = $ARGV[9];
$nPatchSize      = $ARGV[10];
$ROI_file        = $ARGV[11];
$Logfile = "$curdir/matlab.feature_extraction.$nn.out";
$LogfileExt = "$curdir/matlab.feature_extraction.$nn.out.ext";

$nPatchSize =~ s/_/ /;

open(FILE, ">feature_extraction2_${nn}_run.m") || die @_;
print FILE "path(path,\'$codedir\\matlab\')\n";
if(-e "$ROI_file"){ 
print FILE "feature_extraction_ROI(\'$scp\',$nn,\'$codedir\',\'$curdir\',$reduction,$reduceDim,$bPatchSift,$bIncludeBlank,$nOx,$nOy,\'$nPatchSize\',\'$LogfileExt\',\'$ROI_file\')\n";
}else
{
print FILE "feature_extraction2(\'$scp\',$nn,\'$codedir\',\'$curdir\',$reduction,$reduceDim,$bPatchSift,$bIncludeBlank,$nOx,$nOy,\'$nPatchSize\',\'$LogfileExt\')\n";
}
print FILE "exit\n";
close(FILE);


system("matlab -nosplash -nodesktop -r feature_extraction2_${nn}_run -logfile $Logfile");
