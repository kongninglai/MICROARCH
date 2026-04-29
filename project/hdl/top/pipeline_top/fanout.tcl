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

# Drive strength of a fanout-buffer cell. Returns 0 for non-buffers (incl.
# unrelated cell families like buffer$/buffer16$ that aren't in the bufferH<N>$
# rule). Recognized: bufferH<N>$ and bufferHInv<N>$ for any positive integer N.
proc buffer_strength {ref} {
    if {[regexp {^bufferH(?:Inv)?([0-9]+)\$$} $ref -> sz]} {
        return $sz
    }
    return 0
}

# Print a "driver:"/"drivers:" section for a net's drivers, with full
# hierarchical chain. Falls back to "input port '<name>'" for nets fed by a
# top-level input port, or "(none)" for undriven. `indent` is the leading
# whitespace applied to every emitted line.
proc emit_drivers {top_name drv_pin in_ports indent} {
    set lines {}
    foreach_in_collection p $drv_pin {
        set c [get_cells -of_objects $p]
        set chain [build_chain $top_name [get_object_name $c]]
        set port  [lindex [split [get_object_name $p] "/"] end]
        lappend lines "${chain}.${port}"
    }
    if {[llength $lines] == 0} {
        foreach_in_collection p $in_ports {
            lappend lines "input port '[get_object_name $p]'"
        }
    }
    if {[llength $lines] == 0} {
        echo "${indent}driver: (none)"
    } elseif {[llength $lines] == 1} {
        echo "${indent}driver: [lindex $lines 0]"
    } else {
        echo "${indent}drivers:"
        foreach line $lines {
            echo "${indent}  $line"
        }
    }
}

proc fanout_check {args} {
    # ---- argument parsing ----
    set print_loads 0
    set valid_classes {violation warning info ok}
    set print_only $valid_classes  ;# default: print every class
    set i 0
    while {$i < [llength $args]} {
        set arg [lindex $args $i]
        switch -- $arg {
            "-print_loads" {
                set print_loads 1
                incr i
            }
            "-print_only" {
                incr i
                if {$i >= [llength $args]} {
                    error "fanout_check: -print_only requires an argument (comma-separated subset of: [join $valid_classes {, }])"
                }
                set print_only [split [lindex $args $i] ","]
                foreach c $print_only {
                    if {[lsearch $valid_classes $c] < 0} {
                        error "fanout_check: -print_only: unknown class '$c' (valid: [join $valid_classes {, }])"
                    }
                }
                incr i
            }
            default {
                error "fanout_check: unknown option '$arg' (valid: -print_loads, -print_only <classes>)"
            }
        }
    }
    set print_violations [expr {[lsearch $print_only "violation"] >= 0}]
    set print_warnings   [expr {[lsearch $print_only "warning"]   >= 0}]
    set print_infos      [expr {[lsearch $print_only "info"]      >= 0}]
    set print_oks        [expr {[lsearch $print_only "ok"]        >= 0}]

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

        set leaf_name [lindex [split $netname "/"] end]

        # Leaf-level driver: traverse through hierarchical port boundaries.
        # Computed up front so every classification below can include a
        # "driver: ..." line in its report.
        set drv_pin [get_pins -of_objects $n -leaf -filter "direction == out"]
        set has_internal_driver [expr {[sizeof_collection $drv_pin] > 0}]
        set has_external_driver [expr {!$has_internal_driver && $n_ins > 0}]
        set has_external_loads  [expr {$n_outs > 0}]

        # Clock/reset detection: skip the buffer rule for these signals since
        # they're typically distributed by clock-tree synthesis or a reset
        # distribution network, not the regular bufferH<N>$ family.
        set sig_type [detect_clock_or_reset $leaf_name]
        if {$sig_type ne ""} {
            incr n_infos
            if {$print_infos} {
                if {$sig_type eq "clock"} {
                    echo "INFO: wire '$leaf_name' (fanout=$fo) is a clock signal — buffer rule not applied (typically handled by clock-tree synthesis)"
                } else {
                    echo "INFO: wire '$leaf_name' (fanout=$fo) is a reset signal — buffer rule not applied (typically handled by reset distribution network)"
                }
                emit_drivers $top_name $drv_pin $in_ports "  "
            }
            continue
        }

        # Tied-constant detection: nets driven by Synopsys' GTECH constant cells
        # (**logic_0** / **logic_1**, with the canonical wire name *Logic0*/*Logic1*)
        # carry a fixed value. They have no driving gate to size, so the fanout
        # buffer rule doesn't apply — flag as INFO instead of VIOLATION.
        set const_type ""
        if {$leaf_name eq "*Logic0*"} {
            set const_type "logic 0"
        } elseif {$leaf_name eq "*Logic1*"} {
            set const_type "logic 1"
        } elseif {$has_internal_driver} {
            foreach_in_collection p $drv_pin {
                set r [get_attribute [get_cells -of_objects $p] ref_name]
                if {$r eq "**logic_0**"} { set const_type "logic 0"; break }
                if {$r eq "**logic_1**"} { set const_type "logic 1"; break }
            }
        }
        if {$const_type ne ""} {
            incr n_infos
            if {$print_infos} {
                echo "INFO: wire '$leaf_name' (fanout=$fo) is a tied constant ($const_type) — buffer rule not applied (constant signals aren't restricted by fanout rules)"
                emit_drivers $top_name $drv_pin $in_ports "  "
            }
            continue
        }

        # Undefined (X) signal detection: 1'bx assignments are mapped by DC to
        # auto-generated stubs named *GEN*<N> (with literal asterisks). These
        # have no real driver to size — buffer rule does not apply, flag as INFO.
        set is_undefined 0
        if {$has_internal_driver} {
            foreach_in_collection p $drv_pin {
                set r [get_attribute [get_cells -of_objects $p] ref_name]
                if {[regexp {^\*GEN\*[0-9]+$} $r]} { set is_undefined 1; break }
            }
        }
        if {$is_undefined} {
            incr n_infos
            if {$print_infos} {
                echo "INFO: wire '$leaf_name' (fanout=$fo) is an undefined (X) signal — buffer rule not applied (undefined signals aren't restricted by fanout rules)"
                emit_drivers $top_name $drv_pin $in_ports "  "
            }
            continue
        }

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
                if {$print_infos} {
                    set n_bus [llength $bus_drivers]
                    echo "INFO: wire '$leaf_name' (fanout=$fo) driven by $n_bus tristate_bus_driver(s) — off-chip bus pattern, buffer rule not applied"
                    echo "  drivers:"
                    foreach info $bus_drivers {
                        lassign $info c r p
                        set chain [build_chain $top_name [get_object_name $c]]
                        set port  [lindex [split [get_object_name $p] "/"] end]
                        echo "    ${chain}.${port}"
                    }
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
                }
                continue
            }
            if {[llength $bus_drivers] > 0 && [llength $non_bus_drivers] > 0} {
                # Mixed → VIOLATION on the non-bus drivers
                incr n_violations
                if {$print_violations} {
                    set n_bad [llength $non_bus_drivers]
                    echo "VIOLATION: wire '$leaf_name' has $n_bad non-tristate_bus_driver cell(s) on a bus that already includes tristate_bus_driver(s) — replace these with tristate_bus_driver*\$ to match the off-chip bus pattern"
                    echo "  bad drivers:"
                    foreach info $non_bus_drivers {
                        lassign $info c r p
                        set chain [build_chain $top_name [get_object_name $c]]
                        set port  [lindex [split [get_object_name $p] "/"] end]
                        echo "    ${chain}.${port}"
                    }
                }
                continue
            }
        }

        # Boundary case: any external involvement → WARNING (rule can't be cleanly
        # applied because either the driver or some loads are outside this scope).
        if {$has_external_driver || $has_external_loads} {
            if {!$has_external_driver && !$has_internal_driver} {
                # No driver at all — undriven, skip
                continue
            }

            # Reason describing why the buffer rule wasn't applied
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
            if {$print_warnings} {
                echo "WARNING: '$leaf_name' (fanout=$fo: $n_pins internal + $n_outs output ports) — $reason_str; verify buffering at parent"
                emit_drivers $top_name $drv_pin $in_ports "  "
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

        # -------------------------------------------------
        # Determine which buffer this fanout requires
        # -------------------------------------------------
        set expected_refs {}
        if {$fo <= 16} {
            set expected_refs {bufferH16$ bufferHInv16$}
        } elseif {$fo <= 64} {
            set expected_refs {bufferH64$ bufferHInv64$}
        } elseif {$fo <= 256} {
            set expected_refs {bufferH256$ bufferHInv256$}
        } elseif {$fo <= 1024} {
            set expected_refs {bufferH1024$ bufferHInv1024$}
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
            # Buffer rule satisfied — emit OK showing actual matches expected.
            # Skip the empty-driver case (vacuous match) — that's a separate anomaly.
            if {$n_drivers > 0} {
                incr n_ok
                if {$print_oks} {
                    set first_pin [lindex [lindex $drv_info 0] 2]
                    set wire_leaf [lindex [split [get_object_name [get_nets -of_objects $first_pin]] "/"] end]
                    if {$n_drivers == 1} {
                        lassign [lindex $drv_info 0] drv_cell ref drv_pin1
                        set drv_chain [build_chain $top_name [get_object_name $drv_cell]]
                        set drv_port  [lindex [split [get_object_name $drv_pin1] "/"] end]
                        echo "OK: wire '$wire_leaf' (fanout=$fo) driven by $ref (matches expected [join $expected_refs { or }]) — buffer rule satisfied"
                        echo "  driver: ${drv_chain}.${drv_port}"
                    } else {
                        set actual_refs {}
                        foreach info $drv_info { lappend actual_refs [lindex $info 1] }
                        set actual_set [lsort -unique $actual_refs]
                        echo "OK: wire '$wire_leaf' (fanout=$fo) has $n_drivers drivers (refs: [join $actual_set {, }]), all in expected {[join $expected_refs {, }]} — buffer rule satisfied"
                        echo "  drivers:"
                        foreach info $drv_info {
                            lassign $info c r p
                            set chain [build_chain $top_name [get_object_name $c]]
                            set port  [lindex [split [get_object_name $p] "/"] end]
                            echo "    ${chain}.${port}"
                        }
                    }
                }
            }
            continue
        }

        # Over-buffering check: if every driver is a recognized bufferH<N>$ /
        # bufferHInv<N>$ cell with strength >= the required size, the rule is
        # technically satisfied (over-buffering is allowed, just wasteful).
        # We're already in the fully-internal branch — driver and all loads are
        # known and local — so the user's "no external/unknown" condition holds.
        # all_match is 0 here, so at least one driver is in a strictly larger
        # bucket than expected_refs.
        set required_size [buffer_strength [lindex $expected_refs 0]]
        set over_buffered 1
        foreach info $drv_info {
            set sz [buffer_strength [lindex $info 1]]
            if {$sz < $required_size} {
                set over_buffered 0
                break
            }
        }
        if {$over_buffered} {
            incr n_infos
            if {$print_infos} {
                set first_pin [lindex [lindex $drv_info 0] 2]
                set wire_leaf [lindex [split [get_object_name [get_nets -of_objects $first_pin]] "/"] end]
                if {$n_drivers == 1} {
                    lassign [lindex $drv_info 0] drv_cell ref drv_pin1
                    set drv_chain [build_chain $top_name [get_object_name $drv_cell]]
                    set drv_port  [lindex [split [get_object_name $drv_pin1] "/"] end]
                    echo "INFO: wire '$wire_leaf' (fanout=$fo) over-buffered — driven by $ref; required is [join $expected_refs {/}] or stronger — allowed, but a smaller buffer would suffice"
                    echo "  driver: ${drv_chain}.${drv_port}"
                } else {
                    set actual_refs {}
                    foreach info $drv_info { lappend actual_refs [lindex $info 1] }
                    set actual_set [lsort -unique $actual_refs]
                    echo "INFO: wire '$wire_leaf' (fanout=$fo) over-buffered — $n_drivers drivers (refs: [join $actual_set {, }]); required is [join $expected_refs {/}] or stronger — allowed, but smaller buffers would suffice"
                    echo "  drivers:"
                    foreach info $drv_info {
                        lassign $info c r p
                        set chain [build_chain $top_name [get_object_name $c]]
                        set port  [lindex [split [get_object_name $p] "/"] end]
                        echo "    ${chain}.${port}"
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
        if {$print_violations} {
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