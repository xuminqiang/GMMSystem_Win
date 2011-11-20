#!/usr/bin/perl

#Get feature scp file
if( scalar(@ARGV) < 3 && scalar(@ARGV) >5 )
{
    print "Usage:  createlist4sift.pl <img_dir> <feature_dir> <scp_file> [img_ext] [fea_ext]\n";
    exit(1);
}

#use lib '/workspace/tico0/AED/code/perlmodules/';
use FindBin;
use lib "$FindBin::Bin/share"; 
use tytools;

$srcdir = $ARGV[0];
$desdir = $ARGV[1];
$scpfn= $ARGV[2];

print "$srcdir\n$desdir\n$scpfn\n";

$img_ext = 'jpg';
if( scalar(@ARGV) >= 4 )
{
	$img_ext = $ARGV[3];
}

$fea_ext = 'sift';
if( scalar(@ARGV) >= 5 )
{
	$fea_ext = $ARGV[4];
}

print "Image folder is $srcdir, Image ext is $img_ext\n";
$pimgs = getFNsInrecursiveDir4Linux( $srcdir, $img_ext);

$len = @$pimgs;
print "There are totally $len images\n";

$output = ();
foreach $curfile (@$pimgs)
{
  $srcfn = $curfile;
  
  #$curline = str_replace($desdir,$srcdir,$curfile);
  my($idx,$pos,$pre) = {-1,0,-1};
  while(1){
	$idx = index( $curfile, $srcdir, $pos );
	substr $curfile, $idx, length($srcdir), $desdir ;
	if($idx == $pre){
		last;
	}else{
		$idx = $idx+length($srcdir)-1;
		$pre = $idx;
		$pos = $idx;
		}
	}
	
  $desfn = replaceExtension($curfile,$fea_ext);
  $despath = getFilePath($desfn);
  recursiveMakeDirectory4Linux($despath);
  
  push @output, "$srcfn $desfn";
}

writeText($scpfn,join("\n",@output));

