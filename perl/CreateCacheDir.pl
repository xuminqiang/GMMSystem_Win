#!/usr/bin/perl

#Create directories for cache files

if( scalar(@ARGV) != 3 )
{
    print "Usage:  CreateCacheDir.pl <basescp> <srcdir> <des_dir>\n";
    exit(1);
}

use FindBin;
use lib "$FindBin::Bin/share"; 

use tytools;

$basescp = $ARGV[0];
$srcdir = $ARGV[1];
$desdir = $ARGV[2];

$parr = readFile( $basescp );

foreach $curline (@$parr )
{
#	print "\n$curline\n";
    $ind = index($curline,$srcdir);

    if( $ind == 0 )
    {
	$curline = str_replace( $srcdir, $desdir, $curline);

#	$curline =~ s/$srcdir/$desdir/;

	$curpath = getFilePath($curline);
#	print "$curline\n$curpath\n";
	recursiveMakeDirectory4Linux( $curpath );
    }
    else
    {
	die "$curline is not in the srcdir,\"$srcdir\"";
    }
}
