# Problem statements
        # 1.  • Write a tcl proc, to take a “base name” and optionally a “suffix” and create a unique name from this base name.
	# 2.  •	You should create the unique name by adding a prefix counter, then base name, then optionally a suffix if it exists. (i.e. 19_basename_suffix)
	# 3.  •	But we can’t start a variable name by a number, lets add letter “n” as prefix as well to be "n19_basename_suffix"
	# 4.  •	If the base name is already created by the above pattern, please remove the old prefix counter, for example if the  is n19_basename, remove n19 and add the new prefix. (i.e. n20_basename)

# Requirements Summary:
	#1.	Input: basename and optional suffix
	#2.	Output: A unique name in the form of: n<counter>_<basename>_<suffix> (or without _suffix if not provided)
	#3.	Prefix:
	  #•	Prefix is n<counter>, where <counter> increments with each new name.
	#4.	Clean-up:
	  #•	If the basename already has a n<counter>_ prefix, remove it first.
	#5.	Counter: Needs to persist/increment each time the proc is called.

# Global counter to ensure uniqueness
set ::name_counter 0

proc generate_unique_name {basename {suffix ""}} {
    # Access the global counter
    global name_counter

    # Remove existing prefix if any (e.g., n19_)
    set cleaned_basename [regsub {^n\d+_} $basename ""]

    # Increment the counter
    incr name_counter

    # Compose new name
    set newname "n${name_counter}_${cleaned_basename}"
    if {$suffix ne ""} {
        append newname "_$suffix"
    }

    return $newname
}

puts "Creating a unique name from base 'AND' :  [generate_unique_name AND]"
set newName [generate_unique_name AND]
puts "Creating a unique name from base 'AND' again : $newName "
set anotherName [generate_unique_name $newName]
puts "Creating a unique name from previously created unique name : $anotherName "

puts "Creating a unique name from previously created unique name with a suffix : [generate_unique_name $newName RAM] "
