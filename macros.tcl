#!/bin/tclsh8.5
#####################################################
# Script to Automatically Generate Macro Placement  #
# Two Methods to Create 'macro.tcl' with Commands   #
#####################################################

#######################
# Method 1: Append Mode
# Appends new placement commands to an existing file
#######################

# Open output file in append mode
set fw [open "macro.tcl" a]

# Loop through each hard macro in the hierarchy
foreach macro [get_object_name [get_cells -design [current_blocks] -hierarchical -filter "is_hard_macro == true"]] {

    # Get attributes: orgin, bbox and orientation
    set origin  [get_attribute $macro origin]
    set bbox  [get_attribute $macro bbox]
    set orient [get_attribute $macro orientation]

    # Extract x and y coordinates from bbox
    set x [lindex $bbox 0]
    set y [lindex $bbox 1]

    # Write placement command to file
    puts $fw "set_cell_location -coordinates \{$x $y\} -orientation $orient $macro"
}

# Close the file
close $fw


#######################
# Method 2: Write Mode
# Overwrites 'macro.tcl' with fresh placement commands
#######################

# Get list of hard macros once
set macros [get_object_name [get_cells -hierarchical -filter "is_hard_macro == true"]]

# Open output file in write mode (overwrite)
set fw [open "macro.tcl" w]

# Loop through each macro
foreach macro $macros {

    # Get bbox and orientation
    set bbox  [get_attribute $macro bbox]
    set orient [get_attribute $macro orientation]

    # Extract x and y coordinates
    set x [lindex $bbox 0]
    set y [lindex $bbox 1]

    # Write placement command
    puts $fw "set_cell_location -coordinates \{$x $y\} -orientation $orient $macro"
}

# Close the file
close $fw
