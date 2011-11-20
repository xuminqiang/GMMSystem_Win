package HTKfiles;
use FindBin;
use lib "$FindBin::Bin";
use tytools;
use strict;
use warnings;
use warnings::register;
our $VERSION = '0.1';
require Exporter;
require Cwd;

=head1 NAME

HTKfiles - perl module for read htk files.

=head1 SYNOPSIS

    use HTKfiles;

=head1 DESCRIPTION

perl module for read htk files.

=cut

our @ISA = qw(Exporter);
our @EXPORT = (

#MLF releated operation
'getTransFromMLF',		#($mlfsref, $filename) get transctiptions for $filename from $mlfsref
'readMlf',				#($mlffile) read mlf file and stored in an structure
'readMlfIndex',         #($mlffile) read mlf file and stored the info. of each utterance in a array
'readMlfOfUtterance',   #($mlffile,%utterance) read one utterance from mlf file
'fixUtteranceWordInfo',	#($putt) update the word start&end time and likelihood of utterance according to start&end index
'saveMlf',				#($mlffile,$mlfsref) write the mlf file

#dictioary related operation
	#	struct Dict
	#	{
	#		word => sturct Word
	#	}
	#	struct Word
	#	{
	#		struct Pron [] pronArray;
	#	}
	#	struct Pron
	#	{
	#		pron => join (" ", @phonesquence);
	#		syllable => join (" ", @syllablesquence);  (optional)
	#		id => index_in_dictionary
	#	}
	#	Comment1: syllablesquence = join("|",@phonesquence);

  #dictionary I/O
	'isSAPIDict',
	'readDict',				#read HTK format dictionary, return data type: struct Dict
	'readHTKorSAPIDict',	#read sapi/HTK format dictionary

  #dictionary operator
	'addMultiplePron',		#($dictfile,$silencemark)	add multiple pron for file
	'getDictMaxIndex',		#get max index in the dict
	'mergeDict',            #merge two dictionaries
	'phoneHashFromDict',	#($pdicts) read readdict returned array, return phone list hash
	'syllableHashFromDict',  #($pdicts) read readsyllalbedict returned array, return syllable list hash
	'triphone2Monophone',	#($triphone) modify triphone to monophone
	'fixDictSyllable',		#($pdict,$psyllablelists) add syllable pron
#'phoneListFromDictArray',	#($pdicts) read HTK dict format array, return phone list hash
);

sub readMlf
{
	my ($mlffile) = @_;
	my $line;
	my @label;
	my $filename;
	my %utterance;
	my @utterances;

	open FP,$mlffile or die "Error: open $mlffile $!";
	while (<FP>)
	{
		$line = $_;
		chomp($line);
		if ($line =~ /^\"/)
		{
			($filename) = ($line =~ /\"([^\"]+)\"/);
			@label = ();
		}
		elsif ($line =~ /^\./)
		{
			$utterance{filename} = $filename;
			$utterance{labels} = [ @label ];
			push(@utterances, {%utterance} );
		}
		else
		{
			push(@label,$line);
		}
	}
	close FP;

	return @utterances;
}

sub readMlfIndex
{
	my ($mlffile) = @_;
	my $line;
	my %mlfs;

	open FP,$mlffile or die "Error: open $mlffile $!";

	$mlfs{filename} = $mlffile;

	while (<FP>)
	{
		$line = $_;
		chomp($line);
		if ($line =~ /^\"/)
		{
			$line =~ /\"(.+)\"/;

			push @{$mlfs{utterances}}, {
					filename => $1,
					position => (tell FP),
					}
					or die "Erorr: tell $!";
		}
	}
	close FP;

	return \%mlfs;
}

sub readMlfOfUtterance
{
	my ($pmlfs, $filename, $scorenormalized) = @_;

	my $line;
	my %utt;
	my $curindex;

	my $type=0;

	#find in $pmlfs for $filename

	my $filename1 = unixPath( replaceExtension( $filename ) );
	my $bfind;
	foreach my $psingleutt ( @{ $pmlfs->{utterances} } )
	{
		my $filename2 = unixPath( replaceExtension( $psingleutt->{filename} ) );
		$filename2 =~ s/\*/\.\*/g;
		$filename2 =~ s/^\.\*\//\.\*/;
		$filename2 =~ s/\?/\./g;

#		print "file1=$filename1\nfile2=$filename2\n";
		if( $filename1 =~ /$filename2/ )
		{
			$bfind = $psingleutt;
			last;
		}
	}

	die "Error: cann't find \"$filename\" in mlf \"$pmlfs->{filename}\"\n" if( not $bfind );
	open FP,$pmlfs->{filename} or die "Error: open file $!";

	seek( FP, $bfind->{position}, 0);

	$curindex = 0;
	while ($line=<FP>)
	{
		last if ($line =~ /^\"/ or $line =~ /^\./);
		chomp($line);

		my @arr = ($line =~ /\S+/g );

		if( $type == 0 )
		{
			if( @arr==1 || @arr==4 || @arr==5 )
			{
				$type = @arr;
			}
			else
			{
				die "unknown MLF format!";
			}
		}

		if( @arr >= 4  )
		{
			#if we are labels of phone + word
			if ($type==5)
			{
				#update phone array information
				push @{$utt{phonestarttime}}, $arr[0];
				push @{$utt{phoneendtime}}, $arr[1];
				push @{$utt{phone}}, $arr[2] ;
				push @{$utt{phonescore}}, $arr[3];
				$utt{phonescore}->[-1] *= ( ($arr[1]-$arr[0])/1e7 )
					if ($scorenormalized);

				#update word array information
				if( @arr == 5 )
				{
					push @{$utt{word}}, $arr[4];
					push @{$utt{wordstartindex}}, $curindex;
					push @{$utt{wordendindex}}, $curindex + 1;
				}
				else
				{
					$utt{wordendindex}->[-1] = $curindex + 1;
				}
			}
			#if we are labels of word only
			else
			{
				push @{$utt{wordstarttime}}, $arr[0];
				push @{$utt{wordendtime}}, $arr[1];
				push @{$utt{word}}, $arr[2] ;
				push @{$utt{wordscore}}, $arr[3];
			}
		}
		elsif( @arr == 1 )
		{
			push @{$utt{word}}, shift @arr;
		}
		else
		{
			die "Error: unrecognized mlf \"$line\"";
		}
		$curindex ++;
	}
	if( $type == 5 )
	{
#		print "^^^^^^^^^^^^^^^^^^^^^^\n";
		fixUtteranceWordInfo( \%utt );
	}

	close( FP );
	return \%utt;
}

sub fixUtteranceWordInfo
{
	my ($putt) = @_;

	$putt->{wordstarttime} = [ () ];
	$putt->{wordendtime} = [ () ];
	$putt->{wordscore} = [ () ];

	for( my $i=0; $i<@{$putt->{word}}; $i++ )
	{
#		print "sd$i=$putt->{wordstartindex}->[$i]\n";
#		print "ed$i=$putt->{wordendindex}->[$i]\n";

		push @{$putt->{wordscore}}, sum( @{$putt->{phonescore}}[  $putt->{wordstartindex}->[$i]
							                                    .. $putt->{wordendindex}->[$i]-1 ] );
		push @{$putt->{wordstarttime}}, $putt->{phonestarttime}->[ $putt->{wordstartindex}->[$i] ];
		push @{$putt->{wordendtime}}, $putt->{phoneendtime}->[ $putt->{wordendindex}->[$i] - 1 ];
	}
}

sub saveMlf
{
	my ($mlffile,$mlfsref) = @_;
	my $i;
	my @mlfs;
	my @newarr;

	open FP,">$mlffile" || die "Error: open $mlffile $!";

	print FP "#!MLF!#\n";

	@mlfs  = @{$mlfsref};
	for ($i=0; $i< @mlfs; $i++)
	{
		print FP  "\"" . $mlfs[$i]{filename} . "\"" . "\n";
		@newarr = @{$mlfs[$i]{labels}};
		print FP  join("\n",@newarr);
		print FP  "\n";
		print FP  ".\n";
	}
}

sub getTransFromMLF
{
	my ($mlfsref, $filename) = @_;

	my @mlfs  = @{$mlfsref};
	my $i;
	for ($i=0; $i< @mlfs; $i++)
	{
		if ( replaceExtension(dosPath($mlfs[$i]{filename}),"")
			 eq replaceExtension(dosPath($filename),"") )
		{
			return @{$mlfs[$i]{labels}};
		}
	}

	return ();
}

sub readDict
{
	my ($dictfile) = @_;
	my $line;
	my @phonelabel;
	my @syllablelabel;
	my $wordname;
	my %words;
	my $count = 0;
	my $bsyllable;

	open (FP,$dictfile) || die "Error: open $dictfile $!";
	while (<FP>)
	{
		my ($line) = (/^\s*\S+\s+(.+)/);
		next if (not $line);
		$bsyllable = $line =~ /\./;
		last if( $bsyllable == 1 );
	}
	close(FP);

	open (FP,$dictfile) || die "Error: open $dictfile $!";
	while ($line = <FP>)
	{
		chomp($line);
		@phonelabel = ( $line =~ /\S+/g );
		@phonelabel = grep {not /^(\.|1|\.1|\?)$/} @phonelabel;
		$wordname = lc(shift @phonelabel);

		if( $bsyllable == 1 )
		{
			($line) = ($line =~ /^\s*\S+\s+(.+)/);
			next if (not $line);
			@syllablelabel = split(/\.|\.1|1|\?/, $line);
			grep { $_ = trim( $_ ); $_ =~ s/\s+/\|/g; } @syllablelabel;
			@syllablelabel = grep { $_ ne "" } @syllablelabel;

			push @{$words{$wordname}}, {
				id => $count,
				pron => join(" ", @phonelabel ),
				syllable => join(" ", @syllablelabel ),
			};
		}
		else
		{
			push @{$words{$wordname}}, {
				id => $count,
				pron => join(" ",  @phonelabel ),
			};
		}

		$count++;
	}
	close FP;

	return \%words;
}

sub addMultiplePron
{
	my ($dictfile,$silencemarks)=@_;
	my $newdictmultiplepron = "$dictfile.multiplepron";
	my $arr;
	my @arr=readFile($dictfile);
	my @arr2;

	for $arr (@arr)
	{
		push @arr2, $arr;
		next if ($arr=~/^silence\s+/i);
		next if ($arr=~/^sil\s+/i);
		next if ($arr=~/^sp\s+/i);
		next if ($arr=~/^_/i);
		for my $silencemark (split(/\s+/,$silencemarks))
		{
			push @arr2, join(" ",$arr,$silencemark);
		}
	}
	writeLog($newdictmultiplepron, join("\n", @arr2, ""));
}

sub isSAPIDict
{
	my ($dictfile) = @_;

	open (FP,$dictfile) || die "Error: open $dictfile $!";

	if( <FP> =~ /^Word/ and <FP> =~ /^Pronunciation0/)
	{
		close( FP );
		return 1;
	}

	close( FP );
	return 0;
}

sub getDictMaxIndex
{
	my ($pdict) = @_;
	my $maxindex = -1;

	@_ = keys %{$pdict};
	for my $wordname (@_)
	{
		for my $wordprop (@{$$pdict{$wordname}})
		{
			if( $wordprop->{id} > $maxindex )
			{
				$maxindex = $wordprop->{id};
			}
		}
	}

	return $maxindex;
}

sub mergeDict
{
	my ($pdict1, $pdict2) = @_;
	my $maxindex = getDictMaxIndex($pdict1);

	for my $wordname (keys %$pdict2)
	{
		if (not exists $$pdict1{$wordname})
		{
			grep { $_->{id} = ++$maxindex;} @{$$pdict2{$wordname}};
			$$pdict1{$wordname} = $$pdict2{$wordname};
		}
		else
		{
			my $bexist;
			for my $type2 (@{$$pdict2{$wordname}})
			{
				$bexist = 0;
				for my $type1 (@{$$pdict1{$wordname}})
				{
					if( $type1->{pron} eq $type2->{pron} )
					{
						if( (not exists $type1->{syllable}) and (exists $type2->{syllable}) )
						{
							$type1->{syllable} = $type2->{syllable};
						}
						$bexist = 1;
					}
				}
				if( $bexist == 0 )
				{
					$type2->{id} = ++$maxindex;
					push @{$$pdict1{$wordname}}, $type2;
				}
			}
		}
	}
}

sub syllableHashFromDict
{
	my ($pdicts) = @_;
	my %syllablelist;

	for my $word (keys %$pdicts)
	{
		for my $wordprop (@{$$pdicts{$word}})
		{
			next if (not defined($wordprop->{syllable}));
			my @syllable = ($wordprop->{syllable} =~ /(\S+)/g);
			for my $syllableprop (@syllable)
			{
				$syllablelist{$syllableprop} ++;
			}
		}
	}
	return \%syllablelist;
}

sub phoneHashFromDict
{
	my ($pdicts) = @_;
	my %phonelist;

	for my $word (keys %$pdicts)
	{
		for my $wordprop (@{$$pdicts{$word}})
		{
			my @phone = split(/\s+/, $wordprop->{pron});
			for my $phoneprop (@phone)
			{
				$phonelist{$phoneprop}=1;
			}
		}
	}
	return \%phonelist;
}

sub readHTKorSAPIDict
{
	my ($dictfile) = @_;
	my $line;
	my @label;

	my $wordname;
	my %words;
	my $count = 0;
	my $bSAPI;

	open (FP,$dictfile) || die "Error: open $dictfile $!";

	if( <FP> =~ /^Word/ and <FP> =~ /^Pronunciation0/)
	{
		print "okok\n";
		seek (FP, 0, 0);
		while(<FP>)
		{
			$line = $_;

			if ($line =~ /Word/)
			{
				($wordname) = ($line =~ /\S+\s+(\S+)/);
			}
			else
			{
				my ($list) = ($line =~ /\S+\s+(.+)/);
				@label = ( $list =~ /(\S+)/g );
				$wordname = lc($wordname);

				push @{$words{$wordname}}, {
					id => $count,
					pron => join(" ",@label),
				};
				$count ++;
			}
		}
		close( FP );

		return \%words;
	}
	else
	{
		return readDict($dictfile);
	}
}

sub triphone2Monophone
{
	
	 $_[0] =~ s/[^\-]+\-//; 
	 $_[0] =~ s/\+.+//; 
	 
	 return $_[0];
}

sub fixDictSyllable
{
	my ($pdict,$psyllablelists) = @_;

	if( not defined ($psyllablelists) )
	{
		$psyllablelists = syllableHashFromDict($pdict);
	}

	#add syllable pron		
	for my $wordname (keys %$pdict)
	{
		my $count = 0;
		while (1)
		{
		    last if ($count==@{$pdict->{$wordname}});
			my $wordprop = $pdict->{$wordname}->[$count];
			if (not exists $wordprop->{syllable})
			{
				#varaible for store final matched path	
				my @syllablepron;
				
				pron2Syllable($wordprop->{pron}, $psyllablelists, "", \@syllablepron);
				
				if (@syllablepron > 0)
				{
					print join ("\n", "match for $wordname: $wordprop->{pron},", @syllablepron,"");
					$wordprop->{syllable} = trim( $syllablepron[0] );
				}
				else
				{
					print "error for $wordname: $wordprop->{pron},\n";
					#delete the pron + syllable
					print "delete phone+syllable $wordname: $wordprop->{pron},\n";
					splice( @{$pdict->{$wordname}},$count,1 );
					$count--;
				}
			}
			$count++;
		}
		
		#delete the word if there is no pron
		if ( @{$pdict->{$wordname}} == 0)
		{
			print "delete word $wordname,\n";
			delete $pdict->{$wordname};
		}
	}
}

sub pron2Syllable
{
	my ($pron, $psyllablelist, $cursyllable, $presults) = @_;
	
	print "DEBUG:pron=$pron   cursyllable=$cursyllable\n";
	
	#for all syllables
	for my $syllable( keys %$psyllablelist )
	{
		#convert syllable to phone list
		my $syl2phone = $syllable;
		$syl2phone =~ s/\|/ /g;
		$syl2phone = trim($syl2phone);
		
		#if we get a final match
		if( $pron =~ /^$syl2phone$/ )
		{
			push @{$presults}, $cursyllable . " " . $syllable;
			return 1;
		}
		#if we get a one word match
		elsif( $pron =~ /^$syl2phone / )
		{
			my $subpron = $pron;
			$subpron =~ s/^$syl2phone //;
			return 1 if (pron2Syllable( trim( $subpron ), $psyllablelist, join(" ", $cursyllable, $syllable), $presults ));
		}
	}
	
	return 0;
}
			

1;