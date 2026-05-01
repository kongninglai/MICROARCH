define_design_lib WORK -path ./WORK

set top_design pipeline_top

# Send analyze/elaborate/link chatter to a log file so the terminal
# only shows the behavioral-code report at the end.
redirect -file check_behavioral_setup.log {

analyze -format Verilog {
~/MICROARCH/project/hdl/top/pipeline_top/pipeline_top.v
~/MICROARCH/project/scripts/fanout/junk.v
~/MICROARCH/project/hdl/local-lib/gates/big_and.v
~/MICROARCH/project/hdl/local-lib/gates/big_or.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_16.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux3_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux4_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_64.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_96.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_96.v
~/MICROARCH/project/hdl/local-lib/muxes/mux4_64.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_64.v
~/MICROARCH/project/hdl/stages/forwarding/gp_forwarding.v
~/MICROARCH/project/hdl/local-lib/extenders/ze.v
~/MICROARCH/project/hdl/local-lib/extenders/se.v
~/MICROARCH/project/hdl/local-lib/comparators/big_eq.v
~/MICROARCH/project/hdl/local-lib/regfiles/reg16e.v
~/MICROARCH/project/hdl/local-lib/regfiles/regfile_2r1w.v
~/MICROARCH/project/hdl/PRF/gpr_shifter.v
~/MICROARCH/project/hdl/PRF/regfile_gp.v
~/MICROARCH/project/hdl/PRF/regfile_mmx.v
~/MICROARCH/project/hdl/PRF/regfile_seg.v
~/MICROARCH/project/hdl/stages/rr/get_segreg_idx.v
~/MICROARCH/project/hdl/stages/rr/regunit.v
~/MICROARCH/project/hdl/stages/rr/pending_int.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/ucoderom.v
~/MICROARCH/project/hdl/stages/decoder/to_rr_ucode_lookup.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_controller.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_fsm.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/rr_sig.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/ag_sig.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/mem_sig.v
~/MICROARCH/project/hdl/stages/pipeline_regs/rr_to_ag/reg_rr_to_ag.v
~/MICROARCH/project/hdl/stages/pipeline_regs/rr_to_ag/rr_to_ag.v
~/MICROARCH/project/hdl/stages/rr/stage_rr.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_const.v
~/MICROARCH/project/hdl/local-lib/gates/xor3LL.v
~/MICROARCH/project/hdl/local-lib/adders/gen_prop.v
~/MICROARCH/project/hdl/local-lib/adders/gen_prop_2.v
~/MICROARCH/project/hdl/local-lib/adders/PA_32b.v
~/MICROARCH/project/hdl/stages/ag/address_adder.v
~/MICROARCH/project/hdl/stages/ag/stage_ag.v
~/MICROARCH/project/hdl/stages/pipeline_regs/ag_to_mem/reg_ag_to_mem.v
~/MICROARCH/project/hdl/stages/pipeline_regs/ag_to_mem/ag_to_mem.v
~/MICROARCH/project/hdl/stages/pipeline_regs/mem_to_ex/reg_mem_to_ex.v
~/MICROARCH/project/hdl/stages/pipeline_regs/mem_to_ex/mem_to_ex.v
~/MICROARCH/project/hdl/local-lib/comparators/cmp_gen_32b.v
~/MICROARCH/project/hdl/local-lib/comparators/gt9_4b.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_64.v
~/MICROARCH/project/hdl/local-lib/gates/xor4LL.v
~/MICROARCH/project/hdl/local-lib/gates/xor8LL.v
~/MICROARCH/project/hdl/local-lib/adders/PA_16b.v
~/MICROARCH/project/hdl/local-lib/adders/FA_16b.v
~/MICROARCH/project/hdl/local-lib/adders/FA_32b.v
~/MICROARCH/project/hdl/local-lib/adders/PA_4b.v
~/MICROARCH/project/hdl/local-lib/adders/HA_4b.v
~/MICROARCH/project/hdl/local-lib/adders/PA_8b.v
~/MICROARCH/project/hdl/local-lib/adders/HA_32b.v
~/MICROARCH/project/hdl/local-lib/adders/SUB_32b.v
~/MICROARCH/project/hdl/stages/execute/palu/pack/sat_signed_narrow.v
~/MICROARCH/project/hdl/stages/execute/eflags/set_sf_zf_pf.v
~/MICROARCH/project/hdl/stages/execute/alu/alu_eflags.v
~/MICROARCH/project/hdl/stages/execute/alu/ex_alu.v
~/MICROARCH/project/hdl/stages/execute/cmp/cmp_eflags.v
~/MICROARCH/project/hdl/stages/execute/cmp/ex_cmp.v
~/MICROARCH/project/hdl/stages/execute/palu/pavg/ex_pavg.v
~/MICROARCH/project/hdl/stages/execute/palu/padd/ex_padd.v
~/MICROARCH/project/hdl/stages/execute/palu/pack/ex_pack.v
~/MICROARCH/project/hdl/stages/execute/palu/ex_palu.v
~/MICROARCH/project/hdl/local-lib/adders/big_increment.v
~/MICROARCH/project/hdl/stages/execute/aaa/ex_aaa.v
~/MICROARCH/project/hdl/stages/execute/bsf/bsf.v
~/MICROARCH/project/hdl/stages/execute/bsf/ex_bsf.v
~/MICROARCH/project/hdl/stages/execute/eflags/ex_eflags.v
~/MICROARCH/project/hdl/stages/execute/inc/ex_inc.v
~/MICROARCH/project/hdl/stages/execute/not/ex_not.v
~/MICROARCH/project/hdl/local-lib/adders/big_decrement.v
~/MICROARCH/project/hdl/local-lib/shifters/rshfa_const.v
~/MICROARCH/project/hdl/local-lib/muxes/mux32.v
~/MICROARCH/project/hdl/local-lib/shifters/rshfa_var_32b.v
~/MICROARCH/project/hdl/local-lib/muxes/mux32_16b.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_var_32b.v
~/MICROARCH/project/hdl/stages/execute/shf/ex_shf.v
~/MICROARCH/project/hdl/stages/execute/control/ex_control.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/ex_sig.v
~/MICROARCH/project/hdl/stages/rr/ucode_rom/wb_sig.v
~/MICROARCH/project/hdl/local-lib/comparators/seg_limit_cmp.v
~/MICROARCH/project/hdl/stages/execute/stage_ex.v
~/MICROARCH/project/hdl/local-lib/regs/reg_n.v
~/MICROARCH/project/hdl/local-lib/comparators/big_neq.v
~/MICROARCH/project/hdl/cache/controllers/stream_buffer.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_chunks.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_chunks_var_16b.v
~/MICROARCH/project/hdl/cache/controllers/we_logic_block.v
~/MICROARCH/project/hdl/cache/controllers/io_addr_logic_block.v
~/MICROARCH/project/hdl/cache/controllers/cache_controller.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_16b.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_8b.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_16b.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_chunks_var_256b.v
~/MICROARCH/project/hdl/off-core/io/dmu.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_var_16b.v
~/MICROARCH/project/hdl/off-core/io/dmac.v
~/MICROARCH/project/hdl/off-core/io/kb.v
~/MICROARCH/project/hdl/off-core/memory/rank.v
~/MICROARCH/project/hdl/off-core/memory/main_memory.v
~/MICROARCH/project/hdl/off-core/memory/mcu_ctrl.v
~/MICROARCH/project/hdl/off-core/memory/mcu.v
~/MICROARCH/project/hdl/off-core/arbiter/arbiter.v
~/MICROARCH/project/hdl/off-core/top/off_core_top.v
~/MICROARCH/project/hdl/cache/controllers/dcache_controller_wbe.v
~/MICROARCH/project/hdl/cache/integration/full_cc_off_core.v
~/MICROARCH/project/hdl/cache/tag_stores/lru_store_per_set.v
~/MICROARCH/project/hdl/cache/tag_stores/lru_store.v
~/MICROARCH/project/hdl/local-lib/encoders/encoder4_2.v
~/MICROARCH/project/hdl/cache/tag_stores/tag_hit_logic.v
~/MICROARCH/project/hdl/cache/tag_stores/tag_store.v
~/MICROARCH/project/hdl/cache/tag_stores/valid_or_dirty_store.v
~/MICROARCH/project/hdl/cache/data_stores/data_store.v
~/MICROARCH/project/hdl/local-lib/extenders/bit_duplicator.v
~/MICROARCH/project/hdl/cache/controllers/sticky_bit_fsm.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_chunks_var_64b.v
~/MICROARCH/project/hdl/cache/top/full_cache.v
~/MICROARCH/project/hdl/stages/mem/sticky_bit_load_fsm.v
~/MICROARCH/project/hdl/local-lib/shifters/rshf_chunks.v
~/MICROARCH/project/hdl/local-lib/shifters/rshf_bytes_var_128b.v
~/MICROARCH/project/hdl/cache/tlb/tlb_wrapper.v
~/MICROARCH/project/hdl/local-lib/comparators/cmp_gt_32b.v
~/MICROARCH/project/hdl/stages/mem/stage_mem.v
~/MICROARCH/project/hdl/cache/data_stores/store_queue_entry.v
~/MICROARCH/project/hdl/cache/data_stores/store_queue.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_bytes_var_256b.v
~/MICROARCH/project/hdl/stages/pipeline_regs/ex_to_wb/reg_ex_to_wb.v
~/MICROARCH/project/hdl/stages/pipeline_regs/ex_to_wb/ex_to_wb.v
~/MICROARCH/project/hdl/stages/wb/stage_wb.v
~/MICROARCH/project/hdl/stages/wb/temp_exception_regs.v
~/MICROARCH/project/hdl/stages/fetch/intgr_fshifter_decode.v
~/MICROARCH/project/hdl/stages/pipeline_regs/f_to_de/fetch_buffer.v
~/MICROARCH/project/hdl/stages/pipeline_regs/de_to_rr/de_to_rr.v
~/MICROARCH/project/hdl/stages/pipeline_regs/de_to_rr/iq_de_to_rr.v
~/MICROARCH/project/hdl/stages/pipeline_regs/de_to_rr/iq_de_to_rr_entry.v
~/MICROARCH/project/hdl/stages/fetch/stage_fetch_a.v
~/MICROARCH/project/hdl/stages/decoder/stage_decode.v
~/MICROARCH/project/hdl/stages/fetch/fetch_pointer.v
~/MICROARCH/project/hdl/stages/pipeline_regs/f_to_de/logic_cl_shifter.v
~/MICROARCH/project/hdl/stages/pipeline_regs/f_to_de/logic_tail_ptr.v
~/MICROARCH/project/hdl/local-lib/shift_reg/shift_reg.v
~/MICROARCH/project/hdl/local-lib/comparators/big_eq.v
~/MICROARCH/project/hdl/local-lib/comparators/big_neq.v
~/MICROARCH/project/hdl/local-lib/gates/big_and.v
~/MICROARCH/project/hdl/local-lib/gates/big_or.v
~/MICROARCH/project/hdl/local-lib/gates/xor3LL.v
~/MICROARCH/project/hdl/local-lib/regs/reg_n.v
~/MICROARCH/project/hdl/local-lib/shifters/rshf_chunks.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_var_16b.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_const.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_chunks.v
~/MICROARCH/project/hdl/local-lib/shifters/rshf_bytes_var_128b.v
~/MICROARCH/project/hdl/local-lib/shifters/lshf_bytes_var_256b.v
~/MICROARCH/project/hdl/local-lib/adders/gen_prop.v
~/MICROARCH/project/hdl/local-lib/adders/gen_prop_2.v
~/MICROARCH/project/hdl/local-lib/adders/PA_4b.v
~/MICROARCH/project/hdl/local-lib/adders/PA_8b.v
~/MICROARCH/project/hdl/local-lib/adders/PA_32b.v
~/MICROARCH/project/hdl/local-lib/adders/big_decrement.v
~/MICROARCH/project/hdl/local-lib/adders/big_increment.v
~/MICROARCH/project/hdl/local-lib/adders/prefix_modrm_sib_adder.v
~/MICROARCH/project/hdl/local-lib/adders/p_m_s_d_adder.v
~/MICROARCH/project/hdl/stages/decoder/pf_expn.v
~/MICROARCH/project/hdl/stages/decoder/block_decoder.v
~/MICROARCH/project/hdl/stages/decoder/eip_incr.v
~/MICROARCH/project/hdl/stages/decoder/logic_disp_bytes.v
~/MICROARCH/project/hdl/stages/decoder/logic_is_sib.v
~/MICROARCH/project/hdl/stages/decoder/logic_sib_disp.v
~/MICROARCH/project/hdl/stages/decoder/predictor.v
~/MICROARCH/project/hdl/stages/decoder/bp.v
~/MICROARCH/project/hdl/stages/decoder/logic_modrm_imm.v
~/MICROARCH/project/hdl/stages/decoder/logic_stall_flush.v
~/MICROARCH/project/hdl/stages/decoder/br_target.v
~/MICROARCH/project/hdl/stages/decoder/ghr.v
~/MICROARCH/project/hdl/stages/decoder/logic_imm.v
~/MICROARCH/project/hdl/stages/decoder/logic_prefix_combadder.v
~/MICROARCH/project/hdl/stages/decoder/logic_true_modrm.v
~/MICROARCH/project/hdl/stages/decoder/choose_eip.v
~/MICROARCH/project/hdl/stages/decoder/hash.v
~/MICROARCH/project/hdl/stages/decoder/logic_incr_amt.v
~/MICROARCH/project/hdl/stages/decoder/logic_seg_ov.v
~/MICROARCH/project/hdl/stages/decoder/logic_true_prefix.v
~/MICROARCH/project/hdl/stages/decoder/comb_choose_eip.v
~/MICROARCH/project/hdl/stages/decoder/logic_branch.v
~/MICROARCH/project/hdl/stages/decoder/logic_is_prefix.v
~/MICROARCH/project/hdl/stages/decoder/logic_sib_byte.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_64.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_128.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_256.v
~/MICROARCH/project/hdl/local-lib/muxes/mux4_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux4_48.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_8.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_8b.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_16.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_16b.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_48.v
~/MICROARCH/project/hdl/local-lib/muxes/mux32_16b.v
~/MICROARCH/project/hdl/local-lib/muxes/mux4_48.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_8.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_16.v
~/MICROARCH/project/hdl/local-lib/adders/prefix_modrm_sib_adder.v
~/MICROARCH/project/hdl/local-lib/adders/p_m_s_d_adder.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_48.v
~/MICROARCH/project/hdl/stages/decoder/logic_modrm_imm.v
~/MICROARCH/project/hdl/stages/decoder/logic_is_sib.v
~/MICROARCH/project/hdl/stages/decoder/logic_seg_ov.v
~/MICROARCH/project/hdl/stages/decoder/logic_is_prefix.v
~/MICROARCH/project/hdl/stages/decoder/logic_prefix_combadder.v
~/MICROARCH/project/hdl/stages/decoder/logic_true_prefix.v
~/MICROARCH/project/hdl/stages/decoder/logic_true_modrm.v
~/MICROARCH/project/hdl/stages/decoder/logic_sib_byte.v
~/MICROARCH/project/hdl/stages/decoder/logic_disp_bytes.v
~/MICROARCH/project/hdl/stages/decoder/logic_imm.v
~/MICROARCH/project/hdl/stages/decoder/logic_sib_disp.v
~/MICROARCH/project/hdl/stages/decoder/logic_incr_amt.v
~/MICROARCH/project/hdl/stages/decoder/block_decoder.v
~/MICROARCH/project/hdl/stages/rr/dep_unit/check_dep.v
~/MICROARCH/project/hdl/stages/rr/dep_unit/gp_dep.v
~/MICROARCH/project/hdl/stages/rr/dep_unit/single_stage_dep.v
~/MICROARCH/project/hdl/stages/rr/dep_unit/dep_unit.v
~/MICROARCH/project/hdl/top/backend/backend_top.v
~/MICROARCH/project/hdl/top/frontend/fetch_decode_top.v
~/MICROARCH/project/hdl/stages/decoder/br_target.v
~/MICROARCH/project/hdl/stages/decoder/sat_cntr.v
~/MICROARCH/project/hdl/local-lib/decoders/decoder4_16.v
};
elaborate pipeline_top;
current_design pipeline_top;
set target_library "";
set link_library "*";
link;

}
# end of redirect — everything below prints to the terminal

# ---------------------------------------------------------------------------
# Behavioral-code check
# ---------------------------------------------------------------------------
# After elaborate, any operator (&, |, +, ==, ?:, ~, etc.) or procedural
# block becomes a GTECH_* / *_OP cell, and any inferred flop shows up in
# all_registers. Pure wiring (concat, bit-select, direct assign) and
# explicit gate instantiations produce no such cells, so they are ignored.
# ---------------------------------------------------------------------------

set inferred [get_cells -hierarchical -filter \
    "ref_name =~ GTECH_* || ref_name =~ *_OP"]
set n_inferred [sizeof_collection $inferred]
set n_regs     [sizeof_collection [all_registers]]

echo "============================================================"
echo " Behavioral-code report for $top_design"
echo "============================================================"
echo " Inferred operator/GTECH cells : $n_inferred"
echo " Inferred registers            : $n_regs"
echo "------------------------------------------------------------"

if {$n_inferred > 0 || $n_regs > 0} {
    echo " >>> Behavioral / operator logic PRESENT"

    # Group offenders by parent module so it is easy to find the source.
    array unset by_parent
    foreach_in_collection c $inferred {
        set full   [get_attribute $c full_name]
        set ref    [get_attribute $c ref_name]
        set parent [file dirname $full]
        lappend by_parent($parent) "$full ($ref)"
    }

    foreach parent [lsort [array names by_parent]] {
        echo ""
        echo " Module instance: $parent"
        foreach line $by_parent($parent) {
            echo "    $line"
        }
    }

    if {$n_regs > 0} {
        echo ""
        echo " Inferred registers:"
        foreach_in_collection r [all_registers] {
            echo "    [get_attribute $r full_name]"
        }
    }
} else {
    echo " >>> Pure structural / wiring only - no behavioral code found"
}
echo "============================================================"
