#ifndef MMX_REGFILE_H
#define MMX_REGFILE_H

#include <stdint.h>
#include <stddef.h>

#ifndef RF_DEPTH
#define RF_DEPTH 8
#endif

// RF_WIDTH must be 16, 32, or 64
#ifndef RF_WIDTH
#define RF_WIDTH 64
#endif

typedef uint64_t mmx_word_t;

typedef struct {
    mmx_word_t r[RF_DEPTH];
} mmx_regfile_t;

// Init / reset
static inline void mmx_regfile_reset(mmx_regfile_t* rf)
{
    for (size_t i = 0; i < RF_DEPTH; i++) rf->r[i] = (mmx_word_t)0;
}

// 2 reads (combinational-style)
static inline mmx_word_t mmx_regfile_read0(const mmx_regfile_t* rf, int idx)
{
    return rf->r[(size_t)idx % RF_DEPTH];
}
static inline mmx_word_t mmx_regfile_read1(const mmx_regfile_t* rf, int idx)
{
    return rf->r[(size_t)idx % RF_DEPTH];
}

// 1 write (posedge-style commit)
static inline void mmx_regfile_write(mmx_regfile_t* rf, int idx, mmx_word_t data, int we)
{
    if (we) rf->r[(size_t)idx % RF_DEPTH] = data;
}

// Convenience API: do both reads + optional write in one call
static inline void mmx_regfile_step(
    mmx_regfile_t* rf,
    int rd0_idx, int rd1_idx,
    mmx_word_t* rd0_data, mmx_word_t* rd1_data,
    int wr_idx, mmx_word_t wr_data, int wr_en
){  
    mmx_word_t rd0_data_temp, rd1_data_temp;
    rd0_data_temp = mmx_regfile_read0(rf, rd0_idx);
    rd1_data_temp = mmx_regfile_read1(rf, rd1_idx);
    if (rd0_idx == wr_idx){
        *rd0_data = wr_data;
    } else {
        *rd0_data = rd0_data_temp;
    }

    if (rd1_idx == wr_idx){
        *rd1_data = wr_data;
    } else {
        *rd1_data = rd1_data_temp;
    }

    mmx_regfile_write(rf, wr_idx, wr_data, wr_en);
}

#endif // MMX_REGFILE_H
