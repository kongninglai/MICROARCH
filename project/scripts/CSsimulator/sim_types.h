#ifndef SIM_TYPES_H
#define SIM_TYPES_H
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gp_regfile.h"
#include "mmx_regfile.h"
#include "seg_regfile.h"
#include "mem.h"

enum CS_BITS {  
    CS_R0_IDX1,CS_R0_IDX0, // EAX, ESP, EDI, EDX
    CS_R1_IDX, // regR, opcode
    CS_R3_IDX1,CS_R3_IDX0, // SIB_IDX, ESP, ESI, EAX
    // TODO: need S0 IDX
    CS_S1_IDX, // SS, ES
    CS_A_SRC1,CS_A_SRC0, // 0, 2, 3
    CS_C_SRC, // 0, 3
    CS_BASE1_SRC, // 2, 3
    CS_BASE2_SRC, // 0, 3
    CS_DSTA_IDX, // RA_IDX, RB_IDX
    CS_ALU_IN1_SRC, // RA, mem
    CS_DATASIZE, // 0X: 8-bit, 10: 16-bit, 11: 32-bit
    CS_LD_MADDR1, CS_LD_MADDR0, //mAddrD1, mAddrD2, mAddrS
    CS_ST_MADDR1, CS_ST_MADDR0, //mAddrD1, mAddrD2, mAddrS
    CS_R,CS_W,
    CS_ALU_IN2_SRC, // imm, RB
    CS_IMM_SE8, // sign extend imm from 8-bit
    CS_LD_REGA,
    CS_LD_REGB,
    CS_LD_SREG,
    CS_LD_MMREG,
    CS_LD_EFLAGS,
    CS_LD_EIP,
    CS_LD_CS,
    CS_CONTROL_STORE_BITS
} CS_BITS;

void print_DE_CS(int* CS){
    printf("=== DE CS ===\n");
    printf("R0_IDX      : %d%d\n", CS[CS_R0_IDX1], CS[CS_R0_IDX0]);
    printf("R1_IDX      : %d\n", CS[CS_R1_IDX]);
    printf("R3_IDX      : %d%d\n", CS[CS_R3_IDX1], CS[CS_R3_IDX1]);
    printf("S1_IDX      : %d\n", CS[CS_S1_IDX]);
    printf("A_SRC       : %d%d\n", CS[CS_A_SRC1], CS[CS_A_SRC0]);
    printf("C_SRC       : %d\n", CS[CS_C_SRC]);
    printf("BASE1_SRC   : %d\n", CS[CS_BASE1_SRC]);
    printf("BASE2_SRC   : %d\n", CS[CS_BASE2_SRC]);
    printf("DSTA_IDX    : %d\n", CS[CS_DSTA_IDX]);
    printf("ALU_IN1_SRC : %d\n", CS[CS_ALU_IN1_SRC]);
    printf("DATASIZE    : %d\n", CS[CS_DATASIZE]);
    printf("LD_MADDR    : %d%d\n", CS[CS_LD_MADDR1], CS[CS_LD_MADDR0]);
    printf("ST_MADDR    : %d%d\n", CS[CS_ST_MADDR1], CS[CS_ST_MADDR0]);
    printf("RW          : %d%d\n", CS[CS_R], CS[CS_W]);
    printf("ALU_IN2_SRC : %d\n", CS[CS_ALU_IN2_SRC]);
    printf("LD_REGA     : %d\n", CS[CS_LD_REGA]);
    printf("LD_REGB     : %d\n", CS[CS_LD_REGB]);
    printf("LD_SREG     : %d\n", CS[CS_LD_SREG]);
    printf("LD_SREG     : %d\n", CS[CS_LD_SREG]);
    printf("LD_MMREG    : %d\n", CS[CS_LD_MMREG]);
    printf("LD_EFLAGS   : %d\n", CS[CS_LD_EFLAGS]);
    printf("LD_EIP      : %d\n", CS[CS_LD_EIP]);
    printf("LD_CS       : %d\n", CS[CS_LD_CS]);
    
}

enum E1_CS_BITS {
    E1_ALU_IN1_SRC, // RA, mem
    E1_ALU_OP1, E1_ALU_OP0,// ADD, OR, AND
    E1_DATASIZE1, E1_DATASIZE0, // 0X: 8-bit, 10: 16-bit, 11: 32-bit
    E1_LD_MADDR1, E1_LD_MADDR0, //mAddrD1, mAddrD2, mAddrS
    E1_ST_MADDR1, E1_ST_MADDR0, //mAddrD1, mAddrD2, mAddrS
    E1_R,E1_W,
    E1_ALU_IN2_SRC, // imm, RB
    E1_IMM_SE8, // sign extend imm from 8-bit
    E1_LD_REGA,
    E1_LD_REGB,
    E1_LD_SREG,
    E1_LD_MMREG,
    E1_LD_EFLAGS,
    E1_LD_EIP,
    E1_LD_CS,
    NUM_E1_CS_BITS
} E1_CS_BITS;

void print_E1_CS(int* CS){
    printf("=== E1 CS===\n");
    printf("ALU_IN1_SRC : %d\n", CS[E1_ALU_IN1_SRC]);
    printf("ALUOP       : %d%d\n", CS[E1_ALU_OP1], CS[E1_ALU_OP0]);
    printf("DATASIZE    : %d%d\n", CS[E1_DATASIZE1], CS[E1_DATASIZE0]);
    printf("LD_MADDR    : %d%d\n", CS[E1_LD_MADDR1], CS[E1_LD_MADDR0]);
    printf("ST_MADDR    : %d%d\n", CS[E1_ST_MADDR1], CS[E1_ST_MADDR0]);
    printf("RW          : %d%d\n", CS[E1_R], CS[E1_W]);
    printf("ALU_IN2_SRC : %d\n", CS[E1_ALU_IN2_SRC]);
    printf("LD_REGA     : %d\n", CS[E1_LD_REGA]);
    printf("LD_REGB     : %d\n", CS[E1_LD_REGB]);
    printf("LD_SREG     : %d\n", CS[E1_LD_SREG]);
    printf("LD_SREG     : %d\n", CS[E1_LD_SREG]);
    printf("LD_MMREG    : %d\n", CS[E1_LD_MMREG]);
    printf("LD_EFLAGS   : %d\n", CS[E1_LD_EFLAGS]);
    printf("LD_EIP      : %d\n", CS[E1_LD_EIP]);
    printf("LD_CS       : %d\n", CS[E1_LD_CS]);
    
}

enum M1_CS_BITS {
    M1_ALU_IN1_SRC, // RA, mem
    M1_ALU_OP1, M1_ALU_OP0,// ADD, OR, AND
    M1_DATASIZE1, M1_DATASIZE0, // 0X: 8-bit, 10: 16-bit, 11: 32-bit
    M1_PUSH_STACK, // TODO: should be pop stack??
    M1_R,M1_W,
    M1_ALU_IN2_SRC, // imm, RB
    M1_IMM_SE8, // sign extend imm from 8-bit
    M1_LD_REGA,
    M1_LD_REGB,
    M1_LD_SREG,
    M1_LD_MMREG,
    M1_LD_EFLAGS,
    M1_LD_EIP,
    M1_LD_CS,
    NUM_M1_CS_BITS
} M1_CS_BITS;

void print_M1_CS(int* CS){
    printf("=== M1 CS===\n");
    printf("ALU_IN1_SRC   : %d\n", CS[M1_ALU_IN1_SRC]);
    printf("ALUOP         : %d%d\n", CS[M1_ALU_OP1], CS[M1_ALU_OP0]);
    printf("DATASIZE      : %d%d\n", CS[M1_DATASIZE1], CS[M1_DATASIZE0]);
    printf("M1_PUSH_STACK : %d\n", CS[M1_PUSH_STACK]);
    printf("RW            : %d%d\n", CS[M1_R], CS[M1_W]);
    printf("ALU_IN2_SRC   : %d\n", CS[M1_ALU_IN2_SRC]);
    printf("LD_REGA       : %d\n", CS[M1_LD_REGA]);
    printf("LD_REGB       : %d\n", CS[M1_LD_REGB]);
    printf("LD_SREG       : %d\n", CS[M1_LD_SREG]);
    printf("LD_SREG       : %d\n", CS[M1_LD_SREG]);
    printf("LD_MMREG      : %d\n", CS[M1_LD_MMREG]);
    printf("LD_EFLAGS     : %d\n", CS[M1_LD_EFLAGS]);
    printf("LD_EIP        : %d\n", CS[M1_LD_EIP]);
    printf("LD_CS         : %d\n", CS[M1_LD_CS]);
    
}

enum E2_CS_BITS {
    E2_ALU_IN1_SRC, // RA, mem
    E2_ALU_OP1, E2_ALU_OP0,// ADD, OR, AND
    E2_DATASIZE1, E2_DATASIZE0, // 0X: 8-bit, 10: 16-bit, 11: 32-bit
    E2_PUSH_STACK,
    E2_R,E2_W,
    E2_ALU_IN2_SRC, // imm, RB
    E2_IMM_SE8, // sign extend imm from 8-bit
    E2_LD_REGA,
    E2_LD_REGB,
    E2_LD_SREG,
    E2_LD_MMREG,
    E2_LD_EFLAGS,
    E2_LD_EIP,
    E2_LD_CS,
    NUM_E2_CS_BITS
} E2_CS_BITS;

void print_E2_CS(int* CS){
    printf("=== E2 CS===\n");
    printf("ALU_IN1_SRC   : %d\n", CS[E2_ALU_IN1_SRC]);
    printf("ALUOP         : %d%d\n", CS[E2_ALU_OP1], CS[E2_ALU_OP0]);
    printf("DATASIZE      : %d%d\n", CS[E2_DATASIZE1], CS[E2_DATASIZE0]);
    printf("M1_PUSH_STACK : %d\n", CS[E2_PUSH_STACK]);
    printf("RW            : %d%d\n", CS[E2_R], CS[E2_W]);
    printf("ALU_IN2_SRC   : %d\n", CS[E2_ALU_IN2_SRC]);
    printf("LD_REGA       : %d\n", CS[E2_LD_REGA]);
    printf("LD_REGB       : %d\n", CS[E2_LD_REGB]);
    printf("LD_SREG       : %d\n", CS[E2_LD_SREG]);
    printf("LD_SREG       : %d\n", CS[E2_LD_SREG]);
    printf("LD_MMREG      : %d\n", CS[E2_LD_MMREG]);
    printf("LD_EFLAGS     : %d\n", CS[E2_LD_EFLAGS]);
    printf("LD_EIP        : %d\n", CS[E2_LD_EIP]);
    printf("LD_CS         : %d\n", CS[E2_LD_CS]);
    
}

enum WB_CS_BITS {
    WB_DATASIZE1, WB_DATASIZE0, // 0X: 8-bit, 10: 16-bit, 11: 32-bit
    WB_PUSH_STACK,
    WB_R,WB_W,
    WB_LD_REGA,
    WB_LD_REGB,
    WB_LD_SREG,
    WB_LD_MMREG,
    WB_LD_EFLAGS,
    WB_LD_EIP,
    WB_LD_CS,
    NUM_WB_CS_BITS
} WB_CS_BITS;

void print_WB_CS(int* CS){
    printf("=== WB CS===\n");
    printf("DATASIZE      : %d%d\n", CS[WB_DATASIZE1], CS[WB_DATASIZE0]);
    printf("M1_PUSH_STACK : %d\n", CS[WB_PUSH_STACK]);
    printf("RW            : %d%d\n", CS[WB_R], CS[WB_W]);
    printf("LD_REGA       : %d\n", CS[WB_LD_REGA]);
    printf("LD_REGB       : %d\n", CS[WB_LD_REGB]);
    printf("LD_SREG       : %d\n", CS[WB_LD_SREG]);
    printf("LD_SREG       : %d\n", CS[WB_LD_SREG]);
    printf("LD_MMREG      : %d\n", CS[WB_LD_MMREG]);
    printf("LD_EFLAGS     : %d\n", CS[WB_LD_EFLAGS]);
    printf("LD_EIP        : %d\n", CS[WB_LD_EIP]);
    printf("LD_CS         : %d\n", CS[WB_LD_CS]);
    
}
typedef struct {
    int prefix_mux; // inst_prefix, op_size_prefix, seg_prefix(000-101: ES-GS, 011: NO seg prefix)
    int opcode;
    int escape;
    int modrm;
    int sib;
    int displacement;
    int disp_size; // 0: 32-bit or all zero; 1: 8-bit, sign extend needed
    int immediate;
    int imm_size; // 00: 8-bit; 01: 16-bit; 10: 32-bit; 11: 0 (unused)
    int oeip;
    int ieip;
    int reg0_src; // 00: ZERO; 01: modrm[2:0]; 10: sib[2:0]; 11: unused
} PD_INST;


typedef struct {
    int OEIP_V;
    int IEIP_V;
    int OEFLAGS_V;
    int SRCREGA_V;
    int SRCREGB_V;
    int SRCREGC_V;
    int SRCSREG_V;
    mmx_word_t MMA_V;
    mmx_word_t MMB_V;
    int IMM_V;
    int PTRA_V;
    int PTRB_V;
    int DSTREGA_IDX;
    int DSTREGB_IDX;
    int SREG1_V;
    int SLIM1_V;
    int BASE1_V;
    int INDEX1_V;
    int DISP1_V;
    int SCALE1_MUX; // 00=×1, 01=×2, 10=×4, 11=×8
    int MSIZE1_MUX; // 00=1, 01=2, 10=4, 11=8
    int SREG2_V;
    int SLIM2_V;
    int BASE2_V;
    int MSIZE2_MUX; // 00=1, 01=2, 10=4, 11=8
    int E1_CS[NUM_E1_CS_BITS];
} DE_REG;



typedef struct {
    int OEIP_V;
    int IEIP_V;
    int OEFLAGS_V;
    int SRCREGA_V;
    int SRCREGB_V;
    int SRCREGC_V;
    int SRCSREG_V;
    mmx_word_t MMA_V;
    mmx_word_t MMB_V;
    int IMM_V;
    int PTRA_V;
    int PTRB_V;
    int DSTREGA_IDX;
    int DSTREGB_IDX;
    int LOAD_ADDR;
    int LOAD_SIZE; // TODO: ??? load size?
    int STORE_ADDR;
    int STORE_SIZE; // TODO: ??? store size?
    int M1_CS[NUM_M1_CS_BITS];
} E1_REG;

typedef struct {
    int OEIP_V;
    int IEIP_V;
    int OEFLAGS_V;
    int SRCREGA_V;
    int SRCREGB_V;
    int SRCREGC_V;
    int SRCSREG_V;
    mmx_word_t MMA_V;
    mmx_word_t MMB_V;
    int IMM_V;
    int PTRA_V;
    int PTRB_V;
    int DSTREGA_IDX;
    int DSTREGB_IDX;
    int LOAD_ADDR;
    uint64_t LOAD_RESULT;
    int STORE_ADDR;
    int STORE_SIZE; // TODO: ??? store size?
    int E2_CS[NUM_E2_CS_BITS];
} M1_REG;

typedef struct {
    int OEIP_V;
    int IEIP_V;
    int OEFLAGS_V;
    int SRCREGA_V;
    int SRCREGB_V;
    int SRCREGC_V;
    int SRCSREG_V;
    mmx_word_t MMA_V;
    mmx_word_t MMB_V;
    int IMM_V;
    int PTRA_V;
    int PTRB_V;
    int DSTREGA_IDX;
    int DSTREGB_IDX;
    int LOAD_ADDR;
    uint64_t LOAD_RESULT;
    uint64_t EX_RESULT;
    int NEW_EFLAGS;
    int STORE_ADDR;
    int STORE_SIZE; // TODO: ??? store size?
    int WB_CS[NUM_WB_CS_BITS];
} E2_REG;

typedef struct 
{
    int gp_wr0_idx;
    int gp_wr0_data;
    int gp_wr0_en;
    int gp_wr0_size;
    int gp_wr1_idx;
    int gp_wr1_data;
    int gp_wr1_en;
    int gp_wr1_size;

    int seg_wr_idx;
    seg_word_t seg_wr_data;
    int seg_wr_en;

    int mmx_wr_idx;
    mmx_word_t mmx_wr_data;
    int mmx_wr_en;

    int eflags;
    int ld_eflags;
} WB_TO_RF;

typedef struct
{
    uint32_t w_addr;
    int w_size; 
    uint64_t w_data;
    int w_en;
} WB_TO_MEM;

uint32_t gp_regs[8];
gp_regfile_t gp_rf;

mmx_regfile_t mmx_rf;
seg_regfile_t seg_rf;
uint32_t seg_limits[8] = {0x4FFF, 0x11FF, 0x4000, 0x03FF, 0x03FF, 0x07FF};
uint32_t EFLAGS;
uint32_t EIP;
mem1024_t memory;

PD_INST from_pd_to_de, new_from_pd_to_de;
DE_REG from_de_to_e1, new_from_de_to_e1;
E1_REG from_e1_to_m1, new_from_e1_to_m1;
M1_REG from_m1_to_e2, new_from_m1_to_e2;
E2_REG from_e2_to_wb, new_from_e2_to_wb;
WB_TO_RF from_wb_to_de;
WB_TO_MEM from_wb_to_mem;

void print_PD_INST(void){
    printf("========PD INST========\n");
    printf("prefix mux  : %02x\n", from_pd_to_de.prefix_mux);
    printf("opcode      : %02x\n", from_pd_to_de.opcode);
    printf("escape      : %d\n", from_pd_to_de.escape);
    printf("modrm       : %02x\n", from_pd_to_de.modrm);
    printf("sib         : %02x\n", from_pd_to_de.sib);
    printf("displacement: %08x\n", from_pd_to_de.displacement);
    printf("disp size   : %02x\n", from_pd_to_de.disp_size);
    printf("immediate   : %08x\n", from_pd_to_de.immediate);
    printf("imm size    : %02x\n", from_pd_to_de.imm_size);
    printf("oeip        : %08x\n", from_pd_to_de.oeip);
    printf("ieip        : %08x\n", from_pd_to_de.ieip);
    printf("reg0 src    : %02x\n", from_pd_to_de.reg0_src);
    printf("\n");
}

void print_DE_REG(void){
    printf("========DE REG========\n");
    printf("OEIP       : %08x\n", from_de_to_e1.OEIP_V);
    printf("IEIP       : %08x\n", from_de_to_e1.IEIP_V);
    printf("OEFLAGS    : %08x\n", from_de_to_e1.OEFLAGS_V);
    printf("SRCREGA    : %08x\n", from_de_to_e1.SRCREGA_V);
    printf("SRCREGB    : %08x\n", from_de_to_e1.SRCREGB_V);
    printf("SRCREGC    : %08x\n", from_de_to_e1.SRCREGC_V);
    printf("SRCSREG    : %08x\n", from_de_to_e1.SRCSREG_V);
    printf("MMA        : %016" PRIx64 "\n", from_de_to_e1.MMA_V);
    printf("MMB        : %016" PRIx64 "\n", from_de_to_e1.MMB_V);
    printf("IMM        : %08x\n", from_de_to_e1.IMM_V);
    printf("PTRA       : %08x\n", from_de_to_e1.PTRA_V);
    printf("PTRB       : %08x\n", from_de_to_e1.PTRB_V);
    printf("DSTREGA IDX: %d\n", from_de_to_e1.DSTREGA_IDX);
    printf("DSTREGB IDX: %d\n", from_de_to_e1.DSTREGA_IDX);
    printf("SREG1      : %08x\n", from_de_to_e1.SREG1_V);
    printf("SLIM1      : %08x\n", from_de_to_e1.SLIM1_V);
    printf("BASE1      : %08x\n", from_de_to_e1.BASE1_V);
    printf("INDEX1     : %08x\n", from_de_to_e1.INDEX1_V);
    printf("DISP1      : %08x\n", from_de_to_e1.DISP1_V);
    printf("SCALE1 MUX : %02x\n", from_de_to_e1.SCALE1_MUX);
    printf("MSIZE1 MUX : %02x\n", from_de_to_e1.MSIZE1_MUX);
    printf("SREG2      : %08x\n", from_de_to_e1.SREG2_V);
    printf("SLIM2      : %08x\n", from_de_to_e1.SLIM2_V);
    printf("BASE2      : %08x\n", from_de_to_e1.BASE2_V);
    printf("MSIZE2 MUX : %02x\n", from_de_to_e1.MSIZE2_MUX);
}

void print_E1_REG(void){
    printf("========E1 REG========\n");
    printf("OEIP       : %08x\n", from_e1_to_m1.OEIP_V);
    printf("IEIP       : %08x\n", from_e1_to_m1.IEIP_V);
    printf("OEFLAGS    : %08x\n", from_e1_to_m1.OEFLAGS_V);
    printf("SRCREGA    : %08x\n", from_e1_to_m1.SRCREGA_V);
    printf("SRCREGB    : %08x\n", from_e1_to_m1.SRCREGB_V);
    printf("SRCREGC    : %08x\n", from_e1_to_m1.SRCREGC_V);
    printf("SRCSREG    : %08x\n", from_e1_to_m1.SRCSREG_V);
    printf("MMA        : %016" PRIx64 "\n", from_e1_to_m1.MMA_V);
    printf("MMB        : %016" PRIx64 "\n", from_e1_to_m1.MMB_V);
    printf("IMM        : %08x\n", from_e1_to_m1.IMM_V);
    printf("PTRA       : %08x\n", from_e1_to_m1.PTRA_V);
    printf("PTRB       : %08x\n", from_e1_to_m1.PTRB_V);
    printf("DSTREGA IDX: %d\n", from_e1_to_m1.DSTREGA_IDX);
    printf("DSTREGB IDX: %d\n", from_e1_to_m1.DSTREGA_IDX);
    printf("LOAD ADDR  : %08x\n", from_e1_to_m1.LOAD_ADDR);
    printf("LOAD SIZE  : %08x\n", from_e1_to_m1.LOAD_SIZE);
    printf("STORE ADDR : %08x\n", from_e1_to_m1.STORE_ADDR);
    printf("STORE SIZE : %08x\n", from_e1_to_m1.STORE_SIZE);
}

void print_M1_REG(void){
    printf("========M1 REG========\n");
    printf("OEIP       : %08x\n", from_m1_to_e2.OEIP_V);
    printf("IEIP       : %08x\n", from_m1_to_e2.IEIP_V);
    printf("OEFLAGS    : %08x\n", from_m1_to_e2.OEFLAGS_V);
    printf("SRCREGA    : %08x\n", from_m1_to_e2.SRCREGA_V);
    printf("SRCREGB    : %08x\n", from_m1_to_e2.SRCREGB_V);
    printf("SRCREGC    : %08x\n", from_m1_to_e2.SRCREGC_V);
    printf("SRCSREG    : %08x\n", from_m1_to_e2.SRCSREG_V);
    printf("MMA        : %016" PRIx64 "\n", from_m1_to_e2.MMA_V);
    printf("MMB        : %016" PRIx64 "\n", from_m1_to_e2.MMB_V);
    printf("IMM        : %08x\n", from_m1_to_e2.IMM_V);
    printf("PTRA       : %08x\n", from_m1_to_e2.PTRA_V);
    printf("PTRB       : %08x\n", from_m1_to_e2.PTRB_V);
    printf("DSTREGA IDX: %d\n", from_m1_to_e2.DSTREGA_IDX);
    printf("DSTREGB IDX: %d\n", from_m1_to_e2.DSTREGA_IDX);
    printf("LOAD ADDR  : %08x\n", from_m1_to_e2.LOAD_ADDR);
    printf("LOAD SIZE  : %016" PRIx64 "\n", from_m1_to_e2.LOAD_RESULT);
    printf("STORE ADDR : %08x\n", from_m1_to_e2.STORE_ADDR);
    printf("STORE SIZE : %08x\n", from_m1_to_e2.STORE_SIZE);
}
// PD_INST from_pd, DE_REG *to_de, WB_TO_RF from_wb, 

#endif
