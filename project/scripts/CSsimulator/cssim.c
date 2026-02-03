#include "cssim.h"
#include "gp_regfile.h"
#include "mmx_regfile.h"
#include "seg_regfile.h"
#include "mem.h"
#include "sim_types.h"

#define CONTROL_STORE_ROWS 64
#define INITIAL_STATE_NUMBER 18


/***************************************************************/
/* A couple of useful definitions.                             */
/***************************************************************/
#define TRUE  1
#define FALSE 0

int tempCS[CS_CONTROL_STORE_BITS];


void DE(int* CS);
void E1(void);
void M1(void);
void E2(void);
void WB(void);

int CONTROL_STORE[CONTROL_STORE_ROWS][CS_CONTROL_STORE_BITS];

void init_control_store(char *ucode_filename) {                 
    FILE *ucode;
    int i, j, index;
    char line[200];

    printf("Loading Control Store from file: %s\n", ucode_filename);

    /* Open the micro-code file. */
    if ((ucode = fopen(ucode_filename, "r")) == NULL) {
	printf("Error: Can't open micro-code file %s\n", ucode_filename);
	exit(-1);
    }

    /* Read a line for each row in the control store. */
    for(i = 0; i < CONTROL_STORE_ROWS; i++) {
	if (fscanf(ucode, "%[^\n]\n", line) == EOF) {
	    printf("Error: Too few lines (%d) in micro-code file: %s\n",
		   i, ucode_filename);
	    exit(-1);
	}

	/* Put in bits one at a time. */
	index = 0;

	for (j = 0; j < CS_CONTROL_STORE_BITS; j++) {
	    /* Needs to find enough bits in line. */
	    if (line[index] == '\0') {
		printf("Error: Too few control bits in micro-code file: %s\nLine: %d\n",
		       ucode_filename, i);
		exit(-1);
	    }
	    if (line[index] != '0' && line[index] != '1') {
		printf("Error: Unknown value in micro-code file: %s\nLine: %d, Bit: %d\n",
		       ucode_filename, i, j);
		exit(-1);
	    }

	    /* Set the bit in the Control Store. */
	    CONTROL_STORE[i][j] = (line[index] == '0') ? 0:1;
	    index++;
	}

	/* Warn about extra bits in line. */
	if (line[index] != '\0')
	    printf("Warning: Extra bit(s) in control store file %s. Line: %d\n",
		   ucode_filename, i);
    }
    printf("\n");
}

/* simulator signal */
int RUN_BIT;

/***************************************************************/
/* A cycle counter.                                            */
/***************************************************************/
int CYCLE_COUNT;

// PD_INST from_pd_to_de, new_from_pd_to_de;
// DE_REG from_de_to_e1, new_from_de_to_e1;
// E1_REG from_e1_to_m1, new_from_e1_to_m1;
// M1_REG from_m1_to_e2, new_from_m1_to_e2;
// WB_TO_RF from_wb_to_de, new_from_wb_to_de;
void init_PS(void){
    new_from_pd_to_de = from_pd_to_de;
    new_from_de_to_e1 = from_de_to_e1;
    new_from_e1_to_m1 = from_e1_to_m1;
    new_from_m1_to_e2 = from_m1_to_e2;
    new_from_e2_to_wb = from_e2_to_wb;
}

void update_PS(void){
    from_pd_to_de = new_from_pd_to_de;
    from_de_to_e1 = new_from_de_to_e1;
    from_e1_to_m1 = new_from_e1_to_m1;
    from_m1_to_e2 = new_from_m1_to_e2;
    from_e2_to_wb = new_from_e2_to_wb;
}

void cycle(void) {
  init_PS();
  WB();
  E2();
  M1();
  E1();
  DE(tempCS);
  update_PS();
  CYCLE_COUNT++;
}

void run(int num_cycles) {
    int i;
    
    if (RUN_BIT == FALSE) {
      printf("Can't simulate, Simulator is halted\n\n");
	return;
    }

    printf("Simulating for %d cycles...\n\n", num_cycles);
    for (i = 0; i < num_cycles; i++) {
	    cycle();
    }
}

void mdump(FILE *dumpfile, uint32_t start_addr, uint32_t stop_addr)
{
    if (!dumpfile) return;

    // clamp + normalize range
    if (start_addr >= MEM_SIZE_BYTES) start_addr = MEM_SIZE_BYTES - 1;
    if (stop_addr  >= MEM_SIZE_BYTES) stop_addr  = MEM_SIZE_BYTES - 1;
    if (start_addr > stop_addr) {
        uint32_t tmp = start_addr;
        start_addr = stop_addr;
        stop_addr = tmp;
    }

    const uint32_t BYTES_PER_LINE = 16;
    uint32_t line_start = start_addr & ~(BYTES_PER_LINE - 1u); // align down

    fprintf(dumpfile, "=== MEM DUMP [0x%04x .. 0x%04x] (%u bytes) ===\n",
            start_addr, stop_addr, (unsigned)(stop_addr - start_addr + 1));
    printf("=== MEM DUMP [0x%04x .. 0x%04x] (%u bytes) ===\n",
            start_addr, stop_addr, (unsigned)(stop_addr - start_addr + 1));
    for (uint32_t addr = line_start; addr <= stop_addr; addr += BYTES_PER_LINE) {
        // address
        fprintf(dumpfile, "0x%04x: ", addr);
        printf("0x%04x: ", addr);
        // hex bytes
        for (uint32_t i = 0; i < BYTES_PER_LINE; i++) {
            uint32_t a = addr + i;

            if (a < start_addr || a > stop_addr) {
                fprintf(dumpfile, "   ");           // out of requested range
                printf("   "); 
            } else {
                fprintf(dumpfile, "%02x ", memory.b[a]);
                printf("%02x ", memory.b[a]);
            }

            if (i == 7) fprintf(dumpfile, " ");    // extra space in middle
            if (i == 7) printf(" ");    // extra space in middle
        }

        // ascii (optional but useful)
        fprintf(dumpfile, " |");
        printf(" |");
        for (uint32_t i = 0; i < BYTES_PER_LINE; i++) {
            uint32_t a = addr + i;
            if (a < start_addr || a > stop_addr) {
                fputc(' ', dumpfile);
                printf(" ");
            } else {
                uint8_t c = memory.b[a];
                fputc((c >= 32 && c <= 126) ? (char)c : '.', dumpfile);
                if ((c >= 32 && c <= 126)){
                    printf("%c", c);
                }else{
                    printf(".");
                }
            }
        }
        fprintf(dumpfile, "|\n");
        printf("|\n");
        // prevent uint32_t overflow in addr loop when stop_addr is near max
        if (addr + BYTES_PER_LINE < addr) break;
    }

    fprintf(dumpfile, "=== END MEM DUMP ===\n");
    printf("=== END MEM DUMP ===\n");
}

/***************************************************************/
/*                                                             */
/* Procedure : rdump                                           */
/*                                                             */
/* Purpose   : Dump current architectural state  to the       */   
/*             output file.                                    */
/*                                                             */
/***************************************************************/
void rdump(FILE * dumpsim_file) {
    int k; 

    printf("\n=== Current architectural state ===\n");
    printf("Cycle Count : %d\n", CYCLE_COUNT);
    printf("EIP         : 0x%08x\n", EIP);
    printf("EFLAGS      : 0x%08x\n", EFLAGS);
    printf("General Purpose Registers:\n");
    for (k = 0; k < 8; k++)
	    printf("%d: 0x%08x\n", k, (gp_rf.regs[k]));
    printf("Segment Registers:\n");
    for (k = 0; k < 6; k++)
	    printf("%d: 0x%08x\n", k, (seg_rf.r[k]));
    printf("MMX Registers:\n");
    for (k = 0; k < 8; k++)
	    printf("%d: 0x%016" PRIx64 "\n", k, (mmx_rf.r[k]));
    printf("\n");

    /* dump the state information into the dumpsim file */
    fprintf(dumpsim_file, "\n=== Current architectural state ===\n");
    fprintf(dumpsim_file, "Cycle Count : %d\n", CYCLE_COUNT);
    fprintf(dumpsim_file, "EIP         : 0x%08x\n", EIP);
    fprintf(dumpsim_file, "EFLAGS      : 0x%08x\n", EFLAGS);
    fprintf(dumpsim_file, "General Purpose Registers:\n");
    for (k = 0; k < 8; k++)
	    fprintf(dumpsim_file, "%d: 0x%08x\n", k, (gp_rf.regs[k]));
    fprintf(dumpsim_file, "Segment Registers:\n");
    for (k = 0; k < 6; k++)
	    fprintf(dumpsim_file, "%d: 0x%08x\n", k, (seg_rf.r[k]));
    fprintf(dumpsim_file, "MMX Registers:\n");
    for (k = 0; k < 8; k++)
	    printf("%d: 0x%016" PRIx64 "\n", k, (mmx_rf.r[k]));
    fprintf(dumpsim_file, "\n");

    fflush(dumpsim_file);
}

/***************************************************************/
/*                                                             */
/* Procedure : idump                                           */
/*                                                             */
/* Purpose   : Dump current internal state to the              */
/*             output file.                                    */
/*                                                             */
/***************************************************************/
void idump(FILE * dumpsim_file) {
    int k;
    printf("\n=== Current architectural state ===\n");
    printf("Cycle Count : %d\n", CYCLE_COUNT);
    printf("EIP         : 0x%08x\n", EIP);
    printf("EFLAGS      : 0x%08x\n", EFLAGS);
    printf("General Purpose Registers:\n");
    for (k = 0; k < 8; k++)
	    printf("%d: 0x%08x\n", k, (gp_rf.regs[k]));
    printf("Segment Registers:\n");
    for (k = 0; k < 6; k++)
	    printf("%d: 0x%08x\n", k, (seg_rf.r[k]));
    printf("MMX Registers:\n");
    for (k = 0; k < 8; k++)
	    printf("%d: 0x%016" PRIx64 "\n", k, (mmx_rf.r[k]));
    printf("\n");

    printf("=== PD INST ===\n");
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

    printf("=== DE REG ===\n");
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
    printf("\n");

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
    printf("\n");

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
    printf("LOAD RESULT  : %016" PRIx64 "\n", from_m1_to_e2.LOAD_RESULT);
    printf("STORE ADDR : %08x\n", from_m1_to_e2.STORE_ADDR);
    printf("STORE SIZE : %08x\n", from_m1_to_e2.STORE_SIZE);
    printf("\n");

    printf("========E2 REG========\n");
    printf("OEIP       : %08x\n", from_e2_to_wb.OEIP_V);
    printf("IEIP       : %08x\n", from_e2_to_wb.IEIP_V);
    printf("OEFLAGS    : %08x\n", from_e2_to_wb.OEFLAGS_V);
    printf("SRCREGA    : %08x\n", from_e2_to_wb.SRCREGA_V);
    printf("SRCREGB    : %08x\n", from_e2_to_wb.SRCREGB_V);
    printf("SRCREGC    : %08x\n", from_e2_to_wb.SRCREGC_V);
    printf("SRCSREG    : %08x\n", from_e2_to_wb.SRCSREG_V);
    printf("MMA        : %016" PRIx64 "\n", from_e2_to_wb.MMA_V);
    printf("MMB        : %016" PRIx64 "\n", from_e2_to_wb.MMB_V);
    printf("IMM        : %08x\n", from_e2_to_wb.IMM_V);
    printf("PTRA       : %08x\n", from_e2_to_wb.PTRA_V);
    printf("PTRB       : %08x\n", from_e2_to_wb.PTRB_V);
    printf("DSTREGA IDX: %d\n", from_e2_to_wb.DSTREGA_IDX);
    printf("DSTREGB IDX: %d\n", from_e2_to_wb.DSTREGA_IDX);
    printf("LOAD ADDR  : %08x\n", from_e2_to_wb.LOAD_ADDR);
    printf("LOAD RESULT  : %016" PRIx64 "\n", from_e2_to_wb.LOAD_RESULT);
    printf("EXECUTE RESULT : %016" PRIx64 "\n", from_e2_to_wb.EX_RESULT);
    printf("NEW EFLAGS : %08x\n", from_e2_to_wb.NEW_EFLAGS);
    printf("STORE ADDR : %08x\n", from_e2_to_wb.STORE_ADDR);
    printf("STORE SIZE : %08x\n", from_e2_to_wb.STORE_SIZE);
    printf("\n");

    printf("========WB REG========\n");
    printf("GP WR0 IDX  : %0d\n", from_wb_to_de.gp_wr0_idx);
    printf("GP WR0 DATA : %08x\n", from_wb_to_de.gp_wr0_data);
    printf("GP WR0 SIZE : %0d\n", from_wb_to_de.gp_wr0_size);
    printf("GP WR0 EN   : %0d\n", from_wb_to_de.gp_wr0_en);
    printf("GP WR1 IDX  : %0d\n", from_wb_to_de.gp_wr1_idx);
    printf("GP WR1 DATA : %08x\n", from_wb_to_de.gp_wr1_data);
    printf("GP WR1 SIZE : %0d\n", from_wb_to_de.gp_wr1_size);
    printf("GP WR1 EN   : %0d\n", from_wb_to_de.gp_wr1_en);
    printf("SEG WR IDX  : %0d\n", from_wb_to_de.seg_wr_idx);
    printf("SEG WR DATA : %04x\n", from_wb_to_de.seg_wr_data);
    printf("SEG WR EN   : %0d\n", from_wb_to_de.seg_wr_en);
    printf("MMX WR IDX  : %0d\n", from_wb_to_de.mmx_wr_idx);
    printf("MMX WR DATA : %016" PRIx64 "\n", from_wb_to_de.mmx_wr_data);
    printf("MMX WR EN   : %0d\n", from_wb_to_de.mmx_wr_en);
    printf("MEM WR ADDR : %08x\n", from_wb_to_mem.w_addr);
    printf("MEM WR DATA :  %016" PRIx64 "\n", from_wb_to_mem.w_data);
    printf("MEM WR SIZE : %0d\n", from_wb_to_mem.w_size);
    printf("MEM WR EN   : %0d\n", from_wb_to_mem.w_en);
    printf("\n");

    fprintf(dumpsim_file, "\n=== Current architectural state ===\n");
    fprintf(dumpsim_file,"Cycle Count : %d\n", CYCLE_COUNT);
    fprintf(dumpsim_file,"EIP         : 0x%08x\n", EIP);
    fprintf(dumpsim_file,"EFLAGS      : 0x%08x\n", EFLAGS);
    fprintf(dumpsim_file,"General Purpose Registers:\n");
    for (k = 0; k < 8; k++)
	    fprintf(dumpsim_file,"%d: 0x%08x\n", k, (gp_rf.regs[k]));
    fprintf(dumpsim_file,"Segment Registers:\n");
    for (k = 0; k < 6; k++)
	    fprintf(dumpsim_file,"%d: 0x%08x\n", k, (seg_rf.r[k]));
    fprintf(dumpsim_file,"MMX Registers:\n");
    for (k = 0; k < 8; k++)
	    fprintf(dumpsim_file,"%d: 0x%016" PRIx64 "\n", k, (mmx_rf.r[k]));
    fprintf(dumpsim_file,"\n");

    fprintf(dumpsim_file,"=== PD INST ===\n");
    fprintf(dumpsim_file,"prefix mux  : %02x\n", from_pd_to_de.prefix_mux);
    fprintf(dumpsim_file,"opcode      : %02x\n", from_pd_to_de.opcode);
    fprintf(dumpsim_file,"escape      : %d\n", from_pd_to_de.escape);
    fprintf(dumpsim_file,"modrm       : %02x\n", from_pd_to_de.modrm);
    fprintf(dumpsim_file,"sib         : %02x\n", from_pd_to_de.sib);
    fprintf(dumpsim_file,"displacement: %08x\n", from_pd_to_de.displacement);
    fprintf(dumpsim_file,"disp size   : %02x\n", from_pd_to_de.disp_size);
    fprintf(dumpsim_file,"immediate   : %08x\n", from_pd_to_de.immediate);
    fprintf(dumpsim_file,"imm size    : %02x\n", from_pd_to_de.imm_size);
    fprintf(dumpsim_file,"oeip        : %08x\n", from_pd_to_de.oeip);
    fprintf(dumpsim_file,"ieip        : %08x\n", from_pd_to_de.ieip);
    fprintf(dumpsim_file,"reg0 src    : %02x\n", from_pd_to_de.reg0_src);
    fprintf(dumpsim_file,"\n");

    fprintf(dumpsim_file,"=== DE REG ===\n");
    fprintf(dumpsim_file,"OEIP       : %08x\n", from_de_to_e1.OEIP_V);
    fprintf(dumpsim_file,"IEIP       : %08x\n", from_de_to_e1.IEIP_V);
    fprintf(dumpsim_file,"OEFLAGS    : %08x\n", from_de_to_e1.OEFLAGS_V);
    fprintf(dumpsim_file,"SRCREGA    : %08x\n", from_de_to_e1.SRCREGA_V);
    fprintf(dumpsim_file,"SRCREGB    : %08x\n", from_de_to_e1.SRCREGB_V);
    fprintf(dumpsim_file,"SRCREGC    : %08x\n", from_de_to_e1.SRCREGC_V);
    fprintf(dumpsim_file,"SRCSREG    : %08x\n", from_de_to_e1.SRCSREG_V);
    fprintf(dumpsim_file,"MMA        : %016" PRIx64 "\n", from_de_to_e1.MMA_V);
    fprintf(dumpsim_file,"MMB        : %016" PRIx64 "\n", from_de_to_e1.MMB_V);
    fprintf(dumpsim_file,"IMM        : %08x\n", from_de_to_e1.IMM_V);
    fprintf(dumpsim_file,"PTRA       : %08x\n", from_de_to_e1.PTRA_V);
    fprintf(dumpsim_file,"PTRB       : %08x\n", from_de_to_e1.PTRB_V);
    fprintf(dumpsim_file,"DSTREGA IDX: %d\n", from_de_to_e1.DSTREGA_IDX);
    fprintf(dumpsim_file,"DSTREGB IDX: %d\n", from_de_to_e1.DSTREGA_IDX);
    fprintf(dumpsim_file,"SREG1      : %08x\n", from_de_to_e1.SREG1_V);
    fprintf(dumpsim_file,"SLIM1      : %08x\n", from_de_to_e1.SLIM1_V);
    fprintf(dumpsim_file,"BASE1      : %08x\n", from_de_to_e1.BASE1_V);
    fprintf(dumpsim_file,"INDEX1     : %08x\n", from_de_to_e1.INDEX1_V);
    fprintf(dumpsim_file,"DISP1      : %08x\n", from_de_to_e1.DISP1_V);
    fprintf(dumpsim_file,"SCALE1 MUX : %02x\n", from_de_to_e1.SCALE1_MUX);
    fprintf(dumpsim_file,"MSIZE1 MUX : %02x\n", from_de_to_e1.MSIZE1_MUX);
    fprintf(dumpsim_file,"SREG2      : %08x\n", from_de_to_e1.SREG2_V);
    fprintf(dumpsim_file,"SLIM2      : %08x\n", from_de_to_e1.SLIM2_V);
    fprintf(dumpsim_file,"BASE2      : %08x\n", from_de_to_e1.BASE2_V);
    fprintf(dumpsim_file,"MSIZE2 MUX : %02x\n", from_de_to_e1.MSIZE2_MUX);
    fprintf(dumpsim_file,"\n");

    fprintf(dumpsim_file,"========E1 REG========\n");
    fprintf(dumpsim_file,"OEIP       : %08x\n", from_e1_to_m1.OEIP_V);
    fprintf(dumpsim_file,"IEIP       : %08x\n", from_e1_to_m1.IEIP_V);
    fprintf(dumpsim_file,"OEFLAGS    : %08x\n", from_e1_to_m1.OEFLAGS_V);
    fprintf(dumpsim_file,"SRCREGA    : %08x\n", from_e1_to_m1.SRCREGA_V);
    fprintf(dumpsim_file,"SRCREGB    : %08x\n", from_e1_to_m1.SRCREGB_V);
    fprintf(dumpsim_file,"SRCREGC    : %08x\n", from_e1_to_m1.SRCREGC_V);
    fprintf(dumpsim_file,"SRCSREG    : %08x\n", from_e1_to_m1.SRCSREG_V);
    fprintf(dumpsim_file,"MMA        : %016" PRIx64 "\n", from_e1_to_m1.MMA_V);
    fprintf(dumpsim_file,"MMB        : %016" PRIx64 "\n", from_e1_to_m1.MMB_V);
    fprintf(dumpsim_file,"IMM        : %08x\n", from_e1_to_m1.IMM_V);
    fprintf(dumpsim_file,"PTRA       : %08x\n", from_e1_to_m1.PTRA_V);
    fprintf(dumpsim_file,"PTRB       : %08x\n", from_e1_to_m1.PTRB_V);
    fprintf(dumpsim_file,"DSTREGA IDX: %d\n", from_e1_to_m1.DSTREGA_IDX);
    fprintf(dumpsim_file,"DSTREGB IDX: %d\n", from_e1_to_m1.DSTREGA_IDX);
    fprintf(dumpsim_file,"LOAD ADDR  : %08x\n", from_e1_to_m1.LOAD_ADDR);
    fprintf(dumpsim_file,"LOAD SIZE  : %08x\n", from_e1_to_m1.LOAD_SIZE);
    fprintf(dumpsim_file,"STORE ADDR : %08x\n", from_e1_to_m1.STORE_ADDR);
    fprintf(dumpsim_file,"STORE SIZE : %08x\n", from_e1_to_m1.STORE_SIZE);
    fprintf(dumpsim_file,"\n");

    fprintf(dumpsim_file,"========M1 REG========\n");
    fprintf(dumpsim_file,"OEIP       : %08x\n", from_m1_to_e2.OEIP_V);
    fprintf(dumpsim_file,"IEIP       : %08x\n", from_m1_to_e2.IEIP_V);
    fprintf(dumpsim_file,"OEFLAGS    : %08x\n", from_m1_to_e2.OEFLAGS_V);
    fprintf(dumpsim_file,"SRCREGA    : %08x\n", from_m1_to_e2.SRCREGA_V);
    fprintf(dumpsim_file,"SRCREGB    : %08x\n", from_m1_to_e2.SRCREGB_V);
    fprintf(dumpsim_file,"SRCREGC    : %08x\n", from_m1_to_e2.SRCREGC_V);
    fprintf(dumpsim_file,"SRCSREG    : %08x\n", from_m1_to_e2.SRCSREG_V);
    fprintf(dumpsim_file,"MMA        : %016" PRIx64 "\n", from_m1_to_e2.MMA_V);
    fprintf(dumpsim_file,"MMB        : %016" PRIx64 "\n", from_m1_to_e2.MMB_V);
    fprintf(dumpsim_file,"IMM        : %08x\n", from_m1_to_e2.IMM_V);
    fprintf(dumpsim_file,"PTRA       : %08x\n", from_m1_to_e2.PTRA_V);
    fprintf(dumpsim_file,"PTRB       : %08x\n", from_m1_to_e2.PTRB_V);
    fprintf(dumpsim_file,"DSTREGA IDX: %d\n", from_m1_to_e2.DSTREGA_IDX);
    fprintf(dumpsim_file,"DSTREGB IDX: %d\n", from_m1_to_e2.DSTREGA_IDX);
    fprintf(dumpsim_file,"LOAD ADDR  : %08x\n", from_m1_to_e2.LOAD_ADDR);
    fprintf(dumpsim_file,"LOAD RESULT: %016" PRIx64 "\n", from_m1_to_e2.LOAD_RESULT);
    fprintf(dumpsim_file,"STORE ADDR : %08x\n", from_m1_to_e2.STORE_ADDR);
    fprintf(dumpsim_file,"STORE SIZE : %08x\n", from_m1_to_e2.STORE_SIZE);
    fprintf(dumpsim_file,"\n");

    fprintf(dumpsim_file,"========E2 REG========\n");
    fprintf(dumpsim_file,"OEIP       : %08x\n", from_e2_to_wb.OEIP_V);
    fprintf(dumpsim_file,"IEIP       : %08x\n", from_e2_to_wb.IEIP_V);
    fprintf(dumpsim_file,"OEFLAGS    : %08x\n", from_e2_to_wb.OEFLAGS_V);
    fprintf(dumpsim_file,"SRCREGA    : %08x\n", from_e2_to_wb.SRCREGA_V);
    fprintf(dumpsim_file,"SRCREGB    : %08x\n", from_e2_to_wb.SRCREGB_V);
    fprintf(dumpsim_file,"SRCREGC    : %08x\n", from_e2_to_wb.SRCREGC_V);
    fprintf(dumpsim_file,"SRCSREG    : %08x\n", from_e2_to_wb.SRCSREG_V);
    fprintf(dumpsim_file,"MMA        : %016" PRIx64 "\n", from_e2_to_wb.MMA_V);
    fprintf(dumpsim_file,"MMB        : %016" PRIx64 "\n", from_e2_to_wb.MMB_V);
    fprintf(dumpsim_file,"IMM        : %08x\n", from_e2_to_wb.IMM_V);
    fprintf(dumpsim_file,"PTRA       : %08x\n", from_e2_to_wb.PTRA_V);
    fprintf(dumpsim_file,"PTRB       : %08x\n", from_e2_to_wb.PTRB_V);
    fprintf(dumpsim_file,"DSTREGA IDX: %d\n", from_e2_to_wb.DSTREGA_IDX);
    fprintf(dumpsim_file,"DSTREGB IDX: %d\n", from_e2_to_wb.DSTREGA_IDX);
    fprintf(dumpsim_file,"LOAD ADDR  : %08x\n", from_e2_to_wb.LOAD_ADDR);
    fprintf(dumpsim_file,"LOAD RESULT: %016" PRIx64 "\n", from_e2_to_wb.LOAD_RESULT);
    fprintf(dumpsim_file,"EX RESULT  : %016" PRIx64 "\n", from_e2_to_wb.EX_RESULT);
    fprintf(dumpsim_file,"NEW EFLAGS : %08x\n", from_e2_to_wb.NEW_EFLAGS);
    fprintf(dumpsim_file,"STORE ADDR : %08x\n", from_m1_to_e2.STORE_ADDR);
    fprintf(dumpsim_file,"STORE SIZE : %08x\n", from_m1_to_e2.STORE_SIZE);
    fprintf(dumpsim_file,"\n");

    fprintf(dumpsim_file,"========WB REG========\n");
    fprintf(dumpsim_file,"GP WR0 IDX  : %0d\n", from_wb_to_de.gp_wr0_idx);
    fprintf(dumpsim_file,"GP WR0 DATA : %08x\n", from_wb_to_de.gp_wr0_data);
    fprintf(dumpsim_file,"GP WR0 SIZE : %0d\n", from_wb_to_de.gp_wr0_size);
    fprintf(dumpsim_file,"GP WR0 EN   : %0d\n", from_wb_to_de.gp_wr0_en);
    fprintf(dumpsim_file,"GP WR1 IDX  : %0d\n", from_wb_to_de.gp_wr1_idx);
    fprintf(dumpsim_file,"GP WR1 DATA : %08x\n", from_wb_to_de.gp_wr1_data);
    fprintf(dumpsim_file,"GP WR1 SIZE : %0d\n", from_wb_to_de.gp_wr1_size);
    fprintf(dumpsim_file,"GP WR1 EN   : %0d\n", from_wb_to_de.gp_wr1_en);
    fprintf(dumpsim_file,"SEG WR IDX  : %0d\n", from_wb_to_de.seg_wr_idx);
    fprintf(dumpsim_file,"SEG WR DATA : %04x\n", from_wb_to_de.seg_wr_data);
    fprintf(dumpsim_file,"SEG WR EN   : %0d\n", from_wb_to_de.seg_wr_en);
    fprintf(dumpsim_file,"MMX WR IDX  : %0d\n", from_wb_to_de.mmx_wr_idx);
    fprintf(dumpsim_file,"MMX WR DATA : %016" PRIx64 "\n", from_wb_to_de.mmx_wr_data);
    fprintf(dumpsim_file,"MMX WR EN   : %0d\n", from_wb_to_de.mmx_wr_en);
    fprintf(dumpsim_file,"MEM WR ADDR : %08x\n", from_wb_to_mem.w_addr);
    fprintf(dumpsim_file,"MEM WR DATA :  %016" PRIx64 "\n", from_wb_to_mem.w_data);
    fprintf(dumpsim_file,"MEM WR SIZE : %0d\n", from_wb_to_mem.w_size);
    fprintf(dumpsim_file,"MEM WR EN   : %0d\n", from_wb_to_mem.w_en);
    fprintf(dumpsim_file,"\n");
    
    fflush(dumpsim_file);
}

/***************************************************************/
/*                                                             */
/* Procedure : help                                            */
/*                                                             */
/* Purpose   : Print out a list of commands.                   */
/*                                                             */
/***************************************************************/
void help(void) {
    printf("----------------LC-3bSIM Help-------------------------\n");
    // printf("go               -  run program to completion       \n");
    printf("run n            -  execute program for n cycles    \n");
    printf("mdump low high   -  dump memory from low to high    \n");
    printf("rdump            -  dump the architectural state    \n");
    printf("idump            -  dump the internal state         \n");
    printf("?                -  display this help menu          \n");
    printf("quit             -  exit the program                \n\n");
}


/***************************************************************/
/*                                                             */
/* Procedure : get_command                                     */
/*                                                             */
/* Purpose   : Read a command from standard input.             */  
/*                                                             */
/***************************************************************/
void get_command(FILE * dumpsim_file) {
    char buffer[20];
    int start, stop, cycles;

    printf("x86-SIM> ");

    scanf("%s", buffer);
    printf("\n");

    switch(buffer[0]) {
    case 'M':
    case 'm':
	scanf("%i %i", &start, &stop);
	mdump(dumpsim_file, start, stop);
	break;

    case '?':
	help();
	break;
    case 'Q':
    case 'q':
	printf("Bye.\n");
	exit(0);

    case 'R':
    case 'r':
	if (buffer[1] == 'd' || buffer[1] == 'D')
	    rdump(dumpsim_file);
	else {
	    scanf("%d", &cycles);
	    run(cycles);
	}
	break;

    case 'I':
    case 'i':
        idump(dumpsim_file);
        break;
	
    default:
	printf("Invalid Command\n");
	break;
    }
}




/**
 * shift_mask(inst, start, num_bits)
 * return: inst[start+num_bits-1 : start]
 */
int shift_mask(int inst, int start, int num_bits){
    int mask = (1 << num_bits) - 1;
    return ((inst >> start) & mask);
}

int mux2(int sel, int in0, int in1){
    return sel ? in1 : in0;
}
int mux4(int sel, int in0, int in1, int in2, int in3){
    int result;
    switch (sel)
    {
        case 0:
            result = in0;
            break;
        case 1:
            result = in1;
            break;
        case 2:
            result = in2;
            break;
        case 3:
            result = in3;
            break;
        default:
            result = 0;
            break;
    }
    return result;
}


int get_modrm_mod(int modrm){return shift_mask(modrm, 6, 2);}
int get_modrm_rm(int modrm){return shift_mask(modrm, 0, 3);}
int get_modrm_reg(int modrm){return shift_mask(modrm, 3, 3);}
int get_sib_base(int sib){return shift_mask(sib, 0, 3);}
int get_sib_index(int sib){return shift_mask(sib, 3, 3);}
int get_sib_scale(int sib){return shift_mask(sib, 6, 2);}
int get_opcode_opR(int opcode){return shift_mask(opcode, 0, 3);}
int get_prefix_seg_prefix(int prefix_mux){return shift_mask(prefix_mux, 0, 3);}
int get_prefix_operand(int prefix_mux){return shift_mask(prefix_mux, 3, 1);}
void DE(int* CS){
    int gp_rd0_idx, gp_rd1_idx, gp_rd2_idx, gp_rd3_idx;
    int gp_rd0_data, gp_rd1_data, gp_rd2_data, gp_rd3_data;
    int seg_rd0_idx, seg_rd1_idx;
    seg_word_t seg_rd0_data, seg_rd1_data, seg_cs_data;
    int mmx_rd0_idx, mmx_rd1_idx;
    uint64_t mmx_rd0_data, mmx_rd1_data;
    int r0_idx_mux = (CS[CS_R0_IDX1] << 1) + CS[CS_R0_IDX0];
    int r3_idx_mux = (CS[CS_R3_IDX1] << 1) + CS[CS_R3_IDX0];
    int regA_mux = (CS[CS_A_SRC1] << 1) + CS[CS_A_SRC0];

    gp_rd0_idx = mux4(r0_idx_mux, 0, 4, 7, 2);
    gp_rd1_idx = mux2(CS[CS_R1_IDX], get_modrm_reg(from_pd_to_de.modrm), get_opcode_opR(from_pd_to_de.opcode));
    gp_rd2_idx = mux2((from_pd_to_de.reg0_src==1), get_sib_base(from_pd_to_de.sib), get_modrm_rm(from_pd_to_de.modrm));
    
    gp_rd3_idx = mux4(r3_idx_mux, get_sib_index(from_pd_to_de.sib), 4, 6, 0);

    // TODO: S0, S1 read index need to be fixed. Sreg instructions? pop/push sregs?
    seg_rd0_idx = get_prefix_seg_prefix(from_pd_to_de.prefix_mux);
    seg_rd1_idx = mux2(((r3_idx_mux==2) && (r0_idx_mux==2)), 2, 0);
    mmx_rd0_idx = get_modrm_rm(from_pd_to_de.modrm);
    mmx_rd1_idx = get_modrm_reg(from_pd_to_de.modrm);

    int regA_idx = mux4(regA_mux, gp_rd0_idx, gp_rd2_idx, gp_rd3_idx, gp_rd0_idx);
    int regB_idx = gp_rd1_idx;
    int alu_op_src = mux2(shift_mask(from_pd_to_de.opcode, 7, 1), get_modrm_reg(from_pd_to_de.opcode), get_modrm_reg(from_pd_to_de.modrm));
    gp_regfile_step(
        &gp_rf, 
        gp_rd0_idx, gp_rd1_idx, gp_rd2_idx, gp_rd3_idx,
        &gp_rd0_data, &gp_rd1_data, &gp_rd2_data, &gp_rd3_data,
        from_wb_to_de.gp_wr0_idx, from_wb_to_de.gp_wr1_idx,
        from_wb_to_de.gp_wr0_data, from_wb_to_de.gp_wr1_data,
        from_wb_to_de.gp_wr0_en, from_wb_to_de.gp_wr1_en,
        from_wb_to_de.gp_wr0_size, from_wb_to_de.gp_wr1_size
    );
    seg_regfile_step(
        &seg_rf,
        seg_rd0_idx, seg_rd1_idx,
        &seg_rd0_data, &seg_rd1_data, &seg_cs_data,
        from_wb_to_de.seg_wr_idx, from_wb_to_de.seg_wr_data, from_wb_to_de.seg_wr_en
    );
    mmx_regfile_step(
        &mmx_rf,
        mmx_rd0_idx, mmx_rd1_idx,
        &mmx_rd0_data, &mmx_rd1_data,
        from_wb_to_de.mmx_wr_idx, from_wb_to_de.mmx_wr_data, from_wb_to_de.mmx_wr_en
    );

    if(from_wb_to_de.ld_eflags){
        EFLAGS = from_wb_to_de.eflags;
    }
    new_from_de_to_e1.OEIP_V = from_pd_to_de.oeip;
    new_from_de_to_e1.IEIP_V = from_pd_to_de.ieip;
    new_from_de_to_e1.OEFLAGS_V = EFLAGS;
    new_from_de_to_e1.SRCREGA_V = mux4(regA_mux, gp_rd0_data, gp_rd2_data, gp_rd3_data, gp_rd0_data);
    new_from_de_to_e1.SRCREGB_V = gp_rd1_data;
    new_from_de_to_e1.SRCREGC_V = mux2(CS[CS_C_SRC], gp_rd0_data, gp_rd3_data);
    new_from_de_to_e1.SRCSREG_V = (int)(seg_rd0_data << 16); // TODO: the source of sreg?
    new_from_de_to_e1.MMA_V = mmx_rd0_data; // TODO: the source of MMX?
    new_from_de_to_e1.MMB_V = mmx_rd1_data;
    new_from_de_to_e1.IMM_V = from_pd_to_de.immediate; // TODO: immediate size? sign extend?
    new_from_de_to_e1.PTRA_V = from_pd_to_de.displacement; // TODO: how to choose ptr?
    new_from_de_to_e1.PTRB_V = from_pd_to_de.immediate;
    new_from_de_to_e1.DSTREGA_IDX = mux2(CS[CS_DSTA_IDX], regA_idx, regB_idx); // TODO: dst index logic?
    new_from_de_to_e1.DSTREGB_IDX = 0;
    new_from_de_to_e1.SREG1_V = (int)(seg_rd0_data << 16);
    new_from_de_to_e1.SLIM1_V = seg_limits[seg_rd0_idx];
    new_from_de_to_e1.BASE1_V = mux2(CS[CS_C_SRC], gp_rd2_data, gp_rd3_data);
    new_from_de_to_e1.INDEX1_V = mux2(shift_mask(from_pd_to_de.reg0_src, 1, 1), gp_rd3_data, 0);
    new_from_de_to_e1.DISP1_V = 0;
    new_from_de_to_e1.SCALE1_MUX = get_sib_scale(from_pd_to_de.sib);
    
    new_from_de_to_e1.SREG2_V = (int)(seg_rd1_data << 16);
    new_from_de_to_e1.SLIM2_V = seg_limits[seg_rd0_idx];
    new_from_de_to_e1.BASE2_V = mux2(CS[CS_C_SRC], gp_rd3_data, gp_rd0_data);
    new_from_de_to_e1.MSIZE2_MUX = 0;
    new_from_de_to_e1.E1_CS[E1_ALU_IN1_SRC] = (get_modrm_mod(from_pd_to_de.modrm)!=3);
    new_from_de_to_e1.E1_CS[E1_ALU_OP1] = ((alu_op_src & 0x4)>>2);
    new_from_de_to_e1.E1_CS[E1_ALU_OP0] = (alu_op_src & 0x1);
    if(CS[CS_DATASIZE]){
        if(get_prefix_operand(from_pd_to_de.prefix_mux)){
            new_from_de_to_e1.E1_CS[E1_DATASIZE1] = 0;
            new_from_de_to_e1.E1_CS[E1_DATASIZE0] = 1;
            new_from_de_to_e1.MSIZE1_MUX = 1;
        }else{
            new_from_de_to_e1.E1_CS[E1_DATASIZE1] = 1;
            new_from_de_to_e1.E1_CS[E1_DATASIZE0] = 0;
            new_from_de_to_e1.MSIZE1_MUX = 2;
        }
    }else{
        new_from_de_to_e1.E1_CS[E1_DATASIZE1] = 0;
        new_from_de_to_e1.E1_CS[E1_DATASIZE0] = 0;
        new_from_de_to_e1.MSIZE1_MUX = 0;
    }
    // 00: 8-bit, 01: 16-bit, 10: 32-bit
    int i = E1_LD_MADDR1;
    int j = CS_LD_MADDR1;
    while (i < NUM_E1_CS_BITS){
        new_from_de_to_e1.E1_CS[i] = CS[j];
        i++;
        j++;
    }
}

int E1_mAddrD1(int sreg, int base, int index, int disp, int scale, int slim, int data_size, int* addr){
    int seg_addr = base+index*scale+disp;
    int exception = 0;
    if (seg_addr+data_size > slim){
        exception = 1;
    }
    *addr = seg_addr + sreg;
    return exception;
}

int E1_mAddrD2(int sreg, int base, int index, int disp, int scale, int slim, int data_size, int* addr){
    int seg_addr = base+index*scale+disp;
    int exception = 0;
    if (seg_addr+data_size > slim){
        exception = 1;
    }
    *addr = seg_addr + sreg;
    return exception;
}

int E1_mAddrS(int ss, int esp, int disp, int* addr){
    *addr = ss + esp + disp;
    return 0;
}


void E1_exception(int mem_en, int ex){
    if (mem_en && ex){
        printf("EXCEPTION!\n");
        exit(-1);
    }
}

void E1(void){
    int mAddrD1=0, mAddrD2=0, mAddrS = 0;
    // ADDR1
    int scale1, msize1, msize2, sdisp;
    int ld_maddr_mux = (from_de_to_e1.E1_CS[E1_LD_MADDR1]<<1) + from_de_to_e1.E1_CS[E1_LD_MADDR0];
    int st_maddr_mux = (from_de_to_e1.E1_CS[E1_ST_MADDR1]<<1) + from_de_to_e1.E1_CS[E1_ST_MADDR0];
    int ld_maddr, ld_ex, st_maddr, st_ex;
    scale1 = mux4(from_de_to_e1.SCALE1_MUX, 1, 2, 4, 8);
    msize1 = mux4(from_de_to_e1.MSIZE1_MUX, 1, 2, 4, 8);
    msize2 = mux4(from_de_to_e1.MSIZE2_MUX, 1, 2, 4, 8);
    sdisp = mux4(from_de_to_e1.MSIZE2_MUX, 0, -2, -4, -8);
    if (from_de_to_e1.E1_CS[E1_LD_MADDR1]) sdisp = 0;

    int exp_mAddrD1 = E1_mAddrD1(from_de_to_e1.SREG1_V, from_de_to_e1.BASE1_V, from_de_to_e1.INDEX1_V, from_de_to_e1.DISP1_V, scale1, from_de_to_e1.SLIM1_V, msize1 &mAddrD1, &mAddrD1);
    int exp_mAddrD2 = E1_mAddrD2(from_de_to_e1.SREG2_V, from_de_to_e1.BASE2_V, 0, 0, 1, from_de_to_e1.SLIM1_V, msize2 &mAddrD1, &mAddrD2);
    int exp_mAddrS = E1_mAddrS(from_de_to_e1.SREG2_V, sdisp, from_de_to_e1.BASE2_V, &mAddrS);
    ld_maddr = mux4(ld_maddr_mux, mAddrD1, mAddrD2, mAddrS, 0);
    ld_ex = mux4(ld_maddr_mux, exp_mAddrD1, exp_mAddrD2, exp_mAddrS, 0);
    st_maddr = mux4(st_maddr_mux, mAddrD1, mAddrD2, mAddrS, 0);
    st_ex = mux4(st_maddr_mux, exp_mAddrD1, exp_mAddrD2, exp_mAddrS, 0);
    E1_exception(from_de_to_e1.E1_CS[E1_R], ld_ex);
    E1_exception(from_de_to_e1.E1_CS[E1_W], st_ex);

    new_from_e1_to_m1.OEIP_V = from_de_to_e1.OEIP_V;
    new_from_e1_to_m1.IEIP_V = from_de_to_e1.IEIP_V;
    new_from_e1_to_m1.OEFLAGS_V = from_de_to_e1.OEFLAGS_V;
    new_from_e1_to_m1.SRCREGA_V = from_de_to_e1.SRCREGA_V;
    new_from_e1_to_m1.SRCREGB_V = from_de_to_e1.SRCREGB_V;
    new_from_e1_to_m1.SRCREGC_V = from_de_to_e1.SRCREGC_V;
    new_from_e1_to_m1.MMA_V = from_de_to_e1.MMA_V;
    new_from_e1_to_m1.MMB_V = from_de_to_e1.MMB_V;
    new_from_e1_to_m1.IMM_V = from_de_to_e1.IMM_V;
    new_from_e1_to_m1.PTRA_V = from_de_to_e1.PTRA_V;
    new_from_e1_to_m1.PTRB_V = from_de_to_e1.PTRB_V;
    new_from_e1_to_m1.DSTREGA_IDX = from_de_to_e1.DSTREGA_IDX;
    new_from_e1_to_m1.DSTREGB_IDX = from_de_to_e1.DSTREGB_IDX;
    new_from_e1_to_m1.LOAD_ADDR = ld_maddr;
    new_from_e1_to_m1.STORE_ADDR = st_maddr;
    new_from_e1_to_m1.LOAD_SIZE = mux2((ld_maddr_mux==0), msize2, msize1); // TODO: LOAD SIZE LOGIC
    new_from_e1_to_m1.STORE_SIZE = mux2((st_maddr_mux==0), msize2, msize1);
    new_from_e1_to_m1.M1_CS[M1_ALU_IN1_SRC] = from_de_to_e1.E1_CS[E1_ALU_IN1_SRC];
    new_from_e1_to_m1.M1_CS[M1_ALU_OP1] = from_de_to_e1.E1_CS[E1_ALU_OP1];
    new_from_e1_to_m1.M1_CS[M1_ALU_OP0] = from_de_to_e1.E1_CS[E1_ALU_OP0];
    new_from_e1_to_m1.M1_CS[M1_DATASIZE1] = from_de_to_e1.E1_CS[E1_DATASIZE1];
    new_from_e1_to_m1.M1_CS[M1_DATASIZE0] = from_de_to_e1.E1_CS[E1_DATASIZE0];
    new_from_e1_to_m1.M1_CS[M1_PUSH_STACK] = from_de_to_e1.E1_CS[E1_ST_MADDR1];
    int i = M1_R;
    int j = E1_R;
    while (i < NUM_M1_CS_BITS){
        new_from_e1_to_m1.M1_CS[i] = from_de_to_e1.E1_CS[j];
        i++;
        j++;
    }
}

void M1(void){
    uint64_t LR;
    mem_step(&memory, from_e1_to_m1.LOAD_ADDR, from_e1_to_m1.LOAD_SIZE, &LR, from_e1_to_m1.M1_CS[M1_R],
            from_wb_to_mem.w_addr, from_wb_to_mem.w_size, from_wb_to_mem.w_data, from_wb_to_mem.w_en);
    new_from_m1_to_e2.OEIP_V = from_e1_to_m1.OEIP_V;
    new_from_m1_to_e2.IEIP_V = from_e1_to_m1.IEIP_V;
    new_from_m1_to_e2.OEFLAGS_V = from_e1_to_m1.OEFLAGS_V;
    new_from_m1_to_e2.SRCREGA_V = from_e1_to_m1.SRCREGA_V;
    new_from_m1_to_e2.SRCREGB_V = from_e1_to_m1.SRCREGB_V;
    new_from_m1_to_e2.SRCREGC_V = from_e1_to_m1.SRCREGC_V;
    new_from_m1_to_e2.MMA_V = from_e1_to_m1.MMA_V;
    new_from_m1_to_e2.MMB_V = from_e1_to_m1.MMB_V;
    new_from_m1_to_e2.IMM_V = from_e1_to_m1.IMM_V;
    new_from_m1_to_e2.PTRA_V = from_e1_to_m1.PTRA_V;
    new_from_m1_to_e2.PTRB_V = from_e1_to_m1.PTRB_V;
    new_from_m1_to_e2.DSTREGA_IDX = from_e1_to_m1.DSTREGA_IDX;
    new_from_m1_to_e2.DSTREGB_IDX = from_e1_to_m1.DSTREGB_IDX;
    new_from_m1_to_e2.LOAD_ADDR = from_e1_to_m1.LOAD_ADDR;
    new_from_m1_to_e2.LOAD_RESULT = LR;
    new_from_m1_to_e2.STORE_ADDR = from_e1_to_m1.STORE_ADDR;
    new_from_m1_to_e2.STORE_SIZE = from_e1_to_m1.STORE_SIZE;
    
    int i = M1_ALU_IN1_SRC;
    int j = E2_ALU_IN1_SRC;
    while (i < NUM_M1_CS_BITS){
        new_from_m1_to_e2.E2_CS[i] = from_e1_to_m1.M1_CS[j];
        i++;
        j++;
    }
}

static inline uint32_t width_mask(uint8_t data_size)
{
    switch (data_size & 0x3) {
        case 0: return 0x000000FFu; // 8
        case 1: return 0x0000FFFFu; // 16
        case 2: return 0xFFFFFFFFu; // 32
        default: return 0xFFFFFFFFu;
    }
}

static inline int msb_index(uint8_t data_size)
{
    switch (data_size & 0x3) {
        case 0: return 7;
        case 1: return 15;
        case 2: return 31;
        default: return 31;
    }
}

// PF: even parity of low 8 bits
static inline uint8_t parity_even8(uint32_t v)
{
    uint8_t x = (uint8_t)(v & 0xFFu);
    // fold bits to compute parity
    x ^= x >> 4;
    x ^= x >> 2;
    x ^= x >> 1;
    // now LSB is odd parity bit (1 if odd #ones); we want even parity flag
    return (uint8_t)((x & 1u) == 0u);
}

int sign_extend(int imm, int num_bits)
{
  unsigned int mask = 0xFFFFFFFF;
  int immediate;
  /* get instruction[num_bits-1] */
  if (imm & (0x1 << (num_bits-1)))
  {
    immediate = (0xFFFFFFFF << num_bits) | (imm & (mask >> (32-num_bits)));
  }
  else
  {
    immediate = imm & (mask >> (32-num_bits));
  }
  return immediate;
}

void E2_alu(uint32_t in0, uint32_t in1, uint8_t alu_op, uint32_t OEFLAGS, uint8_t data_size, uint32_t* result, uint32_t* NEW_EFLAGS)
{
    uint8_t CF, PF, AF, ZF, SF, OF;

    const uint32_t m = width_mask(data_size);
    const int msb = msb_index(data_size);

    uint32_t a = in0 & m;
    uint32_t b = in1 & m;

    uint32_t res = 0;
    // printf("alu op: %d, in0: %08x, in1: %08x\n", alu_op, in0, in1);
    switch (alu_op & 0x3) {
        case 0x0: { // ADD
            // Use wider sum to get carry out
            uint64_t sum = (uint64_t)a + (uint64_t)b;
            res = (uint32_t)(sum & (uint64_t)m);

            // CF: carry out of MSB (unsigned overflow)
            CF = (uint8_t)(((sum >> (msb + 1)) & 1u) != 0u);

            // AF: carry out of bit 3 (nibble carry)
            // only meaningful for add/sub; for add:
            AF = (uint8_t)((((a & 0xFu) + (b & 0xFu)) & 0x10u) != 0u);

            // OF: signed overflow: (~(a^b) & (a^res)) has MSB set
            uint32_t of = (~(a ^ b) & (a ^ res)) >> msb;
            OF = (uint8_t)(of & 1u);

            break;
        }
        case 0x1: { // OR
            res = (a | b) & m;
            // x86: CF=0, OF=0; AF undefined -> choose 0
            CF = 0;
            OF = 0;
            AF = 0;
            break;
        }
        case 0x2: { // AND
            res = (a & b) & m;
            // x86: CF=0, OF=0; AF undefined -> choose 0
            CF = 0;
            OF = 0;
            AF = 0;
            break;
        }
        default: { // treat as AND (or you can assert)
            res = (a & b) & m;
            CF = 0;
            OF = 0;
            AF = 0;
            break;
        }
    }

    // ZF: result is zero (within operand width)
    ZF = (uint8_t)(res == 0u);

    // SF: MSB of result (within operand width)
    SF = (uint8_t)(((res >> msb) & 1u) != 0u);

    // PF: even parity of low 8 bits of result
    PF = parity_even8(res);

    // output zero-extended to 32
    *result = res;
    *NEW_EFLAGS = (CF + (PF<<2) + (AF<<4) + (ZF<<6) + (SF<<7) + (OF<<11) + (OEFLAGS & 0xFFFFF72A));
}

void E2(void){
    uint32_t alu_in1, alu_in2, alu_result, OEFLAGS, NEW_EFLAGS;
    uint8_t alu_datasize, alu_op;
    int imm = mux2(from_m1_to_e2.E2_CS[E2_IMM_SE8], from_m1_to_e2.IMM_V, sign_extend(from_m1_to_e2.IMM_V, 8));
    alu_in1 = (uint32_t)(mux2(from_m1_to_e2.E2_CS[E2_ALU_IN1_SRC], from_m1_to_e2.SRCREGA_V, (int)(from_m1_to_e2.LOAD_RESULT)));
    alu_in2 = (uint32_t)(mux2(from_m1_to_e2.E2_CS[E2_ALU_IN2_SRC], imm, from_m1_to_e2.SRCREGB_V));
    alu_datasize = (uint8_t)(from_m1_to_e2.E2_CS[E2_DATASIZE0] + (from_m1_to_e2.E2_CS[E2_DATASIZE1]<<1));
    OEFLAGS = (uint32_t)(from_m1_to_e2.OEFLAGS_V);
    alu_op = (uint8_t)(from_m1_to_e2.E2_CS[E2_ALU_OP0] + (from_m1_to_e2.E2_CS[E2_ALU_OP1]<<1));
    E2_alu(alu_in1, alu_in2, alu_op, OEFLAGS, alu_datasize, &alu_result, &NEW_EFLAGS);

    new_from_e2_to_wb.OEIP_V = from_m1_to_e2.OEIP_V;
    new_from_e2_to_wb.IEIP_V = from_m1_to_e2.IEIP_V;
    new_from_e2_to_wb.OEFLAGS_V = from_m1_to_e2.OEFLAGS_V;
    new_from_e2_to_wb.SRCREGA_V = from_m1_to_e2.SRCREGA_V;
    new_from_m1_to_e2.SRCREGB_V = from_m1_to_e2.SRCREGB_V;
    new_from_e2_to_wb.SRCREGC_V = from_m1_to_e2.SRCREGC_V;
    new_from_e2_to_wb.MMA_V = from_m1_to_e2.MMA_V;
    new_from_e2_to_wb.MMB_V = from_m1_to_e2.MMB_V;
    new_from_e2_to_wb.IMM_V = from_m1_to_e2.IMM_V;
    new_from_e2_to_wb.PTRA_V = from_m1_to_e2.PTRA_V;
    new_from_e2_to_wb.PTRB_V = from_m1_to_e2.PTRB_V;
    new_from_e2_to_wb.DSTREGA_IDX = from_m1_to_e2.DSTREGA_IDX;
    new_from_e2_to_wb.DSTREGB_IDX = from_m1_to_e2.DSTREGB_IDX;
    new_from_e2_to_wb.LOAD_ADDR = from_m1_to_e2.LOAD_ADDR;
    new_from_e2_to_wb.LOAD_RESULT = from_m1_to_e2.LOAD_RESULT;
    new_from_e2_to_wb.EX_RESULT = (uint64_t)(alu_result);
    new_from_e2_to_wb.NEW_EFLAGS = (int)(NEW_EFLAGS);
    new_from_e2_to_wb.STORE_ADDR = from_m1_to_e2.STORE_ADDR;
    new_from_e2_to_wb.STORE_SIZE = from_m1_to_e2.STORE_SIZE;
    
    int i = WB_DATASIZE1;
    int j = E2_DATASIZE1;
    while (j < E2_ALU_IN2_SRC){
        new_from_e2_to_wb.WB_CS[i] = from_m1_to_e2.E2_CS[j];
        i++;
        j++;
    }

    i = WB_LD_REGA;
    j = E2_LD_REGA;
    while (i < NUM_WB_CS_BITS){
        new_from_e2_to_wb.WB_CS[i] = from_m1_to_e2.E2_CS[j];
        i++;
        j++;
    }

}

void WB(void){
    int datasize = from_e2_to_wb.WB_CS[WB_DATASIZE0] + (from_e2_to_wb.WB_CS[WB_DATASIZE1] << 1);
    from_wb_to_de.gp_wr0_idx = from_e2_to_wb.DSTREGA_IDX;
    from_wb_to_de.gp_wr0_data = (int)(from_e2_to_wb.EX_RESULT);
    from_wb_to_de.gp_wr0_size = datasize;
    from_wb_to_de.gp_wr0_en = from_e2_to_wb.WB_CS[WB_LD_REGA];
    
    from_wb_to_de.gp_wr1_idx = from_e2_to_wb.DSTREGB_IDX;
    from_wb_to_de.gp_wr1_data = (int)(from_e2_to_wb.EX_RESULT);
    from_wb_to_de.gp_wr1_size = datasize;
    from_wb_to_de.gp_wr1_en = from_e2_to_wb.WB_CS[WB_LD_REGB];

    from_wb_to_de.seg_wr_idx = from_e2_to_wb.DSTREGA_IDX;
    from_wb_to_de.seg_wr_data = (seg_word_t)(from_e2_to_wb.EX_RESULT);
    from_wb_to_de.seg_wr_en = from_e2_to_wb.WB_CS[WB_LD_SREG];

    from_wb_to_de.mmx_wr_idx = from_e2_to_wb.DSTREGA_IDX;
    from_wb_to_de.mmx_wr_data = from_e2_to_wb.EX_RESULT;
    from_wb_to_de.mmx_wr_en = from_e2_to_wb.WB_CS[WB_LD_MMREG];

    from_wb_to_de.eflags = from_e2_to_wb.NEW_EFLAGS;
    from_wb_to_de.ld_eflags = from_e2_to_wb.WB_CS[WB_LD_EFLAGS];

    from_wb_to_mem.w_addr = (uint32_t)(from_e2_to_wb.STORE_ADDR);
    from_wb_to_mem.w_size = from_e2_to_wb.STORE_SIZE;
    from_wb_to_mem.w_data = from_e2_to_wb.EX_RESULT;
    from_wb_to_mem.w_en = from_e2_to_wb.WB_CS[WB_W];

}

void init_regfile(void){
    gp_regfile_init(&gp_rf, gp_regs);
    gp_regfile_reset(&gp_rf);
    mmx_regfile_reset(&mmx_rf);
    seg_regfile_reset(&seg_rf);
}

void init_pipeline(void){
    init_regfile();
    mem_reset(&memory);
    memset(&from_pd_to_de, 0, sizeof(from_pd_to_de));
    memset(&from_de_to_e1, 0, sizeof(from_de_to_e1));
    memset(&from_e1_to_m1, 0, sizeof(from_e1_to_m1));
    memset(&from_m1_to_e2, 0, sizeof(from_m1_to_e2));
    memset(&from_e2_to_wb, 0, sizeof(from_e2_to_wb));
    memset(&from_wb_to_de, 0, sizeof(from_wb_to_de));
    memset(&from_wb_to_mem, 0, sizeof(from_wb_to_mem));
    for (int i = 0; i < CS_CONTROL_STORE_BITS; i++){
        tempCS[i] = 0;
    }
    tempCS[CS_LD_REGA] = 0;
    tempCS[CS_LD_EFLAGS] = 1;
    tempCS[CS_DATASIZE] = 1;
    tempCS[CS_A_SRC1] = 0;
    tempCS[CS_A_SRC0] = 0;
    tempCS[CS_BASE1_SRC] = 0;
    tempCS[CS_ALU_IN1_SRC] = 1;
    tempCS[CS_LD_MADDR1] = 0;
    tempCS[CS_LD_MADDR0] = 0;
    tempCS[CS_ST_MADDR1] = 0;
    tempCS[CS_ST_MADDR0] = 0;
    tempCS[CS_R] = 1;
    tempCS[CS_W] = 1;
    tempCS[CS_IMM_SE8] = 0;

    gp_set_reg(&gp_rf, 1, 0x04);
    set_mem(&memory, 0x04, 4, 0x5678);
    RUN_BIT = TRUE;
}

int main(void){
    FILE * dumpsim_file;

    init_pipeline();
    from_pd_to_de.prefix_mux = 0;
    from_pd_to_de.opcode = 0x81;
    from_pd_to_de.escape = 0;
    from_pd_to_de.modrm = 0x01;
    from_pd_to_de.sib = 0;
    from_pd_to_de.displacement = 0;
    from_pd_to_de.disp_size = 0;
    from_pd_to_de.immediate = 0x12340001;
    from_pd_to_de.imm_size = 0;
    from_pd_to_de.oeip = 0;
    from_pd_to_de.ieip = 0;
    from_pd_to_de.reg0_src = 0x01;

    if ( (dumpsim_file = fopen( "dumpsim", "w" )) == NULL ) {
        printf("Error: Can't open dumpsim file\n");
        exit(-1);
    }

    while (1){
        get_command(dumpsim_file);
    }


    return 0;
}
