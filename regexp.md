# Mastering Regular Expressions, `regsub`, `grep`, and `glob` in Tcl

## Introduction
Regular expressions (regex) are a powerful way to search, match, and manipulate text. Tcl provides built-in support for regex through commands like `regexp` (for matching) and `regsub` (for substitution). Additionally, `grep` and `glob` play essential roles in file searching and pattern matching. In this article, we will explore these commands with in-depth explanations and practical examples.

---

## Regular Expressions in Tcl (`regexp` Command)

### Syntax
```tcl
regexp ?options? pattern string ?matchVar?
```
- `pattern`: The regex pattern to search for.
- `string`: The text to check.
- `matchVar`: (Optional) Stores the matched result.
- Options include `-nocase` (case-insensitive matching) and `-all` (find all occurrences).

### Basic Example
```tcl
set text "Hello Tcl 101"
if {[regexp {Tcl} $text]} {
    puts "Match found!"
}
```
**Output:**
```
Match found!
```

### Capturing Groups
```tcl
set text "Name: Ahmed"
regexp {Name: (\w+)} $text match name
puts "Extracted Name: $name"
```
**Output:**
```
Extracted Name: Ahmed
```

### Matching Numbers
```tcl
set number "Price is 250"
if {[regexp {\d+} $number match]} {
    puts "Found number: $match"
}
```
**Output:**
```
Found number: 250
```

### Finding All Matches
```tcl
set text "Order 123 contains 5 items"
set numbers [regexp -all -inline {\d+} $text]
puts "Numbers: $numbers"
```
**Output:**
```
Numbers: 123 5
```

---

## String Substitution with `regsub`
The `regsub` command replaces occurrences of a pattern in a string.

### Syntax
```tcl
regsub ?options? pattern string replacement resultVar
```

### Basic Example
```tcl
set text "I love Tcl!"
regsub {Tcl} $text "Python" newText
puts $newText
```
**Output:**
```
I love Python!
```

### Replacing All Matches
```tcl
set text "Price: 100 USD, Discount: 20 USD"
regsub -all {\d+} $text "#" newText
puts $newText
```
**Output:**
```
Price: # USD, Discount: # USD
```

### Swapping First and Last Name
```tcl
set name "Ahmed Johnson"
regsub {(\w+) (\w+)} $name "\2, \1" newName
puts $newName
```
**Output:**
```
Johnson, Ahmed
```

---

## Searching with `grep`
Tcl does not have a built-in `grep` command like Unix, but equivalent functionality can be achieved using `lsearch`.

### Searching in a List
```tcl
set colors {red blue green yellow}
set search "blue"
if {[lsearch -exact $colors $search] >= 0} {
    puts "$search found in the list"
}
```
**Output:**
```
blue found in the list
```

### Searching with a Pattern
```tcl
set words {apple banana grape orange}
set matches [lsearch -regexp $words {a.*e}]
puts "Matching word index: $matches"
```
**Output:**
```
Matching word index: 0 2
```

---

## File Matching with `glob`
The `glob` command retrieves file names matching a pattern.

### Syntax
```tcl
glob ?options? pattern
```

### Listing All `.tcl` Files
```tcl
puts [glob *.tcl]
```
**Output:** (Example)
```
script1.tcl script2.tcl
```

### Listing Files in a Directory
```tcl
puts [glob /home/user/*.txt]
```

### Listing Files with Multiple Extensions
```tcl
puts [glob -nocomplain *.tcl *.txt]
```
`-nocomplain` prevents errors if no files match.

### Using `glob` with Loops
```tcl
foreach file [glob *.tcl] {
    puts "Processing file: $file"
}
```

---

## Summary of Common Regex Patterns
Here are some frequently used regex patterns with explanations:

| Pattern  | Description | Example Match |
|----------|------------|---------------|
| `\d+` | Matches one or more digits | `123`, `42` |
| `\w+` | Matches one or more word characters (letters, numbers, underscore) | `hello`, `Tcl_101` |
| `\s+` | Matches one or more whitespace characters | spaces, tabs |
| `[^a-z]` | Matches any character **except** lowercase letters | `123!@#` |
| `^hello` | Matches `hello` at the beginning of a string | `hello world!` |
| `world$` | Matches `world` at the end of a string | `Hello world` |
| `(abc\|def)` | Matches `abc` or `def` | `abc`, `def` |
| `\bword\b` | Matches `word` as a whole word | `word`, not `sword` |

### Additional Common Patterns

| Pattern | Description | Example Match |
|---------|------------|---------------|
| `.` | Any character except newline | "a", "7", "@" |
| `\d` | Digit (0-9) | "5", "9" |
| `\w` | Word character (A-Z, a-z, 0-9, _) | "Ahmed", "hello123" |
| `\s` | Whitespace (space, tab, newline) | " " |
| `\D` | Not a digit | "A", "hello" |
| `\W` | Not a word character | "@", "#" |
| `\S` | Not whitespace | "A", "9" |
| `^` | Start of string | `^Hello` matches "Hello World" |
| `$` | End of string | `World$` matches "Hello World" |
| `*` | 0 or more times | `ba*` matches "b", "ba", "baa" |
| `+` | 1 or more times | `ba+` matches "ba", "baa", but not "b" |
| `?` | 0 or 1 time (optional) | `colou?r` matches "color" and "colour" |

---

### Additional EDA Tool Examples Using Regex

When working with EDA tools like Cadence, Synopsys, or Mentor Graphics, parsing log files for specific error messages, warnings, or specific output is a common task. We can use regex to quickly extract this information.

### Example: Extracting Errors or Warnings from a Log File
```tcl
# Sample log data (simulated)
set log_data "INFO: Simulation complete\nERROR: Design rule violation\nWARNING: Timing failure detected\nINFO: Cleanup completed"

# Regex to find errors and warnings
set error_warning_regex {^(ERROR|WARNING): (.*)$}

# Iterate through the log and extract relevant lines
foreach line [split $log_data "\n"] {
    if {[regexp $error_warning_regex $line match level message]} {
        puts "Found $level: $message"
    }
}
```
### Explanation
 
* This script scans each line of the log, searching for lines that start with “ERROR” or “WARNING” using regexp.
* The regexp captures the level of the message (error or warning) and the message itself.
 
**Example Output:**
```
Found ERROR: Design rule violation
Found WARNING: Timing failure detected```
```


###  Extracting and Modifying Design Constraints

In EDA scripts, design constraints (e.g., clock definitions, setup/hold time constraints) are often stored in a format that can be parsed and modified using regex.

### Example: Modify Clock Frequency Constraint in a Constraints File 
```tcl
# Simulate a design constraints file
set constraints_data {
    set_clock_period 10
    set_clock_period 20
    set_clock_period 15
}

# Regex to find and modify clock period constraints
set clock_period_regex {set_clock_period (\d+)}
foreach line $constraints_data {
    if {[regexp $clock_period_regex $line match old_period]} {
        # Modify the clock period value
        regsub $clock_period_regex $line "set_clock_period 25" updated_line
        puts "Updated Line: $updated_line"
    }
}
```
### Explanation
 
* This script scans for any set_clock_period commands in the constraints data and updates the clock period to 25 using regsub.
 
**Example Output:**
```
Updated Line: set_clock_period 25
Updated Line: set_clock_period 25
Updated Line: set_clock_period 25
```

###  File Path Handling for EDA Tools

EDA tools often involve file manipulations, such as adding directories to the search path or adjusting file extensions. Regular expressions can be used to handle these file paths dynamically.

### Example: Extracting Verilog and VHDL Files from a Directory Listing
```tcl
# Sample directory listing with various file types
set files {design.vhdl design.svf synthesis.v design_test.vhdl top_module.v}

# Regex to find Verilog (.v) and VHDL (.vhdl) files
set file_regex {(\S+)\.(vhdl|v)$}

# Extract and display only Verilog and VHDL files
foreach file $files {
    if {[regexp $file_regex $file match filename ext]} {
        puts "Found $ext file: $filename.$ext"
    }
}
```
### Explanation
 
* This script uses regexp to find files that have the extensions .vhdl or .v. It extracts and prints out the file names with their extensions.
 
**Example Output:**
```
Found vhdl file: design.vhdl
Found vhdl file: design_test.vhdl
Found v file: design.v
Found v file: top_module.v
```

###  Searching for Specific Variables in a Design Script

Design scripts often include variables for timing parameters, constraints, and other settings. We can search for specific variables to validate or modify their values.

### Example: Find All Variables Starting with clk_
```tcl
# Simulated script containing design variables
set design_script {
    set clk_period 10
    set clk_delay 2
    set setup_time 5
    set hold_time 3
}

# Regex to find variables starting with 'clk_'
set clk_var_regex {^clk_\w+}

foreach line $design_script {
    if {[regexp $clk_var_regex $line match]} {
        puts "Found clock variable: $line"
    }
}
```
### Explanation
 
* This script searches for all variables that start with clk_, such as clk_period and clk_delay.
 
**Example Output:**
```
Found clock variable: set clk_period 10
Found clock variable: set clk_delay 2
```

###  Generating and Validating File Names for Reports

EDA tools often generate report files with specific naming conventions. We can use regex to ensure that the generated filenames follow the correct pattern.

### Example: Validate Report File Naming Convention
```tcl
# Simulated list of filenames for reports
set report_files {timing_report_001.txt power_report_001.txt design_report_01.log}

# Regex to match valid report filenames (must start with 'report_' followed by digits)
set report_regex {^report_\d+(\.txt|\.log)$}

foreach file $report_files {
    if {[regexp $report_regex $file]} {
        puts "Valid report file: $file"
    } else {
        puts "Invalid report file: $file"
    }
}
```
### Explanation
 
* This script checks if each report file matches the specified pattern: starts with report_ followed by one or more digits and ends with .txt or .log.
 
**Example Output:**
```
Valid report file: timing_report_001.txt
Valid report file: power_report_001.txt
Valid report file: design_report_01.log
```
---



## Conclusion
- **`regexp`** is used for pattern matching.
- **`regsub`** performs substitutions based on regex.
- **`grep` (via `lsearch`)** finds patterns in lists.
- **`glob`** retrieves file names based on patterns.



