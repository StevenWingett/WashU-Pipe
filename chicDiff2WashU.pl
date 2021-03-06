#!/usr/bin/perl

use strict;
use warnings;
use POSIX;
use Getopt::Long;
use FindBin '$Bin';
use lib $Bin;
#use WashU_Pipe_Module;

use Data::Dumper;

###################################################################################
###################################################################################
##This file is Copyright (C) 2015, Steven Wingett (steven.wingett@babraham.ac.uk)##
##                                                                               ##
##                                                                               ##
##This file is part of WashU_Pipe.                                               ##
##                                                                               ##
##WashU_Pipe is free software: you can redistribute it and/or modify             ##
##it under the terms of the GNU General Public License as published by           ##
##the Free Software Foundation, either version 3 of the License, or              ##
##(at your option) any later version.                                            ##
##                                                                               ##
##WashU_Pipe is distributed in the hope that it will be useful,                  ##
##but WITHOUT ANY WARRANTY; without even the implied warranty of                 ##
##MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  ##
##GNU General Public License for more details.                                   ##
##                                                                               ##
##You should have received a copy of the GNU General Public License              ##
##along with WashU_Pipe.  If not, see <http://www.gnu.org/licenses/>.            ##
###################################################################################
###################################################################################



#############################################################################################
#Perl script to convert a chicDiff coordinates file:
#group	baseMean	log2FoldChange	lfcSE	stat	pvalue	padj	baitID	maxOE	minOE	regionID	OEchr	OEstart	OEend	baitchr	baitstart	baitend	avDist	uniform	shuff	avgLogDist	avWeights	weight	weighted_pvalue	weighted_padj	Chromosome	Start	End	BaitName
#a format that can be read by the WashU browser
#WashU browser format:
#chr1   \t   111   \t   222   \t   chr2:333-444,55   \t   1   \t   .
#chr2   \t   333   \t   444   \t   chr1:111-222,55   \t   2   \t   .
#
#After running this script
#1) Import ucsc_tools and tabix
#2) bedSort filein fileout
#3) bgzip bedfile
#4) tabix -p bed gedfile.gz
#5)Upload the tbi file and the bedfile.gz to the remote server.  The http link needs to be
#passed to the washU browser.
############################################################################################



my $version;
my $filelist;

my $config_result = GetOptions(
	"filelist=s" => \$filelist,
	"version" => \$version
);
die "Could not parse options" unless ($config_result);

#if($version){
#	$version = get_version();
#	print "WashU_Pipe v$version\n";
#	exit(0);
#}

my @files;
push(@files, getFilenames($filelist)) if defined $filelist;
push (@files, @ARGV) if @ARGV;
@files = deduplicate_array(@files);
die "Please specify files to process.\n" unless (@files);

print "Converting fragments data to WashU format\n";

foreach my $file (@files){

	open(IN, '<', $file) or die "Could not open '$file' : $!";
	open(OUT, '>', "$file.washu_format.txt") or die "Could not open '$file.washu_format.txt' : $!";
	
	print "Processing $file\n";
	
	scalar <IN>;    #Ignore header

	my $i = 1;
	while(<IN>){

		my $line = $_;
		chomp $line;
		
		my $csomeF = (split(/\t/, $line))[11];   #readF = OE
		my $csomeR = (split(/\t/, $line))[14];   #readR = bait

		$csomeF = csome_formatter($csomeF);
		$csomeR = csome_formatter($csomeR);

		my $startF = (split(/\t/, $line))[12];
		my $startR = (split(/\t/, $line))[15];
		my $endF = (split(/\t/, $line))[13];
		my $endR = (split(/\t/, $line))[16];
		
		my $score = (split(/\t/, $line))[2];    #log2FoldChange

		print OUT "$csomeF\t$startF\t$endF\t".$csomeR.':'.$startR.'-'.$endR.','."$score\t$i\t.\n";
		$i++;
		print OUT "$csomeR\t$startR\t$endR\t".$csomeF.':'.$startF.'-'.$endF.','."$score\t$i\t.\n";
		$i++;		
	}	
	close IN or die "Could not close filehandle on $file : $!";
	close OUT or die "Could not close filehandle on $file.washu_format.txt : $!";
}

print "Conversion complete\n";

exit;

###################
#WashU Module subroutines
###################




#Sub csome_formatter
#Makes sure output only in BED format, so:
#* -> chr*, c
#chr* -> chr*
sub csome_formatter{
	my $csome = $_[0];
	
	if(length $csome <= 3){
		return 'chr' . $csome;
	}elsif( substr($csome, 0, 3) eq 'chr' ){
		return $csome;
	}else{
		return 'chr' . $csome;
	}
}





#Sub: deduplicate_array
#Takes and array and returns the array with duplicates removed
#(keeping 1 copy of each unique entry).
sub deduplicate_array{
	my @array = @_;
	my %uniques;

	foreach (@array){
		$uniques{$_} = '';	
	}
	my @uniques_array = keys %uniques;
	return @uniques_array;
}
