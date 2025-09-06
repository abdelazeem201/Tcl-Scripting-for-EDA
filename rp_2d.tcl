#==============================================================================
# Procedure: rp_2d
# Description: Creates a 2D relative placement (RP) group with specified pitch
#              constraints for optimal cell placement and routing
# Author: Enhanced version with improved error handling and documentation
# Version: 2.0
#==============================================================================

proc rp_2d {-cell_list cell_collection -no_of_cells_per_row cells_per_row -x_pitch x_pitch -y_pitch y_pitch -name rp_group_name} {
    
    #--------------------------------------------------------------------------
    # Input Validation and Error Handling
    #--------------------------------------------------------------------------
    
    # Validate that cell collection exists and is not empty
    if {[catch {set cell_collection [get_cells $cell_collection]} error_msg]} {
        puts "ERROR: Failed to get cell collection: $error_msg"
        return -code error "Invalid cell collection specified"
    }
    
    # Get total number of cells in the collection
    set total_cells [sizeof_collection $cell_collection]
    
    if {$total_cells == 0} {
        puts "ERROR: Cell collection is empty"
        return -code error "No cells found in the specified collection"
    }
    
    # Validate numeric inputs
    if {$cells_per_row <= 0} {
        puts "ERROR: Number of cells per row must be positive"
        return -code error "Invalid cells_per_row value: $cells_per_row"
    }
    
    if {$x_pitch <= 0 || $y_pitch <= 0} {
        puts "ERROR: Pitch values must be positive"
        return -code error "Invalid pitch values: x_pitch=$x_pitch, y_pitch=$y_pitch"
    }
    
    #--------------------------------------------------------------------------
    # Get Site Information and Calculate Pitch Parameters
    #--------------------------------------------------------------------------
    
    # Get standard cell site dimensions from the technology library
    set site_height [get_attribute [get_site_defs] height]
    set site_width [get_attribute [get_site_defs] width]
    
    if {$site_height == 0 || $site_width == 0} {
        puts "ERROR: Invalid site dimensions retrieved"
        return -code error "Cannot retrieve valid site dimensions"
    }
    
    # Calculate row pitch in terms of site units
    # Add 1 to ensure minimum spacing, then round up to next integer
    set row_pitch_sites [expr {($y_pitch / $site_height) + 1}]
    set row_pitch_sites [expr {int(ceil($row_pitch_sites))}]
    
    # Calculate column pitch in terms of site units
    set column_pitch_sites [expr {($x_pitch / $site_width) + 1}]
    set column_pitch_sites [expr {int(ceil($column_pitch_sites))}]
    
    #--------------------------------------------------------------------------
    # Calculate RP Group Dimensions
    #--------------------------------------------------------------------------
    
    # Calculate total number of rows needed
    # Based on total cells divided by cells per row, multiplied by row pitch
    # Add 2 extra rows for margin and round up
    set total_rows_needed [expr {($row_pitch_sites * ($total_cells / double($cells_per_row))) + 2}]
    set total_rows [expr {int(ceil($total_rows_needed))}]
    
    # Calculate total columns needed
    set total_columns [expr {int(ceil($column_pitch_sites * $cells_per_row))}]
    
    #--------------------------------------------------------------------------
    # Create the RP Group
    #--------------------------------------------------------------------------
    
    puts "INFO: Creating RP group '$rp_group_name' with dimensions:"
    puts "      - Total cells: $total_cells"
    puts "      - Cells per row: $cells_per_row"
    puts "      - Site dimensions: ${site_width}x${site_height}"
    puts "      - Pitch: X=${x_pitch}, Y=${y_pitch}"
    puts "      - RP grid: ${total_rows}x${total_columns}"
    puts "      - Row pitch: $row_pitch_sites sites"
    puts "      - Column pitch: $column_pitch_sites sites"
    
    # Create the relative placement group with calculated dimensions
    if {[catch {create_rp_group -name $rp_group_name -rows $total_rows -columns $total_columns} error_msg]} {
        puts "ERROR: Failed to create RP group: $error_msg"
        return -code error "RP group creation failed"
    }
    
    #--------------------------------------------------------------------------
    # Place Cells and Create Blockages
    #--------------------------------------------------------------------------
    
    set cell_index 0          ;# Current cell being processed
    set blockage_row_id 0     ;# Row-wise blockage counter
    set blockage_cell_id 0    ;# Cell-wise blockage counter
    
    # Iterate through rows with specified row pitch
    for {set current_row 0} {$current_row < $total_rows} {set current_row [expr {$current_row + $row_pitch_sites}]} {
        
        # Reset column blockage counter for each row
        set blockage_cell_id 0
        
        # Iterate through columns with specified column pitch
        for {set current_col 0} {$current_col < $total_columns} {set current_col [expr {$current_col + $column_pitch_sites}]} {
            
            # Break if all cells have been placed
            if {$cell_index >= $total_cells} {
                break
            }
            
            # Get the current cell from the collection
            set current_cell [index_collection $cell_collection $cell_index]
            incr cell_index
            
            # Add cell to the RP group at calculated position
            if {[catch {add_to_rp_group $rp_group_name -cells $current_cell -row $current_row -column $current_col} error_msg]} {
                puts "WARNING: Failed to add cell $current_cell to RP group: $error_msg"
                continue
            }
            
            # Create horizontal blockage to maintain X pitch spacing
            # Blockage starts at next column and spans the remaining pitch width
            set blockage_start_col [expr {$current_col + 1}]
            set blockage_width [expr {$column_pitch_sites - 1}]
            
            if {$blockage_width > 0} {
                set h_blockage_name "blk_${rp_group_name}_r${blockage_row_id}_c${blockage_cell_id}"
                
                if {[catch {
                    add_to_rp_group $rp_group_name \
                        -blockage $h_blockage_name \
                        -column $blockage_start_col \
                        -width $blockage_width \
                        -row $current_row
                } error_msg]} {
                    puts "WARNING: Failed to create horizontal blockage: $error_msg"
                }
            }
            
            incr blockage_cell_id
        }
        
        # Create vertical blockage to maintain Y pitch spacing
        # Blockage starts at next row and spans the remaining pitch height
        set blockage_start_row [expr {$current_row + 1}]
        set blockage_height [expr {$row_pitch_sites - 1}]
        
        if {$blockage_height > 0} {
            set v_blockage_name "blk_${rp_group_name}_r${blockage_row_id}"
            
            if {[catch {
                add_to_rp_group $rp_group_name \
                    -blockage $v_blockage_name \
                    -row $blockage_start_row \
                    -height $blockage_height
            } error_msg]} {
                puts "WARNING: Failed to create vertical blockage: $error_msg"
            }
        }
        
        incr blockage_row_id
    }
    
    #--------------------------------------------------------------------------
    # Configure RP Group Options
    #--------------------------------------------------------------------------
    
    # Allow non-RP cells to be placed on blockages for flexibility
    if {[catch {set_rp_group_options $rp_group_name -allow_non_rp_cells_on_blockages} error_msg]} {
        puts "WARNING: Failed to set RP group options: $error_msg"
    }
    
    #--------------------------------------------------------------------------
    # Success Message and Summary
    #--------------------------------------------------------------------------
    
    puts "SUCCESS: Created relative placement group '$rp_group_name'"
    puts "         - Placed $cell_index cells out of $total_cells total cells"
    puts "         - Grid dimensions: ${total_rows} rows x ${total_columns} columns"
    puts "         - Pitch constraints: X=${x_pitch}, Y=${y_pitch}"
    
    return $rp_group_name
}

#==============================================================================
# Procedure Attributes Definition
# Defines the command-line interface and help documentation
#==============================================================================

define_proc_attributes rp_2d \
    -info "Creates a 2D relative placement group with specified X and Y pitch constraints for optimal cell placement and routing" \
    -define_args {
        {-cell_list "Collection or list of cell names to be placed in the RP group" cell_names string required}
        {-no_of_cells_per_row "Number of cells to be placed in each row of the RP group" no_of_cells_per_row int required}
        {-x_pitch "Horizontal pitch constraint between cells (in design units)" x_pitch double required}
        {-y_pitch "Vertical pitch constraint between cells (in design units)" y_pitch double required}
        {-name "Name for the relative placement group to be created" name string required}
        {-verbose "Enable verbose output with detailed progress messages" "" boolean optional}
    }

#==============================================================================
# Usage Examples:
#
# The following example uses the `rp_2d` procedure to place cells with a 
# x-pitch of 15.2 and y-pitch of 16.72:
#
# *_shell> source rp_2d.tcl 
# *_shell> set cells [list U1001 U1003 U1005 U1007 U1009 U1011] 
# *_shell> rp_2d -cell_list $cells -no_of_cells_per_row 3 \
#                   -x_pitch 15.2 -y_pitch 16.72 -name rp 
# *_shell> create_placement
#
# # Additional example: Create RP group for a set of memory cells
# rp_2d -cell_list {mem_cell_0 mem_cell_1 mem_cell_2 mem_cell_3} \
#       -no_of_cells_per_row 2 \
#       -x_pitch 10.0 \
#       -y_pitch 15.0 \
#       -name "memory_array_rp"
#
# # Example using a cell collection
# set my_cells [get_cells "cpu_core/alu_*"]
# rp_2d -cell_list $my_cells \
#       -no_of_cells_per_row 4 \
#       -x_pitch 8.5 \
#       -y_pitch 12.0 \
#       -name "alu_placement_rp"
#==============================================================================
