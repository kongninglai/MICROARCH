#include "gp_regfile.h"

/* ---------- helpers ---------- */

static inline uint32_t apply_write(uint32_t oldv, uint32_t mask, uint32_t aligned)
{
    return (oldv & ~mask) | (aligned & mask);
}

static inline uint32_t make_mask(int idx, int size2b)
{
    if (size2b == 0) {
        return (idx & 0x4) ? 0x0000FF00u : 0x000000FFu;
    } else if (size2b == 1) {
        return 0x0000FFFFu;
    } else {
        return 0xFFFFFFFFu;
    }
}

static inline uint32_t align_data(int idx, uint32_t data, int size2b)
{
    if (size2b == 0) {
        uint32_t b = data & 0xFFu;
        return (idx & 0x4) ? (b << 8) : b;
    } else if (size2b == 1) {
        return data & 0xFFFFu;
    } else {
        return data;
    }
}

static inline int phys_idx(int idx, int size2b)
{
    if (size2b == 0) return (idx & 0x3); // AL..BH map to 0..3
    return (idx & 0x7);
}

static inline int norm_size(int size_sig)
{
    switch (size_sig & 0x3) {
        case 0: return 0; // 8
        case 1: return 1; // 16
        case 2: return 2; // 32
        default: return 2;
    }
}

static inline uint32_t bypass_read_full32(
    int rpidx,
    uint32_t base,
    int wr0_en, int wr0_idx, uint32_t wr0_data, int wr0_size_sig,
    int wr1_en, int wr1_idx, uint32_t wr1_data, int wr1_size_sig
){
    uint32_t v = base;

    int w0s = norm_size(wr0_size_sig);
    int w1s = norm_size(wr1_size_sig);

    // Apply write0 then write1 (write1 wins overlap)
    if (wr0_en) {
        int p0 = phys_idx(wr0_idx, w0s);
        if (p0 == rpidx) {
            uint32_t m0 = make_mask(wr0_idx, w0s);
            uint32_t a0 = align_data(wr0_idx, wr0_data, w0s);
            v = apply_write(v, m0, a0);
        }
    }

    if (wr1_en) {
        int p1 = phys_idx(wr1_idx, w1s);
        if (p1 == rpidx) {
            uint32_t m1 = make_mask(wr1_idx, w1s);
            uint32_t a1 = align_data(wr1_idx, wr1_data, w1s);
            v = apply_write(v, m1, a1);
        }
    }

    return v;
}

/* ---------- API ---------- */

void gp_regfile_reset(gp_regfile_t *rf)
{
    for (int i = 0; i < 8; i++) {
        rf->regs[i] = 0;
    }
}

void gp_set_reg(gp_regfile_t *rf, int idx, int data)
{
    rf->regs[idx] = data;
}

int gp_regfile_step(
    gp_regfile_t *rf,
    int rd0_idx, int rd1_idx, int rd2_idx, int rd3_idx,
    int *rd0_data, int *rd1_data, int *rd2_data, int *rd3_data,
    int wr0_idx, int wr1_idx,
    int wr0_data, int wr1_data,
    int wr0_en, int wr1_en,
    int wr0_size, int wr1_size
){
    int w0s = norm_size(wr0_size);
    int w1s = norm_size(wr1_size);

    int r0 = rd0_idx & 7;
    int r1 = rd1_idx & 7;
    int r2 = rd2_idx & 7;
    int r3 = rd3_idx & 7;

    uint32_t base0 = rf->regs[r0];
    uint32_t base1 = rf->regs[r1];
    uint32_t base2 = rf->regs[r2];
    uint32_t base3 = rf->regs[r3];

    uint32_t v0 = bypass_read_full32(r0, base0, wr0_en, wr0_idx, (uint32_t)wr0_data, wr0_size,
                                              wr1_en, wr1_idx, (uint32_t)wr1_data, wr1_size);
    uint32_t v1 = bypass_read_full32(r1, base1, wr0_en, wr0_idx, (uint32_t)wr0_data, wr0_size,
                                              wr1_en, wr1_idx, (uint32_t)wr1_data, wr1_size);
    uint32_t v2 = bypass_read_full32(r2, base2, wr0_en, wr0_idx, (uint32_t)wr0_data, wr0_size,
                                              wr1_en, wr1_idx, (uint32_t)wr1_data, wr1_size);
    uint32_t v3 = bypass_read_full32(r3, base3, wr0_en, wr0_idx, (uint32_t)wr0_data, wr0_size,
                                              wr1_en, wr1_idx, (uint32_t)wr1_data, wr1_size);

    if (rd0_data) *rd0_data = (int)v0;
    if (rd1_data) *rd1_data = (int)v1;
    if (rd2_data) *rd2_data = (int)v2;
    if (rd3_data) *rd3_data = (int)v3;

    // -------- writeback at end of step --------
    if (wr0_en || wr1_en) {
        int p0 = phys_idx(wr0_idx, w0s);
        int p1 = phys_idx(wr1_idx, w1s);

        uint32_t m0 = wr0_en ? make_mask(wr0_idx, w0s) : 0u;
        uint32_t a0 = wr0_en ? align_data(wr0_idx, (uint32_t)wr0_data, w0s) : 0u;

        uint32_t m1 = wr1_en ? make_mask(wr1_idx, w1s) : 0u;
        uint32_t a1 = wr1_en ? align_data(wr1_idx, (uint32_t)wr1_data, w1s) : 0u;

        if (wr0_en && wr1_en && (p0 == p1)) {
            // merge on same physical reg; wr1 wins overlap
            uint32_t oldv = rf->regs[p0];
            uint32_t merged =
                (oldv & ~(m0 | m1)) |
                (a0   & (m0 & ~m1)) |
                (a1   & m1);
            rf->regs[p0] = merged;
        } else {
            if (wr0_en) {
                rf->regs[p0] = apply_write(rf->regs[p0], m0, a0);
            }
            if (wr1_en) {
                rf->regs[p1] = apply_write(rf->regs[p1], m1, a1);
            }
        }
    }

    return 0;
}
