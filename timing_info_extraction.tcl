#!/bin/tclsh8.5
#############################################################
# TCL Script to Parse Report Timing File and Extract Info   #
# Extracts: Startpoints, Endpoints, Path Groups, Nets, Slack#
#############################################################

# Prompt user for max_paths and delay_type
puts -nonewline "Max_Paths are: "
flush stdout
gets stdin m

puts -nonewline "Delay_Type: "
flush stdout
gets stdin dt

# Generate report_timing file
set cmd "report_timing -max_paths $m -delay_type $dt -slack_lesser_than 0 -nets -nosplit > report_timing.rpt"
eval $cmd

# Open the generated report file for reading
set fp [open "report_timing.rpt" r]

# Initialize list to store startpoints
set sp_list {}

# Read and process the file line by line
set i 0
while {[gets $fp li] >= 0} {

    # Startpoint
    if {[lindex $li 0] == "Startpoint:"} {
        set sp [lindex $li 1]
        puts "$i     Start_Point: $sp"
        lappend sp_list $sp
    }

    # Endpoint
    if {[lindex $li 0] == "Endpoint:"} {
        set ep [lindex $li 1]
        puts "     End_Point: $ep"
    }

    # Path Group
    if {[lindex $li 0] == "Path" && [lindex $li 1] == "Group:"} {
        set pg [lindex $li 2]
        puts "     Path_Group: $pg"
    }

    # Fanout Nets and Net Driving
    if {[lindex $li 0] == "(net)" && [llength $li] > 5} {
        set net [lindex $li 2]
        set driver [lindex $li 4]
        puts "     Fanout_Nets: $net     Net_driving: $driver"
    }

    # Slack
    if {[lindex $li 0] == "slack"} {
        set slack [lindex $li 2]
        puts "     Slack_Value: $slack"
        puts ""  ;# print newline for readability
        incr i   ;# increment counter for startpoints
    }
}

# Close the file after parsing
close $fp
