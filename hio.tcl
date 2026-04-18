proc hio {} {

    #--------------------------------------------------
    # Clear previous annotations
    #--------------------------------------------------
    remove_annotation_shapes -all

    #--------------------------------------------------
    # Get selected cells
    #--------------------------------------------------
    set cells [get_attribute [get_selection] full_name]

    foreach cell $cells {

        #----------------------------------------------
        # Cache flat cell (IMPORTANT for performance)
        #----------------------------------------------
        set flat_cell [get_flat_cells $cell]

        # Cell origin
        set cur_loc [get_attr $flat_cell origin]

        #----------------------------------------------
        # OUT pins (fanout side)
        #----------------------------------------------
        set out_pins [get_pins -of_objects $flat_cell -filter "direction==out"]

        set all_ep [all_fanout -from $out_pins -flat -endpoints_only]

        #----------------------------------------------
        # IN pins (fanin side)
        #----------------------------------------------
        set in_pins [get_pins -of_objects $flat_cell \
            -filter "direction==in && name!=SI && name!=SE && name!=CD && name!=CP"]

        set all_sp [all_fanin -to $in_pins -flat -startpoints_only]

        #==================================================
        # 🔶 FANOUT (YELLOW)
        #==================================================
        foreach_in_collection ep $all_ep {

            set ep_loc  [get_attr $ep bounding_box.ll]
            set ep_type [get_attr $ep object_class]
            set ep_name [get_object_name $ep]

            if { $ep_type == "port" &&
                 $ep_name ne "reset" &&
                 ![regexp ^test_se $ep_name] } {

                # Arrow: cell → endpoint
                create_annotation_shape \
                    -type line -line_arrow -color yellow -pen_width 3 \
                    -label $ep_name \
                    -annotation_points [list $cur_loc $ep_loc]

                # Box around port
                create_annotation_shape \
                    -type rect -color yellow \
                    -annotation_points [get_attr $ep bbox]

            } else {

                # Internal endpoint
                create_annotation_shape \
                    -type line -line_arrow -color yellow -pen_width 3 \
                    -annotation_points [list $cur_loc $ep_loc]

                create_annotation_shape \
                    -type rect -color yellow \
                    -annotation_points [get_attr [get_cells -of $ep] bbox]
            }
        }

        #==================================================
        # 🔴 FANIN (RED)
        #==================================================
        foreach_in_collection sp $all_sp {

            set sp_loc  [get_attr $sp bounding_box.ll]
            set sp_type [get_attr $sp object_class]
            set sp_name [get_object_name $sp]

            if { $sp_type == "port" &&
                 $sp_name ne "reset" &&
                 ![regexp ^test_se $sp_name] &&
                 ![regexp {^cts\d+$} $sp_name] &&
                 ![regexp {^syn_insert_te} $sp_name] } {

                # Arrow: startpoint → cell
                create_annotation_shape \
                    -type line -line_arrow -color red -pen_width 3 \
                    -label $sp_name \
                    -annotation_points [list $sp_loc $cur_loc]

                create_annotation_shape \
                    -type rect -color red \
                    -annotation_points [get_attr $sp bbox]

            } else {

                create_annotation_shape \
                    -type line -line_arrow -color red -pen_width 3 \
                    -annotation_points [list $sp_loc $cur_loc]

                create_annotation_shape \
                    -type rect -color red \
                    -annotation_points [get_attr [get_cells -of $sp] bbox]
            }
        }
    }
}
