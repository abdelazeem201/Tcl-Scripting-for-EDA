(bin) 1 % set institute(0) VLSI
VLSI
(bin) 2 % set institute(1) Academy 
Academy
(bin) 3 % set institute(2) China
China
(bin) 4 % for {set index 0} {$index < [array size institute]} {incr index} {
> puts "institute($index) : $institute($index)"
> }
institute(0) : VLSI
institute(1) : Academy
institute(2) : China
(bin) 5 % array size institute
3
(bin) 6 % puts "$institute($index)"
can't read "institute(3)": no such element in array
(bin) 7 % for {set index 0} {$index < [array size institute]} {incr index} {
puts "institute($index) : $institute($index)"
}
institute(0) : VLSI
institute(1) : Academy
institute(2) : China
(bin) 8 % array name institute 
0 1 2
(bin) 9 % array names institute
0 1 2
(bin) 10 % foreach index [array names institute] {
> puts "institute($index) : $institute($index)"
> }
institute(0) : VLSI
institute(1) : Academy
institute(2) : China
(bin) 11 % 
(bin) 11 % 
(bin) 11 % set students(jacob) 24
24
(bin) 12 % set students(ryan) 27
27
(bin) 13 % set students(callie) 27
27
(bin) 14 % set students(john) 29
29
(bin) 15 % set students(yang) 23
23
(bin) 16 % set name_to_find callie
callie
(bin) 17 % foreach name [array name students] {
> if {$name == $name_to_find} {
> puts "Name : $name"
> puts "age : $students($name)"
> } 
> }
Name : callie
age : 27
(bin) 18 % 
(bin) 18 % puts [string rang "I am studying physical design" 2 12]
am studying
(bin) 19 % puts [string tolower "VLSI DESIGN"]
vlsi design
(bin) 20 % puts [string toupper "visi design"]
VISI DESIGN
(bin) 21 % 
(bin) 21 % 