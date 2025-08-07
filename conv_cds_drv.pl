#!/usr/bin/perl 

#
# File: conv_cds_drv.pl
# Created: 02/15/02 - BTM
# Edits: 05/08/06 -atolon
#        - Added datatypes as CalibreDRV supports them now.
#        11/18/13 -Karl Skjaveland
#        - Added -tech <techname> option - Now outputs files based on techname
#			- Main output file now called <techname>.layerprops
#			- Layerprops file now includes information header
#        - Added support for symbolic paths $DRV_BITMAP_DIR for centralized bitmaps
#			- Moved default X bitmap location to $HOME/.calibrewb_workspace/bitmaps/<techname>
#			- Fixed drf file parsing to support old and new display.drf syntax
#        - Added exception handling for non-square bitmaps - Outputs a message if bitmap height and width are different
#        - Enhanced <techname>_cds_layer.map to include layer names
#        - Added SVRF layer mapping for use with Layer -> Load Input SVRF Layer Names as an alternate to the Layerprops file
#        - Added exception handling for duplicate definitions of same layer and datatype - duplicate entries are commented out
#			- General formatting cleanup
#
# This file is used to try to simulate the look of a design from Cadence
# Virtuoso in Calibre Design Rev.  This script will look though the 
# display <display.drf> file and create X bitmap images for each of the 
# stipple patterns specified in that file.  It will also convert the 
# color RGB values to HEX to be read into Design Rev.  These values are
# then stored as packets.  It then looks through the technology <tech.tf>
# file and assigns each layer the correct packet (stipple pattern/color).
# It then looks in either the technology file or in the map <layermap.map>
# file to assign the appropriate gds layer.  The map file is optional, 
# however, if one is given, it will override the values in the technology
# file.  [This appears to be the way that Virtuoso behaves].
#
# -----------------------------------------------------------------------------------------------------------------------
#
# Usage:
#
# conv_cds_drv.pl -tech <techname> -disp <display_file_name> -tf <technology_file_name>
#                 -map <layermap_file_name>                                                        <- optional argument
#
# Output files:
#
# Bitmaps: If $DRV_BITMAP_DIR environment variable is defined ->  $DRV_BITMAP_DIR/<stipple_pattern_name>.xbm
#
#          If $DRV_BITMAP_DIR is not defined  -> $HOME/.calibrewb_workspace/bitmaps/<techname>/<stipple_pattern_name>.xbm
#
# Layerprops file
# <current directory>/<techname>.layerprops				- DesignRev layer properties file with Virtuoso colors and fill patterns
#
# GDS mapping file
# <current directory>/<techname>_cds_layer.map			- GDS2 layer.datatype with corresponding Virtuoso layer names
#
# SVRF Input Layer Mapping file
# <current directory>/<techname>_Input_Layers.svrf		- Input SVRF Layer Names mapping statements as alternate to layerprops file
#
# -----------------------------------------------------------------------------------------------------------------------

%colors = ();
%packet_colors = ();
%packet_stipples = ();
%layer_packets = ();
@layers_data = ();

$define = "";
$drf_format = 0;											# two typical drf formats are possible - initialize to 0 for default format
$row_count = 0;											# Initialize bitmap row counter
$bit_width = 0;											# Initialize bit width variable
$bitmap_name = "";
$symbolic_path = 0;										# Initialize bitmap path type

$last_stream = -1;										# Used to find duplicate definitions for same layer and datatype values - Initialized to -1 to avoid removing layer 0 datatype 0
$last_datatype = -1;

$svrf_layer_counter = 1000;							# Starting layer map number for SVRF layer mapping file - an arbitrary number that should exceed the highest GDS2 layer number

&check_usage;
&map_file;													# See if map file exists

# Parse input arguments

foreach $i (0..$#ARGV) {

	if ($ARGV[$i] =~ /^\-.*tech/i) {
		$techname = $ARGV[++$i];
		# print "tech name $techname\n";
		&create_bitmap_dir;								# Create directory for bitmaps based on techname specified by -tech

	} elsif ($ARGV[$i] =~ /^\-.*disp/i) {
        
		$drf_file = $ARGV[++$i];
		# print "display file $drf_file\n";
		&parse_disp_file();

	} elsif ($ARGV[$i] =~ /^\-.*map/i) {
        
		$map_file = $ARGV[++$i];
		# print "map file $map_file\n";
		&parse_map_file();

	} elsif ($ARGV[$i] =~ /^\-.*tf/i) {
        
		$tf_file = $ARGV[++$i];
		# print "techfile $tf_file\n";
		&parse_tf_file();
	}
}

# Write the <tech>.layerprops, <tech>_cds_layer.map and <tech>_Input_Layers.svrf files

$layerprops_file = "$techname.layerprops";			# Name layerprops file based on technology name specified by -tech <techname>
#print "layerprops_file $layerprops_file\n";
$layermap_file = "$techname\_cds_layer.map"; 		# Name cds_layer.map file based on technology name specified by -tech <techname>
#print "layer map file $layermap_file\n";
$svrf_layer_file = "$techname\_Input_Layers.svrf"; # Name INPUT SVRF layers file based on technology name specified by -tech <techname>
#print "SVRF layer map file $svrf_layer_file\n";



open( LAYPRP, "> $layerprops_file" );
open( LAYMAP, "> $layermap_file" );
open( SVRFMAP, "> $svrf_layer_file" );

# Printer Header in Layer Properties File

print LAYPRP "\# Converted by conv_cds_drv \(Version 3.0\)\n";																		# Record script version

if ($map_file ne "") {
	print LAYPRP "\# Using -tech $techname -disp $drf_file -tf $tf_file -map $map_file \n";								# Print arguments with optional map file

} else {
	print LAYPRP "\# Using -tech $techname -disp $drf_file -tf $tf_file \n";													# Print arguments excluding map file
}

print LAYPRP "\# ------------------------------------------------------------------------------------------\n";

foreach $record (@layers_data) {
	#foreach $layer (sort keys (%stream_layers)) {
	($layer, $stream, $datatype) = @$record;
	$packet  = $layer_packets{$layer};
	$color = $colors{$packet_colors{$packet}} ;
	$stipple = $packet_stipples{$packet};
	#$stream  = $stream_layers{$layer};
	#$datatype = $stream_datatypes{$layer};
	($lay = $layer) =~ s/_drawing//i;

	# print "layer:$layer stream $stream datatype $datatype lay $lay\n";
 
	if ($stipple ne "") {																									# Don't write records with no stipple pattern

		print LAYMAP "$stream.$datatype\t\t$lay\n";																	# Write out the <techname>_cds_layer.map

		if ($stream == $last_stream && $datatype == $last_datatype) {											# Is the record a duplicate of same later and datatype
			print "Duplicate definition for GDS2 layer\: $stream datatype\: $datatype - commenting out\n";
			print SVRFMAP "\/\/LAYER MAP $stream DATATYPE $datatype $svrf_layer_counter\n";				# If yes comment out the duplicate definitions
			print SVRFMAP "\/\/LAYER $lay $svrf_layer_counter\n";
			print LAYPRP "\#";																								# Comment duplicate definition (next entry in layerprop file)
		} else {
			print SVRFMAP "LAYER MAP $stream DATATYPE $datatype $svrf_layer_counter\n";
			print SVRFMAP "LAYER $lay $svrf_layer_counter\n";
		}

		$last_stream = $stream;
		$last_datatype = $datatype;

		$svrf_layer_counter = $svrf_layer_counter + 1;																# Increment arbitrary layer number counter

		if ($symbolic_path == 1) {
			print LAYPRP "$stream.$datatype\t#$color\t\@\$DRV_BITMAP_DIR\/$stipple.xbm\t$lay 1 1\n";	# Use with symbolic paths $DRV_BITMAP_DIR to specify global bitmap directory
		} else {
			print LAYPRP "$stream.$datatype\t#$color\t\@$bitmap_dir\/$stipple.xbm\t$lay 1 1\n";			# Use with hard paths to specify local bitmap directory
		}
	} else {
		print "Packet: $packet not found for layer:$layer stream: $stream datatype: $datatype name: $lay\n";
	}
}


sub parse_disp_file {

	open( CDS_DISP, "$drf_file" )
	|| die "Unable to open file $drf_file for reading.\n";

	while ( <CDS_DISP> ) {
		# Make everything uppercase since Calibre is case-insensitive.
		tr/a-z/A-Z/;

		# Remove ; ! # style comments
		chomp;
		#s/(\;|\!|\#).*$//;
		# Remove parenthesis
		s/\(|\)//g;
		# Remove leading white space
		s/^\s+//g;
		&check_section();
		if ( $define =~ /color/i ) {
			if ( /^\s*display\s+\w+\s+\d+\s+\d+\s+\d+/i ) {
				@fields = split (/\s+/, $_) ;
				$color_name = $fields[1];
				$red = &dec2hex($fields[2]);
				$green = &dec2hex($fields[3]);
				$blue = &dec2hex($fields[4]);
				$colors{$color_name} = "$red$green$blue";
			}
		}
	
		if ( $define =~ /stipple/i ) {
			if ( /^\s*display\s+/i ) {

				# Add "}" to last line of xbm file
				if ($row_count > 0) {				# Found new bitmap while processing one - Close the last bitmap
					print tmp_bit "\}";				# Add close } to previous bitmap

					# Output information about bitmap just processed in transcript

					if ($row_count != $bit_width) {
						print "Bitmap: $bitmap_name \($bit_width x $row_count\) \-\> $bitmap_dir/$bitmap_name.xbm    \<\- please modify $bitmap_name\_height to $row_count \n";
					} else {
						print "Bitmap: $bitmap_name \($bit_width x $row_count\) \-\> $bitmap_dir/$bitmap_name.xbm\n";
					}
				}

				@fields = split (/\s+/, $_) ;

				$bitmap_name = $fields[1];

				# Open a file to write bitmap
				$tmpxbm = "$bitmap_dir/$bitmap_name.xbm";
#				print "Converting: $tmpxbm\n";
				open( tmp_bit, "> $tmpxbm" );

				# Shifting fields twice to remove "display" and "StippleName"
				shift (@fields);
				shift (@fields);

				$bit_width = @fields;

				if ($bit_width > 0) {					# Main drf format
				
					# Printing header for xbm file
					print tmp_bit "#define $bitmap_name\_width $bit_width\n";
					print tmp_bit "#define $bitmap_name\_height $bit_width\n";
					print tmp_bit "static unsigned char $bitmap_name\_bits[] = \{\n";

					# Converting first row of binary to hex one byte at a time
					while (@fields) {
						$fbyte = bin2hex(pack ("a" x 8, @fields));
						splice (@fields,0,8);
						print tmp_bit "0x$fbyte, ";
					}

					print tmp_bit "\n";

					$row_count = 1;						# first row has been written

				} else {
#					print "alternate drf format\n";
					$drf_format = 1;						# set to alternate drf format
					$row_count = 0;						# waiting for first row
				}

			} elsif( /^\d/ ) {

				# Convert remaining rows of the same stipple pattern
				@fields = split (/\s+/, $_) ;
				# Converting binary to hex one byte at a time

				$bit_width = @fields;

				# Output header info for first line of alternate format
				if ($drf_format == 1) {

					print tmp_bit "#define $bitmap_name\_width $bit_width\n";
					print tmp_bit "#define $bitmap_name\_height $bit_width\n";
					print tmp_bit "static unsigned char $bitmap_name\_bits[] = \{\n";
					
					$drf_format = 2;		# Set to 2 so it will not execute next line
				}
				
				while (@fields) {	
					$fbyte = bin2hex(pack ("a" x 8, @fields));
					splice (@fields,0,8);
					print tmp_bit "0x$fbyte, ";
				}

				print tmp_bit "\n";

				$row_count = $row_count + 1;						# keep track of how many rows have been written
			}
		}

		if ( $define =~ /packet/i ) {
			if ( /^\s*display\s+/i ) {
				@fields = split (/\s+/, $_) ;
				$packet_name = $fields[1]; 
				$stipple = $fields[2];
				$fill = $fields[4];
				$packet_colors{$packet_name} = "$fill";
				$packet_stipples{$packet_name} = "$stipple";
			}
		}
	}				# end while CDS_DISP 

	if ($row_count > 0) {				# Finished processing drf file - write closing } in last bitmap
		print tmp_bit "\}";
		if ($row_count != $bit_width) {
			print "Bitmap: $bitmap_name \($bit_width x $row_count\) \-\> $bitmap_dir/$bitmap_name.xbm    \<\- please modify $bitmap_name\_height to $row_count \n";
		}
	}

	close( CDS_DISP );			# Close the Display file.
}			       

sub parse_tf_file {

	open( CDS_TF, "$tf_file" )
	|| die "Unable to open file $tf_file for reading.\n";
	my $linecount = 0;
	#print "tf file $tf_file\n";
	while ( <CDS_TF> ) {
		$linecount = $linecount + 1;
		# Make everything uppercase since Calibre is case-insensitive.
		tr/a-z/A-Z/;

		# Remove ; style comments
		chomp;
		#s/(\;|\!|\#).*$//;
		# Remove quotes
		s/\"|\'//g;
		# Remove parenthesis
		s/\(|\)//g;
		# Remove leading white space
		s/^\s+//g;

		&check_section();
		if ( $define =~ /techdisp/i ) {
			if ( /^\s*\w+\s+\w+\s+\w+/i ) {
				@fields = split (/\s+/, $_) ;
				$layer_name_purpose = "$fields[0]_$fields[1]";
				$layer_packet = $fields[2];
				$layer_packets{$layer_name_purpose} = "$layer_packet";
			}
		}
		if ( ($define =~ /streamLayers/i) && ($map_file ne "1") ) {
			if ( /^\s*\w+\s+\w+\s+\d+\s+\d+\s+/i ) {
				@fields = split (/\s+/, $_) ;
				$layer_name_purpose = "$fields[0]_$fields[1]";
				$stream_layer = $fields[2];
				$stream_datatype = $fields[3];
				$translate = $fields[4];

				# Generate layer data for layers with "translate" set to "t" in streamLayers section of technology.tf file

				if ( $translate eq "T" ) {
					# print "$tf_file:$linecount: $layer_name_purpose -> layer:$stream_layer datatype:$stream_datatype translate $translate\n";
					#$stream_layers{$layer_name_purpose} = "$stream_layer";
					#$stream_datatypes{$layer_name_purpose} = "$stream_datatype";
					push @layers_data, [$layer_name_purpose, $stream_layer, $stream_datatype];
				}
			}
		}
	} # end while CDS_TF 
	close( CDS_TF );		# Close the Tech file.
}

sub parse_map_file  {

	open( CDS_MAP, "$map_file" )
	|| die "Unable to open file $map_file for reading.\n";
	my $linecount = 0;
#	print "mapfile $map_file\n";
	while ( <CDS_MAP> ) {       
		$linecount = $linecount + 1;
		# Make everything uppercase since Calibre is case-insensitive.
		tr/a-z/A-Z/;

		# Remove ; ! # style comments
		chomp;
		# s/(\;|\!|\#).*$//;
		# Remove parenthesis
		s/\(|\)//g;
		# Remove leading white space
		s/^\s+//g;

		if ( /^\s*\w+\s+\w+\s+\d+\s+\d+/i ) {
			@fields = split (/\s+/, $_) ;
			$layer_name_purpose = "$fields[0]_$fields[1]";
			$stream_layer = $fields[2];
			$stream_datatype = $fields[3];
			#print "$map_file:$linecount: $layer_name_purpose -> layer:$stream_layer datatype:$stream_datatype\n";
			#$stream_layers{$layer_name_purpose} = "$stream_layer";
			#$stream_datatypes{$layer_name_purpose} = "$stream_datatype";
			push @layers_data, [$layer_name_purpose, $stream_layer, $stream_datatype];
		}
	} # end while CDS_MAP 

	close( CDS_MAP );	# Close the Map file.
}

sub dec2hex {			# Convert Dec to Bin and Call bintohex function
	return &bin2hex(unpack("b32", pack("N", shift)));
}

sub bin2hex {			# Add leading zeros and combines last 8 bits to convert to hex
	return uc(unpack("H2", pack("b8", substr("0" x 8 . shift, -8, 8))));
}

sub check_section {

	if ( /drDefineColor/i ) {
		$define = "color";
	} elsif ( /drDefineStipple/i ) {
		$define = "stipple";
	} elsif ( /drDefinePacket/i ) {
		$define = "packet";
	} elsif ( /techDisplays/i ) {
		$define = "techdisp";
	} elsif ( /streamLayers/i ) {
		$define = "streamLayers";
	} elsif ( /^drDef|^techLayerP|^equivalent/i ) {
		$define = "";
	}
}	    

sub check_usage {
	$disp_file = "";
	$tf_file = "";
	$map_file = "";
	foreach $i (0..$#ARGV) {
		$disp_file = 1 if ($ARGV[$i] =~ /^\-.*disp/i); 
		$tf_file = 1 if ($ARGV[$i] =~ /^\-.*tf/i);
		$map_file = 1 if ($ARGV[$i] =~ /^\-.*map/i); 
	}
	die "Usage: \nconv_cds_drv.pl -tech <techname> -disp <display_file_name> -tf <technology_file_name> [-map <layermap_file_name>].\n\n" unless ($disp_file eq "1" && $tf_file eq "1");
}

sub map_file {
	$map_file = "";
	foreach $i (0..$#ARGV) {
		$map_file = 1 if ($ARGV[$i] =~ /^\-.*map/i); 
	}
}

sub create_bitmap_dir {		# Create directory for bitmaps

	$drv_bitmap_dir = $ENV{'DRV_BITMAP_DIR'};

	if ($drv_bitmap_dir ne "") {									# Check if environment variable is defined
		
		print "\$DRV_BITMAP_DIR \= $drv_bitmap_dir\n";		# If yes create directories accordingly

		print "Creating $drv_bitmap_dir\n\n";					# Create $DRV_BITMAP_DIR directory
		mkdir ("$drv_bitmap_dir",0777);

		$bitmap_dir = $drv_bitmap_dir;

		$symbolic_path = 1;

	} else {
	
		print "Note: \$DRV_BITMAP_DIR not defined\n";		# If not default to $HOME/.calibrewb_workspace

		$HOME = $ENV{'HOME'};
		$drv_dir = "$HOME/.calibrewb_workspace";
		print "Defaulting to $drv_dir\n";

		$drv_bmp_dir = "$drv_dir/bitmaps";
#		print "Creating $drv_bmp_dir\n";
		mkdir ("$drv_bmp_dir",0777);

		$bitmap_dir = "$drv_bmp_dir/$techname";
		print "Creating $bitmap_dir\n\n";
		mkdir ("$bitmap_dir",0777);
	
	}

	# Create blank and solid bitmaps
	
	open( tmp_bit, "> $bitmap_dir\/BLANK.xbm" );
	# Printing header for xbm file
	print tmp_bit "#define BLANK_width 16\n";
	print tmp_bit "#define BLANK_height 16\n";
	print tmp_bit "static unsigned char BLANK_bits[] = \{\n";
	print tmp_bit "0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00,\n0x00, 0x00\n}";

	print "Bitmap: BLANK \(16 x 16\) \-\> $bitmap_dir/BLANK.xbm    \<\- Default bitmap\n";

	open( tmp_bit, "> $bitmap_dir\/SOLID.xbm" );
	# Printing header for xbm file
	print tmp_bit "#define SOLID_width 16\n";
	print tmp_bit "#define SOLID_height 16\n";
	print tmp_bit "static unsigned char SOLID_bits[] = \{\n";
	print tmp_bit "0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF,\n0xFF, 0xFF\n}";

	print "Bitmap: SOLID \(16 x 16\) \-\> $bitmap_dir/SOLID.xbm    \<\- Default bitmap\n";

}
