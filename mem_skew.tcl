###############################################################################
# mem_skew_icc2.tcl
#
# Description:
#   Analyze timing paths TO and FROM memory macros in ICC2.
#
#   For every RAM instance, report:
#
#       WNS_FROM  : Worst slack on RAM -> Register paths
#       TNS_FROM  : Total negative slack on RAM -> Register paths
#
#       WNS_TO    : Worst slack on Register -> RAM paths
#       TNS_TO    : Total negative slack on Register -> RAM paths
#
# Purpose:
#
#   Help identify memories that are good candidates for useful clock skew.
#
###############################################################################


###########################################################################
# Sum a Tcl list
###########################################################################
proc sum_list {lst} {

    set total 0.0

    foreach val $lst {
        set total [expr {$total + $val}]
    }

    return $total
}


###########################################################################
# Analyze memories
###########################################################################
proc mem_skew_icc2 { {inst_pattern *} {lib_pattern *ram*} {neg_only false} } {

    #######################################################################
    # Find RAMs
    #######################################################################

    set memories [get_cells $inst_pattern \
        -hier \
        -filter "ref_name =~ $lib_pattern && is_hierarchical==false"]


    puts ""
    puts "=============================================================================================================="
    puts [format "%-45s %10s %10s %10s %10s" \
        "Instance" "WNS_FROM" "TNS_FROM" "WNS_TO" "TNS_TO"]
    puts "=============================================================================================================="


    #######################################################################
    # Loop over every RAM
    #######################################################################

    foreach_in_collection mem $memories {

        set inst [get_object_name $mem]

        ###############################################################
        # FROM RAM
        ###############################################################

        set from_paths \
            [get_timing_paths \
                -from $mem \
                -max_paths 1000 \
                -slack_lesser_than 0.0]

        set WNS_FROM 999
        set TNS_FROM 0

        if {[sizeof_collection $from_paths] > 0} {

            set WNS_FROM \
                [get_attribute \
                    [index_collection $from_paths 0] \
                    slack]

            set slacks [get_attribute $from_paths slack]

            set TNS_FROM [sum_list $slacks]

        } else {

            set worst \
                [get_timing_paths \
                    -from $mem \
                    -max_paths 1]

            if {[sizeof_collection $worst]} {

                set WNS_FROM \
                    [get_attribute \
                        [index_collection $worst 0] \
                        slack]
            }

            set TNS_FROM 0
        }


        ###############################################################
        # TO RAM
        ###############################################################

        set to_paths \
            [get_timing_paths \
                -to $mem \
                -max_paths 1000 \
                -slack_lesser_than 0.0]

        set WNS_TO 999
        set TNS_TO 0

        if {[sizeof_collection $to_paths] > 0} {

            set WNS_TO \
                [get_attribute \
                    [index_collection $to_paths 0] \
                    slack]

            set slacks [get_attribute $to_paths slack]

            set TNS_TO [sum_list $slacks]

        } else {

            set worst \
                [get_timing_paths \
                    -to $mem \
                    -max_paths 1]

            if {[sizeof_collection $worst]} {

                set WNS_TO \
                    [get_attribute \
                        [index_collection $worst 0] \
                        slack]
            }

            set TNS_TO 0
        }


        ###############################################################
        # Print
        ###############################################################

        if {$neg_only} {

            if {$TNS_FROM < 0 || $TNS_TO < 0} {

                puts [format \
                    "%-45s %10.3f %10.3f %10.3f %10.3f" \
                    $inst \
                    $WNS_FROM \
                    $TNS_FROM \
                    $WNS_TO \
                    $TNS_TO]
            }

        } else {

            puts [format \
                "%-45s %10.3f %10.3f %10.3f %10.3f" \
                $inst \
                $WNS_FROM \
                $TNS_FROM \
                $WNS_TO \
                $TNS_TO]
        }
    }

    puts "=============================================================================================================="
}
