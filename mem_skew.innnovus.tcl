##Problem

#I want to set clock latencies for RAM macros. What information can I get to determine which RAM instance is a good candidate for skewing? This is required to determine if I can improve my overall timing by analyzing the balancing of timing paths going to and from the RAM macro.


#Solution
#
#The attached script analyzes all timing paths to and from the macro and determines the WNS and TNS of those paths, respectively.
#
#If the paths into the RAM have mostly negative slack and the paths from the RAM have mostly positive slack, you can improve timing by pushing out the clock timing of the RAM clock. Else, if the paths into the RAM have mostly positive slack and the paths from the RAM have mostly negative slack, you can then improve the timing by pulling in the clock timing of the RAM clock. If the paths both into and from the RAM have negative slack, you cannot improve timing by skewing the clock.
#
#In the Tcl proc, you gather the most negative paths to and from the RAM (WNS). You also add up all negative paths to and from the RAM into a total negative slack number (TNS). The Tcl proc has a few command-line options to customize and simplify usage.
#
#The Tcl proc is written for a testcase where the RAM macros did not provide the is_macro_cell or is_memory_cell. So, a heuristic way is used. You check if the name of the lib_cell contains *ram* and if the instance has more than 20 pins. As needed, this can be changed in the code.

#Usage:

#innovus 14> mem_skew -help
#Description:
#analyze mem tns wns
#Usage: mem_skew [-help] [-inst_mask <string>] [-neg_only] [-ref_lib_mask <string>]
#-help                   # Prints out the command usage
#-inst_mask <string>     # Instances to analyze. Default * (string, optional)
#-neg_only               # Only print negative slack. Default False (bool, optional)
#-ref_lib_mask <string>  # Name mask to find rams by ref_lib_cell_name. Default *ram* (string, optional)

#Sample Output:

#This is the basic functionality to show all RAMs with their from/to WNS and TNS.

#innovus > mem_skew                                                                                  

#-----------------------------------------------------------------------------------------------------
#| WNS from | TNS from |  WNS to  |  TNS to  | Instance name                                       
#|---------------------------------------------------------------------------------------------------
#|   +0.033 |   +0.000 |   +3.414 |   +0.000 | u_dig/top/u_buf/u_buf1_i
#|   +0.044 |   +0.000 |   +3.403 |   +0.000 | u_dig/top/u_buf/u_buf1_o
#|   +0.029 |   +0.000 |   +3.391 |   +0.000 | u_dig/top/u_buf/u_buf2_i
#|   +0.345 |   +0.000 |   +2.408 |   +0.000 | u_dig/top/u_buf/u_buf2_o
#|   +0.006 |   +0.000 |   +3.625 |   +0.000 | u_dig/top/u_buf/u_buf3_i
#|   +0.057 |   +0.000 |   +3.966 |   +0.000 | u_dig/top/u_buf/u_buf3_o
#|   +0.011 |   +0.000 |   +1.606 |   +0.000 | u_stats/u_accum/u_stats1/u_ram
#|   -0.028 |   -0.208 |   +1.752 |   +0.000 | u_stats/u_accum/u_stats2/u_ram
#|   +0.016 |   +0.000 |   +1.200 |   +0.000 | u_stats/u_accum/u_stats3/u_ram
#|   -0.017 |   -0.069 |   +0.964 |   +0.000 | u_stats/u_accum/u_stats4/u_ram
#-----------------------------------------------------------------------------------------------------

#For skew analysis, only RAMs with negative slack are relevant. So, you add the flag to only show the RAMs with negative slack.

#innovus > mem_skew -neg_only

#-----------------------------------------------------------------------------------------------------
#| WNS from | TNS from |  WNS to  |  TNS to  | Instance name                                       
#|---------------------------------------------------------------------------------------------------
#
#|   -0.028 |   -0.208 |   +1.752 |   +0.000 | u_stats/u_accum/u_stats2/u_ram
#|   -0.017 |   -0.069 |   +0.964 |   +0.000 | u_stats/u_accum/u_stats4/u_ram
#-----------------------------------------------------------------------------------------------------

#If you only want a RAM with a name mask, you can filter for that as well.

#innovus > mem_skew -neg_only -inst_mask u_stats/u_accum/u_stats4/*
#-----------------------------------------------------------------------------------------------------
#| WNS from | TNS from |  WNS to  |  TNS to  | Instance name                                         
#|--------------------------------------------------------------------------------------------------
#| -0.017 |   -0.069 |   +0.964 |   +0.000 | u_stats/u_accum/u_stats4/u_ram
#-----------------------------------------------------------------------------------------------------

proc sum_l {lst} {
  set sum 0.0
  foreach l $lst { set sum [ expr { $sum + $l } ] }
  return $sum
}

define_proc_arguments mem_skew -info "analyze mem tns wns" -define_args {
  { -inst_mask "Instances to analyze. Default *" "" string optional }
  { -ref_lib_mask "Name mask to find rams by ref_lib_cell_name. Default *ram*" "" string optional }
  { -neg_only "Only print negative slack. Default False" "" boolean optional}
  { -h "help" "" string optional } 
}

proc mem_skew { args } {

  set inst_m "*"
  set cell_m "*" 
  set neg_only "false"

  parse_proc_arguments -args $args opts
  foreach argname [array names opts] {
    switch $argname {
      -inst_mask { set inst_m $opts($argname) }
      -ref_lib_mask { set cell_m $opts($argname) }
      -neg_only { set neg_only "true" }
      -h {  puts "mem_skew \[-inst_mask <Instances to analyze. Default *>\] \[-ref_lib_mask <Name mask to find rams by ref_lib_cell_name. Default \*>\] \
          \[-neg_only <Only print negative slack. Default False> \] \[-h <help>"
          return  }
      default { Puts "This should not happen" }
    }
}

if {$inst_m == "*"} {
set ram_l [get_cells -hier * -filter "ref_lib_cell_name =~ $cell_m && pin_count > 20 && is_hierarchical == false" ]
} else {
set ram_l [get_cells $inst_m -filter "ref_lib_cell_name =~ $cell_m && pin_count > 20 && is_hierarchical == false" ]
}
Puts "-----------------------------------------------------------------------------------------------------"
Puts "| WNS from | TNS from | WNS to | TNS to | Instance name |"
Puts "-----------------------------------------------------------------------------------------------------"
foreach_in_collection ram $ram_l {
set Ram [ get_object_name $ram ]
set WNS_from [ get_property [ report_timing -coll -from $ram ] slack ]
set TNS_from [ sum_l [ get_property [ report_timing -coll -from $ram -max_paths 1000 -max_slack 0.0 ] slack ] ]
if {$TNS_from > 0.0} {set TNS_from 0.0}
set WNS_to [ get_property [ report_timing -coll -to $ram ] slack ]
set TNS_to [ sum_l [ get_property [ report_timing -coll -to $ram -max_paths 1000 -max_slack 0.0 ] slack ] ]
if {$TNS_to > 0.0} {set TNS_to 0.0}
if {$neg_only == "true"} {
if { $TNS_from < 0.0 || $TNS_to < 0.0 } {
Puts [format "| %+8.3f | %+8.3f | %+8.3f | %+8.3f | %s" $WNS_from $TNS_from $WNS_to $TNS_to $Ram ]
}
} else {
Puts [format "| %+8.3f | %+8.3f | %+8.3f | %+8.3f | %s" $WNS_from $TNS_from $WNS_to $TNS_to $Ram ]
}
}
Puts "-----------------------------------------------------------------------------------------------------"
}
