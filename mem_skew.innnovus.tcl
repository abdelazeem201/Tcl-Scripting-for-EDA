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
