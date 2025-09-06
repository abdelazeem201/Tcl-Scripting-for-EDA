# Enhanced Clock Port Width Checker
# Checks if clock port widths meet layer minimum width requirements
# Author: Enhanced version
# Date: [Current Date]

proc check_clock_port_widths {} {
    # Initialize counters and collections
    set violation_count 0
    set total_ports 0
    set violations_list {}
    
    # Header for output
    puts "=========================================="
    puts "Clock Port Width Analysis Report"
    puts "=========================================="
    puts ""
    
    # Get all clock sources
    set clocks [get_clocks]
    if {[llength $clocks] == 0} {
        puts "WARNING: No clocks found in design"
        return
    }
    
    puts "Found [llength $clocks] clock(s) in design"
    puts ""
    
    # Process each clock port
    foreach_in_collection clock_port [get_attribute $clocks sources] {
        incr total_ports
        
        # Get port attributes with error checking
        if {[catch {set port_name [get_attribute $clock_port name]} err]} {
            puts "ERROR: Cannot get port name for clock port #$total_ports: $err"
            continue
        }
        
        if {[catch {set shape [get_shapes -of_objects $clock_port]} err]} {
            puts "WARNING: No shape found for port '$port_name': $err"
            continue
        }
        
        # Get layer information
        if {[catch {
            set layer [get_attribute $shape layer]
            set layer_name [get_attribute $layer name]
            set layer_min_width [get_attribute $layer min_width]
        } err]} {
            puts "ERROR: Cannot get layer information for port '$port_name': $err"
            continue
        }
        
        # Get port dimensions
        if {[catch {
            set ll_y [get_attribute $clock_port bounding_box.ll_y]
            set ur_y [get_attribute $clock_port bounding_box.ur_y]
        } err]} {
            puts "ERROR: Cannot get bounding box for port '$port_name': $err"
            continue
        }
        
        # Calculate width
        set port_width [expr {$ur_y - $ll_y}]
        
        # Check for violation
        if {$port_width < $layer_min_width} {
            incr violation_count
            
            # Store violation details
            set violation_info [list \
                port_name $port_name \
                layer_name $layer_name \
                required_width $layer_min_width \
                actual_width $port_width \
                violation_amount [expr {$layer_min_width - $port_width}] \
            ]
            lappend violations_list $violation_info
            
            # Print violation with enhanced formatting
            puts "VIOLATION: Port '$port_name'"
            puts "  Layer: $layer_name"
            puts "  Required Width: $layer_min_width"
            puts "  Actual Width: $port_width"
            puts "  Shortage: [expr {$layer_min_width - $port_width}]"
            puts "  Coordinates: Y($ll_y, $ur_y)"
            puts ""
        } else {
            # Optional: Print passing ports (uncomment if needed)
            # puts "PASS: Port '$port_name' - Width: $port_width (Required: $layer_min_width)"
        }
    }
    
    # Summary report
    puts "=========================================="
    puts "SUMMARY REPORT"
    puts "=========================================="
    puts "Total clock ports analyzed: $total_ports"
    puts "Width violations found: $violation_count"
    puts "Pass rate: [expr {$total_ports > 0 ? (($total_ports - $violation_count) * 100.0 / $total_ports) : 0}]%"
    puts ""
    
    if {$violation_count > 0} {
        puts "ACTION REQUIRED: $violation_count port(s) need width adjustment"
        
        # Generate fix suggestions
        puts ""
        puts "SUGGESTED FIXES:"
        puts "----------------------------------------"
        foreach violation $violations_list {
            array set v $violation
            puts "Port '$v(port_name)': Increase width by $v(violation_amount) (from $v(actual_width) to $v(required_width))"
        }
    } else {
        puts "All clock ports meet minimum width requirements ✓"
    }
    
    puts ""
    puts "Analysis complete."
    
    # Return violation count for scripting
    return $violation_count
}

# Enhanced version with additional utility functions
proc export_violations_to_file {filename} {
    # Re-run analysis and export to file
    set fp [open $filename "w"]
    puts $fp "# Clock Port Width Violations Report"
    puts $fp "# Generated on [clock format [clock seconds]]"
    puts $fp ""
    
    # Redirect puts to file temporarily
    set old_stdout [dup stdout]
    close stdout
    open $filename "a"
    
    # Run the check
    check_clock_port_widths
    
    # Restore stdout
    close stdout
    dup $old_stdout stdout
    close $old_stdout
    
    puts "Violations report exported to: $filename"
}

proc get_violation_summary {} {
    # Return structured data about violations
    set violations {}
    
    foreach_in_collection clock_port [get_attribute [get_clocks] sources] {
        set port_name [get_attribute $clock_port name]
        set shape [get_shapes -of_objects $clock_port]
        set layer [get_attribute $shape layer]
        set layer_name [get_attribute $layer name]
        set layer_min_width [get_attribute $layer min_width]
        set ll_y [get_attribute $clock_port bounding_box.ll_y]
        set ur_y [get_attribute $clock_port bounding_box.ur_y]
        set port_width [expr {$ur_y - $ll_y}]
        
        if {$port_width < $layer_min_width} {
            lappend violations [list $port_name $layer_name $port_width $layer_min_width]
        }
    }
    
    return $violations
}

# Main execution
puts "Clock Port Width Checker - Enhanced Version"
puts "Type 'check_clock_port_widths' to run analysis"
puts "Type 'export_violations_to_file <filename>' to export report"
puts "Type 'get_violation_summary' to get structured violation data"

# Uncomment to run automatically:
# check_clock_port_widths
