# --------------------------------------------------------
# Procedure : sort_by_area
# Purpose   : Sort the design blocks according to their area
# Inputs    :
#   decoder_list - List of design blocks (global 'decoder')
# Globals   :
#   block_area   - Global array storing area for all leaf blocks
#   decoder_full - Global list of all design cells (hierarchical + leaf)
# --------------------------------------------------------

proc sort_by_area {decoder_list} {
    global block_area decoder_full

    # --------------------------------------------------------
    # Stage 1: Sort the decoder list using a custom sorting command
    # --------------------------------------------------------
    # - Custom comparison command will access the global block_area array
    # - Sorting is done numerically by the block's area
    proc compare_area {a b} {
        global block_area
        # Compare area values of block a and block b
        return [expr {$block_area($a) - $block_area($b)}]
    }

    # Perform sorting of the decoder list
    set sorted_list [lsort -command compare_area $decoder_list]

    # --------------------------------------------------------
    # Stage 2: Build result with both block names and their areas
    # --------------------------------------------------------
    # - First, extract only the leaf blocks from the decoder_full list
    # - Leaf blocks are the ones that have an explicit entry in block_area
    set leaf_blocks {}
    foreach blk $decoder_full {
        if {[lsearch -exact [array names block_area] $blk] != -1} {
            lappend leaf_blocks $blk
        }
    }

    # Initialize result list and total area counter
    set result {}
    set total_area 0

    # Loop through sorted blocks and determine their area
    foreach blk $sorted_list {
        # If this block is a leaf block, get its area directly
        if {[info exists block_area($blk)]} {
            set area $block_area($blk)
        } else {
            # If hierarchical, sum the areas of all leaf blocks under it
            set area 0
            foreach leaf $leaf_blocks {
                if {[string match ${blk}* $leaf]} {
                    incr area $block_area($leaf)
                }
            }
        }

        # Append {block_name area} to the result list
        lappend result [list $blk $area]

        # Accumulate into total area
        incr total_area $area
    }

    # --------------------------------------------------------
    # Output results
    # --------------------------------------------------------
    puts "Sorted blocks with areas:"
    foreach entry $result {
        puts "[lindex $entry 0]  [lindex $entry 1]"
    }
    puts "Total area: $total_area"

    return $result
}

# ---------------------------
# Example usage:
#   % source decoder.tcl
#   % sort_by_area $decoder
# ---------------------------
