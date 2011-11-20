package tytools;
use FindBin;
use lib "$FindBin::Bin";
use File::Basename;
use File::Path;
use strict;
use warnings;
use warnings::register;
our $VERSION = '0.1';
require Exporter;
require Cwd;

our @ISA = qw(Exporter);
our @EXPORT = (

#file I/O processing
	'appendLog',		#($filepath,$str) append one string to the end of a text file
	'clearLog',			#($filepath)      clear the content of a file
	'writeLog',			#($filepath,$str) write one string to a text file
	'writeText',		#($filepath,$str) write one string to a text file
	'readConfig',		#($filename)      read a configre file, return a hash
	'readFile',			#($filename)      read a file, return a array
	'readFileAsHashKey',	#($filename)      read a file, return a hash, each line is the key of the hash
	'saveArray',		#($filepath,$array) save the array to a file, $array is the array pointer

#dir I/O processing
	'recursiveMakeDirectory4Linux', #($dirname)  build a directory recursively for Linux
	'recursiveMakeDirectory',	#($dirname)  build a directory recursively for Windows
    'recursiveMakeDirectory4List', #(@files) build directories for a list of files
	'getFilenamesInDir',	#($path,$ext) return the filename list with ext in the directory
	'getFNsInrecursiveDir',  #($path,$ext) return the filename list with ext in the recursive directory
	'getFNsInrecursiveDir4Linux', 
    'createList4FeatureExtraction', #($srcpath,$despath,$srcext,$desext,[$scp_file]) return the list for feature extraction
	
#path processing
	'unixPath',			#($path) 		  return unix style path /
	'dosPath',			#($path) 		  return dos style path \
	'fileNameforPerl',  #($filepath)      replace \ with \\
	'getFileNameExt', 	#($pathname)      remove path from full name
	'getExtOnly', 			#($pathname)      return the ext of a file
	'str_replace',   # (string search, string replace, string subject)
	'getFileNameOnly',	#($filepath)      return the filename (no ext) of a file
	'getFilePath',		#($filepath) 	  return the path of a file
	'getReleativePath', #($path,$rootpath) remove the relative path from the $path
	'replaceExtension', #($filename, $newext)  repalce the extension of file

#string processing
	'trim',				#($str)           remove leading and tailing blank of a string

#array processing
	'ifArrayMember',    #($var,$parr)      If $varin a member in @arr
	'getArrayIndex',    #($var,$parr)      Get the index of $varin in @arr, return -1 if not exists 
	'ifArrayMemberPart',#($var,$parr)      If $varin part of a member in @arr
	'grepIndex',        #($var,@arr)    Get the indexes of $var in @arr
	'lcArray',					#($arr)      	  lower case the array
	'removeDuplicate',  #(@arr)           remove duplicate items of arr
	'array2Hash',				#($arr)					return a hash, each member is the key of the hash
	'hash2Array',       #($phash)       return a array
	'randIndex',        #($var1,$var2)  return a array of $var1 random and non-repeating numbers, range from 1 to $var2

#math processing
	'max',				#($v1,$v2,....)        return max of listed variables
	'min',				#($v1,$v2,....)        return min of listed variables
	'sum',				#($v1,$v2,....)        return sum of listed variables
	'percentage',		#($n,$sum)        return $n/$sum and handle case for $sum==0

#system processing
	'mySys',			#($cmd)           print and execute the command line
	'processCommandLine', #(%ProcessingArgs) hash of configure name and value pointer

#q processing
	'disableQ',			#() diable q
	'enableQ',			#() enable q
	'qWait',			#($jobidorlabel, @options) wait q jobs
	'qSys',				#($cmd, @options) submit q jobs
#HTK relevant
	'ReadHCopyCfg',			#($filename, %parahash)
#word2snor
	       'word2snor', #($word)

);

sub ReadHCopyCfg
{
	my $filename=$_[0];
	my $parahash=$_[1];
	my $parafile=readFile($filename);
	foreach my $line(@$parafile){
		my $key=$line;$key=~s/^\s*(\S+)\s*\=\s*(\S+)\s*\n?$/$1/;
		my $val=$line;$val=~s/^\s*(\S+)\s*\=\s*(\S+)\s*\n?$/$2/;
		${$parahash}{$key}=$val;
		}

}
our @EXPORT_OK   = (
'$QENABLE',		#disable/enable q
'$SHAREPERL',	#perl path on msrcnsh
);

our $QENABLE = 1;
our $SHAREPERL="\\\\msrcnsh\\GROUPWIDE\\Tools\\Perl5.8v2\\bin\\perl.exe";

sub appendLog
{
	my ($filepath,$msg)=@_;
	open FP, ">>$filepath";
	print FP $msg;
	close FP;
}

sub clearLog
{
	my ($filepath)=@_;
	open FP, ">$filepath";
	close FP;
}

sub disableQ
{
	$QENABLE = 0;
}

sub dosPath
{
	my ($path)=@_;
	$path =~ s/\//\\/g;
	return $path;
}

sub enableQ
{
	$QENABLE = 1;
}

sub fileNameforPerl
{
	my ($filename) = @_;
	$filename =~ s/\\/\\\\/g;
	return($filename);
}


#
#    Function:
#    str_replace ( string search, string replace, string subject [, int count] )
#
#    Description:
#    This function returns a string or an array with all occurrences of
#    $search in $subject replaced with the given $replace value. If you
#    don't need fancy replacing rules (like regular expressions), you
#    should always use this function instead. Ported to Perl from PHP.
#
#    @PARAM $search String that you want to replace.
#    @PARAM $replace Replacement string.
#    @PARAM $subject The string that we are operating on.
#    @PARAM $count (optional) Limit the number of instances to replace.
#
#    Return values:
#    This function returns a string. Additionally, it returns -1
#    in case you forgot to provide the three basic parameters.
#
sub str_replace
{
  my $search = shift;							# what to find
  my $replace = shift;							# what to replace it with
  my $subject = shift;							# the scalar we are operating on
  if (! defined $subject) { return -1; }		# exit if all three required parameters are missing (!)
  my $count = shift;							# number of occurrences to replace
  if (! defined $count) { $count = -1; }		# set $count to -1 (infinite) if undefined

  # start iterating
  my ($i,$pos) = (0,0);
  while ( (my $idx = index( $subject, $search, $pos )) != -1 )	# find next index of $search, starting from our last position
  {
    substr( $subject, $idx, length($search) ) = $replace;		# replace $search with $replace

    $pos=$idx+length($replace);		# jump forward by the length of $replace as it may be
									# longer or shorter than $search was, and if we don't
									# compensate for this we end up in a different portion
									# of the string.

    if ($count>0 && ++$i>=$count) { last; }				# stop iterating if we have reached the limit ($count)
  }

  return $subject;
}



sub getFileNameExt
{
	my ($filepath)=@_;

	my ($filename) = ($filepath =~ /([^\\\/]+)$/);
	return $filename;
}

sub getFileNameOnly
{
	my ($filepath)=@_;

	my ($filename) = ($filepath =~ /([^\\\/]+)$/);
	my $filenameonly;
	
	if( $filename =~ /\./ )
	{
		($filenameonly) = ($filename =~ /^(.*)\.[^\.]+$/);
	}
	else
	{
		$filenameonly = $filename;
	}

	return $filenameonly;
}

sub getExtOnly
{
	my ($filepath)=@_;
#	return basename($filepath,qr{\..*});

	my ($filename) = ($filepath =~ /([^\\\/]+)$/);
	my $ext;
	
	if( $filename =~ /\./ )
	{
		($ext) = ($filename =~ /([^\.]+)$/);
	}
	else
	{
		$ext = "";
	}
	
	return $ext;
}


sub getFilePath
{
	my ($filepath)=@_;
	return dirname($filepath);
}

sub getReleativePath
{
	my ($path,$rootpath) = @_;
	my $pathrelpath;

#	$path=fileNameforPerl($path);
	$path = dosPath($path);
	$rootpath = dosPath($rootpath);
	$pathrelpath = fileNameforPerl($rootpath);

	$path =~ s/^\s*$pathrelpath[\\\/]//i;

	return $path;
}

sub ifArrayMember
{
	my ($var,$parr)=@_;

	foreach (@$parr)
	{
		return 1 if ($var eq $_);
	}
	return 0;
}

sub getArrayIndex
{
	my ($var,$parr)=@_;

	for(my $i=0; $i<@$parr; $i++)
	{
		return $i if ($var eq $parr->[$i]);
	}
	return -1;
}

sub grepIndex
{
	my ($var,@arr)=@_;
	my @aindex;
	
	for(my $i=0; $i<@arr; $i++)
	{
		push @aindex, $i if( $arr[$i] =~/$var/ );
	}
	
	return @aindex;
}

sub getFilenamesInDir
{
	my ($path, $ext)=@_;
	
	opendir(THEDIR,"$path")|| die   " *** Can't open dir \"$path\" for reading.\n";
	my @nCur = grep(!/^\./, readdir(THEDIR));
	closedir(THEDIR);
	
	@nCur = grep( getExtOnly($_) =~ /^$ext$/i, @nCur ) if( defined($ext) );
	
	return \@nCur;
}

sub ifArrayMemberPart
{
	my ($var,$parr)=@_;

	foreach (@$parr)
	{
		return 1 if (/$var/);
	}
	return 0;
}

sub lcArray
{
	grep {$_=lc;} @_;
	return @_;
}

sub max
{
	my $max = $_[0];
	for my $num (@_)
	{
		$max = $num if ($num > $max);
	}
	return $max;
}

sub min
{
	my $min = $_[0];
	for my $num (@_)
	{
		$min = $num if ($num < $min);
	}
	return $min;
}

sub sum
{
	my $sum = 0;
	for my $num (@_)
	{
		$sum += $num;
	}
	return $sum;
}

sub mySys
{
	my ($cmd)=@_;
	print $cmd . "\n";
	system ($cmd) >= 0
	     or die "system \"$cmd\" failed: $?"
}

sub percentage
{
	my ($n,$sum)=@_;
	return 0 if (not defined $sum);
	return 0 if (not defined $n);
	return 0 if ($sum eq 0);
	return $n/$sum;
}

sub processCommandLine
{
    my %ProcessingArgs  = (@_);
    my $name,
    my $value;

    while (1)
    {
    	last if (@main::ARGV == 0 );
    	my $arg = shift @main::ARGV;
    	if ($arg =~ /^[-]/)
    	{
    		($name) = ($arg =~ /^[-](.+)/);
    		if( ifArrayMember($name,[keys %ProcessingArgs]) )
    		{
    			die "no value for -$name" if (@main::ARGV == 0);
    			my $value = shift @main::ARGV;
    			${$ProcessingArgs{$name}} = $value;
    		}
    		else
    		{
    			die "unknown configure -$name";
    		}
    	}
    	else
    	{
    		unshift @main::ARGV,$arg;
    		last;
    	}
   }
}

sub qWait
{
	my ($jobidorlabel, @options) = @_;
	if ($QENABLE)
	{
		mySys("q wait " . join(" ",@options) . " $jobidorlabel");
	}
}

sub qSys
{
	my ($cmd, @options) = @_;
	if ($QENABLE)
	{
		mySys("q sub " . join(" ",@options) . " $cmd");
	}
	else
	{
		mySys("$cmd");
	}
}

sub readConfig
{
	my ($filename)=@_;

	my @arr = readFile($filename);

	my %conf;

	grep {$_=trim($_)} @arr;
	@arr = grep {/^[^#]/} @arr;
	@arr = grep {/=/} @arr;
	grep {/([^=]+)[=\s]+([^=]*)/; $conf{$1}=$2?$2:""; } @arr;

	$conf{"selfname"} = $filename;

	return %conf;
}

sub readFile
{
	my ($filename)=@_;
	open (FP,$filename) || die "Error readFile: can not open $filename : $!";
	my  @arr = <FP>;
	grep chomp,@arr;
	close FP;

	return \@arr;
}


sub readFileAsHashKey
{
	my ($filename)=@_;
	open (FP,$filename) || die "Error: can not open $filename : $!";
	my @arr = <FP>;
	close FP;

	my %hash;
	grep {chomp, $hash{trim($_)}=1;} @arr;

	return \%hash;
}


sub randIndex
{
	my ($var1,$var2)=@_;
	my %rand1;
  foreach   (1..$var1)
  {  
  	my $rand1 = int (rand($var2));
  	redo   if   $rand1{$rand1};
  	$rand1{$rand1}=1;  
  }
  return hash2Array(\%rand1);
}

sub hash2Array
{
	my ($phash)=@_;
	
	my @arr;
	my $i=0;
	foreach (sort  {$a <=> $b} (keys %$phash))
	{
		$arr[$i++] = $_;
	}
	return \@arr;
}


sub array2Hash
{
	my ($parr)=@_;
	
	my %hash;
	grep {chomp, $hash{trim($_)}=1;} @$parr;
	return \%hash;
}

sub recursiveMakeDirectory
{
    my $dir = $_[0];
    $dir =~ s/\//\\/g;
    $dir =~ s/\\$//;    # strip trailing \

    return -1 if -e $dir;

    my $ParentDir = $dir;
    $ParentDir =~ s/^(.*)\\+[^\\]+$/$1/;

    if($ParentDir ne $dir && !-e $ParentDir)
    {
        if(!recursiveMakeDirectory($ParentDir))
        {
            return 0;
        }
    }

    if(!mkdir($dir))
    {
        die("Could not create <DIR>$dir</DIR>");
        return 0;
    }

    return -1;
}

sub recursiveMakeDirectory4Linux
{
    my $dir = $_[0];
    $dir =~ s/\\/\//g;
    $dir =~ s/\/$//;    # strip trailing \

    return -1 if -e $dir;

    my $ParentDir = $dir;
    $ParentDir =~ s/^(.*)\/+[^\/]+$/$1/;

    if($ParentDir ne $dir && !-e $ParentDir)
    {
        if(!recursiveMakeDirectory4Linux($ParentDir))
        {
            return 0;
        }
    }

    if(!mkdir($dir))
    {
        die("Could not create <DIR>$dir</DIR>");
        return 0;
    }

    return -1;
}

sub recursiveMakeDirectory4List
{
    my (@files) = @_;
    foreach my $file(@files)
    {
        my $path = dirname($file);
        mkpath($path) unless (-e $path);
    }
}

sub getFNsInrecursiveDir
{
	my ($path,$ext) = @_;
	my $filesep;
	if ($path =~ /\//) {
		$filesep = '/';
	} else {
		$filesep = '\\';
	}
	
	my @pFNList;
	my $tmpFNList = getFilenamesInDir( "$path" );
	for (@$tmpFNList )
	{
		if( (-d( "${path}${filesep}$_" )) )
		{
			my $tmp = getFNsInrecursiveDir("${path}${filesep}$_",$ext);
			push @pFNList, @$tmp;
		}else{ 
			if( !defined($ext) || getExtOnly($_) =~ /^$ext$/i )
			{
				push @pFNList, "${path}${filesep}$_";
			}
		}
	}
	return \@pFNList;
}

sub getFNsInrecursiveDir4Linux
{
	my ($path,$ext) = @_;
	my @pFNList;
	my $tmpFNList = getFilenamesInDir( "$path" );
	for (@$tmpFNList )
	{
		if( (-d( "$path/$_" )) )
		{
			my $tmp = getFNsInrecursiveDir4Linux("$path/$_",$ext);
			push @pFNList, @$tmp;
		}else{ 
			if( !defined($ext) || getExtOnly($_) =~ /^$ext$/i )
			{
				push @pFNList, "$path/$_";
			}
		}
	}
	return \@pFNList;
}

sub createList4FeatureExtraction
{
	my ($src_dir,$des_dir,$src_ext,$des_ext,$scp_file) = @_;
	my $src_dir_escape = $src_dir;
	$src_dir_escape =~ s/\\/\\\\/g;
	
	my $pfiles = getFNsInrecursiveDir($src_dir, $src_ext);	
	my @pList;
	foreach my $srcfile (@$pfiles)
	{
		my $desfile = $srcfile;
		$desfile =~ s/$src_dir_escape/$des_dir/;
		$desfile = replaceExtension($desfile,$des_ext);
		my $despath = dirname($desfile);
		mkpath($despath) unless (-e "$despath");
		push @pList, "$srcfile $desfile";
	}
	if (defined($scp_file))
	{
		writeText($scp_file,join("\n",@pList));
	}
	return \@pList;	
}

sub removeDuplicate
{
	my (@arr)=@_;
	my @arrnew;
	my $cur="";
	my $i;
	@arr = sort( @arr );
	for ($i=0;$i<@arr;$i++)
	{
		if ($arr[$i] ne $cur)
		{
			$cur=$arr[$i];
			push @arrnew,$cur;
		}
	}

	return @arrnew;
}

sub replaceExtension
{
	my ($filename, $newext) = @_;

	my ($ext) = ($filename =~ /(\.[^\.\\\/]+)$/);

	$newext = "" if( ! defined($newext) );

	if ( ($newext) and ( $newext !~ /^\./) )
	{
		$newext = ".$newext";
	}

	if ($ext)
	{
		$filename =~ s/\.[^\.\\\/]+$/$newext/;
	}
	else
	{
		$filename .= $newext;
	}
	return $filename;
}

sub saveArray
{
	my ($filepath,$array)=@_;

	open FP,">$filepath";
	print FP join("\n",@$array);
	close FP;
}


sub trim
{
	my ($str)=@_;
	$str =~ s/^(\s)+//;
	$str =~ s/(\s)+$//;
	return $str;
}

sub unixPath
{
	my ($path)=@_;
	$path =~ s/\\/\//g;
	return $path;
}

sub writeLog
{
	my ($filepath,$msg)=@_;
	open FP, ">$filepath"  or die "Error: can not open $filepath to write : $!";
	print FP $msg;
	close FP;
}

sub writeText
{
	my ($filepath,$msg)=@_;
	open FP, ">$filepath" or die "Error: can not open $filepath to write : $!";
	print FP $msg;
	close FP;
}


1;


# word2snor: convert word to its SNOR
#   (standard normalized orthographic representation).
# The purpose of SNOR: to make sure that the only differences between
#   two transcriptions are the ones that you want HResults to count.
# Standard definition for SNOR is available at http://www.nist.gov/speech/.
# The SNOR implemented in this function is NOT QUITE NIST'S DEFINITION.
# Usage: @snor = word2snor($word).
# The length of @snor is:
#   0 - if $word should not be counted (e.g. silence)
#   1 - most of the time
#   2 or more - if $word should be divided into multiple words, e.g.,
#       a compound word, acronym, or number
# This function is used many places, so don't comment it out...
sub word2snor {
    my(@snor) = $_[0]; 
    # Return a zero-length list for silence, noise, ...
    if ($snor[0] =~ /^\[(noise|silence|vocalized-noise)/) { return (); } 
    # ... laughter that is not masking a word ...
    if ($snor[0] =~ /^\[laughter(_|\])/) { return (); }
    # ... utterance boundaries ...
    if ($snor[0] =~ /^!(ENTER|EXIT)$/) { return (); }
    # ... filled pauses ...
    if ($snor[0] =~ /^(uh|um|umm)$/i) { return (); }

    # Remove the laughter cover
    $snor[0] =~ s/^\[laughter\-(.*)\]/$1/;

    # Remove irrelevant detail from the word
    $snor[0] =~ s/_.*//; # Remove pronunciation variants
    $snor[0] =~ s:^.*/(.*)\]$:$1:; # Malaprop => intended word
    $snor[0] =~ s/[\.\']//g; # Ignore period or apostrophe
    
    # The NIST standard says that fragments should count in 
    # the numerator of the WER computation, but not the denominator.
    # HResults doesn't implement that.
    # Here's a heuristic approach:
    #  Keep only the acoustically implemented part.
    #  Disadvantage: "-[De]troit" becomes "troit", hard to read
    #  Advantage: "-[de]pending" becomes "pending", identical to the
    #   word "pending" that HVite would most correctly recognize.
    $snor[0] =~ s/\[[^\]]*\]\-//;  # Eliminate word-final unpronounced phones
    $snor[0] =~ s/\-\[[^\]*]\]//;  # Eliminate word-initial unpron phones

    # Change & to the subword "And", e.g., A&E becomes AAndE
    $snor[0] =~ s/&/And/g;
    
    # Treat any remaining slash (20/20) or dash (AK-47, eighty-six),
    #   as a divider for a compound word.
    my($word) = $snor[0];
    @snor = split(/[\-\/]/, $word);

    # Divide acronyms, e.g. ATT becomes A T T
    for(my $n=$#snor; $n >= 0; $n = $n-1) {
	# Heuristic: Separate around capitalized sub-words & digit strings:
	#  GrandPrixAAndE10fifty => Grand Prix A And E 10 fifty
	my(@bar)=split(/([A-Z][a-z]*|\d+)/,$snor[$n]);
	splice(@snor,$n,1,@bar);
    }

    # Goal: convert digit sequence into its component words
    # Problem: same digit sequence can be pronounced different ways
    # These rules match 43 out of 50 cases in the Switchboard dictionary
    # Warning to hackers: Early rules feed later rules
    for(my $n=0; $n <= $#snor; $n = $n+1) {
	# Double-oh ...
	if($snor[$n]=~/^00(.*)$/) { splice(@snor,$n,1,("double","oh",$1)); }
	# One thousand, twelve thousand, ...
	if($snor[$n]=~/^(\d?\d)000$/) { splice(@snor,$n,1,($1,"thousand")); }
	# One hundred, twelve hundred, ...
	if($snor[$n]=~/^(\d?\d)00$/) { splice(@snor,$n,1,($1,"hundred")); }
	# Any other three or four digit string: split into 2-digit substrings
	if($snor[$n] =~ /^(\d?\d)(\d\d)$/) { splice(@snor,$n,1,($1,$2)); }
	# Any other string longer than four digits: pronounce each digit
	if($snor[$n]=~/\d\d\d\d\d/) { splice(@snor,$n,1,split(//,$snor[$n])); }
	
	# 10..19
	my(@w) = ('ten','eleven','twelve','thirteen','fourteen',
		  'fifteen','sixteen','seventeen','eighteen','nineteen');
	if($snor[$n]=~/^1\d$/) { $snor[$n] = $w[$snor[$n]-10]; }
	# Any other two-digit string
	@w = ('oh','ten','twenty','thirty','forty','fifty',
	      'sixty','seventy','eighty','ninety');
	if($snor[$n]=~/^(\d)(\d)$/) { splice(@snor,$n,1,($w[$1],$2)); }
	# Single digits
	@w = ('zero','one','two','three','four','five','six',
	      'seven','eight','nine');
	if($snor[$n]=~/^(\d)$/) { $snor[$n] = $w[$1]; }
    }

    return(@snor);
}   # END of function definition word2snor
