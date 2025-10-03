foreach_in_collection cp [get_attribute [get_clocks] sources] {
    set port_name [get_attr $cp name]
    set shape [get_shapes -of_objects $cp]
    set layer [get_attribute $shape layer]
    set layer_name [get_attribute $shape layer_name]
    set layer_min_width [get_attribute $layer min_width]
    set ll_y [get_attribute  $cp bounding_box.ll_y]
    set ur_y [get_attribute $cp bounding_box.ur_y]
    set width [expr $ur_y -$ll_y]
    if {$width<$layer_min_width} {
        puts "Port:$port_name; Layer name & width:$layer_name/$layer_min_width; Port Width:$width"     
    } 
  }

