(bin) 1 % puts "Hello world"
Hello world
(bin) 2 % set a snow
snow
(bin) 3 % puts $a 
snow
(bin) 4 % set q [expr 3+4]
7
(bin) 5 % puts $q
7
(bin) 6 % puts  "\[expr 3+4\]"
[expr 3+4]
(bin) 7 % puts  "\[expr 3+4\]"
[expr 3+4]
(bin) 8 % puts a\tb
a	b
(bin) 9 % puts ${q}_1
7_1
(bin) 10 % set cell_1(ref_name) "bufx2"
bufx2
(bin) 11 % set cell_1(full_name) "top/cell_1"
top/cell_1
(bin) 12 % set cell_1(pins) "A B C"
A B C
(bin) 13 % puts $cell_1(pins)
A B C
(bin) 14 % array size cell_1
3
(bin) 15 % array names cell_1
ref_name pins full_name
(bin) 16 % set list1 {bufx1 bufx2 bufx3}
bufx1 bufx2 bufx3
(bin) 17 % set list2 {invx1 invx2 invx3}
invx1 invx2 invx3
(bin) 18 % concat $list1 $list2
bufx1 bufx2 bufx3 invx1 invx2 invx3
(bin) 19 % set a {1 2}
1 2
(bin) 20 % set c 5
5
(bin) 21 % concat $a $c 
1 2 5
(bin) 22 % set b {2 3} 
2 3
(bin) 23 % concat $a $b
1 2 2 3
(bin) 24 % llength $list1
3
(bin) 25 % llength [concat $list1 $list1] 
6
(bin) 26 % lindex $list1 2
bufx3
(bin) 27 % set list3 
can't read "list3": no such variable
(bin) 28 % set list3 {a b c d e f} 
a b c d e f
(bin) 29 % llength $list3
6
(bin) 30 % lindex $list3 [llength $list3]-1
f
(bin) 31 % set list4 {a b c d e}
a b c d e
(bin) 32 % llength $list4
5
(bin) 33 % lindex $list4 [[llength $list4]-1]/2
invalid command name "5-1"
(bin) 34 % lindex $list4 [llength $list4]-1
e
(bin) 35 % set n [expr 5-1]
4
(bin) 36 % set m [expr n/2]
can't use non-numeric string as operand of "/"
(bin) 37 % set m [expr n/2.0]
can't use non-numeric string as operand of "/"
(bin) 38 % set m [expr n<<1]
can't use non-numeric string as operand of "<<"
(bin) 39 % set m [expr 4.0/2]
2.0
(bin) 40 % lappend list4 g
a b c d e g
(bin) 41 % set list5 {f h}
f h
(bin) 42 % lappend list4 $list5
a b c d e g {f h}
(bin) 43 % lindex [lappend list4 $list5] 6
f h
(bin) 44 % lindex [lindex [lappend list4 $list5] 6] 0
f
(bin) 45 % set a {1 2}
1 2
(bin) 46 % set b {3 4 5}
3 4 5
(bin) 47 % set c {6 7 8}
6 7 8
(bin) 48 % lappend a $b 
1 2 {3 4 5}
(bin) 49 % lappend a $c
1 2 {3 4 5} {6 7 8}
(bin) 50 % lindex [lappend a $c] 3
6 7 8
(bin) 51 % lindex [lindex [lappend a $c] 3] 2
8
(bin) 52 % set list6 {0 1.2 -4 3 5}
0 1.2 -4 3 5
(bin) 53 % lsort -real $list6  
-4 0 1.2 3 5
(bin) 54 % lindex [lsort -real $list6] 0
-4
(bin) 55 % llength [lsort -real $list6] 
5
(bin) 56 % lindex [lsort -real $list6] [llength [lsort -real $list6]-1]
(bin) 57 % lindex [lsort -real $list6] llength [lsort -real $list6]-1
bad index "llength": must be integer?[+-]integer? or end?[+-]integer?
(bin) 58 % lindex [lsort -real $list6] [llength [lsort -real $list6]]-1
5
(bin) 59 % echo $list4
"a b c d e g {f h} {f h} {f h}"
(bin) 60 % set list7 {a b c d e}
a b c d e
(bin) 61 % llength $list7
5
(bin) 62 % lindex [expr [llength $list7]-1]
4
(bin) 63 % lindex $list7 [expr [llength $list7]-1]
e
(bin) 64 % lindex $list7 [expr [expr [llength $list7]-1]/2]
c
(bin) 65 % 