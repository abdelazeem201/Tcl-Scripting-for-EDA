# Script to Get Floating PG Pins

set fp [ open "output.rpt" "w"] 
set PG_PINs [get_pins -filter "port_type==power || port_type == ground" -hierarchical -physical_context]

foreachin_collection pin $PG_PINs {
    set net [get_nets -quiet -physical_context -of_objects $pin]
    if {$net==""} {
      set pin_out [get_object_name $pin]
      #echo "$pin_out"
      puts $fp "$pin_out"
    }
}


# Script extracts levels of logic (LOL paths) and other timing related information from FC and ICC2
set FH1 [open "timing_info.rpt" w]
foreach_in_collection timing_path [get_timing_paths -group <group_name>  -slack_lesser_than 0.00 -start_end_pair] {
        set start [get_object_name [get_attribute $timing_path startpoint ]]
        set end [get_object_name [get_attribute $timing_path endpoint ]]
        set Slack [get_attribute $timing_path slack ]
        set margin [get_attr [get_timing_paths -to [get_cells -of $start]] slack]
        set number_of_pins [sizeof [ get_attribute $timing_path points ]]
        set number_of_cells [expr [expr $number_of_pins - 3] /2]
        puts $FH1 "LOL: $number_of_cells\tslack: $Slack\tMargin: $margin\tStartpoint: $start\tEndpoint:$end\n"
}

# Replacing Cells in a Specific Timing Path with SVT, HVT, or RVT Cells
set c [get_cells -of_objects [get_pins [get_object_name [get_attr [get_timing_paths -from I_BLENDER_0/s3_op1_reg[19]/CLK -to I_BLENDER_0/s4_op1_reg[15]/D] points]]]]

set cells_with_rvt [get_cells $c  -filter "ref_name =~ *RVT" -hierarchical]

foreach_in_collection d1 $cells_with_rvt {

        echo [get_object_name $d1]

        set h_lib_cell [lindex [split [get_attr [get_lib_cells -of_objects [get_cells [get_object_name $d1] ]] name] _] 0]_HVT

        if {[sizeof_collection [get_lib_cells [get_object_name $h_lib_cell]]] == 1 } {

        size_cell -lib_cell [get_lib_cells [get_object_name $h_lib_cell]] [get_cells [get_object_name $d1] ]

}  }


#remove the null shapes and vias
set shps [get_shapes [remove_from_collection [get_shapes] [get_shapes -filter net.full_name=~*]]]
set vias [get_vias [remove_from_collection [get_vias] [get_vias -filter net.full_name=~*]]]

set a [sizeof_collection $shps]
puts "number of null shapes= $a"

if {$a > 0} {
    remove_shapes [ get_shapes [remove_from_collection [get_shapes] [get_shapes -filter net.full_name=~*]]] -force
}

set b [sizeof_collection $vias]
puts "number of null vias= $b"

if {$b > 0} {
    remove_vias [get_vias [remove_from_collection [get_vias] [get_vias -filter net.full_name=~*]]] -force
}
