#!/usr/bin/perl

#Get arguments
if(scalar(@ARGV)<2 && scalar(@ARGV)>3)
{
    print "Usage:  createlist4xml.pl <xml_dir> <scp_file> [xml_ext]\n";
    exit(1);
}

use FindBin;
use lib "$FindBin::Bin/share"; 
use tytools;

$xmldir = $ARGV[0];
$scpfn= $ARGV[1];

print "$xmldir\n$scpfn\n";

$xml_ext = 'xml';
if( scalar(@ARGV) >= 3 )
{
	$xml_ext = $ARGV[2];
}

$nxmls = getFNsInrecursiveDir4Linux($xmldir, $xml_ext);
$len = @$nxmls;
print "There are totally $len images\n";

writeText($scpfn,join("\n",@$nxmls));

