#!/usr/bin/env tclsh
#===============================================================================
# MACRO ALIGNMENT CHECKER
#===============================================================================
# Purpose: Validates that all hard macros in the design are properly aligned
#          to the placement site grid in both X and Y dimensions
#
# Author: Enhanced EDA Script
# Version: 2.0
# Compatible with: Synopsys ICC/ICC2, Cadence Innovus
#
# Background:
# - Hard macros must be placed on legal site grid positions
# - X-alignment: Macro origin must align with site row X-boundaries
# - Y-alignment: Macro origin must align with site row Y-boundaries
# - Misaligned macros can cause DRC violations and placement issues
#===============================================================================

proc macroalign {} {
    #---------------------------------------------------------------------------
    # INITIALIZATION AND DATA COLLECTION
    #---------------------------------------------------------------------------
    
    # Collect all hard macros in the current design
    # Hard macros are typically memory blocks, IP cores, or large standard cells
    set all_macros [get_flat_cells -filter "is_hard_macro"]
    set total_macro_count [sizeof_collection $all_macros]
    
    # Validate that macros exist in the design
    if {$total_macro_count == 0} {
        puts "WARNING: No hard macros found in the current design"
        return [list "" ""]
    }
    
    # Initialize collections to store misaligned macros
    # These will accumulate macros that fail alignment checks
    set x_misaligned_macros ""
    set y_misaligned_macros ""
    
    # Initialize counters for detailed reporting
    set x_misaligned_count 0
    set y_misaligned_count 0
    set processed_count 0
    
    #---------------------------------------------------------------------------
    # MAIN ALIGNMENT CHECKING LOOP
    #---------------------------------------------------------------------------
    
    puts "Starting macro alignment validation..."
    puts "Total hard macros to check: $total_macro_count"
    puts [string repeat "=" 60]
    
    # Process each hard macro individually
    foreach_in_collection macro $all_macros {
        incr processed_count
        
        # Extract macro properties
        set macro_name [get_object_name $macro]
        set macro_bbox [get_attribute $macro bbox]          ;# Bounding box
        set macro_origin [get_attribute $macro origin]      ;# Lower-left corner
        set macro_width [get_attribute $macro width]        ;# Macro width
        set macro_height [get_attribute $macro height]      ;# Macro height
        
        # Parse coordinates from origin point {x y}
        set x_macro [lindex $macro_origin 0]
        set y_macro [lindex $macro_origin 1]
        
        # Progress indicator for large designs
        if {$processed_count % 50 == 0} {
            puts "  Processing macro $processed_count of $total_macro_count..."
        }
        
        #-----------------------------------------------------------------------
        # ALIGNMENT STATUS TRACKING
        #-----------------------------------------------------------------------
        
        # Flags to track alignment status (0 = misaligned, 1 = aligned)
        set is_x_aligned 0
        set is_y_aligned 0
        
        # Additional debug information
        set debug_info ""
        set site_rows_checked 0
        
        #-----------------------------------------------------------------------
        # SITE ROW ANALYSIS
        #-----------------------------------------------------------------------
        
        # Get all site rows that intersect with the macro's position
        # Site rows define the legal placement grid
        set relevant_site_rows [get_site_rows -at $macro_origin]
        
        if {[sizeof_collection $relevant_site_rows] == 0} {
            puts "WARNING: No site rows found at macro $macro_name origin $macro_origin"
            append debug_info "No site rows found; "
            continue
        }
        
        # Analyze each relevant site row for alignment
        foreach_in_collection site_row $relevant_site_rows {
            incr site_rows_checked
            
            # Extract site row properties
            set site_origin [get_attribute $site_row origin]
            set site_height [get_attribute $site_row site_height]
            set site_width [get_attribute $site_row site_width]
            set site_name [get_attribute $site_row name]
            
            # Parse site row coordinates
            set x_site_origin [lindex $site_origin 0]
            set y_site_origin [lindex $site_origin 1]
            
            append debug_info "Site:$site_name(${x_site_origin},${y_site_origin}); "
            
            #-------------------------------------------------------------------
            # Y-COORDINATE ALIGNMENT CHECK
            #-------------------------------------------------------------------
            
            # Y-alignment is straightforward: macro Y must equal site row Y
            # This ensures the macro sits exactly on a row boundary
            if {$y_macro == $y_site_origin} {
                set is_y_aligned 1
                append debug_info "Y-aligned; "
            }
            
            #-------------------------------------------------------------------
            # X-COORDINATE ALIGNMENT CHECK
            #-------------------------------------------------------------------
            
            # X-alignment is more complex: macro X must align with site boundaries
            # Sites are arranged in a regular grid pattern
            
            if {$x_macro >= $x_site_origin} {
                # Calculate which site boundary the macro should align to
                # Formula: site_number = floor((macro_x - site_origin_x) / site_width)
                set relative_distance [expr $x_macro - $x_site_origin]
                
                # Handle potential floating point precision issues
                set site_offset [expr int($relative_distance / $site_width + 0.0001)]
                
                # Calculate the expected aligned X coordinate
                set expected_x [expr $x_site_origin + ($site_offset * $site_width)]
                
                # Check if macro is exactly aligned (within floating point tolerance)
                set alignment_tolerance 0.001  ;# Allow small floating point errors
                set x_difference [expr abs($x_macro - $expected_x)]
                
                if {$x_difference < $alignment_tolerance} {
                    set is_x_aligned 1
                    append debug_info "X-aligned(offset:$site_offset); "
                } else {
                    append debug_info "X-misaligned(expected:$expected_x,actual:$x_macro,diff:$x_difference); "
                }
            } else {
                # Macro is to the left of this site row origin
                append debug_info "X-before-site-origin; "
            }
        }
        
        #-----------------------------------------------------------------------
        # COLLECT MISALIGNED MACROS
        #-----------------------------------------------------------------------
        
        # Add macro to appropriate misalignment collections
        if {!$is_x_aligned} {
            append_to_collection x_misaligned_macros $macro
            incr x_misaligned_count
        }
        
        if {!$is_y_aligned} {
            append_to_collection y_misaligned_macros $macro
            incr y_misaligned_count
        }
        
        # Verbose debug output for problematic macros
        if {!$is_x_aligned || !$is_y_aligned} {
            puts "  MISALIGNED: $macro_name at ($x_macro,$y_macro) - X:$is_x_aligned Y:$is_y_aligned"
            puts "    Size: ${macro_width}x${macro_height}, Sites checked: $site_rows_checked"
            puts "    Debug: $debug_info"
        }
    }
    
    #---------------------------------------------------------------------------
    # COMPREHENSIVE REPORTING
    #---------------------------------------------------------------------------
    
    puts [string repeat "=" 60]
    puts "MACRO ALIGNMENT VALIDATION REPORT"
    puts [string repeat "=" 60]
    puts "Design Statistics:"
    puts "  Total hard macros processed: $total_macro_count"
    puts "  X-misaligned macros: $x_misaligned_count"
    puts "  Y-misaligned macros: $y_misaligned_count"
    puts "  Properly aligned macros: [expr $total_macro_count - $x_misaligned_count - $y_misaligned_count + [expr {$x_misaligned_count > 0 && $y_misaligned_count > 0 ? [sizeof_collection [collection_intersection $x_misaligned_macros $y_misaligned_macros]] : 0}]]"
    
    # Calculate alignment percentage
    set total_checks [expr $x_misaligned_count + $y_misaligned_count]
    set alignment_percentage [expr $total_checks > 0 ? 100.0 * ($total_macro_count * 2 - $total_checks) / ($total_macro_count * 2) : 100.0]
    puts "  Overall alignment rate: [format "%.1f" $alignment_percentage]%"
    
    #---------------------------------------------------------------------------
    # DETAILED MISALIGNMENT REPORTS
    #---------------------------------------------------------------------------
    
    if {$x_misaligned_count > 0} {
        puts "\n" [string repeat "-" 40]
        puts "X-COORDINATE MISALIGNED MACROS ($x_misaligned_count found):"
        puts [string repeat "-" 40]
        
        set x_report_count 0
        foreach_in_collection macro $x_misaligned_macros {
            incr x_report_count
            set name [get_object_name $macro]
            set origin [get_attribute $macro origin]
            set size_info "[get_attribute $macro width]x[get_attribute $macro height]"
            
            puts [format "  %3d. %-25s at %-15s size: %s" $x_report_count $name $origin $size_info]
            
            # Limit output for very large lists
            if {$x_report_count >= 20 && $x_misaligned_count > 20} {
                puts "  ... and [expr $x_misaligned_count - 20] more macros"
                break
            }
        }
    }
    
    if {$y_misaligned_count > 0} {
        puts "\n" [string repeat "-" 40]
        puts "Y-COORDINATE MISALIGNED MACROS ($y_misaligned_count found):"
        puts [string repeat "-" 40]
        
        set y_report_count 0
        foreach_in_collection macro $y_misaligned_macros {
            incr y_report_count
            set name [get_object_name $macro]
            set origin [get_attribute $macro origin]
            set size_info "[get_attribute $macro width]x[get_attribute $macro height]"
            
            puts [format "  %3d. %-25s at %-15s size: %s" $y_report_count $name $origin $size_info]
            
            # Limit output for very large lists
            if {$y_report_count >= 20 && $y_misaligned_count > 20} {
                puts "  ... and [expr $y_misaligned_count - 20] more macros"
                break
            }
        }
    }
    
    #---------------------------------------------------------------------------
    # RECOMMENDATIONS AND NEXT STEPS
    #---------------------------------------------------------------------------
    
    if {$x_misaligned_count == 0 && $y_misaligned_count == 0} {
        puts "\n" [string repeat "=" 60]
        puts "✓ VALIDATION PASSED: All macros are properly aligned!"
        puts "  No alignment corrections required."
        puts [string repeat "=" 60]
    } else {
        puts "\n" [string repeat "=" 60]
        puts "⚠ VALIDATION FAILED: Alignment issues detected"
        puts "\nRecommended Actions:"
        
        if {$x_misaligned_count > 0} {
            puts "  1. Review X-misaligned macros and adjust placement"
            puts "     Command: place_macro -macro_name <name> -location {x y}"
        }
        
        if {$y_misaligned_count > 0} {
            puts "  2. Review Y-misaligned macros and adjust placement"
            puts "     Ensure macro Y-coordinates match site row origins"
        }
        
        puts "  3. Re-run this script after corrections"
        puts "  4. Consider using 'legalize_placement -macro' if available"
        puts [string repeat "=" 60]
    }
    
    #---------------------------------------------------------------------------
    # RETURN COLLECTIONS FOR FURTHER PROCESSING
    #---------------------------------------------------------------------------
    
    # Return both collections so calling scripts can process them
    # Usage: set result [macroalign]; set x_bad [lindex $result 0]
    return [list $x_misaligned_macros $y_misaligned_macros]
}

#===============================================================================
# HELPER PROCEDURES
#===============================================================================

# Additional utility procedure to fix common alignment issues
proc fix_macro_alignment {macro_list} {
    puts "Attempting to fix alignment for [sizeof_collection $macro_list] macros..."
    
    foreach_in_collection macro $macro_list {
        set macro_name [get_object_name $macro]
        set current_origin [get_attribute $macro origin]
        
        # This would need to be implemented based on your EDA tool's capabilities
        puts "  Would fix: $macro_name at $current_origin"
        # legalize_placement -macro $macro_name
    }
}

# Procedure to generate alignment report file
proc generate_alignment_report {filename} {
    set report_file [open $filename "w"]
    
    # Redirect puts to file temporarily (implementation depends on tool)
    puts $report_file "Macro Alignment Report Generated: [clock format [clock seconds]]"
    puts $report_file [string repeat "=" 60]
    
    # Call main procedure and capture output
    set result [macroalign]
    
    close $report_file
    puts "Alignment report saved to: $filename"
    return $result
}

#===============================================================================
# USAGE EXAMPLES
#===============================================================================
# 
# Basic usage:
#   macroalign
# 
# Capture results for processing:
#   set alignment_results [macroalign]
#   set x_misaligned [lindex $alignment_results 0]
#   set y_misaligned [lindex $alignment_results 1]
# 
# Generate report file:
#   generate_alignment_report "macro_alignment_report.txt"
#
#===============================================================================
