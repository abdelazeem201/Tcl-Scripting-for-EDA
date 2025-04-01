# Tcl String Operations and Scripting

## **Overview**
Tcl (Tool Command Language) provides a powerful set of string manipulation commands that are useful in various applications, including automation and EDA (Electronic Design Automation). This document covers essential string operations in Tcl with detailed explanations and examples, along with a general scripting example and an EDA-related script.

---

## **Tcl String Operations**

### **1. Concatenating Strings** (`string cat`)
Concatenates multiple strings into one.
- **Syntax:** `string cat ?string1? ?string2...?`
- **Example:**
```tcl
puts [string cat "Hello" " " "World!"]  ;# Output: Hello World!
```

### **2. Comparing Strings** (`string compare`)
Compares two strings lexicographically.
- **Syntax:** `string compare ?-nocase? ?-length length? string1 string2`
- **Options:**
  - `-nocase`: Case-insensitive comparison.
  - `-length length`: Limits comparison to the first `length` characters.
- **Example:**
```tcl
puts [string compare "apple" "Apple"]  ;# Output: 1 (not equal)
puts [string compare -nocase "apple" "Apple"]  ;# Output: 0 (equal)
```

### **3. Checking String Equality** (`string equal`)
Returns `1` if strings are equal, otherwise `0`.
- **Syntax:** `string equal ?-nocase? ?-length length? string1 string2`
- **Example:**
```tcl
puts [string equal "Hello" "Hello"]  ;# Output: 1
puts [string equal -nocase "hello" "HELLO"]  ;# Output: 1
```

### **4. Finding a Substring** (`string first` and `string last`)
- **First occurrence:** `string first needleString haystackString ?startIndex?`
```tcl
puts [string first "lo" "Hello World"]  ;# Output: 3
```
- **Last occurrence:** `string last needleString haystackString ?lastIndex?`
```tcl
puts [string last "o" "Hello World"]  ;# Output: 7
```

### **5. Extracting a Character by Index** (`string index`)
- **Syntax:** `string index string charIndex`
```tcl
puts [string index "Hello" 1]  ;# Output: e
```

### **6. Checking String Properties** (`string is`)
Checks if a string belongs to a specific class.
- **Syntax:** `string is class ?-strict? ?-failindex varname? string`
- **Example:**
```tcl
puts [string is integer "1234"]  ;# Output: 1
puts [string is alpha "hello"]  ;# Output: 1
```

### **7. Getting String Length** (`string length`)
```tcl
puts [string length "Tcl"]  ;# Output: 3
```

### **8. String Mapping (Replacing Substrings)** (`string map`)
```tcl
puts [string map {"Hello" "Hi"} "Hello World"]  ;# Output: Hi World
```

### **9. Pattern Matching** (`string match`)
```tcl
puts [string match "H*" "Hello"]  ;# Output: 1
```

### **10. Extracting a Substring (Range)** (`string range`)
```tcl
puts [string range "Hello World" 0 4]  ;# Output: Hello
```

### **11. Repeating Strings** (`string repeat`)
```tcl
puts [string repeat "Hi " 3]  ;# Output: Hi Hi Hi 
```

### **12. Replacing a Part of the String** (`string replace`)
```tcl
puts [string replace "Hello World" 6 10 "Tcl"]  ;# Output: Hello Tcl
```

### **13. Reversing a String** (`string reverse`)
```tcl
puts [string reverse "Tcl"]  ;# Output: lcT
```

### **14. Changing String Case**
```tcl
puts [string tolower "HELLO"]  ;# Output: hello
puts [string toupper "hello"]  ;# Output: HELLO
puts [string totitle "hello world"]  ;# Output: Hello World
```

### **15. Trimming Strings**
```tcl
puts [string trim "  Hello  "]  ;# Output: Hello
puts [string trimleft "  Hello  "]  ;# Output: Hello  
puts [string trimright "  Hello  "]  ;# Output:   Hello
```

---

## **EDA Tcl Script Example**
This script sets up an EDA environment and verifies a netlist.

```tcl
# Tcl script for setting up an EDA environment and verifying netlist

# Define design and libraries
set design_name "my_chip"
set library_path "./lib/stdcell.lib"
set netlist_file "./netlist/my_chip.v"

# Check if netlist file exists
if {![file exists $netlist_file]} {
    puts "Error: Netlist file not found!"
    exit 1
}

# Read the netlist
puts "Reading netlist: $netlist_file"
set file_id [open $netlist_file r]
set netlist_content [read $file_id]
close $file_id

# Count number of module definitions
set module_count [regexp -all -inline "module" $netlist_content]
puts "Number of modules in netlist: [llength $module_count]"

# Ensure the design module is present
if {[string first $design_name $netlist_content] == -1} {
    puts "Error: Design module '$design_name' not found in netlist!"
    exit 1
}

puts "Netlist verification successful!"
```

---

## **Conclusion**
This README provides an overview of Tcl string operations, a general Tcl script, and an EDA-related script. Tcl's string manipulation commands are essential for scripting in various applications, including automation and EDA tools like Synopsys Design Compiler, Cadence Innovus, and Mentor Graphics tools.

