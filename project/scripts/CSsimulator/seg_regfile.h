#ifndef SEG_REGFILE_H
#define SEG_REGFILE_H

#include <stdint.h>
#include <stddef.h>

#ifndef RF_DEPTH
#define RF_DEPTH 8
#endif

// RF_WIDTH must be 16, 32, or 64
#ifndef RF_WIDTH
#define RF_WIDTH 16
#endif

typedef uint16_t seg_word_t;

typedef struct {
    seg_word_t r[RF_DEPTH];
} seg_regfile_t;

// Init / reset
static inline void seg_regfile_reset(seg_regfile_t* rf)
{
    for (size_t i = 0; i < RF_DEPTH; i++) rf->r[i] = (seg_word_t)0;
}

// 3 reads (combinational-style)
static inline seg_word_t seg_regfile_read0(const seg_regfile_t* rf, int idx)
{
    return rf->r[(size_t)idx % RF_DEPTH];
}
static inline seg_word_t seg_regfile_read1(const seg_regfile_t* rf, int idx)
{
    return rf->r[(size_t)idx % RF_DEPTH];
}

static inline seg_word_t seg_regfile_readcs(const seg_regfile_t* rf)
{
    return rf->r[1];
}

// 1 write (posedge-style commit)
static inline void seg_regfile_write(seg_regfile_t* rf, int idx, seg_word_t data, int we)
{
    if (we) rf->r[(size_t)idx % RF_DEPTH] = data;
}

// Convenience API: do both reads + optional write in one call
static inline void seg_regfile_step(
    seg_regfile_t* rf,
    int rd0_idx, int rd1_idx,
    seg_word_t* rd0_data, seg_word_t* rd1_data, seg_word_t* cs_data,
    int wr_idx, seg_word_t wr_data, int wr_en
){  
    seg_word_t rd0_data_temp, rd1_data_temp, cs_data_temp;
    rd0_data_temp = seg_regfile_read0(rf, rd0_idx);
    rd1_data_temp = seg_regfile_read1(rf, rd1_idx);
    cs_data_temp = seg_regfile_readcs(rf);
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

    if (wr_idx == 1){
        *cs_data = wr_data;
    } else {
        *cs_data = cs_data_temp;
    }
    
    seg_regfile_write(rf, wr_idx, wr_data, wr_en);
}

#endif // SEG_REGFILE_H
