#########################################################################
# Script : nearest_flop_to_pin.tcl
# Author : Ahmed Abdelazeem
# Purpose: Find the nearest register (flop) to a given pin in the design
#
# This utility is useful for physical design engineers who want to:
#   - Debug placement issues
#   - Check timing proximity of pins to registers
#   - Evaluate floorplan quality and logical/physical correlation
#
#########################################################################

#-----------------------------------------------------------------------
# Procedure: nearest_flop_to_pin
# Arguments:
#   -pin <pin_name> : The pin for which you want to find the nearest flop
#
# Functionality:
#   1. Parse the user-provided pin name
#   2. Extract the center coordinates of the pin bounding box
#   3. Iterate over all registers (flops) in the design
#   4. For each flop:
#        - Extract its bounding box
#        - Compute its center coordinates
#        - Calculate the Euclidean distance to the pin
#   5. Track the flop with the minimum distance
#   6. Print and return the closest flop name and distance
#
# Returns:
#   A list of two elements:
#     { flop_name  distance_in_microns }
#
# Example:
#   nearest_flop_to_pin -pin *reg*/Y
#
#   Output:
#     The minimum distant flop is */*/*reg[7][24] and distance is 23.2481420475 microns
#
#-----------------------------------------------------------------------

proc nearest_flop_to_pin {args} {
    # Step 1: Parse user arguments
    parse_proc_arguments -args $args arg_values
    set pin $arg_values(-pin)

    # Step 2: Extract pin center coordinates
    # bbox format: {{llx lly} {urx ury}}
    # Take midpoint between lower-left and upper-right corners
    set pin_x [expr ([lindex [get_attribute $pin bbox] 0 0] + [lindex [get_attribute $pin bbox] 1 0]) / 2.0]
    set pin_y [expr ([lindex [get_attribute $pin bbox] 0 1] + [lindex [get_attribute $pin bbox] 1 1]) / 2.0]

    # Step 3: Collect all registers in the design
    set all_reg [all_registers]
    if {[sizeof_collection $all_reg] == 0} {
        puts "No registers found in design."
        return
    }

    # Step 4: Initialize tracking variables
    set min_distance {}
    set min_distant_flop {}

    # Step 5: Iterate through each register
    foreach_in_collection ff $all_reg {
        # Extract flop bbox center
        set ff_x [expr ([lindex [get_attribute $ff bbox] 0 0] + [lindex [get_attribute $ff bbox] 1 0]) / 2.0]
        set ff_y [expr ([lindex [get_attribute $ff bbox] 0 1] + [lindex [get_attribute $ff bbox] 1 1]) / 2.0]

        # Compute Euclidean distance between pin and flop centers
        set distance [expr sqrt(pow(($ff_x - $pin_x),2) + pow(($ff_y - $pin_y),2))]

        # Update nearest flop if this distance is smaller
        if {$min_distance eq {} || $distance < $min_distance} {
            set min_distance $distance
            set min_distant_flop [get_object_name $ff]
        }
    }

    # Step 6: Print result to terminal
    puts "Nearest flop to pin $pin is $min_distant_flop at distance $min_distance microns"

    # Step 7: Return result for automation or scripting usage
    return [list $min_distant_flop $min_distance]
}

# Register procedure attributes (for help/documentation in tool)
define_proc_attributes nearest_flop_to_pin \
    -info "Returns the nearest flop name and distance (microns) from a given pin" \
    -define_args {{-pin "pin_name" pin string required}}
