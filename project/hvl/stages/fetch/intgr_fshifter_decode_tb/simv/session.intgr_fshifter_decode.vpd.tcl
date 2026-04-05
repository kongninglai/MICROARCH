# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Sun Apr 5 04:39:07 2026
# Designs open: 1
#   V1: intgr_fshifter_decode.vpd
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Source.1: intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.EIP_INCR_LOGIC.CHOOSE_INCR.mux4$_out0
#   Wave.1: 37 signals
#   Group count = 1
#   Group Group1 signal count = 37
# End_DVE_Session_Save_Info

# DVE version: T-2022.06_Full64
# DVE build date: May 31 2022 20:53:03


#<Session mode="Full" path="/home/ecelrc/students/aak3265/MICROARCH/project/hvl/stages/fetch/intgr_fshifter_decode_tb/simv/session.intgr_fshifter_decode.vpd.tcl" type="Debug">

gui_set_loading_session_type Post
gui_continuetime_set

# Close design
if { [gui_sim_state -check active] } {
    gui_sim_terminate
}
gui_close_db -all
gui_expr_clear_all

# Close all windows
gui_close_window -type Console
gui_close_window -type Wave
gui_close_window -type Source
gui_close_window -type Schematic
gui_close_window -type Data
gui_close_window -type DriverLoad
gui_close_window -type List
gui_close_window -type Memory
gui_close_window -type HSPane
gui_close_window -type DLPane
gui_close_window -type Assertion
gui_close_window -type CovHier
gui_close_window -type CoverageTable
gui_close_window -type CoverageMap
gui_close_window -type CovDetail
gui_close_window -type Local
gui_close_window -type Stack
gui_close_window -type Watch
gui_close_window -type Group
gui_close_window -type Transaction



# Application preferences
gui_set_pref_value -key app_default_font -value {Helvetica,10,-1,5,50,0,0,0,0,0}
gui_src_preferences -tabstop 8 -maxbits 24 -windownumber 1
#<WindowLayout>

# DVE top-level session


# Create and position top-level window: TopLevel.1

if {![gui_exist_window -window TopLevel.1]} {
    set TopLevel.1 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.1 TopLevel.1
}
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{8 31} {1430 857}}

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_hide_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_hide_toolbar -toolbar {CopyPaste}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_hide_toolbar -toolbar {TraceInstance}
gui_hide_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Testbench} -dock_state top
gui_set_toolbar_attributes -toolbar {Testbench} -offset 0
gui_show_toolbar -toolbar {Testbench}

# End ToolBar settings

# Docked window settings
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 419]
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 419
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 418} {height 385} {dock_state left} {dock_on_new_line true} {child_hier_colhier 298} {child_hier_coltype 133} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 379]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 379
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 731
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 378} {height 385} {dock_state left} {dock_on_new_line true} {child_data_colvariable 180} {child_data_colvalue 135} {child_data_coltype 111} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 343]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value -1
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 343
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 271} {height 342} {dock_state bottom} {dock_on_new_line true}}
set DriverLoad.1 [gui_create_window -type DriverLoad -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line false -dock_extent 343]
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_width -value_type integer -value 150
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_height -value_type integer -value 343
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DriverLoad.1} {{left 0} {top 0} {width 1150} {height 342} {dock_state bottom} {dock_on_new_line false}}
#### Start - Readjusting docked view's offset / size
set dockAreaList { top left right bottom }
foreach dockArea $dockAreaList {
  set viewList [gui_ekki_get_window_ids -active_parent -dock_area $dockArea]
  foreach view $viewList {
      if {[lsearch -exact [gui_get_window_pref_keys -window $view] dock_width] != -1} {
        set dockWidth [gui_get_window_pref_value -window $view -key dock_width]
        set dockHeight [gui_get_window_pref_value -window $view -key dock_height]
        set offset [gui_get_window_pref_value -window $view -key dock_offset]
        if { [string equal "top" $dockArea] || [string equal "bottom" $dockArea]} {
          gui_set_window_attributes -window $view -dock_offset $offset -width $dockWidth
        } else {
          gui_set_window_attributes -window $view -dock_offset $offset -height $dockHeight
        }
      }
  }
}
#### End - Readjusting docked view's offset / size
gui_sync_global -id ${TopLevel.1} -option true

# MDI window settings
set Source.1 [gui_create_window -type {Source}  -parent ${TopLevel.1}]
gui_show_window -window ${Source.1} -show_state maximized
gui_update_layout -id ${Source.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false}}

# End MDI window settings


# Create and position top-level window: TopLevel.2

if {![gui_exist_window -window TopLevel.2]} {
    set TopLevel.2 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.2 TopLevel.2
}
gui_show_window -window ${TopLevel.2} -show_state maximized -rect {{0 23} {1535 911}}

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_hide_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_hide_toolbar -toolbar {CopyPaste}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_hide_toolbar -toolbar {TraceInstance}
gui_hide_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Testbench} -dock_state top
gui_set_toolbar_attributes -toolbar {Testbench} -offset 0
gui_show_toolbar -toolbar {Testbench}

# End ToolBar settings

# Docked window settings
gui_sync_global -id ${TopLevel.2} -option true

# MDI window settings
set Wave.1 [gui_create_window -type {Wave}  -parent ${TopLevel.2}]
gui_show_window -window ${Wave.1} -show_state maximized
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 445} {child_wave_right 1085} {child_wave_colname 307} {child_wave_colvalue 134} {child_wave_col1 0} {child_wave_col2 1}}

# End MDI window settings

gui_set_env TOPLEVELS::TARGET_FRAME(Source) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Schematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(PathSchematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Wave) none
gui_set_env TOPLEVELS::TARGET_FRAME(List) none
gui_set_env TOPLEVELS::TARGET_FRAME(Memory) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(DriverLoad) none
gui_update_statusbar_target_frame ${TopLevel.1}
gui_update_statusbar_target_frame ${TopLevel.2}

#</WindowLayout>

#<Database>

# DVE Open design session: 

if { ![gui_is_db_opened -db {intgr_fshifter_decode.vpd}] } {
	gui_open_db -design V1 -file intgr_fshifter_decode.vpd -nosource
}
gui_set_precision 1ps
gui_set_time_units 1ns
#</Database>

# DVE Global setting session: 


# Global: Bus

# Global: Expressions

# Global: Signal Time Shift

# Global: Signal Compare

# Global: Signal Groups
gui_load_child_values {intgr_fshifter_decode_tb.uut.STAGE_DECODE.DECODER.TRUE_PREFIX}
gui_load_child_values {intgr_fshifter_decode_tb}
gui_load_child_values {intgr_fshifter_decode_tb.uut}
gui_load_child_values {intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH}
gui_load_child_values {intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC}


set _session_group_1 Group1
gui_sg_create "$_session_group_1"
set Group1 "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { intgr_fshifter_decode_tb.clk intgr_fshifter_decode_tb.rst_bar intgr_fshifter_decode_tb.from_f_cache_line intgr_fshifter_decode_tb.from_f_icache_valid intgr_fshifter_decode_tb.from_wb_flush intgr_fshifter_decode_tb.from_rr_stall intgr_fshifter_decode_tb.from_ex_flush intgr_fshifter_decode_tb.to_rr_pr_valid intgr_fshifter_decode_tb.to_rr_prefixes intgr_fshifter_decode_tb.to_rr_opcode intgr_fshifter_decode_tb.to_rr_modrm intgr_fshifter_decode_tb.to_rr_sib intgr_fshifter_decode_tb.to_rr_disp_size_mux intgr_fshifter_decode_tb.to_rr_addressing_mode intgr_fshifter_decode_tb.to_rr_disp intgr_fshifter_decode_tb.to_rr_imm_size intgr_fshifter_decode_tb.to_rr_imm intgr_fshifter_decode_tb.to_rr_instr_length intgr_fshifter_decode_tb.uut.to_pr_pr_valid intgr_fshifter_decode_tb.uut.to_pr_opcode intgr_fshifter_decode_tb.uut.to_pr_modrm intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH.tail_ptr intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH.incr_amt intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH.instr_valid intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH.instr_invalid intgr_fshifter_decode_tb.uut.STAGE_DECODE.DECODER.TRUE_PREFIX.prefix_num intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.flush_ex intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.take_branch intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.ld_pr_rr intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.instr_valid intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.ld_eip intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.not_flush intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.nand_valid_ld intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.bp_eip_target intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.ex_eip_target intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.i_eip intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.eip_true }

# Global: Highlighting
gui_highlight_signals -color #00ff00 {{intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.EIP_INCR_LOGIC.CHOOSE_INCR.mux4$_out0.S1_temp}}

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 500.08



# Save global setting...

# Wave/List view global setting
gui_cov_show_value -switch false

# Close all empty TopLevel windows
foreach __top [gui_ekki_get_window_ids -type TopLevel] {
    if { [llength [gui_ekki_get_window_ids -parent $__top]] == 0} {
        gui_close_window -window $__top
    }
}
gui_set_loading_session_type noSession
# DVE View/pane content session: 


# Hier 'Hier.1'
gui_show_window -window ${Hier.1}
gui_list_set_filter -id ${Hier.1} -list { {Package 1} {All 0} {Process 1} {VirtPowSwitch 0} {UnnamedProcess 1} {UDP 0} {Function 1} {Block 1} {SrsnAndSpaCell 0} {OVA Unit 1} {LeafScCell 1} {LeafVlgCell 1} {Interface 1} {LeafVhdCell 1} {$unit 1} {NamedBlock 1} {Task 1} {VlgPackage 1} {ClassDef 1} {VirtIsoCell 0} }
gui_list_set_filter -id ${Hier.1} -text {*}
gui_hier_list_init -id ${Hier.1}
gui_change_design -id ${Hier.1} -design V1
catch {gui_list_expand -id ${Hier.1} intgr_fshifter_decode_tb}
catch {gui_list_expand -id ${Hier.1} intgr_fshifter_decode_tb.uut}
catch {gui_list_expand -id ${Hier.1} intgr_fshifter_decode_tb.uut.STAGE_DECODE}
catch {gui_list_select -id ${Hier.1} {intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC}}
gui_view_scroll -id ${Hier.1} -vertical -set 5
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Data 'Data.1'
gui_list_set_filter -id ${Data.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {LowPower 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Data.1} -text {*}
gui_list_show_data -id ${Data.1} {intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC}
gui_show_window -window ${Data.1}
catch { gui_list_select -id ${Data.1} {intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.ld_pr_rr intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.instr_valid intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.ld_eip intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.not_flush intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.nand_valid_ld }}
gui_view_scroll -id ${Data.1} -vertical -set 14
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 5
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# DriverLoad 'DriverLoad.1'
gui_trace_value -session -id ${DriverLoad.1} -signal intgr_fshifter_decode_tb.uut.to_pr_pr_valid -time 502.32 -starttime 600
gui_trace_value -session -id ${DriverLoad.1} -signal {intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH.tail_ptr[4:0]} -time 500.08 -starttime 537.597
gui_trace_value -session -id ${DriverLoad.1} -signal {intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH.incr_amt[3:0]} -time 503.05 -starttime 548.518
gui_trace_value -session -id ${DriverLoad.1} -signal {intgr_fshifter_decode_tb.uut.STAGE_DECODE.DECODER.EIP_INCR_AMT.rom_sum[2:0]} -time 501.22 -starttime 571.576
gui_trace_value -session -id ${DriverLoad.1} -signal {intgr_fshifter_decode_tb.uut.FETCH_BUFF.LOGIC_TAIL_PTR.tail_ptr_reg.in[0]} -time 401.75 -starttime 430.805
gui_trace_value -session -id ${DriverLoad.1} -signal {intgr_fshifter_decode_tb.uut.FETCH_BUFF.LOGIC_TAIL_PTR.offset[3:0]} -time 7.62 -starttime 303.384

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active {intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.EIP_INCR_LOGIC.CHOOSE_INCR.mux4$_out0} /home/projects/courses/spring_22/ee382n19_16785/lib/lib4
gui_view_scroll -id ${Source.1} -vertical -set 1050
gui_src_set_reusable -id ${Source.1}

# View 'Wave.1'
gui_wv_sync -id ${Wave.1} -switch false
set groupExD [gui_get_pref_value -category Wave -key exclusiveSG]
gui_set_pref_value -category Wave -key exclusiveSG -value {false}
set origWaveHeight [gui_get_pref_value -category Wave -key waveRowHeight]
gui_list_set_height -id Wave -height 25
set origGroupCreationState [gui_list_create_group_when_add -wave]
gui_list_create_group_when_add -wave -disable
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 0 768.522
gui_list_add_group -id ${Wave.1} -after {New Group} {Group1}
gui_list_select -id ${Wave.1} {intgr_fshifter_decode_tb.uut.STAGE_DECODE.LOGIC_STALL_FLUSH.tail_ptr }
gui_seek_criteria -id ${Wave.1} {Any Edge}



gui_set_env TOGGLE::DEFAULT_WAVE_WINDOW ${Wave.1}
gui_set_pref_value -category Wave -key exclusiveSG -value $groupExD
gui_list_set_height -id Wave -height $origWaveHeight
if {$origGroupCreationState} {
	gui_list_create_group_when_add -wave -enable
}
if { $groupExD } {
 gui_msg_report -code DVWW028
}
gui_list_set_filter -id ${Wave.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Wave.1} -text {*}
gui_list_set_insertion_bar  -id ${Wave.1} -group Group1  -item intgr_fshifter_decode_tb.uut.STAGE_DECODE.EIP_LOGIC.nand_valid_ld -position below

gui_marker_move -id ${Wave.1} {C1} 500.08
gui_view_scroll -id ${Wave.1} -vertical -set 295
gui_show_grid -id ${Wave.1} -enable false
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${TopLevel.1}]} {
	gui_set_active_window -window ${TopLevel.1}
	gui_set_active_window -window ${Source.1}
	gui_set_active_window -window ${DLPane.1}
}
if {[gui_exist_window -window ${TopLevel.2}]} {
	gui_set_active_window -window ${TopLevel.2}
	gui_set_active_window -window ${Wave.1}
}
#</Session>

