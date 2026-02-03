#ifndef MEM_H
#define MEM_H

#include <stdint.h>

#define MEM_SIZE_BYTES 1024

typedef struct {
    uint8_t b[MEM_SIZE_BYTES];
} mem1024_t;

void mem_reset(mem1024_t *m);
void set_mem(mem1024_t *m, uint32_t addr, int sz, uint64_t data);
// Read/write in one step (same-cycle bypass).
// r*_size / w*_size: must be 1,2,4,8; 0 means disabled.
// Returns 0 on success, -1 on out-of-range or invalid size.
int mem_step(
    mem1024_t *m,
    uint32_t r_addr, int r_size, uint64_t *r_data, int r_en,
    uint32_t w_addr, int w_size, uint64_t w_data, int w_en
);

#endif
