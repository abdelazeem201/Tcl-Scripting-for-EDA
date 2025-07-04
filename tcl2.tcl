(bin) 1 % set list {a b c d e}
a b c d e
(bin) 2 % lindex $list [expr [llength $list]/2]
c
(bin) 3 % set a {1 2}
1 2
(bin) 4 % set b {3 4 5}
3 4 5
(bin) 5 % set c {6 7 8}
6 7 8
(bin) 6 % lappend a $b
1 2 {3 4 5}
(bin) 7 % lappend a $c 
1 2 {3 4 5} {6 7 8}
(bin) 8 % lindex $a [expr [llength $a]-1]
6 7 8
(bin) 9 % lindex [lindex $a [expr [llength $a]-1]] [expr [llength $c]-1]
8
(bin) 10 % set list1 {0 1.2 -4 3 5}
0 1.2 -4 3 5
(bin) 11 % lsort -real $list1 
-4 0 1.2 3 5
(bin) 12 % lindex [lsort -real $list1] [expr [llength $list1]-1] 
5
(bin) 13 % expr [llength $a]+[llength $b]
7
(bin) 14 % set a {0 1 4}
0 1 4
(bin) 15 % set b {2 3 5}
2 3 5
(bin) 16 % lindex [lsort -real $a]
0 1 4
(bin) 17 % lindex [lsort -real $a] [expr [llength $a]-1]
4
(bin) 18 % lindex [lsort -real $b] [expr [llength $b]-1]
5
(bin) 19 % sea alindex [lsort -real $a] [expr [llength $a]-1]
invalid command name "sea"
(bin) 20 % 
(bin) 20 % set a_max [lindex [lsort -real $a] [expr [llength $a]-1]] 
4
(bin) 21 % set b_max [lindex [lsort -real $b] [expr [llength $b]-1]] 
5
(bin) 22 % if {$a_max > $b_max} {
> puts "The max number is in list a"
> }elseif {$a_max == $b_max} { 
extra characters after close-brace
(bin) 23 % if {$a_max > $b_max} {
puts "The max number is in list a"
} elseif{$a_max == $b_max} {
> puts "The max number in list a and b is equal"
> } else {
> puts "The max number is in list b"
> }
wrong # args: extra words after "else" clause in "if" command
(bin) 24 % if {$a_max > $b_max} {
puts "The max number is in list a"
} elseif{$a_max == $b_max} {
puts "The max number in list a and b is equal"
} else{
puts "The max number is in list b"
}
wrong # args: extra words after "else" clause in "if" command
(bin) 25 % if {$a_max > $b_max} {
puts "The max number is in list a"
} elseif{$a_max == $b_max} {
puts "The max number in list a and b is equal"
}else {
puts "The max number is in list b"
}
extra characters after close-brace
(bin) 26 % if {$a_max > $b_max} {
puts "The max number is in list a"
} elseif {$a_max == $b_max} {
puts "The max number in list a and b is equal"
}else {
puts "The max number is in list b"
}
extra characters after close-brace
(bin) 27 % if {$a_max > $b_max} {
puts "The max number is in list a"
} elseif {$a_max == $b_max} {
puts "The max number in list a and b is equal"
} else {
puts "The max number is in list b"
}
The max number is in list b
(bin) 28 % 
(bin) 28 % set list1 {1 3 7 0 19}
1 3 7 0 19
(bin) 29 % set i 0
0
(bin) 30 % foreach j $list1 {
> if {$j > 5} {
> incr i 
> }
> }
(bin) 31 % puts $i
2
(bin) 32 % 
(bin) 32 % set sum 0
0
(bin) 33 % foreach j $list1 {
> set sum [expr $sum + $j]
> }
(bin) 34 % expr $sum/[llength $list1] 
6
(bin) 35 % puts $sum 
30
(bin) 36 % 
(bin) 36 % set list1 {1 2 5 12 50 60}
1 2 5 12 50 60
(bin) 37 % foreach i $list1 {
> if {$i > 10} {
> puts "Error:$i is large than 10"
> break
> }
> }
Error:12 is large than 10
(bin) 38 % 
(bin) 38 % 
(bin) 38 % set list1 {Mike Kim Jim Lucy Sam}
Mike Kim Jim Lucy Sam
(bin) 39 % set list2 {Sam Jim}
Sam Jim
(bin) 40 % set err_flag 0
0
(bin) 41 % foreach i list1 {
> 
> break
> } 
(bin) 42 % foreach i $list1 {
> foreach j $list2 {
> if {$i == $j} {
> puts "Error $j in list1"
> set err_flag 1
> }
> }
> if {$err_flag == 1} {
> break
> }
> }
Error Jim in list1
(bin) 43 % 
(bin) 43 % 
(bin) 43 % set list1 {1 2 7 0 19}
1 2 7 0 19
(bin) 44 % set j 0
0
(bin) 45 % foreach i $list1 {
> if {$i >= 5} {
> continue
> }
> incr j 
> }
(bin) 46 % puts $j
3
(bin) 47 % 
(bin) 47 % 
(bin) 47 % set sum 0
0
(bin) 48 % foreach i $list1 {
> if {$i%2 == 0} {
> continue 
> }
> set sum [expr $sum + $i]
> }
(bin) 49 % puts $sum
27
(bin) 50 % 
(bin) 50 % proc box_area {a b c d} {
> set x [expr $c - $a]
> set y [expr $d - $b]
> set area [expr $x * $y]
> return $area
> }
(bin) 51 % box_area {1 1 3 3}
wrong # args: should be "box_area a b c d"
(bin) 52 % box_area 1 1 3 3
4
(bin) 53 % regexp {name\s+(\w+)\s+name\s+(\w+)} "name snow name vicent" total name1 name2
1
(bin) 54 % puts $total
name snow name vicent
(bin) 55 % puts $name1
snow
(bin) 56 % puts $name2
vicent
(bin) 57 % 
(bin) 57 % 

proc max list {
set a [lsort -real $list]
set b [lindex $a [llength $a]-1]
return $b
}
