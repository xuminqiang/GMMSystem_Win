#!/usr/bin/perl

#Get feature scp file
if( scalar(@ARGV) < 2 && scalar(@ARGV) >3 )
{
    print "Usage:  createlist4sift.pl <feature_dir> <scp_file> [fea_ext]\n";
    exit(1);
}

#use lib '/workspace/tico0/AED/code/perlmodules/';
use FindBin;
use lib "$FindBin::Bin/share"; 
use tytools;

$srcdir = $ARGV[0];
$scpfn= $ARGV[1];

print "$srcdir\n$scpfn\n";

$img_ext = 'sift';
if( scalar(@ARGV) >= 3 )
{
	$img_ext = $ARGV[2];
}

print "Image folder is $srcdir, Image ext is $img_ext\n";
$pimgs = getFNsInrecursiveDir4Linux( $srcdir, $img_ext);

$len = @$pimgs;
print "There are totally $len images\n";

$output = ();
foreach $curfile (@$pimgs)
{
  $srcfn = $curfile;
  push @output, "$srcfn";
}

writeText($scpfn,join("\n",@output));

