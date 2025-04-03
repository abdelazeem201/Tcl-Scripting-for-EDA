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
