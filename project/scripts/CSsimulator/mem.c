#include "mem.h"
#include <string.h>

static inline int valid_size(int sz) {
    return (sz == 1 || sz == 2 || sz == 4 || sz == 8);
}

static inline int in_range(uint32_t addr, int sz) {
    if (sz == 0) return 1;
    if (addr >= MEM_SIZE_BYTES) return 0;
    if ((uint64_t)addr + (uint64_t)sz > MEM_SIZE_BYTES) return 0;
    return 1;
}

// Little-endian load: b[addr] is least-significant byte
static inline uint64_t load_le(const uint8_t *mem, uint32_t addr, int sz) {
    uint64_t v = 0;
    for (int i = 0; i < sz; i++) {
        v |= ((uint64_t)mem[addr + (uint32_t)i]) << (8 * i);
    }
    return v;
}

// Little-endian store
static inline void store_le(uint8_t *mem, uint32_t addr, int sz, uint64_t data) {
    for (int i = 0; i < sz; i++) {
        mem[addr + (uint32_t)i] = (uint8_t)((data >> (8 * i)) & 0xFFu);
    }
}

// Same-cycle bypass: merge write bytes into read result if overlap
static inline uint64_t bypass_merge(
    uint64_t r_val, uint32_t r_addr, int r_sz,
    uint32_t w_addr, int w_sz, uint64_t w_data
){
    // compute overlap range [lo, hi)
    uint32_t r_lo = r_addr;
    uint32_t r_hi = r_addr + (uint32_t)r_sz;
    uint32_t w_lo = w_addr;
    uint32_t w_hi = w_addr + (uint32_t)w_sz;

    uint32_t lo = (r_lo > w_lo) ? r_lo : w_lo;
    uint32_t hi = (r_hi < w_hi) ? r_hi : w_hi;

    if (lo >= hi) return r_val; // no overlap

    // For each overlapping byte address a:
    // - find its byte index within read and within write
    // - replace that byte in r_val with corresponding byte from w_data
    for (uint32_t a = lo; a < hi; a++) {
        int r_i = (int)(a - r_addr);  // 0..r_sz-1
        int w_i = (int)(a - w_addr);  // 0..w_sz-1

        uint64_t w_byte = (w_data >> (8 * w_i)) & 0xFFu;

        // clear read byte then set
        r_val &= ~(0xFFull << (8 * r_i));
        r_val |=  (w_byte  << (8 * r_i));
    }

    return r_val;
}

void mem_reset(mem1024_t *m) {
    memset(m->b, 0, sizeof(m->b));
}

void set_mem(mem1024_t *m, uint32_t addr, int sz, uint64_t data) {
    for (int i = 0; i < sz; i++) {
        m->b[addr + (uint32_t)i] = (uint8_t)((data >> (8 * i)) & 0xFFu);
    }
}

int mem_step(
    mem1024_t *m,
    uint32_t r_addr, int r_size, uint64_t *r_data, int r_en,
    uint32_t w_addr, int w_size, uint64_t w_data, int w_en
){
    // normalize disable
    if ((r_en == 0) || (r_size == 0)) {
        if (r_data) *r_data = 0;
    }
    if (w_en == 0) w_size = 0;

    // validate sizes
    if (r_size != 0 && !valid_size(r_size)) return -1;
    if (w_size != 0 && !valid_size(w_size)) return -1;

    // validate ranges
    if (!in_range(r_addr, r_size)) return -1;
    if (!in_range(w_addr, w_size)) return -1;

    // 1) read base
    uint64_t rv = 0;
    if (r_size != 0) {
        rv = load_le(m->b, r_addr, r_size);
    }

    // 2) bypass merge (read-after-write) within same step
    if (r_size != 0 && w_size != 0) {
        rv = bypass_merge(rv, r_addr, r_size, w_addr, w_size, w_data);
    }

    if (r_data) *r_data = rv;

    // 3) commit write
    if (w_size != 0) {
        store_le(m->b, w_addr, w_size, w_data);
    }

    return 0;
}
