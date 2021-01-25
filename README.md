# WashU-Pipe
Pipeline to prepare Hi-C data for the WashU Epigenome Browser

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
