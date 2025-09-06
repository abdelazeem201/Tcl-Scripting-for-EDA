proc ndr_net_length {argv} {
   # Initialize counters
   set total_nets [llength $argv]
   set processed_nets 0
   
   puts "Analyzing NDR compliance for $total_nets net(s)..."
   puts [string repeat "=" 80]
   
   foreach netname $argv {
      # Initialize per-net variables
      set tlength 0.0
      set mlength 0.0
      set plength 0.0
      set shape_count 0
      set clock_shapes 0
      
      # Check if net exists
      if {[sizeof_collection [get_nets $netname -quiet]] == 0} {
         puts "WARNING: Net '$netname' not found - skipping"
         continue
      }
      
      # Get all shapes for the net
      set net_shapes [get_shapes -of_objects [get_nets $netname] -quiet]
      
      if {[sizeof_collection $net_shapes] == 0} {
         puts "WARNING: No shapes found for net '$netname' - skipping"
         continue
      }
      
      foreach_in_collection shape $net_shapes {
         set shape_name [get_object_name $shape]
         
         # Get shape attributes with error checking
         if {[catch {set minwidth [get_attribute $shape layer.min_width]} err]} {
            puts "WARNING: Cannot get min_width for shape $shape_name: $err"
            continue
         }
         
         if {[catch {set length [get_attribute $shape length]} err]} {
            puts "WARNING: Cannot get length for shape $shape_name: $err"
            continue
         }
         
         if {[catch {set width [get_attribute $shape width]} err]} {
            puts "WARNING: Cannot get width for shape $shape_name: $err"
            continue
         }
         
         if {[catch {set net_type [get_attribute $shape net_type]} err]} {
            puts "WARNING: Cannot get net_type for shape $shape_name: $err"
            continue
         }
         
         # Accumulate total length
         set tlength [expr $tlength + $length]
         incr shape_count
         
         # Check if this is a clock net shape using default width
         if {$net_type == "clock"} {
            incr clock_shapes
            # Compare widths with small tolerance for floating point comparison
            if {abs($width - $minwidth) < 0.001} {
               set mlength [expr $mlength + $length]
            }
         }
      }
      
      # Calculate NDR percentage
      if {$tlength > 0} {
         set plength [expr (($tlength - $mlength) / $tlength) * 100.0]
      } else {
         set plength 0.0
      }
      
      # Format output
      set ndr_length [expr $tlength - $mlength]
      
      puts "Net: $netname"
      puts "  Total Length:        [format "%.3f" $tlength] um"
      puts "  Default Width Length: [format "%.3f" $mlength] um"
      puts "  NDR Length:          [format "%.3f" $ndr_length] um"
      puts "  NDR Percentage:      [format "%.2f" $plength]%"
      puts "  Total Shapes:        $shape_count"
      puts "  Clock Shapes:        $clock_shapes"
      puts ""
      
      incr processed_nets
   }
   
   puts [string repeat "=" 80]
   puts "Analysis complete: $processed_nets/$total_nets nets processed"
}

# Enhanced version with detailed layer-by-layer analysis
proc ndr_net_length_detailed {argv} {
   puts "Detailed NDR Analysis by Layer"
   puts [string repeat "=" 80]
   
   foreach netname $argv {
      # Check if net exists
      if {[sizeof_collection [get_nets $netname -quiet]] == 0} {
         puts "WARNING: Net '$netname' not found - skipping"
         continue
      }
      
      puts "Net: $netname"
      
      # Group shapes by layer
      array unset layer_data
      set total_net_length 0.0
      
      set net_shapes [get_shapes -of_objects [get_nets $netname] -quiet]
      
      foreach_in_collection shape $net_shapes {
         if {[catch {
            set layer_name [get_attribute $shape layer.name]
            set length [get_attribute $shape length]
            set width [get_attribute $shape width]
            set minwidth [get_attribute $shape layer.min_width]
            set net_type [get_attribute $shape net_type]
         } err]} {
            continue
         }
         
         set total_net_length [expr $total_net_length + $length]
         
         if {![info exists layer_data($layer_name,total)]} {
            set layer_data($layer_name,total) 0.0
            set layer_data($layer_name,default) 0.0
            set layer_data($layer_name,minwidth) $minwidth
         }
         
         set layer_data($layer_name,total) [expr $layer_data($layer_name,total) + $length]
         
         if {$net_type == "clock" && abs($width - $minwidth) < 0.001} {
            set layer_data($layer_name,default) [expr $layer_data($layer_name,default) + $length]
         }
      }
      
      # Print layer-by-layer results
      foreach layer_name [lsort [array names layer_data "*,total"]] {
         set layer [lindex [split $layer_name ","] 0]
         set total_len $layer_data($layer,total)
         set default_len $layer_data($layer,default)
         set ndr_len [expr $total_len - $default_len]
         set ndr_pct [expr $total_len > 0 ? ($ndr_len / $total_len) * 100.0 : 0.0]
         
         puts "  Layer $layer:"
         puts "    Total: [format "%.3f" $total_len] um, Default: [format "%.3f" $default_len] um, NDR: [format "%.2f" $ndr_pct]%"
      }
      
      puts ""
   }
}

#-------------------------------------------------------------------------------
# Procedure: ndr_compliance_report
# Purpose: Generate comprehensive NDR compliance report with recommendations
# Arguments: argv - List of net names, optional threshold (default 75%)
# Returns: List of non-compliant nets
#
# Enhancement: Automated compliance checking with actionable recommendations
#-------------------------------------------------------------------------------
proc ndr_compliance_report {argv {threshold 75.0}} {
   puts "=== NDR COMPLIANCE REPORT ==="
   puts "Compliance Threshold: ${threshold}%"
   puts [string repeat "=" 80]
   
   set non_compliant_nets {}
   set total_analyzed 0
   set compliant_count 0
   
   foreach netname $argv {
      if {[sizeof_collection [get_nets $netname -quiet]] == 0} {
         continue
      }
      
      incr total_analyzed
      
      # Calculate NDR percentage (simplified from main function)
      set tlength 0.0
      set mlength 0.0
      
      set net_shapes [get_shapes -of_objects [get_nets $netname] -quiet]
      foreach_in_collection shape $net_shapes {
         if {[catch {
            set length [get_attribute $shape length]
            set width [get_attribute $shape width] 
            set minwidth [get_attribute $shape layer.min_width]
            set net_type [get_attribute $shape net_type]
         }]} continue
         
         set tlength [expr $tlength + $length]
         if {$net_type == "clock" && abs($width - $minwidth) < 0.001} {
            set mlength [expr $mlength + $length]
         }
      }
      
      set ndr_pct [expr $tlength > 0 ? (($tlength - $mlength) / $tlength) * 100.0 : 0.0]
      
      if {$ndr_pct < $threshold} {
         lappend non_compliant_nets $netname
         puts "❌ $netname: [format "%.1f%%" $ndr_pct] (Below threshold)"
      } else {
         incr compliant_count
         puts "✅ $netname: [format "%.1f%%" $ndr_pct] (Compliant)"
      }
   }
   
   # Summary and recommendations
   puts [string repeat "-" 80]
   puts "SUMMARY:"
   puts "  Nets analyzed: $total_analyzed"
   puts "  Compliant nets: $compliant_count"
   puts "  Non-compliant nets: [llength $non_compliant_nets]"
   puts "  Overall compliance rate: [format "%.1f%%" [expr double($compliant_count) / $total_analyzed * 100.0]]"
   
   if {[llength $non_compliant_nets] > 0} {
      puts ""
      puts "RECOMMENDATIONS FOR NON-COMPLIANT NETS:"
      puts "1. Check routing congestion in critical areas"
      puts "2. Review NDR constraints and layer preferences"
      puts "3. Consider adjusting floorplan for better routability" 
      puts "4. Verify power grid interference with signal routing"
      puts "5. Run incremental routing with relaxed DRC constraints"
   }
   
   return $non_compliant_nets
}

#-------------------------------------------------------------------------------
# Procedure: export_ndr_report
# Purpose: Export NDR analysis results to CSV file for external analysis
# Arguments: argv - List of net names, filename - Output CSV file
# Returns: None (creates CSV file)
#
# Enhancement: Data export for spreadsheet analysis and tracking
#-------------------------------------------------------------------------------
proc export_ndr_report {argv filename} {
   # Open output file
   if {[catch {set fp [open $filename "w"]} err]} {
      puts "ERROR: Cannot create file $filename: $err"
      return
   }
   
   # Write CSV header
   puts $fp "Net_Name,Total_Length_um,Default_Length_um,NDR_Length_um,NDR_Percentage,Total_Shapes,Clock_Shapes,NDR_Shapes,Compliance_Status"
   
   foreach netname $argv {
      if {[sizeof_collection [get_nets $netname -quiet]] == 0} {
         puts $fp "$netname,ERROR,ERROR,ERROR,ERROR,ERROR,ERROR,ERROR,NET_NOT_FOUND"
         continue
      }
      
      # Calculate metrics (simplified version)
      set tlength 0.0
      set mlength 0.0
      set total_shapes 0
      set clock_shapes 0
      set ndr_shapes 0
      
      set net_shapes [get_shapes -of_objects [get_nets $netname] -quiet]
      foreach_in_collection shape $net_shapes {
         incr total_shapes
         if {[catch {
            set length [get_attribute $shape length]
            set width [get_attribute $shape width]
            set minwidth [get_attribute $shape layer.min_width]
            set net_type [get_attribute $shape net_type]
         }]} continue
         
         set tlength [expr $tlength + $length]
         if {$net_type == "clock"} {
            incr clock_shapes
            if {abs($width - $minwidth) < 0.001} {
               set mlength [expr $mlength + $length]
            } else {
               incr ndr_shapes
            }
         }
      }
      
      set ndr_length [expr $tlength - $mlength]
      set ndr_pct [expr $tlength > 0 ? ($ndr_length / $tlength) * 100.0 : 0.0]
      set status [expr $ndr_pct >= 75.0 ? "COMPLIANT" : "NON_COMPLIANT"]
      
      puts $fp [format "%s,%.3f,%.3f,%.3f,%.2f,%d,%d,%d,%s" \
         $netname $tlength $mlength $ndr_length $ndr_pct \
         $total_shapes $clock_shapes $ndr_shapes $status]
   }
   
   close $fp
   puts "NDR analysis report exported to: $filename"
}

#===============================================================================
# USAGE EXAMPLES AND HELP
#===============================================================================

# Print usage information
proc ndr_help {} {
   puts "NDR Analysis Tool - Usage Guide"
   puts "==============================="
   puts ""
   puts "Basic Analysis:"
   puts "  ndr_net_length {net1 net2 net3}"
   puts ""
   puts "Detailed Layer Analysis:"
   puts "  ndr_net_length_detailed {net1 net2 net3}"
   puts ""
   puts "Compliance Report:"
   puts "  ndr_compliance_report {net1 net2 net3} ?threshold?"
   puts "  # Default threshold is 75%"
   puts ""
   puts "Export to CSV:"
   puts "  export_ndr_report {net1 net2 net3} output_file.csv"
   puts ""
   puts "Examples:"
   puts "  source ndr_analysis.tcl"
   puts "  ndr_net_length {clk_main clk_cpu clk_mem}"
   puts "  set bad_nets [ndr_compliance_report {clk_*} 80.0]"
   puts "  export_ndr_report \$bad_nets ndr_issues.csv"
}

puts "NDR Analysis Tool loaded successfully. Type 'ndr_help' for usage information."
