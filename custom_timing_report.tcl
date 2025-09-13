# ==========================================================
# Custom Timing Report Script - ICC2 / FusionCompiler
# ==========================================================

# Number of paths to analyze
set NUM_PATHS 1000

# Attributes mapping
array set attrList {
    slack                slack
    LogicLevel           logic_levels
    MaxFanout            max_fanout
    InitCellDelay        init_cell_delay
    TotalNetDelay        total_net_delay
    MaxCellDelay         max_cell_delay
    MaxNetDelay          max_net_delay
    MaxDelayPoint        max_net_delay_point
    MaxDelayCell         max_cell_delay_point
    Skew                 endpoint_clock_latency
    StartPoint           startpoint
    EndPoint             endpoint
    ClkDelay             startpoint_clock_latency
    Distance             bbox
    Note                 name
}

# Get worst timing paths
set paths [get_timing_paths -max_paths $NUM_PATHS -nworst $NUM_PATHS -delay_type max]

# Open output file
set rptFile "custom_timing_report.txt"
set fp [open $rptFile w]

puts $fp [format "%-5s %-10s %-12s %-10s %-12s %-12s %-12s %-12s %-15s %-15s %-10s %-12s %-12s %-12s %-12s"
    "ID" "Slack" "LogicLevel" "MaxFanout" "InitCellDelay" "TotalNetDelay" "MaxCellDelay" "MaxNetDelay" "MaxDelayPoint" "MaxDelayCell" "Skew" "StartPoint" "EndPoint" "ClkDelay" "Distance" "Note"
]

set idx 1
foreach_in_collection path $paths {
    # Collect attributes
    set values {}
    foreach key [array names attrList] {
        set val [get_attribute $path $attrList($key)]
        if {$val eq ""} {
            set val "-"
        }
        lappend values $val
    }

    # Print row
    puts $fp [format "%-5s %-10s %-12s %-10s %-12s %-12s %-12s %-12s %-15s %-15s %-10s %-12s %-12s %-12s %-12s %-12s"
        "P_$idx" \
        [lindex $values 0]  ;# Slack
        [lindex $values 1]  ;# LogicLevel
        [lindex $values 2]  ;# MaxFanout
        [lindex $values 3]  ;# InitCellDelay
        [lindex $values 4]  ;# TotalNetDelay
        [lindex $values 5]  ;# MaxCellDelay
        [lindex $values 6]  ;# MaxNetDelay
        [lindex $values 7]  ;# MaxDelayPoint
        [lindex $values 8]  ;# MaxDelayCell
        [lindex $values 9]  ;# Skew
        [lindex $values 10] ;# StartPoint
        [lindex $values 11] ;# EndPoint
        [lindex $values 12] ;# ClkDelay
        [lindex $values 13] ;# Distance
        [lindex $values 14] ;# Note
    ]

    incr idx
}

close $fp
puts ">>> Report generated: $rptFile"
