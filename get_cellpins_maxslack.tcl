################################################################################
# Procedure: get_cellpins_maxslack
# 
# Description:
#   Reports the maximum slack values for all pins of specified cells in a given
#   timing scenario. This is useful for timing analysis and identifying critical
#   paths in digital designs.
#
# Arguments:
#   -cell <cell_pattern>     : Cell name or pattern to analyze (required)
#   -scenario <scenario_name>: Timing scenario to use for analysis (required)
#   -sort_by_slack          : Optional flag to sort output by slack value
#   -show_violations_only   : Optional flag to show only negative slack pins
#   -output_file <filename> : Optional file to write results to
#
# Returns:
#   Nothing (prints results to console and/or file)
#
# Example Usage:
#   get_cellpins_maxslack -cell "CPU_*" -scenario "setup_max"
#   get_cellpins_maxslack -cell "my_cell" -scenario "hold_min" -sort_by_slack
#   get_cellpins_maxslack -cell "critical_path_*" -scenario "setup_max" \
#                         -show_violations_only -output_file "violations.rpt"
################################################################################

proc get_cellpins_maxslack {args} {
    # Parse command line arguments
    parse_proc_arguments -args $args results
    
    # Extract required arguments
    set cells $results(-cell)
    set scenario $results(-scenario)
    
    # Extract optional arguments with defaults
    set sort_by_slack [info exists results(-sort_by_slack)]
    set show_violations_only [info exists results(-show_violations_only)]
    set output_file ""
    if {[info exists results(-output_file)]} {
        set output_file $results(-output_file)
    }
    
    # Store current scenario to restore later
    set original_scenario [current_scenario]
    
    # Validate and switch to target scenario
    if {[catch {current_scenario $scenario} err]} {
        echo "Error: Cannot switch to scenario '$scenario': $err"
        return -code error "Invalid scenario: $scenario"
    }
    
    # Initialize data collection
    set pin_data {}
    set total_pins 0
    set violation_count 0
    
    # Header formatting
    set header_format "%-60s %12s %8s"
    set data_format "%-60s %12.3f %8s"
    set separator [string repeat "-" 85]
    
    # Prepare output (console and/or file)
    set output_lines {}
    
    # Add header
    lappend output_lines [format $header_format "Pin Name" "Max Slack" "Status"]
    lappend output_lines $separator
    
    # Process each cell matching the pattern
    set cell_collection [get_cells $cells -quiet]
    if {[sizeof_collection $cell_collection] == 0} {
        echo "Warning: No cells found matching pattern '$cells'"
        current_scenario $original_scenario
        return
    }
    
    echo "Processing [sizeof_collection $cell_collection] cells..."
    
    # Iterate through each cell
    foreach_in_collection cell_obj $cell_collection {
        set cell_name [get_object_name $cell_obj]
        
        # Get all pins with defined max_slack for this cell
        set pin_collection [get_pins -of_objects [get_cells $cell_name] \
                           -filter "defined(max_slack)" -quiet]
        
        # Process each pin
        foreach_in_collection pin_obj $pin_collection {
            set pin_name [get_object_name $pin_obj]
            
            # Get slack value with error checking
            if {[catch {get_attribute $pin_obj max_slack} slack]} {
                echo "Warning: Could not get max_slack for pin $pin_name"
                continue
            }
            
            # Skip if slack is undefined or empty
            if {$slack == "" || $slack == "INFINITY" || $slack == "-INFINITY"} {
                continue
            }
            
            # Determine status
            set status "OK"
            if {$slack < 0} {
                set status "VIOL"
                incr violation_count
            }
            
            # Filter for violations only if requested
            if {$show_violations_only && $slack >= 0} {
                continue
            }
            
            # Store pin data for potential sorting
            lappend pin_data [list $pin_name $slack $status]
            incr total_pins
        }
    }
    
    # Sort data if requested
    if {$sort_by_slack} {
        # Sort by slack value (ascending - worst slack first)
        set pin_data [lsort -real -index 1 $pin_data]
        lappend output_lines "# Results sorted by slack value (worst first)"
        lappend output_lines ""
    }
    
    # Format and add data lines
    foreach pin_info $pin_data {
        lassign $pin_info pin_name slack status
        lappend output_lines [format $data_format $pin_name $slack $status]
    }
    
    # Add summary
    lappend output_lines ""
    lappend output_lines $separator
    lappend output_lines "Summary:"
    lappend output_lines "  Total pins analyzed: $total_pins"
    lappend output_lines "  Timing violations: $violation_count"
    if {$total_pins > 0} {
        set violation_percent [expr {($violation_count * 100.0) / $total_pins}]
        lappend output_lines "  Violation percentage: [format "%.1f%%" $violation_percent]"
    }
    lappend output_lines "  Scenario: $scenario"
    lappend output_lines "  Cell pattern: $cells"
    
    # Output to console
    foreach line $output_lines {
        echo $line
    }
    
    # Output to file if specified
    if {$output_file != ""} {
        if {[catch {
            set fh [open $output_file "w"]
            foreach line $output_lines {
                puts $fh $line
            }
            close $fh
            echo "\nResults written to: $output_file"
        } err]} {
            echo "Error writing to file '$output_file': $err"
        }
    }
    
    # Restore original scenario
    current_scenario $original_scenario
    
    # Return summary information
    return [list total_pins $total_pins violations $violation_count]
}

################################################################################
# Define procedure attributes for help system integration
################################################################################
define_proc_attributes get_cellpins_maxslack \
    -info "Reports maximum slack values for all pins of specified cells in a timing scenario" \
    -define_args {
        {-cell "Cell name or pattern to analyze" cell string required}
        {-scenario "Timing scenario name for analysis" scenario string required}
        {-sort_by_slack "Sort output by slack value (worst first)" "" boolean optional}
        {-show_violations_only "Show only pins with negative slack" "" boolean optional}
        {-output_file "File to write results to" output_file string optional}
    }

################################################################################
# Helper procedure for quick violation checking
################################################################################
proc check_cell_violations {cell_pattern scenario_name} {
    # Quick wrapper to check only violations
    return [get_cellpins_maxslack -cell $cell_pattern -scenario $scenario_name -show_violations_only -sort_by_slack]
}

################################################################################
# Helper procedure for generating timing reports
################################################################################
proc generate_timing_report {cell_pattern scenario_name report_file} {
    # Generate comprehensive timing report
    echo "Generating timing report for cells: $cell_pattern"
    echo "Scenario: $scenario_name"
    echo "Output file: $report_file"
    
    return [get_cellpins_maxslack -cell $cell_pattern -scenario $scenario_name \
                                 -sort_by_slack -output_file $report_file]
}
