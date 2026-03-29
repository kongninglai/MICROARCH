# -----------------------------------------
# Flatten the design so all nets are at one
# level and get_pins sees all leaf loads
# -----------------------------------------
ungroup -all -flatten

set hf_nets [all_high_fanout -nets -threshold 5]

# Open output file
set outfile [open "fanout_violations.txt" "w"]

foreach_in_collection n $hf_nets {

    set netname [get_object_name $n]

    if {[string match "*clk*"     $netname] ||
        [string match "*reset_n*" $netname] ||
        [string match "*reset*"   $netname] ||
        [string match "*rst*"     $netname]} {
        continue
    }

    set fo 0
    set drv_pins ""

    foreach_in_collection p [get_pins -of_objects $n] {
        set dir [get_attribute $p direction]
        set oc  [get_attribute $p object_class]

        if {$dir eq "in"} {
            incr fo
        } elseif {$dir eq "out" && $oc eq "pin"} {
            if {$drv_pins eq ""} {
                set drv_pins $p
            } else {
                set drv_pins [add_to_collection $drv_pins $p]
            }
        }
    }

    if {$fo <= 4} { continue }

    if {$drv_pins eq "" || [sizeof_collection $drv_pins] == 0} {
        puts $outfile "VIOLATION: $netname fanout=$fo drv=PORT (expected buffer)"
        continue
    }

    foreach_in_collection drv_pin $drv_pins {

        set drv_cell [get_cells -of_objects $drv_pin]
        if {[sizeof_collection $drv_cell] == 0} { continue }

        set ref [get_attribute $drv_cell ref_name]

        if {[string match "*logic*" $ref] ||
            [string match "*Logic*" $ref] ||
            [string match "*TIE*"   $ref] ||
            [string match "*tie*"   $ref]} {
            continue
        }

        if {$fo <= 16} {
            if {$ref ni {"bufferH16$" "bufferHInv16$" "bufferH64$" "bufferHInv64$" "bufferH256$" "bufferHInv256$" "bufferH1024$" "bufferHInv1024$" "bufferH4096$" "bufferHInv4096$" "tristate_bus_driver1$" "tristate_bus_driver8$" "tristate_bus_driver16$"}} {
                puts $outfile "VIOLATION: $netname fanout=$fo drv=$ref (expected >= H16)"
            }
        } elseif {$fo <= 64} {
            if {$ref ni {"bufferH64$" "bufferHInv64$" "bufferH256$" "bufferHInv256$" "bufferH1024$" "bufferHInv1024$" "bufferH4096$" "bufferHInv4096$" "tristate_bus_driver1$" "tristate_bus_driver8$" "tristate_bus_driver16$"}} {
                puts $outfile "VIOLATION: $netname fanout=$fo drv=$ref (expected >= H64)"
            }
        } elseif {$fo <= 256} {
            if {$ref ni {"bufferH256$" "bufferHInv256$" "bufferH1024$" "bufferHInv1024$" "bufferH4096$" "bufferHInv4096$" "tristate_bus_driver1$" "tristate_bus_driver8$" "tristate_bus_driver16$"}} {
                puts $outfile "VIOLATION: $netname fanout=$fo drv=$ref (expected >= H256)"
            }
        } elseif {$fo <= 1024} {
            if {$ref ni {"bufferH1024$" "bufferHInv1024$" "bufferH4096$" "bufferHInv4096$" "tristate_bus_driver1$" "tristate_bus_driver8$" "tristate_bus_driver16$"}} {
                puts $outfile "VIOLATION: $netname fanout=$fo drv=$ref (expected >= H1024)"
            }
        } elseif {$fo <= 4096} {
            if {$ref ni {"bufferH4096$" "bufferHInv4096$" "tristate_bus_driver1$" "tristate_bus_driver8$" "tristate_bus_driver16$"}} {
                puts $outfile "VIOLATION: $netname fanout=$fo drv=$ref (expected >= H4096)"
            }
        } else {
            puts $outfile "VIOLATION: $netname fanout=$fo drv=$ref (fanout exceeds 4096)"
        }
    }
}

# Close file
close $outfile

puts "Fanout violations written to fanout_violations.txt"