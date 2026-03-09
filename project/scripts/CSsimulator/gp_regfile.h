#ifndef GP_REGFILE_H
#define GP_REGFILE_H

#include <stdint.h>

typedef uint32_t gp_word_t;

typedef struct {
    uint32_t *regs;   // points to an array of 8 uint32_t
} gp_regfile_t;

// init with external storage (regs must have length 8)
static inline void gp_regfile_init(gp_regfile_t *rf, uint32_t regs[8]) {
    rf->regs = regs;
}

void gp_regfile_reset(gp_regfile_t *rf);
void gp_set_reg(gp_regfile_t *rf, int idx, int data);
int gp_regfile_step(
    gp_regfile_t *rf,
    int rd0_idx, int rd1_idx, int rd2_idx, int rd3_idx,
    int *rd0_data, int *rd1_data, int *rd2_data, int *rd3_data,
    int wr0_idx, int wr1_idx,
    int wr0_data, int wr1_data,
    int wr0_en, int wr1_en,
    int wr0_size, int wr1_size
);

#endif // GP_REGFILE_H
