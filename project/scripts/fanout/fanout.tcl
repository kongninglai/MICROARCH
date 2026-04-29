# fanout.tcl — fanout buffer rule check.
# Source once per design_vision session, then call:
#   fanout_check                  -- report violations only
#   fanout_check -print_loads     -- also list every leaf load under each violation

# Build "(top) -> inst1(mod1) -> ... -> leafinst(leafmod)" chain
# from a cell's full hierarchical name (e.g. "d/m/inv1_").
proc build_chain {top_name cell_full} {
    set chain  "(${top_name})"
    set prefix ""
    foreach inst [split $cell_full "/"] {
        if {$prefix == ""} {
            set prefix $inst
        } else {
            set prefix "$prefix/$inst"
        }
        set ref_at_path [get_attribute [get_cells $prefix] ref_name]
        append chain " -> ${inst}(${ref_at_path})"
    }
    return $chain
}

# Build a nested-dict tree from leaf-load pins. Each node may contain
# a "__pins__" entry (list of pin names on that leaf cell) and/or child
# instance names. Example: dict path d/m/inv1_/__pins__ -> {in}.
proc build_loads_tree {load_pins} {
    set tree [dict create]
    foreach_in_collection lp $load_pins {
        set parts     [split [get_object_name $lp] "/"]
        set pin_name  [lindex $parts end]
        set cell_path [lrange $parts 0 end-1]

        set keys [concat $cell_path __pins__]
        set existing {}
        if {[dict exists $tree {*}$keys]} {
            set existing [dict get $tree {*}$keys]
        }
        dict set tree {*}$keys [linsert $existing end $pin_name]
    }
    return $tree
}

# Recursively print a subtree. Linear chains are collapsed onto one line;
# branch points emit "prefix:" and indent the children by 4.
proc print_subtree {node scope_chain scope_path indent} {
    set children {}
    set has_pins false
    set pins     {}
    foreach key [dict keys $node] {
        if {$key eq "__pins__"} {
            set has_pins true
            set pins [dict get $node __pins__]
        } else {
            lappend children $key
        }
    }

    # Leaf: emit one line per loaded pin, with the local wire feeding it.
    # Pins on the same cell may connect to different local wires (e.g. nand2$
    # m1(out,in1,in2) — both inputs carry the same upstream signal but via
    # different local wires), so look up each pin's wire individually.
    if {[llength $children] == 0 && $has_pins} {
        set cell_path [join $scope_path "/"]
        foreach pin_name [lsort $pins] {
            set wire [lindex [split [get_object_name \
                [get_nets -of_objects [get_pins "${cell_path}/${pin_name}"]]] "/"] end]
            echo "${indent}${scope_chain}.${pin_name}    via $wire"
        }
        return
    }

    # Linear continuation: extend chain, recurse same indent
    if {[llength $children] == 1 && !$has_pins} {
        set inst     [lindex $children 0]
        set new_path [linsert $scope_path end $inst]
        set ref      [get_attribute [get_cells [join $new_path "/"]] ref_name]
        print_subtree [dict get $node $inst] \
                      "${scope_chain} -> ${inst}(${ref})" \
                      $new_path $indent
        return
    }

    # Branch point: print "chain:" then deeper-indent each child
    echo "${indent}${scope_chain}:"
    set deeper "${indent}    "
    if {$has_pins} {
        set cell_path [join $scope_path "/"]
        foreach pin_name [lsort $pins] {
            set wire [lindex [split [get_object_name \
                [get_nets -of_objects [get_pins "${cell_path}/${pin_name}"]]] "/"] end]
            echo "${deeper}.${pin_name}    via $wire"
        }
    }
    foreach inst [lsort $children] {
        set new_path [linsert $scope_path end $inst]
        set ref      [get_attribute [get_cells [join $new_path "/"]] ref_name]
        print_subtree [dict get $node $inst] \
                      "${inst}(${ref})" \
                      $new_path $deeper
    }
}

# Drive printing of the loads tree. Each top-level child is its own line,
# starting with "(top) -> ...".
proc print_loads_tree {tree top_name indent} {
    foreach inst [lsort [dict keys $tree]] {
        if {$inst eq "__pins__"} { continue }
        set ref [get_attribute [get_cells $inst] ref_name]
        print_subtree [dict get $tree $inst] \
                      "(${top_name}) -> ${inst}(${ref})" \
                      [list $inst] $indent
    }
}

# Detect a clock or reset signal by leaf name. Uses underscore-separated
# token matching (case-insensitive) to avoid false positives like "first"
# (contains 'rst') or "block" (contains 'lock'). Returns "clock", "reset", or "".
proc detect_clock_or_reset {leaf_name} {
    foreach tok [split [string tolower $leaf_name] "_"] {
        if {$tok eq "clk" || $tok eq "clock"} { return "clock" }
        if {$tok eq "rst" || $tok eq "reset"
            || $tok eq "rstn" || $tok eq "resetn"
            || $tok eq "nrst" || $tok eq "nreset"} { return "reset" }
    }
    return ""
}

proc fanout_check {args} {
    # ---- argument parsing ----
    set print_loads 0
    foreach arg $args {
        switch -- $arg {
            "-print_loads" { set print_loads 1 }
            default {
                error "fanout_check: unknown option '$arg' (valid: -print_loads)"
            }
        }
    }

    set top_name [get_object_name [current_design]]
    array set _reported {}
    set n_violations 0
    set n_warnings   0
    set n_infos      0
    set n_ok         0

    echo "Format: (top) -> inst(submod) -> ... -> inst(leaf_cell).pin"
    if {$print_loads} {
        echo "Loads use the same format with ' via LOCAL_WIRE' appended (the local net feeding the pin)"
        echo "Common chain prefixes are factored: a line ending ':' groups its indented children"
    }
    echo ""

    # Buffer rule kicks in for fanout > 4, so threshold 5 (DC's -threshold is
    # inclusive: it returns fanout >= N).
    set hi_fanout_nets [all_high_fanout -nets -threshold 5]
    set n_analyzed [sizeof_collection $hi_fanout_nets]

    foreach_in_collection n $hi_fanout_nets {

        # Count loads from both sides: leaf cell input pins (internal loads) AND
        # top-level output ports (external loads, which DC also counts as fanout).
        set load_pins  [get_pins  -of_objects $n -leaf -filter "direction == in"]
        set load_ports [get_ports -of_objects $n -filter "direction == out"]
        set in_ports   [get_ports -of_objects $n -filter "direction == in"]
        set n_pins  [sizeof_collection $load_pins]
        set n_outs  [sizeof_collection $load_ports]
        set n_ins   [sizeof_collection $in_ports]
        set fo      [expr {$n_pins + $n_outs}]

        set netname [get_object_name $n]

        # Clock/reset detection: skip the buffer rule for these signals since
        # they're typically distributed by clock-tree synthesis or a reset
        # distribution network, not the regular bufferH<N>$ family.
        set leaf_name [lindex [split $netname "/"] end]
        set sig_type  [detect_clock_or_reset $leaf_name]
        if {$sig_type ne ""} {
            incr n_infos
            if {$sig_type eq "clock"} {
                echo "INFO: wire '$netname' (fanout=$fo) is a clock signal — buffer rule not applied (typically handled by clock-tree synthesis)"
            } else {
                echo "INFO: wire '$netname' (fanout=$fo) is a reset signal — buffer rule not applied (typically handled by reset distribution network)"
            }
            continue
        }

        # Leaf-level driver: traverse through hierarchical port boundaries
        set drv_pin [get_pins -of_objects $n -leaf -filter "direction == out"]
        set has_internal_driver [expr {[sizeof_collection $drv_pin] > 0}]
        set has_external_driver [expr {!$has_internal_driver && $n_ins > 0}]
        set has_external_loads  [expr {$n_outs > 0}]

        # tristate_bus_driver case (off-chip bus pattern) — checked BEFORE the
        # boundary case because off-chip buses often have output port loads.
        # The intent is intentional: don't flag the bus, just note it.
        if {$has_internal_driver} {
            set bus_drivers     {}
            set non_bus_drivers {}
            foreach_in_collection p $drv_pin {
                set c [get_cells -of_objects $p]
                set r [get_attribute $c ref_name]
                if {[string match "tristate_bus_driver*\$" $r]} {
                    lappend bus_drivers     [list $c $r $p]
                } else {
                    lappend non_bus_drivers [list $c $r $p]
                }
            }

            if {[llength $bus_drivers] > 0 && [llength $non_bus_drivers] == 0} {
                # All drivers are tristate_bus_driver → INFO (off-chip bus)
                incr n_infos
                set n_bus [llength $bus_drivers]
                echo "INFO: wire '$netname' (fanout=$fo) driven by $n_bus tristate_bus_driver(s) — off-chip bus pattern, buffer rule not applied"
                if {$print_loads} {
                    echo "  drivers:"
                    foreach info $bus_drivers {
                        lassign $info c r p
                        set chain [build_chain $top_name [get_object_name $c]]
                        set port  [lindex [split [get_object_name $p] "/"] end]
                        echo "    ${chain}.${port}"
                    }
                    if {$n_pins > 0} {
                        echo "  internal loads:"
                        print_loads_tree [build_loads_tree $load_pins] $top_name "    "
                    }
                    if {$n_outs > 0} {
                        echo "  external output ports:"
                        foreach_in_collection p $load_ports {
                            echo "    [get_object_name $p]"
                        }
                    }
                }
                continue
            }
            if {[llength $bus_drivers] > 0 && [llength $non_bus_drivers] > 0} {
                # Mixed → VIOLATION on the non-bus drivers
                incr n_violations
                set n_bad [llength $non_bus_drivers]
                echo "VIOLATION: wire '$netname' has $n_bad non-tristate_bus_driver cell(s) on a bus that already includes tristate_bus_driver(s) — replace these with tristate_bus_driver*\$ to match the off-chip bus pattern"
                echo "  bad drivers:"
                foreach info $non_bus_drivers {
                    lassign $info c r p
                    set chain [build_chain $top_name [get_object_name $c]]
                    set port  [lindex [split [get_object_name $p] "/"] end]
                    echo "    ${chain}.${port}"
                }
                continue
            }
        }

        # Boundary case: any external involvement → WARNING (rule can't be cleanly
        # applied because either the driver or some loads are outside this scope).
        if {$has_external_driver || $has_external_loads} {
            # Build driver description
            if {$has_external_driver} {
                set port_names {}
                foreach_in_collection p $in_ports {
                    lappend port_names [get_object_name $p]
                }
                set driver_desc "input port '[join $port_names {, }]'"
            } elseif {$has_internal_driver} {
                set drv_ref [get_attribute [get_cells -of_objects $drv_pin] ref_name]
                set driver_desc "internal $drv_ref"
            } else {
                # No driver at all — undriven, skip
                continue
            }

            # Build loads description
            set load_parts {}
            if {$n_pins > 0} { lappend load_parts "$n_pins internal" }
            if {$n_outs > 0} { lappend load_parts "$n_outs output port(s)" }
            set loads_desc [join $load_parts " + "]
            if {$loads_desc == ""} { set loads_desc "none" }

            # Build reason describing why the buffer rule wasn't applied
            set reasons {}
            if {$has_external_driver} {
                lappend reasons "driver is external"
            }
            if {$has_external_loads} {
                if {$n_pins == 0} {
                    lappend reasons "loads are external"
                } else {
                    lappend reasons "some loads are external"
                }
            }
            set reason_str [join $reasons " and "]

            incr n_warnings
            echo "WARNING: '$netname' (fanout=$fo: $n_pins internal + $n_outs output ports) — driver: $driver_desc; loads: $loads_desc; $reason_str; verify buffering at parent"
            if {$print_loads} {
                if {$n_pins > 0} {
                    echo "  internal loads:"
                    print_loads_tree [build_loads_tree $load_pins] $top_name "    "
                }
                if {$n_outs > 0} {
                    echo "  external output ports:"
                    foreach_in_collection p $load_ports {
                        echo "    [get_object_name $p]"
                    }
                }
            }
            continue
        }

        # Fully internal — apply the buffer rule strictly to every driver.
        # Collect (cell, ref, pin) for each leaf driver so we can handle
        # multi-driver nets (e.g. tristate buses) correctly.
        set drv_info {}
        foreach_in_collection p $drv_pin {
            set c [get_cells -of_objects $p]
            set r [get_attribute $c ref_name]
            lappend drv_info [list $c $r $p]
        }
        set n_drivers [llength $drv_info]

        if {[string match "*logic*" $r] ||
            [string match "*Logic*" $r] ||
            [string match "*TIE*"   $r] ||
            [string match "*tie*"   $r] ||
            [string match "*GEN*"   $r]} {
            continue
        }

        # -------------------------------------------------
        # Determine which buffer this fanout requires
        # -------------------------------------------------
        set expected_refs {}
        if {$fo <= 16} {
            set expected_refs {bufferH16$ bufferHInv16$ bufferH64$ bufferHInv64$ bufferH256$ bufferHInv256$ bufferH1024$ bufferHInv1024$ bufferH4096$ bufferHInv4096$}
        } elseif {$fo <= 64} {
            set expected_refs {bufferH64$ bufferHInv64$ bufferH256$ bufferHInv256$ bufferH1024$ bufferHInv1024$ bufferH4096$ bufferHInv4096$}
        } elseif {$fo <= 256} {
            set expected_refs {bufferH256$ bufferHInv256$ bufferH1024$ bufferHInv1024$ bufferH4096$ bufferHInv4096$}
        } elseif {$fo <= 1024} {
            set expected_refs {bufferH1024$ bufferHInv1024$ bufferH4096$ bufferHInv4096$}
        } elseif {$fo <= 4096} {
            set expected_refs {bufferH4096$ bufferHInv4096$}
        }
        if {[llength $expected_refs] == 0} { continue }

        # Check every driver against the expected buffer set
        set all_match 1
        foreach info $drv_info {
            if {[lsearch $expected_refs [lindex $info 1]] < 0} { set all_match 0 }
        }
        if {$all_match} {
            # Buffer rule satisfied — emit INFO showing actual matches expected.
            # Skip the empty-driver case (vacuous match) — that's a separate anomaly.
            if {$n_drivers > 0} {
                incr n_ok
                set first_pin [lindex [lindex $drv_info 0] 2]
                set wire_leaf [lindex [split [get_object_name [get_nets -of_objects $first_pin]] "/"] end]
                if {$n_drivers == 1} {
                    lassign [lindex $drv_info 0] drv_cell ref drv_pin1
                    set drv_chain [build_chain $top_name [get_object_name $drv_cell]]
                    set drv_port  [lindex [split [get_object_name $drv_pin1] "/"] end]
                    # echo "OK: wire '$wire_leaf' (fanout=$fo) driven by $ref (matches expected [join $expected_refs { or }]) — buffer rule satisfied"
                    # echo "  driver: ${drv_chain}.${drv_port}"
                } else {
                    set actual_refs {}
                    foreach info $drv_info { lappend actual_refs [lindex $info 1] }
                    set actual_set [lsort -unique $actual_refs]
                    # echo "OK: wire '$wire_leaf' (fanout=$fo) has $n_drivers drivers (refs: [join $actual_set {, }]), all in expected {[join $expected_refs {, }]} — buffer rule satisfied"
                    # echo "  drivers:"
                    foreach info $drv_info {
                        lassign $info c r p
                        set chain [build_chain $top_name [get_object_name $c]]
                        set port  [lindex [split [get_object_name $p] "/"] end]
                        # echo "    ${chain}.${port}"
                    }
                }
            }
            continue
        }

        # Dedup: same electrical signal can appear at multiple hierarchy levels.
        # Use a key built from the sorted set of driver cell names — same set
        # of leaf drivers across levels means same electrical signal.
        set names {}
        foreach info $drv_info { lappend names [get_object_name [lindex $info 0]] }
        set dedup_key [join [lsort $names] " | "]
        if {[info exists _reported($dedup_key)]} { continue }
        set _reported($dedup_key) 1

        # Wire leaf name (same for all drivers — they share the net)
        set first_pin [lindex [lindex $drv_info 0] 2]
        set wire_leaf [lindex [split [get_object_name [get_nets -of_objects $first_pin]] "/"] end]

        incr n_violations
        if {$n_drivers == 1} {
            lassign [lindex $drv_info 0] drv_cell ref drv_pin1
            set drv_chain [build_chain $top_name [get_object_name $drv_cell]]
            set drv_port  [lindex [split [get_object_name $drv_pin1] "/"] end]
            echo "VIOLATION: wire '$wire_leaf' (fanout=$fo) driven by $ref, expected [join $expected_refs { or }]"
            echo "  driver: ${drv_chain}.${drv_port}"
        } else {
            echo "VIOLATION: wire '$wire_leaf' (fanout=$fo) has $n_drivers drivers feeding loads directly — insert a [join $expected_refs { or }] between this bus and its loads"
            echo "  drivers:"
            foreach info $drv_info {
                lassign $info c r p
                set chain [build_chain $top_name [get_object_name $c]]
                set port  [lindex [split [get_object_name $p] "/"] end]
                echo "    ${chain}.${port}"
            }
        }
        if {$print_loads} {
            echo "  loads:"
            print_loads_tree [build_loads_tree $load_pins] $top_name "    "
        }
    }

    # Final summary
    set v_word [expr {$n_violations == 1 ? "violation" : "violations"}]
    set w_word [expr {$n_warnings   == 1 ? "warning"   : "warnings"}]
    set i_word [expr {$n_infos      == 1 ? "info"      : "infos"}]
    set net_word [expr {$n_analyzed == 1 ? "high-fanout net" : "high-fanout nets"}]
    set summary "fanout_check: analyzed $n_analyzed $net_word — $n_violations $v_word, $n_warnings $w_word, $n_infos $i_word, $n_ok ok"
    if {$n_violations == 0 && $n_warnings == 0 && $n_infos == 0} {
        append summary " (no issues found)"
    }
    echo ""
    echo $summary
}
