#!/usr/bin/env tclsh
#
# Script Name: check_filler_gaps.tcl
# Designer: Ahmed Abdelazeem
# Date Created: 2025.01.09
# Last Modified: 2025.27.09
# Version: 1.0
#
# Description:
# This script checks for filler cell gaps in a physical design layout.
# It identifies empty spaces between cells that should be filled with filler cells
# to ensure proper manufacturing and DRC compliance. The script supports two modes:
# - Fast mode: Quick gap detection across the entire core area
# - Row-by-row mode: Detailed analysis with precise gap locations
#
# Usage:
# check_filler_gaps [-mode {fast|row_by_row}] [-no_highlight]
#
# Parameters:
# -mode: Specifies checking mode (default: fast)
# -no_highlight: Disables visual highlighting of gaps in GUI
#

proc check_filler_gaps {args} {
    # Create polygon rectangles for all placed cells in the design
    set cells_pr [create_poly_rect -boundary [get_attribute [get_cells -physical_context] boundary]]
    
    # Create polygon rectangle for the core area boundary
    set block_pr [create_poly_rect -boundary [get_attribute [get_core_area] boundary]]
    
    # Parse command line arguments
    parse_proc_arguments -args $args results
    foreach argname [array names results] {
        set $argname $results($argname)
    }
    
    # Set default values for optional parameters
    if {[info exist -mode]} {
        set mode ${-mode}
    } else {
        set mode fast  # Default to fast mode
    }
    
    if {[info exist -no_highlight]} {
        set highlight 0  # Highlighting disabled
    } else {
        set highlight 1  # Highlighting enabled by default
    }
    
    # Check mode and execute appropriate gap detection algorithm
    if {${mode} != "row_by_row"} {
        # FAST MODE: Check gaps across entire core area
        
        # Get hard keepout margins (areas where cells cannot be placed)
        set ko [get_keepout_margins -type hard -quiet]
        # Get hard placement blockages
        set pb [get_placement_blockages -filter "blockage_type == hard" -quiet]
        
        # Process keepout margins if they exist
        if [sizeof_collection $ko] {
            # Create polygon rectangles for keepout areas
            set ko_pr [create_poly_rect -boundary [get_attribute $ko boundary]]
            # Subtract keepout areas from block area (NOT operation)
            set not_ko [compute_polygons -operation not -objects1 $block_pr -objects2 $ko_pr]
        } else {
            # No keepout margins, use entire block area
            set not_ko $block_pr
        }
        
        # Process placement blockages if they exist
        if [sizeof_collection $pb] {
            # Create polygon rectangles for placement blockages
            set pb_pr [create_poly_rect -boundary [get_attribute $pb boundary]]
            # Subtract placement blockages from available area
            set not_pb [compute_polygons -operation not -objects1 $not_ko -objects2 $pb_pr]
        } else {
            # No placement blockages
            set not_pb $not_ko
        }
        
        # Find gaps: subtract cell areas from available placement area
        set not_cells [compute_polygons -operation not -objects1 $not_pb -objects2 $cells_pr]
        # Get the resulting polygon rectangles (these are the gaps)
        set poly_rects [get_attribute $not_cells poly_rects]
        
        # Highlight gaps in GUI if highlighting is enabled
        if {${highlight}} {
            gui_start  # Initialize GUI
            gui_remove_all_annotations  # Clear previous annotations
            
            # Add yellow rectangle annotations for each gap
            foreach_in_collection each $poly_rects {
                set bbox [get_attribute $each bbox]
                gui_add_annotation -window [gui_get_current_window -types Layout -mru] -type rect $bbox -color yellow
            }
        }
        
        # Report total number of gaps found
        puts "There are [sizeof_collection $poly_rects] errors"
        
    } else {
        # ROW-BY-ROW MODE: Detailed gap analysis per site row
        
        # Create polygon rectangles for each site row
        set block_pr [create_poly_rect -boundary [get_attribute [get_site_rows] bbox]]
        set n 0  # Initialize gap counter
        
        # Initialize GUI for highlighting if enabled
        if {${highlight}} {
            gui_start
            gui_remove_all_annotations
        }
        
        # Process each site row individually
        foreach_in_collection row $block_pr {
            # Find gaps in current row: subtract cell areas from row area
            set not_cells [compute_polygons -operation not -objects1 $row -objects2 $cells_pr]
            # Get polygon rectangles for gaps in this row
            set poly_rects [get_attribute $not_cells poly_rects]
            # Add to total gap count
            set n [expr $n + [sizeof_collection $poly_rects]]
            
            # Highlight gaps in current row if highlighting enabled
            if {${highlight}} {
                foreach_in_collection each $poly_rects {
                    set bbox [get_attribute $each bbox]
                    gui_add_annotation -window [gui_get_current_window -types Layout -mru] -type rect $bbox -color yellow
                }
            }
        }
        
        # Report total number of gaps found across all rows
        puts "There are $n errors"
    }
}

# Define procedure attributes for help documentation and argument validation
define_proc_attributes check_filler_gaps \
  -info "Check if any cell gaps exist in the design layout" \
  -define_args {
      {-mode "Checking mode options:
              fast (default): Quickly check if gaps exist across entire core area
              row_by_row: Check row by row to show exact gaps (increased runtime)" \
              token one_of_string {optional value_help {values {fast row_by_row}}}}
      {-no_highlight "Disable visual highlighting of gaps in GUI" "" boolean {optional}}
  }
