use strict;
use warnings;


our $VERSION = "0.2.3";

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


#Sub: get_version
#Returns the version number of WashU_Pipe
sub get_version{
	return "$VERSION";
}

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



#Sub: create_filename_list_file 
#Receives an array of filenames and writes those to
#a file names 'washu_filename_list_temp_file.txt', each
#filename on a separate line
sub create_filename_list_file{
	my @filenames = @_;
	open(OUT, '>', 'washu_filename_list_temp_file.txt') or die "Could not write to 'washu_filename_list_temp_file.txt' : $!";
	foreach my $filename (@filenames){
		print OUT "$filename\n";
	}
	close OUT or die "Could not close 'washu_filename_list_temp_file.txt' : $!";
}



#Sub: getFilenames
#Receives a filename and returns an array of the file's contents.
#Subroutine opens the file and reads the filenames, which
#are then used to populate the array
sub getFilenames{
	my ($filename) = @_;
	my @files_to_process;
	
	unless(-e $filename){
		die "Filename list '$filename' does not exist.\n";
	}
	
	if ( $filename =~ /\.gz$/ ) {
		open( IN, "zcat $filename |" ) or die "Could not open '$filename' : $!";
	} else {
		open( IN, $filename ) or die "Could not open $filename\n";
	}
	
	while(<IN>){
		my $line = $_;
		chomp $line;
		next if $line =~ /^\s*$/;	
		push(@files_to_process, $line);
	}
	
	close IN or die "Could not close filehandle on '$filename' : $!";
	
	return @files_to_process;
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


#Sub: check_modules
#Checks that the required modules are loaded
#(if not, it dies)
sub check_modules {
	my $ucsc_tools_installed = 0;
	if ( !system "which bedSort >/dev/null 2>&1" ) {
		$ucsc_tools_installed = 1;
	} else {
		warn "ucsc_tools needs installing\n";
	}

	my $tabix_installed = 0;
	if ( !system "which tabix >/dev/null 2>&1" ) {
		$tabix_installed = 1;
	} else {
		warn "Tabix needs installing\n";
	}

	my $samtools_installed = 0;
	if ( !system "which samtools >/dev/null 2>&1" ) {
		$samtools_installed = 1;
	} else {
		warn "Samtools needs installing\n";
	}

	unless ( $ucsc_tools_installed and $tabix_installed and $samtools_installed ) {
		die "Please install modules and try again.\n";
	}
}


#Sub: seqmonk_reformatter
#Converts a gene id in seqmonk into a more concise id:
#e.g. Hcfc1-001|Hcfc1-002|Hcfc1-005 > Hcfc
#Sub: seqmonk_reformatter
#Converts a gene id in seqmonk into a more concise id:
#e.g. Hcfc1-001|Hcfc1-002|Hcfc1-005 > Hcfc
sub seqmonk_reformatter{
	my $description = $_[0];
	
	my %uniques;
    my @pipe_elements = split( /\|/, $description );

	foreach my $pipe_element (@pipe_elements){
		my @hyphen_elements = split( /-/, $pipe_element );
		if ( scalar(@hyphen_elements) > 1 ) {
			if($hyphen_elements[-1] =~ /\d\d\d/){
				pop(@hyphen_elements);
			}
		}
		$pipe_element = join( '-', @hyphen_elements );
		$uniques{$pipe_element} = '1';
	}
	
	my $formatted_description = '';
	foreach my $key (sort keys %uniques){    #In case the description contains separate gene names separated by a pipe
		#print "key: $key\n";
		$formatted_description = $formatted_description . $key . '_';
	}

	$formatted_description =~ s/_$//;		
	return $formatted_description;
}




#Sub: print_help
sub print_help{
	print <<'END_TEXT';

	WashU_Pipe

	SYNOPSIS

	To prepare Hi-C data for the WashU Epigenome Browser

	FUNCTION

	WashU_Pipe [Options] [Input files]

	The input files should either be in:
	i) SAM/BAM format

	ii) Interacting fragment format (no score)
	ChromsomeA  StartA  EndA
	ChromsomeB  StartB  EndB

	iii) Interacting fragment with score
	ChromsomeA  StartA  EndA    Score
	ChromsomeB  StartB  EndB    Score

	iv) WashU format
	chr1   \t   111   \t   222   \t   chr2:333-444,55   \t   1   \t   .
	chr2   \t   333   \t   444   \t   chr1:111-222,55   \t   2   \t   .
	
	The software automatically detects BAM/SAM format files.

	COMMAND LINE OPTIONS

     --4C           List of positions for creating 'virtual 4C' data tracks. 
                    Files should be tab-delimited (4 columns):
                    Bait_Chromosome    Bait_Start    Bait_End    Bait_Name

                    Do NOT place non-alphanumeric characters in the bait name (underscore, 
                    full-stop, hyphen and pipe are ok).
                    For fragment files (i.e. not SAM/BAM) the bait fragment positions need 
                    to correspond EXACTLY to the fragments in the data files. 

                    The file should contain NO header lines.   

    --digest        Bin reads by restriction fragment. Specify the relevant restriction 
                    fragment file (hicup_digester output file). This option is applicable 
                    to SAM/BAM format files.
 
    --columns       The column order for the baits file may be specified using a comma-
                    separated list of integers e.g. --columns 3,5,1,2 indicates that the
                    Chromosome is in column 3; Start in column 5; End in column 1
                    and Bait_ID in column 2. (This is a 1-based numbering system.)
                    Default: 1,2,3,4 (i.e 1:Chromosome; 2:Start; 3:End; 4:Bait_ID)

    --combine       Writes all captured di-tags to the same output file, irrespective of the
                    capture region to which the di-tag maps. (Different sample input BAM/SAM 
                    files will still generate separate outputfiles.)	

    --count         Count the number of identical interactions and use this value to set 
                    the width of the arc. Consequently, the 'Score', if present, will be 
                    ignored.  This option applies to file formats ii and iii.  SAM/BAM 
                    files are return a score by default.
				
    --email         Send email to this address when job complete (WashU_Cluster only)

    --filelist      Name of file that lists files to process. Filenames should be placed on 
                    separate lines (Alternatively files may be passed using the command 
                    line). 

    --ftp           FTP site to which to upload the final data files. Input as a 
                    comma-separated list:
                    --ftp '[Domain],[User],[Password]'

    --help          Print the help message.                    
					
    --maximum       Takes an integer of the maximum number of base pairs allowed between a 
                    di-tag read pair and filters out reads further away than this distance 
                    (as well as trans di-tags) 
					
    --minimum       Takes an integer of the minimum number of base pairs allowed between a 
                    di-tag read pair and filters out reads closer than this distance (as 
                    well as trans di-tags) 

    --merge         Merges a specified number of fragments in the --digest file.

    --washu         Input file is in WashU format.

    --window       Bin reads into tiled windows. Specify the window size (bps). 
                   This option is applicable to SAM/BAM format files.

Steven Wingett, Babraham Institute, Cambridge, UK (steven.wingett@babraham.ac.uk)

END_TEXT
}

1
