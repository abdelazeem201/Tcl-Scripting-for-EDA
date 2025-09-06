#########################################################################
# Procedure : extract_routing_blockages
# Purpose   : Extracts routing blockages from the design database 
#             and generates equivalent `create_routing_blockage` 
#             commands for recreation or debugging.
#
# Output    : Writes Tcl recreate commands into "routing_blockages.tcl"
#
# Notes     :
#   - Some attributes (name, shadow, maskable) are kept commented 
#     for optional use if needed later.
#   - Handles cases where blockage attributes are empty or boolean.
#   - Properly expands `-net_types` if multiple values are found.
#
#########################################################################

proc extract_routing_blockages {} {

    # Redirect all stdout/stderr into a file with tee
    # So both console and file see the output
    redirect -tee -file routing_blockages.tcl {

        # Suppress ATTR-3 messages to avoid noise when fetching attributes
        suppress_message ATTR-3

        # Loop over all routing blockages in the design
        foreach_in_collection rblkge [get_routing_blockages] {

            # -----------------------------------------------------------
            # Extract relevant attributes of each routing blockage
            # -----------------------------------------------------------
            #set name [get_attribute $rblkge full_name] ;# optional, unique name
            set layer_name                   [get_attribute $rblkge layer_name]
            set boundary                     [get_attribute $rblkge boundary]
            set allow_via_ladder             [get_attribute $rblkge allow_via_ladder]
            set is_allow_metal_fill_only     [get_attribute $rblkge is_allow_metal_fill_only]
            set reserve_for_top_level_routing [get_attribute $rblkge reserve_for_top_level_routing]
            set is_zero_spacing              [get_attribute $rblkge is_zero_spacing]
            #set is_shadow                   [get_attribute $rblkge is_shadow]     ;# rarely used
            #set is_maskable                 [get_attribute $rblkge is_maskable]  ;# rarely used
            set blockage_group_id            [get_attribute $rblkge blockage_group_id]
            set is_external_boundary_blockage [get_attribute $rblkge is_external_boundary_blockage] 
            set is_internal_boundary_blockage [get_attribute $rblkge is_internal_boundary_blockage]
            set net_types                    [get_attribute $rblkge net_types] 

            # -----------------------------------------------------------
            # Start building the recreate command
            # -----------------------------------------------------------
            set cmd "create_routing_blockage -layers $layer_name -boundary \{$boundary\}"

            # Add optional flags based on attribute values
            if {$is_external_boundary_blockage == "true"} {
                set cmd "$cmd -boundary_external"
            }
            if {$is_internal_boundary_blockage == "true"} {
                set cmd "$cmd -boundary_internal"
            }
            if {$is_zero_spacing == "true"} {
                set cmd "$cmd -zero_spacing"
            }
            if {$allow_via_ladder == "true"} {
                set cmd "$cmd -allow_via_ladder"
            }
            if {$is_allow_metal_fill_only == "true"} {
                set cmd "$cmd -allow_metal_fill_only"
            }
            if {$reserve_for_top_level_routing == "true"} {
                set cmd "$cmd -reserve_for_top_level_routing"
            }
            if {$blockage_group_id ne ""} {
                set cmd "$cmd -blockage_group_id $blockage_group_id"
            }

            # Save the base command (without net_types) for reuse
            set cmd1 $cmd 

            # -----------------------------------------------------------
            # Handle net_types if available
            # -----------------------------------------------------------
            if {$net_types ne ""} {
                # If multiple net_types are present (comma-separated list)
                if {[llength [split $net_types ,]] > 1} {
                    set net_types [split $net_types ,]
                    for {set i 0} {$i < [llength $net_types]} {incr i} {
                        set cmd $cmd1
                        set cmd "$cmd -net_types [lindex $net_types $i]"
                        puts $cmd
                    }
                } else {
                    # Single net_type
                    set cmd "$cmd -net_types $net_types"
                    puts $cmd
                }
            } else {
                # No net_types present → print base command
                puts $cmd
            }
        }

        # Re-enable suppressed messages
        unsuppress_message ATTR-3
    }
}
