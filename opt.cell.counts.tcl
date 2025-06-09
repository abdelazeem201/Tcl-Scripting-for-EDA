#!/bin/tclsh8.5
#########################################################################
# TCL Script to Count Buffers per Block during Optimization             #
# It counts: Normal Buffers, Inverters, Clock Buffers, Delay Buffers    #
# Output is saved in: buffers_count.rpt                                 #
#########################################################################

# Open file to write buffer count report
set fw [open "buffers_count.rpt" a]

# Add header with current date/time
puts $fw "\n### Buffer Count Report (Generated on [clock format [clock seconds]]) ###\n"

# Read list of blocks from a file (one block per line)
set sfr [open "lib.rpt" r]
set list_blocks [split [read $sfr] "\n"]
close $sfr

# Process each block
foreach pat $list_blocks {
    if {[string trim $pat] ne ""} {
        puts $fw "------------------------------------------------------------"
        puts $fw "Block: $pat"
        puts $fw "------------------------------------------------------------"

        # Open block design
        open_block $pat

        # Count each buffer type using reference name filters
        set bnb [sizeof_collection [get_cells -hierarchical -filter "ref_name =~ BUFF*"]]
        set bin [sizeof_collection [get_cells -hierarchical -filter "ref_name =~ INV*"]]
        set bcb [sizeof_collection [get_cells -hierarchical -filter "ref_name =~ CKB*"]]
        set bdb [sizeof_collection [get_cells -hierarchical -filter "ref_name =~ DEL*"]]
        set bec [sizeof_collection [get_cells -hierarchical -filter "ref_name =~ ECH*"]]

        # Report each type
        puts $fw "Normal_Buffers : $bnb"
        puts $fw "Inverters      : $bin"
        puts $fw "Clock_Buffers  : $bcb"
        puts $fw "Delay_Buffers  : $bdb"
        puts $fw "Echo_Buffers   : $bec"

        # Total
        set total [expr {$bnb + $bin + $bcb + $bdb + $bec}]
        puts $fw "Total Buffers  : $total\n"

        # Optionally show utilization for verification
        puts $fw "Utilization    : [report_utilization -of_objects [get_voltage_areas] ]\n"
    }
}

# Close the report file
close $fw
