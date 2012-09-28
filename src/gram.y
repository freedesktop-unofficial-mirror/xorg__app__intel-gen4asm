%{
/*
 * Copyright © 2006 Intel Corporation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Authors:
 *    Eric Anholt <eric@anholt.net>
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include "gen4asm.h"
#include "brw_defines.h"

#define DEFAULT_EXECSIZE (ffs(program_defaults.execute_size) - 1)
#define DEFAULT_DSTREGION -1

extern long int gen_level;
extern int advanced_flag;
extern int yylineno;
extern int need_export;
static struct src_operand src_null_reg =
{
    .reg_file = BRW_ARCHITECTURE_REGISTER_FILE,
    .reg_nr = BRW_ARF_NULL,
    .reg_type = BRW_REGISTER_TYPE_UD,
};
static struct dst_operand dst_null_reg =
{
    .reg_file = BRW_ARCHITECTURE_REGISTER_FILE,
    .reg_nr = BRW_ARF_NULL,
};
static struct dst_operand ip_dst =
{
    .reg_file = BRW_ARCHITECTURE_REGISTER_FILE,
    .reg_nr = BRW_ARF_IP,
    .reg_type = BRW_REGISTER_TYPE_UD,
    .address_mode = BRW_ADDRESS_DIRECT,
    .horiz_stride = 1,
    .writemask = 0xF,
};
static struct src_operand ip_src =
{
    .reg_file = BRW_ARCHITECTURE_REGISTER_FILE,
    .reg_nr = BRW_ARF_IP,
    .reg_type = BRW_REGISTER_TYPE_UD,
    .address_mode = BRW_ADDRESS_DIRECT,
    .swizzle_x = BRW_CHANNEL_X,
    .swizzle_y = BRW_CHANNEL_Y,
    .swizzle_z = BRW_CHANNEL_Z,
    .swizzle_w = BRW_CHANNEL_W,
};

static int get_type_size(GLuint type);
int set_instruction_dest(struct brw_instruction *instr,
			 struct dst_operand *dest);
int set_instruction_src0(struct brw_instruction *instr,
			 struct src_operand *src);
int set_instruction_src1(struct brw_instruction *instr,
			 struct src_operand *src);
int set_instruction_dest_three_src(struct brw_instruction *instr,
                                   struct dst_operand *dest);
int set_instruction_src0_three_src(struct brw_instruction *instr,
                                   struct src_operand *src);
int set_instruction_src1_three_src(struct brw_instruction *instr,
                                   struct src_operand *src);
int set_instruction_src2_three_src(struct brw_instruction *instr,
                                   struct src_operand *src);
void set_instruction_options(struct brw_instruction *instr,
			     struct brw_instruction *options);
void set_instruction_predicate(struct brw_instruction *instr,
			       struct brw_instruction *predicate);
void set_direct_dst_operand(struct dst_operand *dst, struct direct_reg *reg,
			    int type);
void set_direct_src_operand(struct src_operand *src, struct direct_reg *reg,
			    int type);

%}

%start ROOT

%union {
	char *string;
	int integer;
	double number;
	struct brw_instruction instruction;
	struct brw_program program;
	struct region region;
	struct regtype regtype;
	struct direct_reg direct_reg;
	struct indirect_reg indirect_reg;
	struct condition condition;
	struct declared_register symbol_reg;
	imm32_t imm32;

	struct dst_operand dst_operand;
	struct src_operand src_operand;
}

%token COLON
%token SEMICOLON
%token LPAREN RPAREN
%token LANGLE RANGLE
%token LCURLY RCURLY
%token LSQUARE RSQUARE
%token COMMA EQ
%token ABS DOT 
%token PLUS MINUS MULTIPLY DIVIDE

%token <integer> TYPE_UD TYPE_D TYPE_UW TYPE_W TYPE_UB TYPE_B
%token <integer> TYPE_VF TYPE_HF TYPE_V TYPE_F

%token ALIGN1 ALIGN16 SECHALF COMPR SWITCH ATOMIC NODDCHK NODDCLR
%token MASK_DISABLE BREAKPOINT ACCWRCTRL EOT

%token SEQ ANY2H ALL2H ANY4H ALL4H ANY8H ALL8H ANY16H ALL16H ANYV ALLV
%token <integer> ZERO EQUAL NOT_ZERO NOT_EQUAL GREATER GREATER_EQUAL LESS LESS_EQUAL
%token <integer> ROUND_INCREMENT OVERFLOW UNORDERED
%token <integer> GENREG MSGREG ADDRESSREG ACCREG FLAGREG
%token <integer> MASKREG AMASK IMASK LMASK CMASK
%token <integer> MASKSTACKREG LMS IMS MASKSTACKDEPTHREG IMSD LMSD
%token <integer> NOTIFYREG STATEREG CONTROLREG IPREG
%token GENREGFILE MSGREGFILE

%token <integer> MOV FRC RNDU RNDD RNDE RNDZ NOT LZD
%token <integer> MUL MAC MACH LINE SAD2 SADA2 DP4 DPH DP3 DP2
%token <integer> AVG ADD SEL AND OR XOR SHR SHL ASR CMP CMPN PLN
%token <integer> ADDC BFI1 BFREV CBIT F16TO32 F32TO16 FBH FBL
%token <integer> SEND NOP JMPI IF IFF WHILE ELSE BREAK CONT HALT MSAVE
%token <integer> PUSH MREST POP WAIT DO ENDIF ILLEGAL
%token <integer> MATH_INST
%token <integer> MAD LRP BFE BFI2 SUBB
%token <integer> CALL RET
%token <integer> BRD BRC

%token NULL_TOKEN MATH SAMPLER GATEWAY READ WRITE URB THREAD_SPAWNER VME DATA_PORT

%token MSGLEN RETURNLEN
%token <integer> ALLOCATE USED COMPLETE TRANSPOSE INTERLEAVE
%token SATURATE

%token <integer> INTEGER
%token <string> STRING
%token <number> NUMBER

%token <integer> INV LOG EXP SQRT RSQ POW SIN COS SINCOS INTDIV INTMOD
%token <integer> INTDIVMOD
%token SIGNED SCALAR

%token <integer> X Y Z W

%token <integer> KERNEL_PRAGMA END_KERNEL_PRAGMA CODE_PRAGMA END_CODE_PRAGMA
%token <integer> REG_COUNT_PAYLOAD_PRAGMA REG_COUNT_TOTAL_PRAGMA DECLARE_PRAGMA
%token <integer> BASE ELEMENTSIZE SRCREGION DSTREGION TYPE

%token <integer> DEFAULT_EXEC_SIZE_PRAGMA DEFAULT_REG_TYPE_PRAGMA
%nonassoc SUBREGNUM
%nonassoc SNDOPR
%left  PLUS MINUS
%left  MULTIPLY DIVIDE
%right UMINUS
%nonassoc DOT
%nonassoc STR_SYMBOL_REG
%nonassoc EMPTEXECSIZE
%nonassoc LPAREN

%type <integer> exp sndopr
%type <integer> simple_int
%type <instruction> instruction unaryinstruction binaryinstruction
%type <instruction> binaryaccinstruction trinaryinstruction sendinstruction
%type <instruction> jumpinstruction
%type <instruction> breakinstruction syncinstruction
%type <instruction> msgtarget
%type <instruction> instoptions instoption_list predicate
%type <instruction> mathinstruction
%type <instruction> subroutineinstruction
%type <instruction> multibranchinstruction
%type <instruction> nopinstruction loopinstruction ifelseinstruction haltinstruction
%type <string> label
%type <program> instrseq
%type <integer> instoption
%type <integer> unaryop binaryop binaryaccop breakop
%type <integer> trinaryop
%type <condition> conditionalmodifier 
%type <integer> condition saturate negate abs chansel
%type <integer> writemask_x writemask_y writemask_z writemask_w
%type <integer> srcimmtype execsize dstregion immaddroffset
%type <integer> subregnum sampler_datatype
%type <integer> urb_swizzle urb_allocate urb_used urb_complete
%type <integer> math_function math_signed math_scalar
%type <integer> predctrl predstate
%type <region> region region_wh indirectregion declare_srcregion;
%type <regtype> regtype
%type <direct_reg> directgenreg directmsgreg addrreg accreg flagreg maskreg
%type <direct_reg> maskstackreg notifyreg 
/* %type <direct_reg>  maskstackdepthreg */
%type <direct_reg> statereg controlreg ipreg nullreg
%type <direct_reg> dstoperandex_typed srcarchoperandex_typed
%type <direct_reg> sendleadreg
%type <indirect_reg> indirectgenreg indirectmsgreg addrparam
%type <integer> mask_subreg maskstack_subreg 
%type <integer> declare_elementsize declare_dstregion declare_type
/* %type <intger> maskstackdepth_subreg */
%type <symbol_reg> symbol_reg symbol_reg_p;
%type <imm32> imm32
%type <dst_operand> dst dstoperand dstoperandex dstreg post_dst writemask
%type <dst_operand> declare_base
%type <src_operand> directsrcoperand srcarchoperandex directsrcaccoperand
%type <src_operand> indirectsrcoperand
%type <src_operand> src srcimm imm32reg payload srcacc srcaccimm swizzle
%type <src_operand> relativelocation relativelocation2
%%
simple_int:     INTEGER { $$ = $1; }
		| MINUS INTEGER { $$ = -$2;}
;

exp:		INTEGER { $$ = $1; }
		| exp PLUS exp { $$ = $1 + $3; }
		| exp MINUS exp { $$ = $1 - $3; }
		| exp MULTIPLY exp { $$ = $1 * $3; } 
		| exp DIVIDE exp { if ($3) $$ = $1 / $3; else YYERROR;}
		| MINUS exp %prec UMINUS { $$ = -$2;}
		| LPAREN exp RPAREN { $$ = $2; }
		;

ROOT:		instrseq
		{
		  compiled_program = $1;
		}
;


label:          STRING COLON
;

declare_base:  	BASE EQ dstreg 
	       	{
		   $$ = $3;
	       	}
;
declare_elementsize:  ELEMENTSIZE EQ exp
		{
		   $$ = $3;
		}
;
declare_srcregion: /* empty */
		{
		  /* XXX is this default correct?*/
		  memset (&$$, '\0', sizeof ($$));
		  $$.vert_stride = ffs(0);
		  $$.width = ffs(1) - 1;
		  $$.horiz_stride = ffs(0);
		}
		| SRCREGION EQ region
		{
		    $$ = $3;
		}
;
declare_dstregion: /* empty */
		{
		    $$ = 1;
		}
		| DSTREGION EQ dstregion
		{
		    $$ = $3;
		}
;
declare_type:	TYPE EQ regtype
		{
		    $$ = $3.type;
		}
;
declare_pragma:	DECLARE_PRAGMA STRING declare_base declare_elementsize declare_srcregion declare_dstregion declare_type
		{
		    struct declared_register *reg;
		    int defined;
		    defined = (reg = find_register($2)) != NULL;
		    if (defined) {
			fprintf(stderr, "WARNING: %s already defined\n", $2);
			free($2); // $2 has been malloc'ed by strdup
		    } else {
			reg = calloc(sizeof(struct declared_register), 1);
			reg->name = $2;
		    }
		    reg->base.reg_file = $3.reg_file;
		    reg->base.reg_nr = $3.reg_nr;
		    reg->base.subreg_nr = $3.subreg_nr;
		    reg->element_size = $4;
		    reg->src_region = $5;
		    reg->dst_region = $6;
		    reg->type = $7;
		    if (!defined) {
			insert_register(reg);
		    }
		}
;

reg_count_total_pragma: 	REG_COUNT_TOTAL_PRAGMA exp
;
reg_count_payload_pragma: 	REG_COUNT_PAYLOAD_PRAGMA exp
;

default_exec_size_pragma:	DEFAULT_EXEC_SIZE_PRAGMA exp
				{
				    program_defaults.execute_size = $2;
				}
;
default_reg_type_pragma:	DEFAULT_REG_TYPE_PRAGMA regtype
				{
				    program_defaults.register_type = $2.type;
				}
;
pragma:		reg_count_total_pragma
		|reg_count_payload_pragma
		|default_exec_size_pragma
		|default_reg_type_pragma
		|declare_pragma
;		

instrseq:	instrseq pragma
		{
		    $$ = $1;
		}
		| instrseq instruction SEMICOLON
		{
		  struct brw_program_instruction *list_entry =
		    calloc(sizeof(struct brw_program_instruction), 1);
		  list_entry->instruction = $2;
		  list_entry->next = NULL;
		  if ($1.last) {
			$1.last->next = list_entry;
		  } else {
			$1.first = list_entry;
		  }
		  $1.last = list_entry;
		  $$ = $1;
		}
		| instruction SEMICOLON
		{
		  struct brw_program_instruction *list_entry =
		    calloc(sizeof(struct brw_program_instruction), 1);
		  list_entry->instruction = $1;

		  list_entry->next = NULL;

		  $$.first = list_entry;
		  $$.last = list_entry;
		}
        | instrseq SEMICOLON
		{
		    $$ = $1;
		}
        | instrseq label
        	{
          struct brw_program_instruction *list_entry =
            calloc(sizeof(struct brw_program_instruction), 1);
          list_entry->string = strdup($2);
          list_entry->islabel = 1;
		  list_entry->next = NULL;
		  if ($1.last) {
			$1.last->next = list_entry;
		  } else {
			$1.first = list_entry;
		  }
		  $1.last = list_entry;
		  $$ = $1;
                }
		| label
		{
		  struct brw_program_instruction *list_entry =
		    calloc(sizeof(struct brw_program_instruction), 1);
                  list_entry->string = strdup($1);
                  list_entry->islabel = 1;

		  list_entry->next = NULL;

		  $$.first = list_entry;
		  $$.last = list_entry;
		}
		| pragma
		{
		  $$.first = NULL;
		  $$.last = NULL;
		}
		| instrseq error SEMICOLON {
		  $$ = $1;
		}
;

/* 1.4.1: Instruction groups */
// binaryinstruction:    Source operands cannot be accumulators
// binaryaccinstruction: Source operands can be accumulators
instruction:	unaryinstruction
		| binaryinstruction
		| binaryaccinstruction
		| trinaryinstruction
		| sendinstruction
		| jumpinstruction
		| ifelseinstruction
		| breakinstruction
		| syncinstruction
		| mathinstruction
		| subroutineinstruction
		| multibranchinstruction
		| nopinstruction
		| haltinstruction
		| loopinstruction
;

ifelseinstruction: ENDIF
		{
		  // for Gen4
		  if(gen_level > 5) {
		    fprintf(stderr, "ENDIF Syntax error: should be 'ENDIF execsize relativelocation'\n");
		    YYERROR;
		  }
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $1;
		  $$.header.thread_control |= BRW_THREAD_SWITCH;
		  $$.bits1.da1.dest_horiz_stride = 1;
		  $$.bits1.da1.src1_reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.bits1.da1.src1_reg_type = BRW_REGISTER_TYPE_UD;
		}
		| ENDIF execsize relativelocation instoptions
		{
		  // for Gen6+
		  /* Gen6, Gen7 bspec: predication is prohibited */
		  if(gen_level <= 5) {
		    fprintf(stderr, "ENDIF Syntax error: should be 'ENDIF'\n");
		    YYERROR;
		  }
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $1;
		  $$.header.execution_size = $2;
		  $$.first_reloc_target = $3.reloc_target;
		  $$.first_reloc_offset = $3.imm32;
		}
		| ELSE execsize relativelocation instoptions
		{
		  if(gen_level <= 5) {
		    // for Gen4, Gen5
		    /* Set the istack pop count, which must always be 1. */
		    $3.imm32 |= (1 << 16);

		    memset(&$$, 0, sizeof($$));
		    $$.header.opcode = $1;
		    $$.header.execution_size = $2;
		    $$.header.thread_control |= BRW_THREAD_SWITCH;
		    set_instruction_dest(&$$, &ip_dst);
		    set_instruction_src0(&$$, &ip_src);
		    set_instruction_src1(&$$, &$3);
		    $$.first_reloc_target = $3.reloc_target;
		    $$.first_reloc_offset = $3.imm32;
		  } else if(gen_level <= 7) {
		    memset(&$$, 0, sizeof($$));
		    $$.header.opcode = $1;
		    $$.header.execution_size = $2;
		    $$.first_reloc_target = $3.reloc_target;
		    $$.first_reloc_offset = $3.imm32;
		  } else {
		    fprintf(stderr, "'ELSE' instruction is not implemented.\n");
		    YYERROR;
		  }
		}
		| predicate IF execsize relativelocation
		{
		  /* for Gen4, Gen5 */
		  /* The branch instructions require that the IP register
		   * be the destination and first source operand, while the
		   * offset is the second source operand.  The offset is added
		   * to the pre-incremented IP.
		   */
		  /* for Gen6 */
		  if(gen_level > 6) {
		    fprintf(stderr, "Syntax error: IF should be 'IF execsize JIP UIP'\n");
		    YYERROR;
		  }
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  if(gen_level <= 5) {
		    $$.header.thread_control |= BRW_THREAD_SWITCH;
		    set_instruction_dest(&$$, &ip_dst);
		    set_instruction_src0(&$$, &ip_src);
		    set_instruction_src1(&$$, &$4);
		  }
		  $$.first_reloc_target = $4.reloc_target;
		  $$.first_reloc_offset = $4.imm32;
		}
		| predicate IF execsize relativelocation relativelocation
		{
		  /* for Gen7+ */
		  if(gen_level < 7) {
		    fprintf(stderr, "Syntax error: IF should be 'IF execsize relativelocation'\n");
		    YYERROR;
		  }
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.first_reloc_target = $4.reloc_target;
		  $$.first_reloc_offset = $4.imm32;
		  $$.second_reloc_target = $5.reloc_target;
		  $$.second_reloc_offset = $5.imm32;
		}
;

loopinstruction: predicate WHILE execsize relativelocation instoptions
		{
		  if(gen_level <= 5) {
		    /* The branch instructions require that the IP register
		     * be the destination and first source operand, while the
		     * offset is the second source operand.  The offset is added
		     * to the pre-incremented IP.
		     */
		    set_instruction_dest(&$$, &ip_dst);
		    memset(&$$, 0, sizeof($$));
		    set_instruction_predicate(&$$, &$1);
		    $$.header.opcode = $2;
		    $$.header.execution_size = $3;
		    $$.header.thread_control |= BRW_THREAD_SWITCH;
		    set_instruction_src0(&$$, &ip_src);
		    set_instruction_src1(&$$, &$4);
		    $$.first_reloc_target = $4.reloc_target;
		    $$.first_reloc_offset = $4.imm32;
		  } else if (gen_level == 7) { // TODO: Gen6 also OK?
		    memset(&$$, 0, sizeof($$));
		    set_instruction_predicate(&$$, &$1);
		    $$.header.opcode = $2;
		    $$.header.execution_size = $3;
		    $$.first_reloc_target = $4.reloc_target;
		    $$.first_reloc_offset = $4.imm32;
		  } else {
		    fprintf(stderr, "'WHILE' instruction is not implemented!\n");
		    YYERROR;
		  }
		}
		| DO
		{
		  // deprecated
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $1;
		};

haltinstruction: predicate HALT execsize relativelocation relativelocation instoptions
		{
		  // for Gen6, Gen7
		  /* Gen6, Gen7 bspec: dst and src0 must be the null reg. */
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.first_reloc_target = $4.reloc_target;
		  $$.first_reloc_offset = $4.imm32;
		  $$.second_reloc_target = $5.reloc_target;
		  $$.second_reloc_offset = $5.imm32;
		  set_instruction_dest(&$$, &dst_null_reg);
		  set_instruction_src0(&$$, &src_null_reg);
		};

multibranchinstruction:
		predicate BRD execsize relativelocation instoptions
		{
		  /* Gen7 bspec: dest must be null. use Switch option */
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.header.thread_control |= BRW_THREAD_SWITCH;
		  $$.first_reloc_target = $4.reloc_target;
		  $$.first_reloc_offset = $4.imm32;
		  set_instruction_dest(&$$, &dst_null_reg);
		}
		| predicate BRC execsize relativelocation relativelocation instoptions
		{
		  /* Gen7 bspec: dest must be null. src0 must be null. use Switch option */
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.header.thread_control |= BRW_THREAD_SWITCH;
		  $$.first_reloc_target = $4.reloc_target;
		  $$.first_reloc_offset = $4.imm32;
		  $$.second_reloc_target = $5.reloc_target;
		  $$.second_reloc_offset = $5.imm32;
		  set_instruction_dest(&$$, &dst_null_reg);
		  set_instruction_src0(&$$, &src_null_reg);
		}
;

subroutineinstruction:
		predicate CALL execsize dst relativelocation instoptions
		{
		  /*
		    Gen6 bspec:
		       source, dest type should be DWORD.
		       dest must be QWord aligned.
		       source0 region control must be <2,2,1>.
		       execution size must be 2.
		       QtrCtrl is prohibited.
		       JIP is an immediate operand, must be of type W.
		    Gen7 bspec:
		       source, dest type should be DWORD.
		       dest must be QWord aligned.
		       source0 region control must be <2,2,1>.
		       execution size must be 2.
		   */
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = 1; /* execution size must be 2. Here 1 is encoded 2. */

		  $4.reg_type = BRW_REGISTER_TYPE_D; /* dest type should be DWORD */
		  set_instruction_dest(&$$, &$4);

		  struct src_operand src0;
		  memset(&src0, 0, sizeof(src0));
		  src0.reg_type = BRW_REGISTER_TYPE_D; /* source type should be DWORD */
		  /* source0 region control must be <2,2,1>. */
		  src0.horiz_stride = 1; /*encoded 1*/
		  src0.width = 1; /*encoded 2*/
		  src0.vert_stride = 2; /*encoded 2*/
		  set_instruction_src0(&$$, &src0);

		  $$.first_reloc_target = $5.reloc_target;
		  $$.first_reloc_offset = $5.imm32;
		}
		| predicate RET execsize dstoperandex src instoptions
		{
		  /*
		     Gen6, 7:
		       source cannot be accumulator.
		       dest must be null.
		       src0 region control must be <2,2,1> (not specified clearly. should be same as CALL)
		   */
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = 1; /* execution size of RET should be 2 */
		  set_instruction_dest(&$$, &dst_null_reg);
		  $5.reg_type = BRW_REGISTER_TYPE_D;
		  $5.horiz_stride = 1; /*encoded 1*/
		  $5.width = 1; /*encoded 2*/
		  $5.vert_stride = 2; /*encoded 2*/
		  set_instruction_src0(&$$, &$5);
		}
;

unaryinstruction:
		predicate unaryop conditionalmodifier saturate execsize
		dst srcaccimm instoptions
		{
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.sfid_destreg__conditionalmod = $3.cond;
		  $$.header.saturate = $4;
		  $$.header.execution_size = $5;
		  set_instruction_options(&$$, &$8);
		  set_instruction_predicate(&$$, &$1);
		  if (set_instruction_dest(&$$, &$6) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$7) != 0)
		    YYERROR;

		  if ($3.flag_subreg_nr != -1) {
		    if ($$.header.predicate_control != BRW_PREDICATE_NONE &&
                        ($1.bits2.da1.flag_reg_nr != $3.flag_reg_nr ||
                         $1.bits2.da1.flag_subreg_nr != $3.flag_subreg_nr))
                        fprintf(stderr, "WARNING: must use the same flag register if both prediction and conditional modifier are enabled\n");

		    $$.bits2.da1.flag_reg_nr = $3.flag_reg_nr;
		    $$.bits2.da1.flag_subreg_nr = $3.flag_subreg_nr;
		  }

		  if (gen_level < 6 && 
				get_type_size($$.bits1.da1.dest_reg_type) * (1 << $$.header.execution_size) == 64)
		    $$.header.compression_control = BRW_COMPRESSION_COMPRESSED;
		}
;

unaryop:	MOV | FRC | RNDU | RNDD | RNDE | RNDZ | NOT | LZD | BFREV | CBIT
          | F16TO32 | F32TO16 | FBH | FBL
;

// Source operands cannot be accumulators
binaryinstruction:
		predicate binaryop conditionalmodifier saturate execsize
		dst src srcimm instoptions
		{
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.sfid_destreg__conditionalmod = $3.cond;
		  $$.header.saturate = $4;
		  $$.header.execution_size = $5;
		  set_instruction_options(&$$, &$9);
		  set_instruction_predicate(&$$, &$1);
		  if (set_instruction_dest(&$$, &$6) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$7) != 0)
		    YYERROR;
		  if (set_instruction_src1(&$$, &$8) != 0)
		    YYERROR;

		  if ($3.flag_subreg_nr != -1) {
		    if ($$.header.predicate_control != BRW_PREDICATE_NONE &&
                        ($1.bits2.da1.flag_reg_nr != $3.flag_reg_nr ||
                         $1.bits2.da1.flag_subreg_nr != $3.flag_subreg_nr))
                        fprintf(stderr, "WARNING: must use the same flag register if both prediction and conditional modifier are enabled\n");

		    $$.bits2.da1.flag_reg_nr = $3.flag_reg_nr;
		    $$.bits2.da1.flag_subreg_nr = $3.flag_subreg_nr;
		  }

		  if (gen_level < 6 && 
				get_type_size($$.bits1.da1.dest_reg_type) * (1 << $$.header.execution_size) == 64)
		    $$.header.compression_control = BRW_COMPRESSION_COMPRESSED;
		}
;

/* bspec: BFI1 should not access accumulator. */
binaryop:	MUL | MAC | MACH | LINE | SAD2 | SADA2 | DP4 | DPH | DP3 | DP2 | PLN | BFI1
;

// Source operands can be accumulators
binaryaccinstruction:
		predicate binaryaccop conditionalmodifier saturate execsize
		dst srcacc srcimm instoptions
		{
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.sfid_destreg__conditionalmod = $3.cond;
		  $$.header.saturate = $4;
		  $$.header.execution_size = $5;
		  set_instruction_options(&$$, &$9);
		  set_instruction_predicate(&$$, &$1);
		  if (set_instruction_dest(&$$, &$6) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$7) != 0)
		    YYERROR;
		  if (set_instruction_src1(&$$, &$8) != 0)
		    YYERROR;

		  if ($3.flag_subreg_nr != -1) {
		    if ($$.header.predicate_control != BRW_PREDICATE_NONE &&
                        ($1.bits2.da1.flag_reg_nr != $3.flag_reg_nr ||
                         $1.bits2.da1.flag_subreg_nr != $3.flag_subreg_nr))
                        fprintf(stderr, "WARNING: must use the same flag register if both prediction and conditional modifier are enabled\n");

		    $$.bits2.da1.flag_reg_nr = $3.flag_reg_nr;
		    $$.bits2.da1.flag_subreg_nr = $3.flag_subreg_nr;
		  }

		  if (gen_level < 6 && 
				get_type_size($$.bits1.da1.dest_reg_type) * (1 << $$.header.execution_size) == 64)
		    $$.header.compression_control = BRW_COMPRESSION_COMPRESSED;
		}
;

/* TODO: bspec says ADDC/SUBB/CMP/CMPN/SHL/BFI1 cannot use accumulator as dest. */
binaryaccop:	AVG | ADD | SEL | AND | OR | XOR | SHR | SHL | ASR | CMP | CMPN | ADDC | SUBB
;

trinaryop:	MAD | LRP | BFE | BFI2
;

trinaryinstruction:
		predicate trinaryop conditionalmodifier saturate execsize
		dst src src src instoptions
{
		  memset(&$$, 0, sizeof($$));

		  $$.header.predicate_control = $1.header.predicate_control;
		  $$.header.predicate_inverse = $1.header.predicate_inverse;
		  $$.bits1.three_src_gen6.flag_reg_nr = $1.bits2.da1.flag_reg_nr;
		  $$.bits1.three_src_gen6.flag_subreg_nr = $1.bits2.da1.flag_subreg_nr;

		  $$.header.opcode = $2;
		  $$.header.sfid_destreg__conditionalmod = $3.cond;
		  $$.header.saturate = $4;
		  $$.header.execution_size = $5;

		  if (set_instruction_dest_three_src(&$$, &$6))
		    YYERROR;
		  if (set_instruction_src0_three_src(&$$, &$7))
		    YYERROR;
		  if (set_instruction_src1_three_src(&$$, &$8))
		    YYERROR;
		  if (set_instruction_src2_three_src(&$$, &$9))
		    YYERROR;
		  set_instruction_options(&$$, &$10);

		  if ($3.flag_subreg_nr != -1) {
		    if ($$.header.predicate_control != BRW_PREDICATE_NONE &&
                        ($1.bits2.da1.flag_reg_nr != $3.flag_reg_nr ||
                         $1.bits2.da1.flag_subreg_nr != $3.flag_subreg_nr))
                        fprintf(stderr, "WARNING: must use the same flag register if both prediction and conditional modifier are enabled\n");
		  }
}
;

sendinstruction: predicate SEND execsize exp post_dst payload msgtarget
		MSGLEN exp RETURNLEN exp instoptions
		{
		  /* Send instructions are messy.  The first argument is the
		   * post destination -- the grf register that the response
		   * starts from.  The second argument is the current
		   * destination, which is the start of the message arguments
		   * to the shared function, and where src0 payload is loaded
		   * to if not null.  The payload is typically based on the
		   * grf 0 thread payload of your current thread, and is
		   * implicitly loaded if non-null.
		   */
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.header.sfid_destreg__conditionalmod = $4; /* msg reg index */
		  set_instruction_predicate(&$$, &$1);
		  if (set_instruction_dest(&$$, &$5) != 0)
		    YYERROR;

		  if (gen_level >= 6) {
                      struct src_operand src0;

                      memset(&src0, 0, sizeof(src0));
                      src0.address_mode = BRW_ADDRESS_DIRECT;

                      if (gen_level >= 7)
                          src0.reg_file = BRW_GENERAL_REGISTER_FILE;
                      else
                          src0.reg_file = BRW_MESSAGE_REGISTER_FILE;

                      src0.reg_type = BRW_REGISTER_TYPE_D;
                      src0.reg_nr = $4;
                      src0.subreg_nr = 0;
                      set_instruction_src0(&$$, &src0);
		  } else {
                      if (set_instruction_src0(&$$, &$6) != 0)
                          YYERROR;
		  }

		  $$.bits1.da1.src1_reg_file = BRW_IMMEDIATE_VALUE;
		  $$.bits1.da1.src1_reg_type = BRW_REGISTER_TYPE_D;

		  if (gen_level >= 5) {
                      if (gen_level > 5) {
                          $$.header.sfid_destreg__conditionalmod = $7.bits2.send_gen5.sfid;
                      } else {
                          $$.header.sfid_destreg__conditionalmod = $4; /* msg reg index */
                          $$.bits2.send_gen5.sfid = $7.bits2.send_gen5.sfid;
                          $$.bits2.send_gen5.end_of_thread = $12.bits3.generic_gen5.end_of_thread;
                      }

                      $$.bits3.generic_gen5 = $7.bits3.generic_gen5;
                      $$.bits3.generic_gen5.msg_length = $9;
                      $$.bits3.generic_gen5.response_length = $11;
                      $$.bits3.generic_gen5.end_of_thread =
                          $12.bits3.generic_gen5.end_of_thread;
		  } else {
                      $$.header.sfid_destreg__conditionalmod = $4; /* msg reg index */
                      $$.bits3.generic = $7.bits3.generic;
                      $$.bits3.generic.msg_length = $9;
                      $$.bits3.generic.response_length = $11;
                      $$.bits3.generic.end_of_thread =
                          $12.bits3.generic.end_of_thread;
		  }
		}
		| predicate SEND execsize dst sendleadreg payload directsrcoperand instoptions
		{
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.header.sfid_destreg__conditionalmod = $5.reg_nr; /* msg reg index */

		  set_instruction_predicate(&$$, &$1);

		  if (set_instruction_dest(&$$, &$4) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$6) != 0)
		    YYERROR;
		  /* XXX is this correct? */
		  if (set_instruction_src1(&$$, &$7) != 0)
		    YYERROR;
		  }
		| predicate SEND execsize dst sendleadreg payload imm32reg instoptions
                {
		  if ($7.reg_type != BRW_REGISTER_TYPE_UD &&
		  	  $7.reg_type != BRW_REGISTER_TYPE_D &&
		  	  $7.reg_type != BRW_REGISTER_TYPE_V) {
		    fprintf (stderr, "%d: non-int D/UD/V representation: %d,type=%d\n", yylineno, $7.imm32, $7.reg_type);
			YYERROR;
		  }
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.header.sfid_destreg__conditionalmod = $5.reg_nr; /* msg reg index */

		  set_instruction_predicate(&$$, &$1);
		  if (set_instruction_dest(&$$, &$4) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$6) != 0)
		    YYERROR;
		  $$.bits1.da1.src1_reg_file = BRW_IMMEDIATE_VALUE;
		  $$.bits1.da1.src1_reg_type = $7.reg_type;
		  $$.bits3.ud = $7.imm32;
                }
		| predicate SEND execsize dst sendleadreg sndopr imm32reg instoptions
		{
		  struct src_operand src0;

		  if (gen_level < 6) {
                      fprintf(stderr, "error: the syntax of send instruction\n");
                      YYERROR;
		  }

		  if ($7.reg_type != BRW_REGISTER_TYPE_UD &&
                      $7.reg_type != BRW_REGISTER_TYPE_D &&
                      $7.reg_type != BRW_REGISTER_TYPE_V) {
                      fprintf (stderr, "%d: non-int D/UD/V representation: %d,type=%d\n", yylineno, $7.imm32, $7.reg_type);
                      YYERROR;
		  }

		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
                  $$.header.sfid_destreg__conditionalmod = ($6 & EX_DESC_SFID_MASK); /* SFID */
		  set_instruction_predicate(&$$, &$1);

		  if (set_instruction_dest(&$$, &$4) != 0)
                      YYERROR;

                  memset(&src0, 0, sizeof(src0));
                  src0.address_mode = BRW_ADDRESS_DIRECT;

                  if (gen_level >= 7) {
                      src0.reg_file = BRW_GENERAL_REGISTER_FILE;
                      src0.reg_type = BRW_REGISTER_TYPE_UB;
                  } else {
                      src0.reg_file = BRW_MESSAGE_REGISTER_FILE;
                      src0.reg_type = BRW_REGISTER_TYPE_D;
                  }

                  src0.reg_nr = $5.reg_nr;
                  src0.subreg_nr = 0;
                  set_instruction_src0(&$$, &src0);

		  $$.bits1.da1.src1_reg_file = BRW_IMMEDIATE_VALUE;
		  $$.bits1.da1.src1_reg_type = $7.reg_type;
                  $$.bits3.ud = $7.imm32;
                  $$.bits3.generic_gen5.end_of_thread = !!($6 & EX_DESC_EOT_MASK);
		}
		| predicate SEND execsize dst sendleadreg sndopr directsrcoperand instoptions
		{
		  struct src_operand src0;

		  if (gen_level < 6) {
                      fprintf(stderr, "error: the syntax of send instruction\n");
                      YYERROR;
		  }

                  if ($7.reg_file != BRW_ARCHITECTURE_REGISTER_FILE ||
                      ($7.reg_nr & 0xF0) != BRW_ARF_ADDRESS ||
                      ($7.reg_nr & 0x0F) != 0 ||
                      $7.subreg_nr != 0) {
                      fprintf (stderr, "%d: scalar register must be a0.0<0;1,0>:ud\n", yylineno);
                      YYERROR;
		  }

		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
                  $$.header.sfid_destreg__conditionalmod = ($6 & EX_DESC_SFID_MASK); /* SFID */
		  set_instruction_predicate(&$$, &$1);

		  if (set_instruction_dest(&$$, &$4) != 0)
                      YYERROR;

                  memset(&src0, 0, sizeof(src0));
                  src0.address_mode = BRW_ADDRESS_DIRECT;

                  if (gen_level >= 7) {
                      src0.reg_file = BRW_GENERAL_REGISTER_FILE;
                      src0.reg_type = BRW_REGISTER_TYPE_UB;
                  } else {
                      src0.reg_file = BRW_MESSAGE_REGISTER_FILE;
                      src0.reg_type = BRW_REGISTER_TYPE_D;
                  }

                  src0.reg_nr = $5.reg_nr;
                  src0.subreg_nr = 0;
                  set_instruction_src0(&$$, &src0);

                  set_instruction_src1(&$$, &$7);
                  $$.bits3.generic_gen5.end_of_thread = !!($6 & EX_DESC_EOT_MASK);
		}
		| predicate SEND execsize dst sendleadreg payload sndopr imm32reg instoptions
		{
		  if ($8.reg_type != BRW_REGISTER_TYPE_UD &&
		  	  $8.reg_type != BRW_REGISTER_TYPE_D &&
		  	  $8.reg_type != BRW_REGISTER_TYPE_V) {
		    fprintf (stderr, "%d: non-int D/UD/V representation: %d,type=%d\n", yylineno, $8.imm32, $8.reg_type);
			YYERROR;
		  }
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.header.sfid_destreg__conditionalmod = $5.reg_nr; /* msg reg index */

		  set_instruction_predicate(&$$, &$1);
		  if (set_instruction_dest(&$$, &$4) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$6) != 0)
		    YYERROR;
		  $$.bits1.da1.src1_reg_file = BRW_IMMEDIATE_VALUE;
		  $$.bits1.da1.src1_reg_type = $8.reg_type;
		  if (gen_level == 5) {
		      $$.bits2.send_gen5.sfid = ($7 & EX_DESC_SFID_MASK);
		      $$.bits3.ud = $8.imm32;
		      $$.bits3.generic_gen5.end_of_thread = !!($7 & EX_DESC_EOT_MASK);
		  }
		  else
		      $$.bits3.ud = $8.imm32;
		}
		| predicate SEND execsize dst sendleadreg payload exp directsrcoperand instoptions
		{
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.header.sfid_destreg__conditionalmod = $5.reg_nr; /* msg reg index */

		  set_instruction_predicate(&$$, &$1);

		  if (set_instruction_dest(&$$, &$4) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$6) != 0)
		    YYERROR;
		  /* XXX is this correct? */
		  if (set_instruction_src1(&$$, &$8) != 0)
		    YYERROR;
		  if (gen_level == 5) {
                      $$.bits2.send_gen5.sfid = $7;
		  }
		}
		
;

sndopr: exp %prec SNDOPR
		{
			$$ = $1;
		}
;

jumpinstruction: predicate JMPI execsize relativelocation2
		{
		  /* The jump instruction requires that the IP register
		   * be the destination and first source operand, while the
		   * offset is the second source operand.  The next instruction
		   * is the post-incremented IP plus the offset.
		   */
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = ffs(1) - 1;
		  if(advanced_flag)
		  	$$.header.mask_control = BRW_MASK_DISABLE;
		  set_instruction_predicate(&$$, &$1);
		  set_instruction_dest(&$$, &ip_dst);
		  set_instruction_src0(&$$, &ip_src);
		  set_instruction_src1(&$$, &$4);
		  $$.first_reloc_target = $4.reloc_target;
		  $$.first_reloc_offset = $4.imm32;
		}
;

mathinstruction: predicate MATH_INST execsize dst src srcimm math_function instoptions
		{
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.sfid_destreg__conditionalmod = $7;
		  $$.header.execution_size = $3;
		  set_instruction_options(&$$, &$8);
		  set_instruction_predicate(&$$, &$1);
		  if (set_instruction_dest(&$$, &$4) != 0)
		    YYERROR;
		  if (set_instruction_src0(&$$, &$5) != 0)
		    YYERROR;
		  if (set_instruction_src1(&$$, &$6) != 0)
		    YYERROR;
		}
;

breakinstruction: predicate breakop execsize relativelocation relativelocation instoptions
		{
		  // for Gen6, Gen7
		  memset(&$$, 0, sizeof($$));
		  set_instruction_predicate(&$$, &$1);
		  $$.header.opcode = $2;
		  $$.header.execution_size = $3;
		  $$.first_reloc_target = $4.reloc_target;
		  $$.first_reloc_offset = $4.imm32;
		  $$.second_reloc_target = $5.reloc_target;
		  $$.second_reloc_offset = $5.imm32;
		}
;

breakop:	BREAK | CONT
;

/*
maskpushop:	MSAVE | PUSH
;
 */

syncinstruction: predicate WAIT notifyreg
		{
		  struct dst_operand notify_dst;
		  struct src_operand notify_src;

		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $2;
		  $$.header.execution_size = ffs(1) - 1;
		  set_direct_dst_operand(&notify_dst, &$3, BRW_REGISTER_TYPE_D);
		  set_instruction_dest(&$$, &notify_dst);
		  set_direct_src_operand(&notify_src, &$3, BRW_REGISTER_TYPE_D);
		  set_instruction_src0(&$$, &notify_src);
		  set_instruction_src1(&$$, &src_null_reg);
		}
		
;

nopinstruction: NOP
		{
		  memset(&$$, 0, sizeof($$));
		  $$.header.opcode = $1;
		};

/* XXX! */
payload: directsrcoperand
;

post_dst:	dst
;

msgtarget:	NULL_TOKEN
		{
		  if (gen_level >= 5) {
                      $$.bits2.send_gen5.sfid= BRW_MESSAGE_TARGET_NULL;
                      $$.bits3.generic_gen5.header_present = 0;  /* ??? */
		  } else {
                      $$.bits3.generic.msg_target = BRW_MESSAGE_TARGET_NULL;
		  }
		}
		| SAMPLER LPAREN INTEGER COMMA INTEGER COMMA
		sampler_datatype RPAREN
		{
		  if (gen_level >= 7) {
                      $$.bits2.send_gen5.sfid = BRW_MESSAGE_TARGET_SAMPLER;
                      $$.bits3.generic_gen5.header_present = 1;   /* ??? */
                      $$.bits3.sampler_gen7.binding_table_index = $3;
                      $$.bits3.sampler_gen7.sampler = $5;
                      $$.bits3.sampler_gen7.simd_mode = 2; /* SIMD16, maybe we should add a new parameter */
		  } else if (gen_level >= 5) {
                      $$.bits2.send_gen5.sfid = BRW_MESSAGE_TARGET_SAMPLER;
                      $$.bits3.generic_gen5.header_present = 1;   /* ??? */
                      $$.bits3.sampler_gen5.binding_table_index = $3;
                      $$.bits3.sampler_gen5.sampler = $5;
                      $$.bits3.sampler_gen5.simd_mode = 2; /* SIMD16, maybe we should add a new parameter */
		  } else {
                      $$.bits3.generic.msg_target = BRW_MESSAGE_TARGET_SAMPLER;	
                      $$.bits3.sampler.binding_table_index = $3;
                      $$.bits3.sampler.sampler = $5;
                      switch ($7) {
                      case TYPE_F:
                          $$.bits3.sampler.return_format =
                              BRW_SAMPLER_RETURN_FORMAT_FLOAT32;
                          break;
                      case TYPE_UD:
                          $$.bits3.sampler.return_format =
                              BRW_SAMPLER_RETURN_FORMAT_UINT32;
                          break;
                      case TYPE_D:
                          $$.bits3.sampler.return_format =
                              BRW_SAMPLER_RETURN_FORMAT_SINT32;
                          break;
                      }
		  }
		}
		| MATH math_function saturate math_signed math_scalar
		{
		  if (gen_level == 6) {
                      fprintf (stderr, "Gen6+ donesn't have math function\n");
                      YYERROR;
		  } else if (gen_level == 5) {
                      $$.bits2.send_gen5.sfid = BRW_MESSAGE_TARGET_MATH;
                      $$.bits3.generic_gen5.header_present = 0;
                      $$.bits3.math_gen5.function = $2;
                      if ($3 == BRW_INSTRUCTION_SATURATE)
                          $$.bits3.math_gen5.saturate = 1;
                      else
                          $$.bits3.math_gen5.saturate = 0;
                      $$.bits3.math_gen5.int_type = $4;
                      $$.bits3.math_gen5.precision = BRW_MATH_PRECISION_FULL;
                      $$.bits3.math_gen5.data_type = $5;
		  } else {
                      $$.bits3.generic.msg_target = BRW_MESSAGE_TARGET_MATH;
                      $$.bits3.math.function = $2;
                      if ($3 == BRW_INSTRUCTION_SATURATE)
                          $$.bits3.math.saturate = 1;
                      else
                          $$.bits3.math.saturate = 0;
                      $$.bits3.math.int_type = $4;
                      $$.bits3.math.precision = BRW_MATH_PRECISION_FULL;
                      $$.bits3.math.data_type = $5;
		  }
		}
		| GATEWAY
		{
		  if (gen_level >= 5) {
                      $$.bits2.send_gen5.sfid = BRW_MESSAGE_TARGET_GATEWAY;
                      $$.bits3.generic_gen5.header_present = 0;  /* ??? */
		  } else {
                      $$.bits3.generic.msg_target = BRW_MESSAGE_TARGET_GATEWAY;
		  }
		}
		| READ  LPAREN INTEGER COMMA INTEGER COMMA INTEGER COMMA
                INTEGER RPAREN
		{
		  if (gen_level == 7) {
                      $$.bits2.send_gen5.sfid = 
                          BRW_MESSAGE_TARGET_DP_SC;
                      $$.bits3.generic_gen5.header_present = 1;
                      $$.bits3.dp_gen7.binding_table_index = $3;
                      $$.bits3.dp_gen7.msg_control = $7;
                      $$.bits3.dp_gen7.msg_type = $9;
		  } else if (gen_level == 6) {
                      $$.bits2.send_gen5.sfid = 
                          BRW_MESSAGE_TARGET_DP_SC;
                      $$.bits3.generic_gen5.header_present = 1;
                      $$.bits3.dp_read_gen6.binding_table_index = $3;
                      $$.bits3.dp_read_gen6.msg_control = $7;
                      $$.bits3.dp_read_gen6.msg_type = $9;
		  } else if (gen_level == 5) {
                      $$.bits2.send_gen5.sfid = 
                          BRW_MESSAGE_TARGET_DATAPORT_READ;
                      $$.bits3.generic_gen5.header_present = 1;
                      $$.bits3.dp_read_gen5.binding_table_index = $3;
                      $$.bits3.dp_read_gen5.target_cache = $5;
                      $$.bits3.dp_read_gen5.msg_control = $7;
                      $$.bits3.dp_read_gen5.msg_type = $9;
		  } else {
                      $$.bits3.generic.msg_target =
                          BRW_MESSAGE_TARGET_DATAPORT_READ;
                      $$.bits3.dp_read.binding_table_index = $3;
                      $$.bits3.dp_read.target_cache = $5;
                      $$.bits3.dp_read.msg_control = $7;
                      $$.bits3.dp_read.msg_type = $9;
		  }
		}
		| WRITE LPAREN INTEGER COMMA INTEGER COMMA INTEGER COMMA
		INTEGER RPAREN
		{
		  if (gen_level == 7) {
                      $$.bits2.send_gen5.sfid =
                          BRW_MESSAGE_TARGET_DP_RC;
                      $$.bits3.generic_gen5.header_present = 1;
                      $$.bits3.dp_gen7.binding_table_index = $3;
                      $$.bits3.dp_gen7.msg_control = $5;
                      $$.bits3.dp_gen7.msg_type = $7;
                  } else if (gen_level == 6) {
                      $$.bits2.send_gen5.sfid =
                          BRW_MESSAGE_TARGET_DP_RC;
                      /* Sandybridge supports headerlesss message for render target write.
                       * Currently the GFX assembler doesn't support it. so the program must provide 
                       * message header
                       */
                      $$.bits3.generic_gen5.header_present = 1;
                      $$.bits3.dp_write_gen6.binding_table_index = $3;
                      $$.bits3.dp_write_gen6.msg_control = $5;
                     $$.bits3.dp_write_gen6.msg_type = $7;
                      $$.bits3.dp_write_gen6.send_commit_msg = $9;
		  } else if (gen_level == 5) {
                      $$.bits2.send_gen5.sfid =
                          BRW_MESSAGE_TARGET_DATAPORT_WRITE;
                      $$.bits3.generic_gen5.header_present = 1;
                      $$.bits3.dp_write_gen5.binding_table_index = $3;
                      $$.bits3.dp_write_gen5.pixel_scoreboard_clear = ($5 & 0x8) >> 3;
                      $$.bits3.dp_write_gen5.msg_control = $5 & 0x7;
                      $$.bits3.dp_write_gen5.msg_type = $7;
                      $$.bits3.dp_write_gen5.send_commit_msg = $9;
		  } else {
                      $$.bits3.generic.msg_target =
                          BRW_MESSAGE_TARGET_DATAPORT_WRITE;
                      $$.bits3.dp_write.binding_table_index = $3;
                      /* The msg control field of brw_struct.h is split into
                       * msg control and pixel_scoreboard_clear, even though
                       * pixel_scoreboard_clear isn't common to all write messages.
                       */
                      $$.bits3.dp_write.pixel_scoreboard_clear = ($5 & 0x8) >> 3;
                      $$.bits3.dp_write.msg_control = $5 & 0x7;
                      $$.bits3.dp_write.msg_type = $7;
                      $$.bits3.dp_write.send_commit_msg = $9;
		  }
		}
		| WRITE LPAREN INTEGER COMMA INTEGER COMMA INTEGER COMMA
		INTEGER COMMA INTEGER RPAREN
		{
		  if (gen_level == 7) {
                      $$.bits2.send_gen5.sfid =
                          BRW_MESSAGE_TARGET_DP_RC;
                      $$.bits3.generic_gen5.header_present = ($11 != 0);
                      $$.bits3.dp_gen7.binding_table_index = $3;
                      $$.bits3.dp_gen7.msg_control = $5;
                      $$.bits3.dp_gen7.msg_type = $7;
		  } else if (gen_level == 6) {
                      $$.bits2.send_gen5.sfid =
                          BRW_MESSAGE_TARGET_DP_RC;
                      $$.bits3.generic_gen5.header_present = ($11 != 0);
                      $$.bits3.dp_write_gen6.binding_table_index = $3;
                      $$.bits3.dp_write_gen6.msg_control = $5;
                     $$.bits3.dp_write_gen6.msg_type = $7;
                      $$.bits3.dp_write_gen6.send_commit_msg = $9;
		  } else if (gen_level == 5) {
                      $$.bits2.send_gen5.sfid =
                          BRW_MESSAGE_TARGET_DATAPORT_WRITE;
                      $$.bits3.generic_gen5.header_present = ($11 != 0);
                      $$.bits3.dp_write_gen5.binding_table_index = $3;
                      $$.bits3.dp_write_gen5.pixel_scoreboard_clear = ($5 & 0x8) >> 3;
                      $$.bits3.dp_write_gen5.msg_control = $5 & 0x7;
                      $$.bits3.dp_write_gen5.msg_type = $7;
                      $$.bits3.dp_write_gen5.send_commit_msg = $9;
		  } else {
                      $$.bits3.generic.msg_target =
                          BRW_MESSAGE_TARGET_DATAPORT_WRITE;
                      $$.bits3.dp_write.binding_table_index = $3;
                      /* The msg control field of brw_struct.h is split into
                       * msg control and pixel_scoreboard_clear, even though
                       * pixel_scoreboard_clear isn't common to all write messages.
                       */
                      $$.bits3.dp_write.pixel_scoreboard_clear = ($5 & 0x8) >> 3;
                      $$.bits3.dp_write.msg_control = $5 & 0x7;
                      $$.bits3.dp_write.msg_type = $7;
                      $$.bits3.dp_write.send_commit_msg = $9;
		  }
		}
		| URB INTEGER urb_swizzle urb_allocate urb_used urb_complete
		{
		  $$.bits3.generic.msg_target = BRW_MESSAGE_TARGET_URB;
		  if (gen_level >= 5) {
                      $$.bits2.send_gen5.sfid = BRW_MESSAGE_TARGET_URB;
                      $$.bits3.generic_gen5.header_present = 1;
                      $$.bits3.urb_gen5.opcode = BRW_URB_OPCODE_WRITE;
                      $$.bits3.urb_gen5.offset = $2;
                      $$.bits3.urb_gen5.swizzle_control = $3;
                      $$.bits3.urb_gen5.pad = 0;
                      $$.bits3.urb_gen5.allocate = $4;
                      $$.bits3.urb_gen5.used = $5;
                      $$.bits3.urb_gen5.complete = $6;
		  } else {
                      $$.bits3.generic.msg_target = BRW_MESSAGE_TARGET_URB;
                      $$.bits3.urb.opcode = BRW_URB_OPCODE_WRITE;
                      $$.bits3.urb.offset = $2;
                      $$.bits3.urb.swizzle_control = $3;
                      $$.bits3.urb.pad = 0;
                      $$.bits3.urb.allocate = $4;
                      $$.bits3.urb.used = $5;
                      $$.bits3.urb.complete = $6;
		  }
		}
		| THREAD_SPAWNER  LPAREN INTEGER COMMA INTEGER COMMA
                        INTEGER RPAREN
		{
		  $$.bits3.generic.msg_target =
		    BRW_MESSAGE_TARGET_THREAD_SPAWNER;
		  if (gen_level >= 5) {
                      $$.bits2.send_gen5.sfid = 
                          BRW_MESSAGE_TARGET_THREAD_SPAWNER;
                      $$.bits3.generic_gen5.header_present = 0;
                      $$.bits3.thread_spawner_gen5.opcode = $3;
                      $$.bits3.thread_spawner_gen5.requester_type  = $5;
                      $$.bits3.thread_spawner_gen5.resource_select = $7;
		  } else {
                      $$.bits3.generic.msg_target =
                          BRW_MESSAGE_TARGET_THREAD_SPAWNER;
                      $$.bits3.thread_spawner.opcode = $3;
                      $$.bits3.thread_spawner.requester_type  = $5;
                      $$.bits3.thread_spawner.resource_select = $7;
		  }
		}
		| VME  LPAREN INTEGER COMMA INTEGER COMMA INTEGER COMMA INTEGER RPAREN
		{
		  $$.bits3.generic.msg_target =
                      BRW_MESSAGE_TARGET_VME;

		  if (gen_level >= 6) { 
                      $$.bits2.send_gen5.sfid =
                          BRW_MESSAGE_TARGET_VME;
                      $$.bits3.vme_gen6.binding_table_index = $3;
                      $$.bits3.vme_gen6.search_path_index = $5;
                      $$.bits3.vme_gen6.lut_subindex = $7;
                      $$.bits3.vme_gen6.message_type = $9;
                      $$.bits3.generic_gen5.header_present = 1; 
		  } else {
                      fprintf (stderr, "Gen6- donesn't have vme function\n");
                      YYERROR;
		  }    
		} 

		| DATA_PORT LPAREN INTEGER COMMA INTEGER COMMA INTEGER COMMA 
                INTEGER COMMA INTEGER COMMA INTEGER RPAREN
		{
                    $$.bits2.send_gen5.sfid = $3;
                    $$.bits3.generic_gen5.header_present = ($13 != 0);

                    if (gen_level >= 7) {
                        if ($3 != BRW_MESSAGE_TARGET_DP_SC &&
                            $3 != BRW_MESSAGE_TARGET_DP_RC &&
                            $3 != BRW_MESSAGE_TARGET_DP_CC &&
                            $3 != BRW_MESSAGE_TARGET_DP_DC) {
                            fprintf (stderr, "error: wrong cache type\n");
                            YYERROR;
                        }

                        $$.bits3.dp_gen7.category = $11;
                        $$.bits3.dp_gen7.binding_table_index = $9;
                        $$.bits3.dp_gen7.msg_control = $7;
                        $$.bits3.dp_gen7.msg_type = $5;
                    } else if (gen_level == 6) {
                        if ($3 != BRW_MESSAGE_TARGET_DP_SC &&
                            $3 != BRW_MESSAGE_TARGET_DP_RC &&
                            $3 != BRW_MESSAGE_TARGET_DP_CC) {
                            fprintf (stderr, "error: wrong cache type\n");
                            YYERROR;
                        }

                        $$.bits3.dp_gen6.send_commit_msg = $11;
                        $$.bits3.dp_gen6.binding_table_index = $9;
                        $$.bits3.dp_gen6.msg_control = $7;
                        $$.bits3.dp_gen6.msg_type = $5;
                    } else if (gen_level < 5) {
                        fprintf (stderr, "Gen6- donesn't support data port for sampler/render/constant/data cache\n");
                        YYERROR;
                    }
		} 
;

urb_allocate:	ALLOCATE { $$ = 1; }
		| /* empty */ { $$ = 0; }
;

urb_used:	USED { $$ = 1; }
		| /* empty */ { $$ = 0; }
;

urb_complete:	COMPLETE { $$ = 1; }
		| /* empty */ { $$ = 0; }
;

urb_swizzle:	TRANSPOSE { $$ = BRW_URB_SWIZZLE_TRANSPOSE; }
		| INTERLEAVE { $$ = BRW_URB_SWIZZLE_INTERLEAVE; }
		| /* empty */ { $$ = BRW_URB_SWIZZLE_NONE; }
;

sampler_datatype:
		TYPE_F
		| TYPE_UD
		| TYPE_D
;

math_function:	INV | LOG | EXP | SQRT | POW | SIN | COS | SINCOS | INTDIV
		| INTMOD | INTDIVMOD
;

math_signed:	/* empty */ { $$ = 0; }
		| SIGNED { $$ = 1; }
;

math_scalar:	/* empty */ { $$ = 0; }
		| SCALAR { $$ = 1; }
;

/* 1.4.2: Destination register */

dst:		dstoperand | dstoperandex
;

dstoperand:	symbol_reg dstregion
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.base.reg_file;
		  $$.reg_nr = $1.base.reg_nr;
		  $$.subreg_nr = $1.base.subreg_nr;
		  if ($2 == DEFAULT_DSTREGION) {
		      $$.horiz_stride = $1.dst_region;
		  } else {
		      $$.horiz_stride = $2;
		  }
		  $$.reg_type = $1.type;
		}
		| dstreg dstregion writemask regtype
		{
		  /* Returns an instruction with just the destination register
		   * filled in.
		   */
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		  $$.address_mode = $1.address_mode;
		  $$.address_subreg_nr = $1.address_subreg_nr;
		  $$.indirect_offset = $1.indirect_offset;
		  $$.horiz_stride = $2;
		  $$.writemask_set = $3.writemask_set;
		  $$.writemask = $3.writemask;
		  $$.reg_type = $4.type;
		}
;

/* The dstoperandex returns an instruction with just the destination register
 * filled in.
 */
dstoperandex:	dstoperandex_typed dstregion regtype
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		  $$.horiz_stride = $2;
		  $$.reg_type = $3.type;
		}
		| maskstackreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		  $$.horiz_stride = 1;
		  $$.reg_type = BRW_REGISTER_TYPE_UW;
		}
		| controlreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		  $$.horiz_stride = 1;
		  $$.reg_type = BRW_REGISTER_TYPE_UD;
		}
		| ipreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		  $$.horiz_stride = 1;
		  $$.reg_type = BRW_REGISTER_TYPE_UD;
		}
		| nullreg dstregion regtype
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		  $$.horiz_stride = $2;
		  $$.reg_type = $3.type;
		}
;

dstoperandex_typed: accreg | flagreg | addrreg | maskreg
;

symbol_reg:	STRING %prec STR_SYMBOL_REG 
		{
		    struct declared_register *dcl_reg = find_register($1);

		    if (dcl_reg == NULL) {
			fprintf(stderr, "can't find register %s\n", $1);
			YYERROR;
		    }

		    memcpy(&$$, dcl_reg, sizeof(*dcl_reg));
		    free($1); // $1 has been malloc'ed by strdup
		}
		| symbol_reg_p 
		{
			$$=$1;
		}
;

symbol_reg_p: STRING LPAREN exp RPAREN 
		{
		    struct declared_register *dcl_reg = find_register($1);	

		    if (dcl_reg == NULL) {
			fprintf(stderr, "can't find register %s\n", $1);
			YYERROR;
		    }

		    memcpy(&$$, dcl_reg, sizeof(*dcl_reg));
		    $$.base.reg_nr += $3;
		    free($1);
		}
		| STRING LPAREN exp COMMA exp RPAREN
		{
		    struct declared_register *dcl_reg = find_register($1);	

		    if (dcl_reg == NULL) {
			fprintf(stderr, "can't find register %s\n", $1);
			YYERROR;
		    }

		    memcpy(&$$, dcl_reg, sizeof(*dcl_reg));
		    $$.base.reg_nr += $3;
		    $$.base.subreg_nr += $5;
		    $$.base.reg_nr += $$.base.subreg_nr / (32 / get_type_size(dcl_reg->type));
		    $$.base.subreg_nr = $$.base.subreg_nr % (32 / get_type_size(dcl_reg->type));
		    free($1);
		}
;
/* Returns a partially complete destination register consisting of the
 * direct or indirect register addressing fields, but not stride or writemask.
 */
dstreg:		directgenreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_DIRECT;
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		}
		| directmsgreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_DIRECT;
		  $$.reg_file = $1.reg_file;
		  $$.reg_nr = $1.reg_nr;
		  $$.subreg_nr = $1.subreg_nr;
		}
		| indirectgenreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_REGISTER_INDIRECT_REGISTER;
		  $$.reg_file = $1.reg_file;
		  $$.address_subreg_nr = $1.address_subreg_nr;
		  $$.indirect_offset = $1.indirect_offset;
		}
		| indirectmsgreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_REGISTER_INDIRECT_REGISTER;
		  $$.reg_file = $1.reg_file;
		  $$.address_subreg_nr = $1.address_subreg_nr;
		  $$.indirect_offset = $1.indirect_offset;
		}
;

/* 1.4.3: Source register */
srcaccimm:	srcacc | imm32reg
;

srcacc:		directsrcaccoperand | indirectsrcoperand
;

srcimm:		directsrcoperand | indirectsrcoperand| imm32reg
;

imm32reg:	imm32 srcimmtype
		{
		  union {
		    int i;
		    float f;
		  } intfloat;
		  uint32_t	d;

		  switch ($2) {
		  case BRW_REGISTER_TYPE_UD:
		  case BRW_REGISTER_TYPE_D:
		  case BRW_REGISTER_TYPE_V:
		  case BRW_REGISTER_TYPE_VF:
		    switch ($1.r) {
		    case imm32_d:
		      d = $1.u.d;
		      break;
		    default:
		      fprintf (stderr, "%d: non-int D/UD/V/VF representation: %d,type=%d\n", yylineno, $1.r, $2);
		      YYERROR;
		    }
		    break;
		  case BRW_REGISTER_TYPE_UW:
		  case BRW_REGISTER_TYPE_W:
		    switch ($1.r) {
		    case imm32_d:
		      d = $1.u.d;
		      break;
		    default:
		      fprintf (stderr, "non-int W/UW representation\n");
		      YYERROR;
		    }
		    d &= 0xffff;
		    d |= d << 16;
		    break;
		  case BRW_REGISTER_TYPE_F:
		    switch ($1.r) {
		    case imm32_f:
		      intfloat.f = $1.u.f;
		      break;
		    case imm32_d:
		      intfloat.f = (float) $1.u.d;
		      break;
		    default:
		      fprintf (stderr, "non-float F representation\n");
		      YYERROR;
		    }
		    d = intfloat.i;
		    break;
#if 0
		  case BRW_REGISTER_TYPE_VF:
		    fprintf (stderr, "Immediate type VF not supported yet\n");
		    YYERROR;
#endif
		  default:
		    fprintf(stderr, "unknown immediate type %d\n", $2);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_IMMEDIATE_VALUE;
		  $$.reg_type = $2;
		  $$.imm32 = d;
		}
;

directsrcaccoperand:	directsrcoperand
		| accreg region regtype
		{
		  set_direct_src_operand(&$$, &$1, $3.type);
		  $$.vert_stride = $2.vert_stride;
		  $$.width = $2.width;
		  $$.horiz_stride = $2.horiz_stride;
		  $$.default_region = $2.is_default;
		}
;

/* Returns a source operand in the src0 fields of an instruction. */
srcarchoperandex: srcarchoperandex_typed region regtype
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.reg_file;
		  $$.reg_type = $3.type;
		  $$.subreg_nr = $1.subreg_nr;
		  $$.reg_nr = $1.reg_nr;
		  $$.vert_stride = $2.vert_stride;
		  $$.width = $2.width;
		  $$.horiz_stride = $2.horiz_stride;
		  $$.default_region = $2.is_default;
		  $$.negate = 0;
		  $$.abs = 0;
		}
		| maskstackreg
		{
		  set_direct_src_operand(&$$, &$1, BRW_REGISTER_TYPE_UB);
		}
		| controlreg
		{
		  set_direct_src_operand(&$$, &$1, BRW_REGISTER_TYPE_UD);
		}
/*		| statereg
		{
		  set_direct_src_operand(&$$, &$1, BRW_REGISTER_TYPE_UD);
		}*/
		| notifyreg
		{
		  set_direct_src_operand(&$$, &$1, BRW_REGISTER_TYPE_UD);
		}
		| ipreg
		{
		  set_direct_src_operand(&$$, &$1, BRW_REGISTER_TYPE_UD);
		}
		| nullreg region regtype
		{
		  if ($3.is_default) {
		    set_direct_src_operand(&$$, &$1, BRW_REGISTER_TYPE_UD);
		  } else {
		    set_direct_src_operand(&$$, &$1, $3.type);
		  }
		  $$.default_region = 1;
		}
;

srcarchoperandex_typed: flagreg | addrreg | maskreg
;

sendleadreg: symbol_reg
             {
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = $1.base.reg_file;
		  $$.reg_nr = $1.base.reg_nr;
		  $$.subreg_nr = $1.base.subreg_nr;
             }
             | directgenreg | directmsgreg
;

src:		directsrcoperand | indirectsrcoperand
;

directsrcoperand:	negate abs symbol_reg region regtype
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_DIRECT;
		  $$.reg_file = $3.base.reg_file;
		  $$.reg_nr = $3.base.reg_nr;
		  $$.subreg_nr = $3.base.subreg_nr;
		  if ($5.is_default) {
		    $$.reg_type = $3.type;
		  } else {
		    $$.reg_type = $5.type;
		  }
		  if ($4.is_default) {
		    $$.vert_stride = $3.src_region.vert_stride;
		    $$.width = $3.src_region.width;
		    $$.horiz_stride = $3.src_region.horiz_stride;
		  } else {
		    $$.vert_stride = $4.vert_stride;
		    $$.width = $4.width;
		    $$.horiz_stride = $4.horiz_stride;
		  }
		  $$.negate = $1;
		  $$.abs = $2;
		} 
		| statereg region regtype 
		{
		  if($2.is_default ==1 && $3.is_default == 1)
		  {
		    set_direct_src_operand(&$$, &$1, BRW_REGISTER_TYPE_UD);
		  }
		  else{
		    memset (&$$, '\0', sizeof ($$));
		    $$.address_mode = BRW_ADDRESS_DIRECT;
		    $$.reg_file = $1.reg_file;
		    $$.reg_nr = $1.reg_nr;
		    $$.subreg_nr = $1.subreg_nr;
		    $$.vert_stride = $2.vert_stride;
		    $$.width = $2.width;
		    $$.horiz_stride = $2.horiz_stride;
		    $$.reg_type = $3.type;
		  }
		}
		| negate abs directgenreg region regtype swizzle
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_DIRECT;
		  $$.reg_file = $3.reg_file;
		  $$.reg_nr = $3.reg_nr;
		  $$.subreg_nr = $3.subreg_nr;
		  $$.reg_type = $5.type;
		  $$.vert_stride = $4.vert_stride;
		  $$.width = $4.width;
		  $$.horiz_stride = $4.horiz_stride;
		  $$.default_region = $4.is_default;
		  $$.negate = $1;
		  $$.abs = $2;
		  $$.swizzle_set = $6.swizzle_set;
		  $$.swizzle_x = $6.swizzle_x;
		  $$.swizzle_y = $6.swizzle_y;
		  $$.swizzle_z = $6.swizzle_z;
		  $$.swizzle_w = $6.swizzle_w;
		}
		| srcarchoperandex
;

indirectsrcoperand:
		negate abs indirectgenreg indirectregion regtype swizzle
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_REGISTER_INDIRECT_REGISTER;
		  $$.reg_file = $3.reg_file;
		  $$.address_subreg_nr = $3.address_subreg_nr;
		  $$.indirect_offset = $3.indirect_offset;
		  $$.reg_type = $5.type;
		  $$.vert_stride = $4.vert_stride;
		  $$.width = $4.width;
		  $$.horiz_stride = $4.horiz_stride;
		  $$.negate = $1;
		  $$.abs = $2;
		  $$.swizzle_set = $6.swizzle_set;
		  $$.swizzle_x = $6.swizzle_x;
		  $$.swizzle_y = $6.swizzle_y;
		  $$.swizzle_z = $6.swizzle_z;
		  $$.swizzle_w = $6.swizzle_w;
		}
;

/* 1.4.4: Address Registers */
/* Returns a partially-completed indirect_reg consisting of the address
 * register fields for register-indirect access.
 */
addrparam:	addrreg COMMA immaddroffset
		{
		    if ($3 < -512 || $3 > 511) {
		    fprintf(stderr, "Address immediate offset %d out of"
			    "range %d\n", $3, yylineno);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_subreg_nr = $1.subreg_nr;
		  $$.indirect_offset = $3;
		}
		| addrreg 
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_subreg_nr = $1.subreg_nr;
		  $$.indirect_offset = 0;
		}
;

/* The immaddroffset provides an immediate offset value added to the addresses
 * from the address register in register-indirect register access.
 */
immaddroffset:	/* empty */ { $$ = 0; }
		| exp
;


/* 1.4.5: Register files and register numbers */
subregnum:	DOT exp
		{
		  $$ = $2;
		}
		|  %prec SUBREGNUM
		{
		  /* Default to subreg 0 if unspecified. */
		  $$ = 0;
		}
;

directgenreg:	GENREG subregnum
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_GENERAL_REGISTER_FILE;
		  $$.reg_nr = $1;
		  $$.subreg_nr = $2;
		}
;

indirectgenreg: GENREGFILE LSQUARE addrparam RSQUARE
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_GENERAL_REGISTER_FILE;
		  $$.address_subreg_nr = $3.address_subreg_nr;
		  $$.indirect_offset = $3.indirect_offset;
		}
;

directmsgreg:	MSGREG subregnum
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_MESSAGE_REGISTER_FILE;
		  $$.reg_nr = $1;
		  $$.subreg_nr = $2;
		}
;

indirectmsgreg: MSGREGFILE LSQUARE addrparam RSQUARE
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_MESSAGE_REGISTER_FILE;
		  $$.address_subreg_nr = $3.address_subreg_nr;
		  $$.indirect_offset = $3.indirect_offset;
		}
;

addrreg:	ADDRESSREG subregnum
		{
		  if ($1 != 0) {
		    fprintf(stderr,
			    "address register number %d out of range", $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_ADDRESS | $1;
		  $$.subreg_nr = $2;
		}
;

accreg:		ACCREG subregnum
		{
		  if ($1 > 1) {
		    fprintf(stderr,
			    "accumulator register number %d out of range", $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_ACCUMULATOR | $1;
		  $$.subreg_nr = $2;
		}
;

flagreg:	FLAGREG subregnum
		{
		  if ((gen_level <= 6 && $1) > 0 ||
		      (gen_level > 6 && $1 > 1)) {
                    fprintf(stderr,
			    "flag register number %d out of range\n", $1);
		    YYERROR;
		  }

		  if ($2 > 1) {
		    fprintf(stderr,
			    "flag subregister number %d out of range\n", $1);
		    YYERROR;
		  }

		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_FLAG | $1;
		  $$.subreg_nr = $2;
		}
;

maskreg:	MASKREG subregnum
		{
		  if ($1 > 0) {
		    fprintf(stderr,
			    "mask register number %d out of range", $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_MASK;
		  $$.subreg_nr = $2;
		}
		| mask_subreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_MASK;
		  $$.subreg_nr = $1;
		}
;

mask_subreg:	AMASK | IMASK | LMASK | CMASK
;

maskstackreg:	MASKSTACKREG subregnum
		{
		  if ($1 > 0) {
		    fprintf(stderr,
			    "mask stack register number %d out of range", $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_MASK_STACK;
		  $$.subreg_nr = $2;
		}
		| maskstack_subreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_MASK_STACK;
		  $$.subreg_nr = $1;
		}
;

maskstack_subreg: IMS | LMS
;

/*
maskstackdepthreg: MASKSTACKDEPTHREG subregnum
		{
		  if ($1 > 0) {
		    fprintf(stderr,
			    "mask stack register number %d out of range", $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_MASK_STACK_DEPTH;
		  $$.subreg_nr = $2;
		}
		| maskstackdepth_subreg
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_MASK_STACK_DEPTH;
		  $$.subreg_nr = $1;
		}
;

maskstackdepth_subreg: IMSD | LMSD
;
 */

notifyreg:	NOTIFYREG regtype
		{
		  int num_notifyreg = (gen_level >= 6) ? 3 : 2;

		  if ($1 > num_notifyreg) {
		    fprintf(stderr,
			    "notification register number %d out of range",
			    $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;

                  if (gen_level >= 6) {
		    $$.reg_nr = BRW_ARF_NOTIFICATION_COUNT;
                    $$.subreg_nr = $1;
                  } else {
		    $$.reg_nr = BRW_ARF_NOTIFICATION_COUNT | $1;
                    $$.subreg_nr = 0;
                  }
		}
/*
		| NOTIFYREG regtype
		{
		  if ($1 > 1) {
		    fprintf(stderr,
			    "notification register number %d out of range",
			    $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_NOTIFICATION_COUNT;
		  $$.subreg_nr = 0;
		}
*/
;

statereg:	STATEREG subregnum
		{
		  if ($1 > 0) {
		    fprintf(stderr,
			    "state register number %d out of range", $1);
		    YYERROR;
		  }
		  if ($2 > 1) {
		    fprintf(stderr,
			    "state subregister number %d out of range", $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_STATE | $1;
		  $$.subreg_nr = $2;
		}
;

controlreg:	CONTROLREG subregnum
		{
		  if ($1 > 0) {
		    fprintf(stderr,
			    "control register number %d out of range", $1);
		    YYERROR;
		  }
		  if ($2 > 2) {
		    fprintf(stderr,
			    "control subregister number %d out of range", $1);
		    YYERROR;
		  }
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_CONTROL | $1;
		  $$.subreg_nr = $2;
		}
;

ipreg:		IPREG regtype
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_IP;
		  $$.subreg_nr = 0;
		}
;

nullreg:	NULL_TOKEN
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  $$.reg_nr = BRW_ARF_NULL;
		  $$.subreg_nr = 0;
		}
;

/* 1.4.6: Relative locations */
relativelocation:
		simple_int
		{
		  if (($1 > 32767) || ($1 < -32768)) {
		    fprintf(stderr,
			    "error: relative offset %d out of range \n", 
			    $1);
		    YYERROR;
		  }

		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_IMMEDIATE_VALUE;
		  $$.reg_type = BRW_REGISTER_TYPE_D;
		  $$.imm32 = $1 & 0x0000ffff;
		}
		| STRING
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_IMMEDIATE_VALUE;
		  $$.reg_type = BRW_REGISTER_TYPE_D;
		  $$.reloc_target = $1;
		}
;

relativelocation2:
		  STRING
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_IMMEDIATE_VALUE;
		  $$.reg_type = BRW_REGISTER_TYPE_D;
		  $$.reloc_target = $1;
		}
		| exp
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.reg_file = BRW_IMMEDIATE_VALUE;
		  $$.reg_type = BRW_REGISTER_TYPE_D;
		  $$.imm32 = $1;
		}
		| directgenreg region regtype
		{
		  set_direct_src_operand(&$$, &$1, $3.type);
		  $$.vert_stride = $2.vert_stride;
		  $$.width = $2.width;
		  $$.horiz_stride = $2.horiz_stride;
		  $$.default_region = $2.is_default;
		}
		| symbol_reg_p
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_DIRECT;
		  $$.reg_file = $1.base.reg_file;
		  $$.reg_nr = $1.base.reg_nr;
		  $$.subreg_nr = $1.base.subreg_nr;
		  $$.reg_type = $1.type;
		  $$.vert_stride = $1.src_region.vert_stride;
		  $$.width = $1.src_region.width;
		  $$.horiz_stride = $1.src_region.horiz_stride;
		}
		| indirectgenreg indirectregion regtype
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.address_mode = BRW_ADDRESS_REGISTER_INDIRECT_REGISTER;
		  $$.reg_file = $1.reg_file;
		  $$.address_subreg_nr = $1.address_subreg_nr;
		  $$.indirect_offset = $1.indirect_offset;
		  $$.reg_type = $3.type;
		  $$.vert_stride = $2.vert_stride;
		  $$.width = $2.width;
		  $$.horiz_stride = $2.horiz_stride;
		}
;

/* 1.4.7: Regions */
dstregion:	/* empty */
		{
		  $$ = DEFAULT_DSTREGION;
		}
		|LANGLE exp RANGLE
		{
		  /* Returns a value for a horiz_stride field of an
		   * instruction.
		   */
		  if ($2 != 1 && $2 != 2 && $2 != 4) {
		    fprintf(stderr, "Invalid horiz size %d\n", $2);
		  }
		  $$ = ffs($2);
		}
;

region:		/* empty */
		{
		  /* XXX is this default value correct?*/
		  memset (&$$, '\0', sizeof ($$));
		  $$.vert_stride = ffs(0);
		  $$.width = ffs(1) - 1;
		  $$.horiz_stride = ffs(0);
		  $$.is_default = 1;
		}
		|LANGLE exp RANGLE
		{
		  /* XXX is this default value correct for accreg?*/
		  memset (&$$, '\0', sizeof ($$));
		  $$.vert_stride = ffs($2);
		  $$.width = ffs(1) - 1;
		  $$.horiz_stride = ffs(0);
		}
		|LANGLE exp COMMA exp COMMA exp RANGLE
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.vert_stride = ffs($2);
		  $$.width = ffs($4) - 1;
		  $$.horiz_stride = ffs($6);
		}
		| LANGLE exp SEMICOLON exp COMMA exp RANGLE
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.vert_stride = ffs($2);
		  $$.width = ffs($4) - 1;
		  $$.horiz_stride = ffs($6);
		}

;
/* region_wh is used in specifying indirect operands where rather than having
 * a vertical stride, you use subsequent address registers to get a new base
 * offset for the next row.
 */
region_wh:	LANGLE exp COMMA exp RANGLE
		{
		  memset (&$$, '\0', sizeof ($$));
		  $$.vert_stride = BRW_VERTICAL_STRIDE_ONE_DIMENSIONAL;
		  $$.width = ffs($2) - 1;
		  $$.horiz_stride = ffs($4);
		}
;

indirectregion:	region | region_wh
;

/* 1.4.8: Types */

/* regtype returns an integer register type suitable for inserting into an
 * instruction.
 */
regtype:	/* empty */
		{ $$.type = program_defaults.register_type;$$.is_default = 1;}
		| TYPE_F { $$.type = BRW_REGISTER_TYPE_F;$$.is_default = 0; }
		| TYPE_UD { $$.type = BRW_REGISTER_TYPE_UD;$$.is_default = 0; }
		| TYPE_D { $$.type = BRW_REGISTER_TYPE_D;$$.is_default = 0; }
		| TYPE_UW { $$.type = BRW_REGISTER_TYPE_UW;$$.is_default = 0; }
		| TYPE_W { $$.type = BRW_REGISTER_TYPE_W;$$.is_default = 0; }
		| TYPE_UB { $$.type = BRW_REGISTER_TYPE_UB;$$.is_default = 0; }
		| TYPE_B { $$.type = BRW_REGISTER_TYPE_B;$$.is_default = 0; }
;

srcimmtype:	/* empty */
		{
		    /* XXX change to default when pragma parse is done */
		   $$ = BRW_REGISTER_TYPE_D;
		}
		|TYPE_F { $$ = BRW_REGISTER_TYPE_F; }
		| TYPE_UD { $$ = BRW_REGISTER_TYPE_UD; }
		| TYPE_D { $$ = BRW_REGISTER_TYPE_D; }
		| TYPE_UW { $$ = BRW_REGISTER_TYPE_UW; }
		| TYPE_W { $$ = BRW_REGISTER_TYPE_W; }
		| TYPE_V { $$ = BRW_REGISTER_TYPE_V; }
		| TYPE_VF { $$ = BRW_REGISTER_TYPE_VF; }
;

/* 1.4.10: Swizzle control */
/* Returns the swizzle control for an align16 instruction's source operand
 * in the src0 fields.
 */
swizzle:	/* empty */
		{
		  $$.swizzle_set = 0;
		  $$.swizzle_x = BRW_CHANNEL_X;
		  $$.swizzle_y = BRW_CHANNEL_Y;
		  $$.swizzle_z = BRW_CHANNEL_Z;
		  $$.swizzle_w = BRW_CHANNEL_W;
		}
		| DOT chansel
		{
		  $$.swizzle_set = 1;
		  $$.swizzle_x = $2;
		  $$.swizzle_y = $2;
		  $$.swizzle_z = $2;
		  $$.swizzle_w = $2;
		}
		| DOT chansel chansel chansel chansel
		{
		  $$.swizzle_set = 1;
		  $$.swizzle_x = $2;
		  $$.swizzle_y = $3;
		  $$.swizzle_z = $4;
		  $$.swizzle_w = $5;
		}
;

chansel:	X | Y | Z | W
;

/* 1.4.9: Write mask */
/* Returns a partially completed dst_operand, with just the writemask bits
 * filled out.
 */
writemask:	/* empty */
		{
		  $$.writemask_set = 0;
		  $$.writemask = 0xf;
		}
		| DOT writemask_x writemask_y writemask_z writemask_w
		{
		  $$.writemask_set = 1;
		  $$.writemask = $2 | $3 | $4 | $5;
		}
;

writemask_x:	/* empty */ { $$ = 0; }
		 | X { $$ = 1 << BRW_CHANNEL_X; }
;

writemask_y:	/* empty */ { $$ = 0; }
		 | Y { $$ = 1 << BRW_CHANNEL_Y; }
;

writemask_z:	/* empty */ { $$ = 0; }
		 | Z { $$ = 1 << BRW_CHANNEL_Z; }
;

writemask_w:	/* empty */ { $$ = 0; }
		 | W { $$ = 1 << BRW_CHANNEL_W; }
;

/* 1.4.11: Immediate values */
imm32:		exp { $$.r = imm32_d; $$.u.d = $1; }
		| NUMBER { $$.r = imm32_f; $$.u.f = $1; }
;

/* 1.4.12: Predication and modifiers */
predicate:	/* empty */
		{
		  $$.header.predicate_control = BRW_PREDICATE_NONE;
		  $$.bits2.da1.flag_reg_nr = 0;
		  $$.bits2.da1.flag_subreg_nr = 0;
		  $$.header.predicate_inverse = 0;
		}
		| LPAREN predstate flagreg predctrl RPAREN
		{
		  $$.header.predicate_control = $4;
		  /* XXX: Should deal with erroring when the user tries to
		   * set a predicate for one flag register and conditional
		   * modification on the other flag register.
		   */
		  $$.bits2.da1.flag_reg_nr = ($3.reg_nr & 0xF);
		  $$.bits2.da1.flag_subreg_nr = $3.subreg_nr;
		  $$.header.predicate_inverse = $2;
		}
;

predstate:	/* empty */ { $$ = 0; }
		| PLUS { $$ = 0; }
		| MINUS { $$ = 1; }
;

predctrl:	/* empty */ { $$ = BRW_PREDICATE_NORMAL; }
		| DOT X { $$ = BRW_PREDICATE_ALIGN16_REPLICATE_X; }
		| DOT Y { $$ = BRW_PREDICATE_ALIGN16_REPLICATE_Y; }
		| DOT Z { $$ = BRW_PREDICATE_ALIGN16_REPLICATE_Z; }
		| DOT W { $$ = BRW_PREDICATE_ALIGN16_REPLICATE_W; }
		| ANYV { $$ = BRW_PREDICATE_ALIGN1_ANYV; }
		| ALLV { $$ = BRW_PREDICATE_ALIGN1_ALLV; }
		| ANY2H { $$ = BRW_PREDICATE_ALIGN1_ANY2H; }
		| ALL2H { $$ = BRW_PREDICATE_ALIGN1_ALL2H; }
		| ANY4H { $$ = BRW_PREDICATE_ALIGN1_ANY4H; }
		| ALL4H { $$ = BRW_PREDICATE_ALIGN1_ALL4H; }
		| ANY8H { $$ = BRW_PREDICATE_ALIGN1_ANY8H; }
		| ALL8H { $$ = BRW_PREDICATE_ALIGN1_ALL8H; }
		| ANY16H { $$ = BRW_PREDICATE_ALIGN1_ANY16H; }
		| ALL16H { $$ = BRW_PREDICATE_ALIGN1_ALL16H; }
;

negate:		/* empty */ { $$ = 0; }
		| MINUS { $$ = 1; }
;

abs:		/* empty */ { $$ = 0; }
		| ABS { $$ = 1; }
;

execsize:	/* empty */ %prec EMPTEXECSIZE
		{
		  $$ = ffs(program_defaults.execute_size) - 1;
		}
		|LPAREN exp RPAREN
		{
		  /* Returns a value for the execution_size field of an
		   * instruction.
		   */
		  if ($2 != 1 && $2 != 2 && $2 != 4 && $2 != 8 && $2 != 16 &&
		      $2 != 32) {
		    fprintf(stderr, "Invalid execution size %d\n", $2);
		    YYERROR;
		  }
		  $$ = ffs($2) - 1;
		}
;

saturate:	/* empty */ { $$ = BRW_INSTRUCTION_NORMAL; }
		| SATURATE { $$ = BRW_INSTRUCTION_SATURATE; }
;
conditionalmodifier: condition 
		{
		    $$.cond = $1;
		    $$.flag_reg_nr = 0;
		    $$.flag_subreg_nr = -1;
		}
		| condition DOT flagreg
		{
		    $$.cond = $1;
		    $$.flag_reg_nr = ($3.reg_nr & 0xF);
		    $$.flag_subreg_nr = $3.subreg_nr;
		}

condition: /* empty */    { $$ = BRW_CONDITIONAL_NONE; }
		| ZERO
		| EQUAL
		| NOT_ZERO
		| NOT_EQUAL
		| GREATER
		| GREATER_EQUAL
		| LESS
		| LESS_EQUAL
		| ROUND_INCREMENT
		| OVERFLOW
		| UNORDERED
;

/* 1.4.13: Instruction options */
instoptions:	/* empty */
		{ memset(&$$, 0, sizeof($$)); }
		| LCURLY instoption_list RCURLY
		{ $$ = $2; }
;

instoption_list:instoption_list COMMA instoption
		{
		  $$ = $1;
		  switch ($3) {
		  case ALIGN1:
		    $$.header.access_mode = BRW_ALIGN_1;
		    break;
		  case ALIGN16:
		    $$.header.access_mode = BRW_ALIGN_16;
		    break;
		  case SECHALF:
		    $$.header.compression_control |= BRW_COMPRESSION_2NDHALF;
		    break;
		  case COMPR:
		    if (gen_level < 6) {
                        $$.header.compression_control |=
                            BRW_COMPRESSION_COMPRESSED;
		    }
		    break;
		  case SWITCH:
		    $$.header.thread_control |= BRW_THREAD_SWITCH;
		    break;
		  case ATOMIC:
		    $$.header.thread_control |= BRW_THREAD_ATOMIC;
		    break;
		  case NODDCHK:
		    $$.header.dependency_control |= BRW_DEPENDENCY_NOTCHECKED;
		    break;
		  case NODDCLR:
		    $$.header.dependency_control |= BRW_DEPENDENCY_NOTCLEARED;
		    break;
		  case MASK_DISABLE:
		    $$.header.mask_control = BRW_MASK_DISABLE;
		    break;
		  case BREAKPOINT:
		    $$.header.debug_control = BRW_DEBUG_BREAKPOINT;
		    break;
		  case ACCWRCTRL:
		    $$.header.acc_wr_control = BRW_ACCWRCTRL_ACCWRCTRL;
		  }
		}
		| instoption_list instoption
		{
		  $$ = $1;
		  switch ($2) {
		  case ALIGN1:
		    $$.header.access_mode = BRW_ALIGN_1;
		    break;
		  case ALIGN16:
		    $$.header.access_mode = BRW_ALIGN_16;
		    break;
		  case SECHALF:
		    $$.header.compression_control |= BRW_COMPRESSION_2NDHALF;
		    break;
		  case COMPR:
			if (gen_level < 6) {
		      $$.header.compression_control |=
		        BRW_COMPRESSION_COMPRESSED;
			}
		    break;
		  case SWITCH:
		    $$.header.thread_control |= BRW_THREAD_SWITCH;
		    break;
		  case ATOMIC:
		    $$.header.thread_control |= BRW_THREAD_ATOMIC;
		    break;
		  case NODDCHK:
		    $$.header.dependency_control |= BRW_DEPENDENCY_NOTCHECKED;
		    break;
		  case NODDCLR:
		    $$.header.dependency_control |= BRW_DEPENDENCY_NOTCLEARED;
		    break;
		  case MASK_DISABLE:
		    $$.header.mask_control = BRW_MASK_DISABLE;
		    break;
		  case BREAKPOINT:
		    $$.header.debug_control = BRW_DEBUG_BREAKPOINT;
		    break;
		  case EOT:
		    /* XXX: EOT shouldn't be an instoption, I don't think */
		    $$.bits3.generic.end_of_thread = 1;
		    break;
		  }
		}
		| /* empty, header defaults to zeroes. */
		{
		  memset(&$$, 0, sizeof($$));
		}
;

instoption:	ALIGN1 { $$ = ALIGN1; }
		| ALIGN16 { $$ = ALIGN16; }
		| SECHALF { $$ = SECHALF; }
		| COMPR { $$ = COMPR; }
		| SWITCH { $$ = SWITCH; }
		| ATOMIC { $$ = ATOMIC; }
		| NODDCHK { $$ = NODDCHK; }
		| NODDCLR { $$ = NODDCLR; }
		| MASK_DISABLE { $$ = MASK_DISABLE; }
		| BREAKPOINT { $$ = BREAKPOINT; }
		| ACCWRCTRL { $$ = ACCWRCTRL; }
		| EOT { $$ = EOT; }
;

%%
extern int yylineno;
extern char *input_filename;

int errors;

void yyerror (char *msg)
{
	fprintf(stderr, "%s: %d: %s at \"%s\"\n",
		input_filename, yylineno, msg, lex_text());
	++errors;
}

static int get_type_size(GLuint type)
{
    int size = 1;

    switch (type) {
    case BRW_REGISTER_TYPE_F:
    case BRW_REGISTER_TYPE_UD:
    case BRW_REGISTER_TYPE_D:
        size = 4;
        break;

    case BRW_REGISTER_TYPE_UW:
    case BRW_REGISTER_TYPE_W:
        size = 2;
        break;

    case BRW_REGISTER_TYPE_UB:
    case BRW_REGISTER_TYPE_B:
        size = 1;
        break;

    default:
        assert(0);
        size = 1;
        break;
    }

    return size;
}

static int get_subreg_address(GLuint regfile, GLuint type, GLuint subreg, GLuint address_mode)
{
    int unit_size = 1;

    if (address_mode == BRW_ADDRESS_DIRECT) {
        if (advanced_flag == 1) {
            if ((regfile == BRW_GENERAL_REGISTER_FILE ||
                 regfile == BRW_MESSAGE_REGISTER_FILE || 
                 regfile == BRW_ARCHITECTURE_REGISTER_FILE)) {
                
                unit_size = get_type_size(type);
            } 
        }
    } else {
        unit_size = 1;
    }

    return subreg * unit_size;
}

static void reset_instruction_src_region(struct brw_instruction *instr, 
                                         struct src_operand *src)
{
    if (!src->default_region)
        return;

    if (src->reg_file == BRW_ARCHITECTURE_REGISTER_FILE && 
        ((src->reg_nr & 0xF0) == BRW_ARF_ADDRESS)) {
        src->vert_stride = ffs(0);
        src->width = ffs(1) - 1;
        src->horiz_stride = ffs(0);
    } else if (src->reg_file == BRW_ARCHITECTURE_REGISTER_FILE &&
               ((src->reg_nr & 0xF0) == BRW_ARF_ACCUMULATOR)) {
        int horiz_stride = 1, width, vert_stride;
        if (instr->header.compression_control == BRW_COMPRESSION_COMPRESSED) {
            width = 16;
        } else {
            width = 8;
        }

        if (width > (1 << instr->header.execution_size))
            width = (1 << instr->header.execution_size);

        vert_stride = horiz_stride * width;
        src->vert_stride = ffs(vert_stride);
        src->width = ffs(width) - 1;
        src->horiz_stride = ffs(horiz_stride);
    } else if ((src->reg_file == BRW_ARCHITECTURE_REGISTER_FILE) &&
               (src->reg_nr == BRW_ARF_NULL) &&
               (instr->header.opcode == BRW_OPCODE_SEND)) {
        src->vert_stride = ffs(8);
        src->width = ffs(8) - 1;
        src->horiz_stride = ffs(1);
    } else {

        int horiz_stride = 1, width, vert_stride;

        if (instr->header.execution_size == 0) { /* scalar */
            horiz_stride = 0;
            width = 1;
            vert_stride = 0;
        } else {
            if ((instr->header.opcode == BRW_OPCODE_MUL) ||
                (instr->header.opcode == BRW_OPCODE_MAC) ||
                (instr->header.opcode == BRW_OPCODE_CMP) ||
                (instr->header.opcode == BRW_OPCODE_ASR) ||
                (instr->header.opcode == BRW_OPCODE_ADD) ||
				(instr->header.opcode == BRW_OPCODE_SHL)) {
                horiz_stride = 0;
                width = 1;
                vert_stride = 0;
            } else {
                width = (1 << instr->header.execution_size) / horiz_stride;
                vert_stride = horiz_stride * width;

                if (get_type_size(src->reg_type) * (width + src->subreg_nr) > 32) {
                    horiz_stride = 0;
                    width = 1;
                    vert_stride = 0;
                }
            }
        }

        src->vert_stride = ffs(vert_stride);
        src->width = ffs(width) - 1;
        src->horiz_stride = ffs(horiz_stride);
    }
}

/**
 * Fills in the destination register information in instr from the bits in dst.
 */
int set_instruction_dest(struct brw_instruction *instr,
			 struct dst_operand *dest)
{
	if (dest->horiz_stride == DEFAULT_DSTREGION)
		dest->horiz_stride = ffs(1);
	if (dest->address_mode == BRW_ADDRESS_DIRECT &&
	    instr->header.access_mode == BRW_ALIGN_1) {
		instr->bits1.da1.dest_reg_file = dest->reg_file;
		instr->bits1.da1.dest_reg_type = dest->reg_type;
		instr->bits1.da1.dest_subreg_nr = get_subreg_address(dest->reg_file, dest->reg_type, dest->subreg_nr, dest->address_mode);
		instr->bits1.da1.dest_reg_nr = dest->reg_nr;
		instr->bits1.da1.dest_horiz_stride = dest->horiz_stride;
		instr->bits1.da1.dest_address_mode = dest->address_mode;
		if (dest->writemask_set) {
			fprintf(stderr, "error: write mask set in align1 "
				"instruction\n");
			return 1;
		}
	} else if (dest->address_mode == BRW_ADDRESS_DIRECT) {
		instr->bits1.da16.dest_reg_file = dest->reg_file;
		instr->bits1.da16.dest_reg_type = dest->reg_type;
		instr->bits1.da16.dest_subreg_nr = get_subreg_address(dest->reg_file, dest->reg_type, dest->subreg_nr, dest->address_mode);
		instr->bits1.da16.dest_reg_nr = dest->reg_nr;
		instr->bits1.da16.dest_address_mode = dest->address_mode;
		instr->bits1.da16.dest_horiz_stride = ffs(1);
		instr->bits1.da16.dest_writemask = dest->writemask;
	} else if (instr->header.access_mode == BRW_ALIGN_1) {
		instr->bits1.ia1.dest_reg_file = dest->reg_file;
		instr->bits1.ia1.dest_reg_type = dest->reg_type;
		instr->bits1.ia1.dest_subreg_nr = get_subreg_address(dest->reg_file, dest->reg_type, dest->address_subreg_nr, dest->address_mode);
		instr->bits1.ia1.dest_horiz_stride = dest->horiz_stride;
		instr->bits1.ia1.dest_indirect_offset = dest->indirect_offset;
		instr->bits1.ia1.dest_address_mode = dest->address_mode;
		if (dest->writemask_set) {
			fprintf(stderr, "error: write mask set in align1 "
				"instruction\n");
			return 1;
		}
	} else {
		instr->bits1.ia16.dest_reg_file = dest->reg_file;
		instr->bits1.ia16.dest_reg_type = dest->reg_type;
		instr->bits1.ia16.dest_subreg_nr = get_subreg_address(dest->reg_file, dest->reg_type, dest->address_subreg_nr, dest->address_mode);
		instr->bits1.ia16.dest_writemask = dest->writemask;
		instr->bits1.ia16.dest_horiz_stride = ffs(1);
		instr->bits1.ia16.dest_indirect_offset = (dest->indirect_offset >> 4); /* half register aligned */
		instr->bits1.ia16.dest_address_mode = dest->address_mode;
	}

	return 0;
}

/* Sets the first source operand for the instruction.  Returns 0 on success. */
int set_instruction_src0(struct brw_instruction *instr,
			  struct src_operand *src)
{
	if (advanced_flag) {
		reset_instruction_src_region(instr, src);
	}
	instr->bits1.da1.src0_reg_file = src->reg_file;
	instr->bits1.da1.src0_reg_type = src->reg_type;
	if (src->reg_file == BRW_IMMEDIATE_VALUE) {
		instr->bits3.ud = src->imm32;
	} else if (src->address_mode == BRW_ADDRESS_DIRECT) {
            if (instr->header.access_mode == BRW_ALIGN_1) {
		instr->bits2.da1.src0_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->subreg_nr, src->address_mode);
		instr->bits2.da1.src0_reg_nr = src->reg_nr;
		instr->bits2.da1.src0_vert_stride = src->vert_stride;
		instr->bits2.da1.src0_width = src->width;
		instr->bits2.da1.src0_horiz_stride = src->horiz_stride;
		instr->bits2.da1.src0_negate = src->negate;
		instr->bits2.da1.src0_abs = src->abs;
		instr->bits2.da1.src0_address_mode = src->address_mode;
		if (src->swizzle_set) {
			fprintf(stderr, "error: swizzle bits set in align1 "
				"instruction\n");
			return 1;
		}
            } else {
		instr->bits2.da16.src0_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->subreg_nr, src->address_mode);
		instr->bits2.da16.src0_reg_nr = src->reg_nr;
		instr->bits2.da16.src0_vert_stride = src->vert_stride;
		instr->bits2.da16.src0_negate = src->negate;
		instr->bits2.da16.src0_abs = src->abs;
		instr->bits2.da16.src0_swz_x = src->swizzle_x;
		instr->bits2.da16.src0_swz_y = src->swizzle_y;
		instr->bits2.da16.src0_swz_z = src->swizzle_z;
		instr->bits2.da16.src0_swz_w = src->swizzle_w;
		instr->bits2.da16.src0_address_mode = src->address_mode;
            }
        } else {
            if (instr->header.access_mode == BRW_ALIGN_1) {
		instr->bits2.ia1.src0_indirect_offset = src->indirect_offset;
		instr->bits2.ia1.src0_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->address_subreg_nr, src->address_mode);
		instr->bits2.ia1.src0_abs = src->abs;
		instr->bits2.ia1.src0_negate = src->negate;
		instr->bits2.ia1.src0_address_mode = src->address_mode;
		instr->bits2.ia1.src0_horiz_stride = src->horiz_stride;
		instr->bits2.ia1.src0_width = src->width;
		instr->bits2.ia1.src0_vert_stride = src->vert_stride;
		if (src->swizzle_set) {
			fprintf(stderr, "error: swizzle bits set in align1 "
				"instruction\n");
			return 1;
		}
            } else {
		instr->bits2.ia16.src0_swz_x = src->swizzle_x;
		instr->bits2.ia16.src0_swz_y = src->swizzle_y;
		instr->bits2.ia16.src0_indirect_offset = (src->indirect_offset >> 4); /* half register aligned */
		instr->bits2.ia16.src0_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->address_subreg_nr, src->address_mode);
		instr->bits2.ia16.src0_abs = src->abs;
		instr->bits2.ia16.src0_negate = src->negate;
		instr->bits2.ia16.src0_address_mode = src->address_mode;
		instr->bits2.ia16.src0_swz_z = src->swizzle_z;
		instr->bits2.ia16.src0_swz_w = src->swizzle_w;
		instr->bits2.ia16.src0_vert_stride = src->vert_stride;
            }
        }

	return 0;
}

/* Sets the second source operand for the instruction.  Returns 0 on success.
 */
int set_instruction_src1(struct brw_instruction *instr,
			  struct src_operand *src)
{
	if (advanced_flag) {
		reset_instruction_src_region(instr, src);
	}
	instr->bits1.da1.src1_reg_file = src->reg_file;
	instr->bits1.da1.src1_reg_type = src->reg_type;
	if (src->reg_file == BRW_IMMEDIATE_VALUE) {
		instr->bits3.ud = src->imm32;
	} else if (src->address_mode == BRW_ADDRESS_DIRECT) {
            if (instr->header.access_mode == BRW_ALIGN_1) {
		instr->bits3.da1.src1_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->subreg_nr, src->address_mode);
		instr->bits3.da1.src1_reg_nr = src->reg_nr;
		instr->bits3.da1.src1_vert_stride = src->vert_stride;
		instr->bits3.da1.src1_width = src->width;
		instr->bits3.da1.src1_horiz_stride = src->horiz_stride;
		instr->bits3.da1.src1_negate = src->negate;
		instr->bits3.da1.src1_abs = src->abs;
                instr->bits3.da1.src1_address_mode = src->address_mode;
		/* XXX why?
		if (src->address_mode != BRW_ADDRESS_DIRECT) {
			fprintf(stderr, "error: swizzle bits set in align1 "
				"instruction\n");
			return 1;
		}
		*/
		if (src->swizzle_set) {
			fprintf(stderr, "error: swizzle bits set in align1 "
				"instruction\n");
			return 1;
		}
            } else {
		instr->bits3.da16.src1_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->subreg_nr, src->address_mode);
		instr->bits3.da16.src1_reg_nr = src->reg_nr;
		instr->bits3.da16.src1_vert_stride = src->vert_stride;
		instr->bits3.da16.src1_negate = src->negate;
		instr->bits3.da16.src1_abs = src->abs;
		instr->bits3.da16.src1_swz_x = src->swizzle_x;
		instr->bits3.da16.src1_swz_y = src->swizzle_y;
		instr->bits3.da16.src1_swz_z = src->swizzle_z;
		instr->bits3.da16.src1_swz_w = src->swizzle_w;
                instr->bits3.da16.src1_address_mode = src->address_mode;
		if (src->address_mode != BRW_ADDRESS_DIRECT) {
			fprintf(stderr, "error: swizzle bits set in align1 "
				"instruction\n");
			return 1;
		}
            }
	} else {
            if (instr->header.access_mode == BRW_ALIGN_1) {
		instr->bits3.ia1.src1_indirect_offset = src->indirect_offset;
		instr->bits3.ia1.src1_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->address_subreg_nr, src->address_mode);
		instr->bits3.ia1.src1_abs = src->abs;
		instr->bits3.ia1.src1_negate = src->negate;
		instr->bits3.ia1.src1_address_mode = src->address_mode;
		instr->bits3.ia1.src1_horiz_stride = src->horiz_stride;
		instr->bits3.ia1.src1_width = src->width;
		instr->bits3.ia1.src1_vert_stride = src->vert_stride;
		if (src->swizzle_set) {
			fprintf(stderr, "error: swizzle bits set in align1 "
				"instruction\n");
			return 1;
		}
            } else {
		instr->bits3.ia16.src1_swz_x = src->swizzle_x;
		instr->bits3.ia16.src1_swz_y = src->swizzle_y;
		instr->bits3.ia16.src1_indirect_offset = (src->indirect_offset >> 4); /* half register aligned */
		instr->bits3.ia16.src1_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->address_subreg_nr, src->address_mode);
		instr->bits3.ia16.src1_abs = src->abs;
		instr->bits3.ia16.src1_negate = src->negate;
		instr->bits3.ia16.src1_address_mode = src->address_mode;
		instr->bits3.ia16.src1_swz_z = src->swizzle_z;
		instr->bits3.ia16.src1_swz_w = src->swizzle_w;
		instr->bits3.ia16.src1_vert_stride = src->vert_stride;
            }
        }

	return 0;
}

/* convert 2-src reg type to 3-src reg type
 *
 * 2-src reg type:
 *  000=UD 001=D 010=UW 011=W 100=UB 101=B 110=DF 111=F
 *
 * 3-src reg type:
 *  00=F  01=D  10=UD  11=DF
 */
static int reg_type_2_to_3(int reg_type)
{
	int r = 0;
	switch(reg_type) {
		case 7: r = 0; break;
		case 1: r = 1; break;
		case 0: r = 2; break;
		// TODO: supporting DF
	}
	return r;
}

int set_instruction_dest_three_src(struct brw_instruction *instr,
                                   struct dst_operand *dest)
{
	instr->bits1.three_src_gen6.dest_reg_file = dest->reg_file;
	instr->bits1.three_src_gen6.dest_reg_nr = dest->reg_nr;
	instr->bits1.three_src_gen6.dest_subreg_nr = get_subreg_address(dest->reg_file, dest->reg_type, dest->subreg_nr, dest->address_mode) / 4; // in DWORD
	instr->bits1.three_src_gen6.dest_writemask = dest->writemask;
	instr->bits1.three_src_gen6.dest_reg_type = reg_type_2_to_3(dest->reg_type);
	return 0;
}

int set_instruction_src0_three_src(struct brw_instruction *instr,
                                   struct src_operand *src)
{
	if (advanced_flag) {
		reset_instruction_src_region(instr, src);
	}
	// TODO: supporting src0 swizzle, src0 modifier, src0 rep_ctrl
	instr->bits1.three_src_gen6.src_reg_type = reg_type_2_to_3(src->reg_type);
	instr->bits2.three_src_gen6.src0_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->subreg_nr, src->address_mode) / 4; // in DWORD
	instr->bits2.three_src_gen6.src0_reg_nr = src->reg_nr;
	return 0;
}

int set_instruction_src1_three_src(struct brw_instruction *instr,
                                   struct src_operand *src)
{
	if (advanced_flag) {
		reset_instruction_src_region(instr, src);
	}
	// TODO: supporting src1 swizzle, src1 modifier, src1 rep_ctrl
	int v = get_subreg_address(src->reg_file, src->reg_type, src->subreg_nr, src->address_mode) / 4; // in DWORD
	instr->bits2.three_src_gen6.src1_subreg_nr_low = v % 4; // lower 2 bits
	instr->bits3.three_src_gen6.src1_subreg_nr_high = v / 4; // highest bit
	instr->bits3.three_src_gen6.src1_reg_nr = src->reg_nr;
	return 0;
}

int set_instruction_src2_three_src(struct brw_instruction *instr,
                                   struct src_operand *src)
{
	if (advanced_flag) {
		reset_instruction_src_region(instr, src);
	}
	// TODO: supporting src2 swizzle, src2 modifier, src2 rep_ctrl
	instr->bits3.three_src_gen6.src2_subreg_nr = get_subreg_address(src->reg_file, src->reg_type, src->subreg_nr, src->address_mode) / 4; // in DWORD
	instr->bits3.three_src_gen6.src2_reg_nr = src->reg_nr;
	return 0;
}

void set_instruction_options(struct brw_instruction *instr,
			     struct brw_instruction *options)
{
	/* XXX: more instr options */
	instr->header.access_mode = options->header.access_mode;
	instr->header.mask_control = options->header.mask_control;
	instr->header.dependency_control = options->header.dependency_control;
	instr->header.compression_control =
		options->header.compression_control;
}

void set_instruction_predicate(struct brw_instruction *instr,
			       struct brw_instruction *predicate)
{
	instr->header.predicate_control = predicate->header.predicate_control;
	instr->header.predicate_inverse = predicate->header.predicate_inverse;
	instr->bits2.da1.flag_reg_nr = predicate->bits2.da1.flag_reg_nr;
	instr->bits2.da1.flag_subreg_nr = predicate->bits2.da1.flag_subreg_nr;
}

void set_direct_dst_operand(struct dst_operand *dst, struct direct_reg *reg,
			    int type)
{
	memset(dst, 0, sizeof(*dst));
	dst->address_mode = BRW_ADDRESS_DIRECT;
	dst->reg_file = reg->reg_file;
	dst->reg_nr = reg->reg_nr;
	dst->subreg_nr = reg->subreg_nr;
	dst->reg_type = type;
	dst->horiz_stride = 1;
	dst->writemask_set = 0;
	dst->writemask = 0xf;
}

void set_direct_src_operand(struct src_operand *src, struct direct_reg *reg,
			    int type)
{
	memset(src, 0, sizeof(*src));
	src->address_mode = BRW_ADDRESS_DIRECT;
	src->reg_file = reg->reg_file;
	src->reg_type = type;
	src->subreg_nr = reg->subreg_nr;
	src->reg_nr = reg->reg_nr;
	src->vert_stride = 0;
	src->width = 0;
	src->horiz_stride = 0;
	src->negate = 0;
	src->abs = 0;
	src->swizzle_set = 0;
	src->swizzle_x = BRW_CHANNEL_X;
	src->swizzle_y = BRW_CHANNEL_Y;
	src->swizzle_z = BRW_CHANNEL_Z;
	src->swizzle_w = BRW_CHANNEL_W;
}
