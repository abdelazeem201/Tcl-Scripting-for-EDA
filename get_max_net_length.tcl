#!/bin/tclsh8.5
#Longest Net

# Convert a collection into a list
proc collection_to_list {a_collection} {
    set my_list {}
    foreach_in_collection item $a_collection {
        lappend my_list [get_object_name $item]
    }
    return $my_list
}

# Define a procedure to get the net with the maximum length in the design
proc get_max_net_length {} {
    # Get the list of all nets in the design by name
    set nets [collection_to_list [get_nets] -no_braces -name_only]

    # Initialize the max length to zero
    set max_length 0
    set max_net ""
    set max_type ""

    # Loop through each net to find the one with the maximum length
    foreach net $nets {
        # Get the routed length (dr_length) of the current net
        set net_len [get_attribute [get_nets $net] dr_length]
        
        # Get the net type (e.g., signal, power, ground, etc.)
        set net_type [get_attribute [get_nets $net] net_type]
        
        # Skip power and ground nets
        if {($net_type != "power") && ($net_type != "ground")} {
            # Check if the current net is longer than the previous max
            if {$net_len > $max_length} {
                set max_length $net_len
                set max_net $net
                set max_type $net_type
            }
        }
    }

    # Print the details of the longest net found
    puts "Longest Net Details: 
==============================================
Net Name   : $max_net
Net Length : $max_length
Net Type   : $max_type
"
}
