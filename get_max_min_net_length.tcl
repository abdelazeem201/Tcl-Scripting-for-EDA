# Convert a collection into a list
proc collection_to_list {a_collection} {
    set my_list {}
    foreach_in_collection item $a_collection {
        lappend my_list [get_object_name $item]
    }
    return $my_list
}

# Procedure to find the maximum and minimum net length in the design
proc get_max_min_net_length {} {
    # Get all hierarchical net full names
    set nets [get_attribute [get_nets -hierarchical] full_name]

    # Initialize variables
    set i 0
    set max_length 0.0             ;# max length
    set min_length INF             ;# min length

    # Loop through all nets
    foreach net $nets {
        # Get the routed length (dr_length) for the current net
        set net_length [get_attribute [get_nets $net] dr_length]

        # Skip nets with 0 length (likely unconnected or purely logical)
        if {$net_length != 0} {
            # ----- Check for min length -----
            set min_val [expr {min($min_length, $net_length)}]
            if {$net_length == $min_val} {
                set min_length $net_length
                set min_net [get_attribute $net full_name]
            }

            # ----- Check for max length -----
            set max_val [expr {max($max_length, $net_length)}]
            if {$net_length == $max_val} {
                set max_length $net_length
                set max_net [get_attribute $net full_name]
            }
        }

        # Increment counter and print optional per-net details (can be commented out if too verbose)
        incr i
        puts [format "%-7s %6f %10f %-45s %10f" $i $min_length $max_length $net $net_length]
    }

    # Summary output
    puts "\n**************************************************************"
    puts "The max length net is  : $max_net  -->  $max_length um"
    puts "The min length net is  : $min_net  -->  $min_length um"
    puts "**************************************************************"
}
