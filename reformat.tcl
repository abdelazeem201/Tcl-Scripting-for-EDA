set data {
    BITS_CLK2QDLY[0]
    BITS_CLK2QDLY[1]
    BITS_DCC_MAIN[0]
    BITS_DCC_MAIN[1]
    BITS_DCC_MAIN[2]
    BITS_DCC_MAIN[3]
    BITS_DCC_MAIN[4]
    BITS_DCC_MAIN[5]
    BITS_DCC_MAIN[6]
    BITS_FIXDLY_MAIN[0]
    BITS_FIXDLY_MAIN[1]
    BITS_FIXDLY_MAIN[2]
    BITS_FIXDLY_MAIN[3]
    BITS_FIXDLY_MAIN[4]
    BITS_FIXDLY_MAIN[5]
    BITS_FIXDLY_MAIN[6]
    BITS_FIXDLY_MAIN[7]
    BITS_NDE_DLY[0]
    BITS_NDE_DLY[1]
    BITS_NDE_DLY[2]
    BITS_NDE_DLY[3]
    BITS_NDE_DLY[4]
    BITS_NDE_DLY[5]
    BITS_NDE_DLY[6]
    BITS_NDE_DLY[7]
}

set keyword_numbers {}

# Process each item in the data
foreach item [split $data "\n"] {
    if {[regexp {(\w+)\[(\d+)\]} $item -> keyword number]} {
        # Check if the keyword already exists in the dictionary
        if {![dict exists $keyword_numbers $keyword]} {
            # If it doesn't exist, set the bit_start to the current number
            dict set keyword_numbers $keyword bit_start $number
        }
        # Set the bit_end to the current number (updates with each occurrence)
        dict set keyword_numbers $keyword bit_end $number
    }
}

# Output each key-value pair on a new line
dict for {keyword values} $keyword_numbers  {
    puts "$keyword \{$values\}"
}


###############################################
# Define a list of bit field names with indices
set data {
    BITS_CLK2QDLY[0]
    BITS_CLK2QDLY[1]
    BITS_DCC_MAIN[0]
    BITS_DCC_MAIN[1]
    BITS_DCC_MAIN[2]
    BITS_DCC_MAIN[4]
    BITS_DCC_MAIN[3]
    BITS_DCC_MAIN[6]
    BITS_DCC_MAIN[5]
    BITS_FIXDLY_MAIN[0]
    BITS_FIXDLY_MAIN[1]
    BITS_FIXDLY_MAIN[2]
    BITS_FIXDLY_MAIN[3]
    BITS_FIXDLY_MAIN[4]
    BITS_FIXDLY_MAIN[5]
    BITS_FIXDLY_MAIN[6]
    BITS_FIXDLY_MAIN[7]
    BITS_NDE_DLY[0]
    BITS_NDE_DLY[1]
    BITS_NDE_DLY[2]
    BITS_NDE_DLY[3]
    BITS_NDE_DLY[4]
    BITS_NDE_DLY[5]
    BITS_NDE_DLY[6]
    BITS_NDE_DLY[7]
}

# Initialize an empty dictionary to store bit range information
set keyword_numbers {}

# Iterate over each item in the data list
foreach item [split $data "\n"] {
    # Extract the keyword (base name) and bit index using regular expressions
    if {[regexp {(\w+)\[(\d+)\]} $item -> keyword number]} {
        # If the keyword already exists in the dictionary, update its bit range
        if [dict exists $keyword_numbers $keyword] {
            # Get the current min and max bit indices for the keyword
            set min_index [expr {min([dict get $keyword_numbers $keyword bit_start], $number)}]
            set max_index [expr {max([dict get $keyword_numbers $keyword bit_end], $number)}]
            
            # Update the dictionary with the new min and max values
            dict set keyword_numbers $keyword bit_start $min_index
            dict set keyword_numbers $keyword bit_end $max_index
        } else {
            # If the keyword does not exist, initialize its bit_start and bit_end with the current number
            dict set keyword_numbers $keyword [dict create bit_start $number bit_end $number]
        }
    }
}

# Iterate through the dictionary and print each keyword with its bit range
dict for {keyword values} $keyword_numbers {
    puts "$keyword \{$values\}"
}
