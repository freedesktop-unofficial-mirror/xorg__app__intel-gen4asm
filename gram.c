#include <stdlib.h>
#ifndef lint
#ifdef __unused
__unused
#endif
static char const 
yyrcsid[] = "$FreeBSD: src/usr.bin/yacc/skeleton.c,v 1.37 2003/02/12 18:03:55 davidc Exp $";
#endif
#define YYBYACC 1
#define YYMAJOR 1
#define YYMINOR 9
#define YYLEX yylex()
#define YYEMPTY -1
#define yyclearin (yychar=(YYEMPTY))
#define yyerrok (yyerrflag=0)
#define YYRECOVERING() (yyerrflag!=0)
#if defined(__cplusplus) || __STDC__
static int yygrowstack(void);
#else
static int yygrowstack();
#endif
#define YYPREFIX "yy"
#line 2 "gram.y"
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
#include "gen4asm.h"
#include "brw_defines.h"

#line 37 "gram.y"
typedef union {
	char *s;
	int integer;
	double number;
	struct brw_instruction instruction;
	struct brw_program program;
	struct region {
		int vert_stride, width, horiz_stride;
	} region;
	struct direct_gen_reg {
		int reg_file, reg_nr, subreg_nr;
	} direct_gen_reg;
	double imm32;
} YYSTYPE;
#line 71 "y.tab.c"
#define YYERRCODE 256
#define SEMICOLON 257
#define LPAREN 258
#define RPAREN 259
#define LANGLE 260
#define RANGLE 261
#define LCURLY 262
#define RCURLY 263
#define COMMA 264
#define DOT 265
#define TYPE_UD 266
#define TYPE_D 267
#define TYPE_UW 268
#define TYPE_W 269
#define TYPE_UB 270
#define TYPE_B 271
#define TYPE_VF 272
#define TYPE_HF 273
#define TYPE_V 274
#define TYPE_F 275
#define ALIGN1 276
#define ALIGN16 277
#define MASK_DISABLE 278
#define EOT 279
#define GENREG 280
#define MSGREG 281
#define ACCREG 282
#define ADDRESSREG 283
#define FLAGREG 284
#define CONTROLREG 285
#define IPREG 286
#define MOV 287
#define MUL 288
#define MAC 289
#define MACH 290
#define LINE 291
#define SAD2 292
#define SADA2 293
#define DP4 294
#define DPH 295
#define DP3 296
#define DP2 297
#define ADD 298
#define SEND 299
#define NULL_TOKEN 300
#define MATH 301
#define SAMPLER 302
#define GATEWAY 303
#define READ 304
#define WRITE 305
#define URB 306
#define THREAD_SPAWNER 307
#define MSGLEN 308
#define RETURNLEN 309
#define SATURATE 310
#define INTEGER 311
#define NUMBER 312
#define flagreg 313
#define maskreg 314
#define NOP 315
const short yylhs[] = {                                        -1,
    0,   21,   21,   21,    1,    1,    1,    1,    1,    2,
   22,    3,   23,   23,    4,   24,    5,    6,    7,   41,
   32,   32,   32,   32,   32,   32,   32,   32,   40,   40,
    8,    9,    9,   10,   10,   17,   17,   16,   15,   15,
   12,   13,   14,   31,   31,   34,   35,   11,   36,   37,
   30,   33,   27,   27,   27,   27,   27,   27,   27,   28,
   38,   38,   39,   29,   26,   26,   25,   18,   19,   19,
   20,   20,   20,   20,
};
const short yylen[] = {                                         2,
    1,    3,    2,    3,    1,    1,    1,    1,    1,    8,
    1,    9,    1,    1,    9,    1,    1,   12,    1,    1,
    1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
    3,    3,    1,    1,    1,    1,    2,    1,    1,    2,
    1,    1,    3,    2,    0,    3,    3,    3,    3,    1,
    3,    7,    1,    1,    1,    1,    1,    1,    1,    1,
    1,    1,    0,    3,    0,    2,    0,    3,    2,    0,
    1,    1,    1,    1,
};
const short yydefred[] = {                                      0,
    0,   19,    0,    0,    5,    6,    7,    8,   17,    9,
    1,    0,    0,    0,   11,   13,   14,   16,    0,   67,
   67,   67,    4,    2,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,   50,   29,
   30,    0,    0,   34,   35,   33,    0,   66,    0,    0,
    0,   64,    0,    0,    0,    0,    0,    0,   20,    0,
    0,    0,    0,    0,    0,   46,   47,   48,    0,   54,
   55,   56,   57,   58,   59,   53,   31,   32,    0,    0,
   21,   23,   22,   24,   25,   26,   27,   28,    0,   61,
   62,   38,   41,   36,    0,    0,    0,   42,    0,   44,
   51,    0,   43,    0,    0,   10,   60,   37,   39,    0,
    0,    0,    0,    0,   71,   72,   73,   74,    0,    0,
   12,   40,   15,    0,    0,   68,   69,    0,    0,    0,
   18,   52,
};
const short yydgoto[] = {                                       3,
    4,    5,    6,    7,    8,    9,   10,   40,   41,   42,
   43,   92,   97,   93,  110,   94,   95,  106,  119,  120,
   11,   20,   21,   22,   26,   32,  107,  108,   30,   57,
   66,   89,   80,   60,   45,    0,   46,  111,   12,   47,
   61,
};
const short yysindex[] = {                                   -256,
 -244,    0,    0, -218,    0,    0,    0,    0,    0,    0,
    0, -266, -256, -256,    0,    0,    0,    0, -265,    0,
    0,    0,    0,    0, -205, -194, -194, -194, -239, -274,
 -237, -205, -205, -205, -185, -236, -235, -234,    0,    0,
    0, -182, -182,    0,    0,    0, -201,    0, -274, -274,
 -274,    0, -184, -184, -184, -231, -226, -226,    0, -178,
 -240, -277, -201, -201, -228,    0,    0,    0, -177,    0,
    0,    0,    0,    0,    0,    0,    0,    0, -225, -226,
    0,    0,    0,    0,    0,    0,    0,    0, -223,    0,
    0,    0,    0,    0, -175, -226, -277,    0, -277,    0,
    0, -176,    0, -222, -221,    0,    0,    0,    0, -175,
 -226, -175, -220, -219,    0,    0,    0,    0, -171, -221,
    0,    0,    0, -170, -216,    0,    0, -215, -175, -168,
    0,    0,
};
const short yyrindex[] = {                                   -251,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0, -251,    1,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0, -161, -161, -161,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0, -162, -162, -162,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0, -164,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0, -164,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,
};
const short yygindex[] = {                                      0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,  -45,    2,   36,    0,  -98,  -18,    0,
   -3,    0,    0,    0,   -2,   23,  -53,   -8,  -17,   61,
  -30,    0,    0,  -21,    0,    0,    0,   43,    0,   19,
    0,
};
#define YYTABLESIZE 300
const short yytable[] = {                                       1,
    3,   59,   36,   77,   78,   36,   37,   38,   44,   23,
   24,  121,   13,  123,   49,   50,   51,   98,   27,   28,
   15,   16,   17,   67,   68,   39,  103,   44,   44,   44,
  131,   18,   19,   90,   91,   63,   63,   63,   14,   70,
   71,   72,   73,   74,   75,   25,   63,   63,   76,   33,
   34,  109,   29,  109,  115,  116,  117,  118,    2,   81,
   82,   83,   84,   85,   86,   87,   88,   62,   63,   64,
   31,   35,   48,   52,   53,   54,   55,   56,   36,   69,
   65,   79,  100,  101,  104,  102,  105,  113,  114,  125,
  124,  126,  132,  128,  129,  130,   65,   45,   70,   99,
  112,  127,  122,   58,   96,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,   63,   63,   63,
    0,    0,    0,    0,    0,    0,    0,    0,   63,   63,
};
const short yycheck[] = {                                     256,
    0,   47,  280,   57,   58,  280,  281,  282,   30,   13,
   14,  110,  257,  112,   32,   33,   34,   63,   21,   22,
  287,  288,  289,   54,   55,  300,   80,   49,   50,   51,
  129,  298,  299,  311,  312,  287,  288,  289,  257,  266,
  267,  268,  269,  270,  271,  311,  298,  299,  275,   27,
   28,   97,  258,   99,  276,  277,  278,  279,  315,  300,
  301,  302,  303,  304,  305,  306,  307,   49,   50,   51,
  265,  311,  310,  259,  311,  311,  311,  260,  280,  311,
  265,  260,  311,  261,  308,  311,  262,  264,  311,  309,
  311,  263,  261,  264,  311,  311,  258,  260,  263,   64,
   99,  120,  111,   43,   62,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,  287,  288,  289,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,  298,  299,
};
#define YYFINAL 3
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
#define YYMAXTOKEN 315
#if YYDEBUG
const char * const yyname[] = {
"end-of-file",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"SEMICOLON","LPAREN","RPAREN",
"LANGLE","RANGLE","LCURLY","RCURLY","COMMA","DOT","TYPE_UD","TYPE_D","TYPE_UW",
"TYPE_W","TYPE_UB","TYPE_B","TYPE_VF","TYPE_HF","TYPE_V","TYPE_F","ALIGN1",
"ALIGN16","MASK_DISABLE","EOT","GENREG","MSGREG","ACCREG","ADDRESSREG",
"FLAGREG","CONTROLREG","IPREG","MOV","MUL","MAC","MACH","LINE","SAD2","SADA2",
"DP4","DPH","DP3","DP2","ADD","SEND","NULL_TOKEN","MATH","SAMPLER","GATEWAY",
"READ","WRITE","URB","THREAD_SPAWNER","MSGLEN","RETURNLEN","SATURATE","INTEGER",
"NUMBER","flagreg","maskreg","NOP",
};
const char * const yyrule[] = {
"$accept : ROOT",
"ROOT : instrseq",
"instrseq : instruction SEMICOLON instrseq",
"instrseq : instruction SEMICOLON",
"instrseq : error SEMICOLON instrseq",
"instruction : unaryinstruction",
"instruction : binaryinstruction",
"instruction : binaryaccinstruction",
"instruction : triinstruction",
"instruction : specialinstruction",
"unaryinstruction : predicate unaryop conditionalmodifier saturate execsize dst srcaccimm instoptions",
"unaryop : MOV",
"binaryinstruction : predicate binaryop conditionalmodifier saturate execsize dst src srcimm instoptions",
"binaryop : MUL",
"binaryop : MAC",
"binaryaccinstruction : predicate binaryaccop conditionalmodifier saturate execsize dst srcacc srcimm instoptions",
"binaryaccop : ADD",
"triinstruction : sendinstruction",
"sendinstruction : predicate SEND INTEGER execsize dst payload msgtarget MSGLEN INTEGER RETURNLEN INTEGER instoptions",
"specialinstruction : NOP",
"payload : directsrcoperand",
"msgtarget : NULL_TOKEN",
"msgtarget : SAMPLER",
"msgtarget : MATH",
"msgtarget : GATEWAY",
"msgtarget : READ",
"msgtarget : WRITE",
"msgtarget : URB",
"msgtarget : THREAD_SPAWNER",
"dst : dstoperand",
"dst : dstoperandex",
"dstoperand : dstreg dstregion regtype",
"dstoperandex : accreg dstregion regtype",
"dstoperandex : nullreg",
"dstreg : directgenreg",
"dstreg : directmsgreg",
"srcaccimm : srcacc",
"srcaccimm : imm32 srcimmtype",
"srcacc : directsrcaccoperand",
"srcimm : directsrcoperand",
"srcimm : imm32 srcimmtype",
"directsrcaccoperand : directsrcoperand",
"src : directsrcoperand",
"directsrcoperand : directgenreg region regtype",
"subregnum : DOT INTEGER",
"subregnum :",
"directgenreg : GENREG INTEGER subregnum",
"directmsgreg : MSGREG INTEGER subregnum",
"accreg : ACCREG INTEGER subregnum",
"addrreg : ADDRESSREG INTEGER subregnum",
"nullreg : NULL_TOKEN",
"dstregion : LANGLE INTEGER RANGLE",
"region : LANGLE INTEGER COMMA INTEGER COMMA INTEGER RANGLE",
"regtype : TYPE_F",
"regtype : TYPE_UD",
"regtype : TYPE_D",
"regtype : TYPE_UW",
"regtype : TYPE_W",
"regtype : TYPE_UB",
"regtype : TYPE_B",
"srcimmtype : regtype",
"imm32 : INTEGER",
"imm32 : NUMBER",
"predicate :",
"execsize : LPAREN INTEGER RPAREN",
"saturate :",
"saturate : DOT SATURATE",
"conditionalmodifier :",
"instoptions : LCURLY instoption_list RCURLY",
"instoption_list : instoption instoption_list",
"instoption_list :",
"instoption : ALIGN1",
"instoption : ALIGN16",
"instoption : MASK_DISABLE",
"instoption : EOT",
};
#endif
#if YYDEBUG
#include <stdio.h>
#endif
#ifdef YYSTACKSIZE
#undef YYMAXDEPTH
#define YYMAXDEPTH YYSTACKSIZE
#else
#ifdef YYMAXDEPTH
#define YYSTACKSIZE YYMAXDEPTH
#else
#define YYSTACKSIZE 10000
#define YYMAXDEPTH 10000
#endif
#endif
#define YYINITSTACKSIZE 200
int yydebug;
int yynerrs;
int yyerrflag;
int yychar;
short *yyssp;
YYSTYPE *yyvsp;
YYSTYPE yyval;
YYSTYPE yylval;
short *yyss;
short *yysslim;
YYSTYPE *yyvs;
int yystacksize;
#line 470 "gram.y"
extern int yylineno;

void yyerror (char *msg)
{
	fprintf(stderr, "parse error \"%s\" at line %d, token \"%s\"\n",
		msg, yylineno, lex_text());
}

#line 415 "y.tab.c"
/* allocate initial stack or double stack size, up to YYMAXDEPTH */
static int yygrowstack()
{
    int newsize, i;
    short *newss;
    YYSTYPE *newvs;

    if ((newsize = yystacksize) == 0)
        newsize = YYINITSTACKSIZE;
    else if (newsize >= YYMAXDEPTH)
        return -1;
    else if ((newsize *= 2) > YYMAXDEPTH)
        newsize = YYMAXDEPTH;
    i = yyssp - yyss;
    newss = yyss ? (short *)realloc(yyss, newsize * sizeof *newss) :
      (short *)malloc(newsize * sizeof *newss);
    if (newss == NULL)
        return -1;
    yyss = newss;
    yyssp = newss + i;
    newvs = yyvs ? (YYSTYPE *)realloc(yyvs, newsize * sizeof *newvs) :
      (YYSTYPE *)malloc(newsize * sizeof *newvs);
    if (newvs == NULL)
        return -1;
    yyvs = newvs;
    yyvsp = newvs + i;
    yystacksize = newsize;
    yysslim = yyss + newsize - 1;
    return 0;
}

#define YYABORT goto yyabort
#define YYREJECT goto yyabort
#define YYACCEPT goto yyaccept
#define YYERROR goto yyerrlab

#ifndef YYPARSE_PARAM
#if defined(__cplusplus) || __STDC__
#define YYPARSE_PARAM_ARG void
#define YYPARSE_PARAM_DECL
#else	/* ! ANSI-C/C++ */
#define YYPARSE_PARAM_ARG
#define YYPARSE_PARAM_DECL
#endif	/* ANSI-C/C++ */
#else	/* YYPARSE_PARAM */
#ifndef YYPARSE_PARAM_TYPE
#define YYPARSE_PARAM_TYPE void *
#endif
#if defined(__cplusplus) || __STDC__
#define YYPARSE_PARAM_ARG YYPARSE_PARAM_TYPE YYPARSE_PARAM
#define YYPARSE_PARAM_DECL
#else	/* ! ANSI-C/C++ */
#define YYPARSE_PARAM_ARG YYPARSE_PARAM
#define YYPARSE_PARAM_DECL YYPARSE_PARAM_TYPE YYPARSE_PARAM;
#endif	/* ANSI-C/C++ */
#endif	/* ! YYPARSE_PARAM */

int
yyparse (YYPARSE_PARAM_ARG)
    YYPARSE_PARAM_DECL
{
    int yym, yyn, yystate;
#if YYDEBUG
    const char *yys;

    if ((yys = getenv("YYDEBUG")))
    {
        yyn = *yys;
        if (yyn >= '0' && yyn <= '9')
            yydebug = yyn - '0';
    }
#endif

    yynerrs = 0;
    yyerrflag = 0;
    yychar = (-1);

    if (yyss == NULL && yygrowstack()) goto yyoverflow;
    yyssp = yyss;
    yyvsp = yyvs;
    *yyssp = yystate = 0;

yyloop:
    if ((yyn = yydefred[yystate])) goto yyreduce;
    if (yychar < 0)
    {
        if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, reading %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
    }
    if ((yyn = yysindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: state %d, shifting to state %d\n",
                    YYPREFIX, yystate, yytable[yyn]);
#endif
        if (yyssp >= yysslim && yygrowstack())
        {
            goto yyoverflow;
        }
        *++yyssp = yystate = yytable[yyn];
        *++yyvsp = yylval;
        yychar = (-1);
        if (yyerrflag > 0)  --yyerrflag;
        goto yyloop;
    }
    if ((yyn = yyrindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
        yyn = yytable[yyn];
        goto yyreduce;
    }
    if (yyerrflag) goto yyinrecovery;
#if defined(lint) || defined(__GNUC__)
    goto yynewerror;
#endif
yynewerror:
    yyerror("syntax error");
#if defined(lint) || defined(__GNUC__)
    goto yyerrlab;
#endif
yyerrlab:
    ++yynerrs;
yyinrecovery:
    if (yyerrflag < 3)
    {
        yyerrflag = 3;
        for (;;)
        {
            if ((yyn = yysindex[*yyssp]) && (yyn += YYERRCODE) >= 0 &&
                    yyn <= YYTABLESIZE && yycheck[yyn] == YYERRCODE)
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: state %d, error recovery shifting\
 to state %d\n", YYPREFIX, *yyssp, yytable[yyn]);
#endif
                if (yyssp >= yysslim && yygrowstack())
                {
                    goto yyoverflow;
                }
                *++yyssp = yystate = yytable[yyn];
                *++yyvsp = yylval;
                goto yyloop;
            }
            else
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: error recovery discarding state %d\n",
                            YYPREFIX, *yyssp);
#endif
                if (yyssp <= yyss) goto yyabort;
                --yyssp;
                --yyvsp;
            }
        }
    }
    else
    {
        if (yychar == 0) goto yyabort;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, error recovery discards token %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
        yychar = (-1);
        goto yyloop;
    }
yyreduce:
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: state %d, reducing by rule %d (%s)\n",
                YYPREFIX, yystate, yyn, yyrule[yyn]);
#endif
    yym = yylen[yyn];
    yyval = yyvsp[1-yym];
    switch (yyn)
    {
case 1:
#line 97 "gram.y"
{
		  compiled_program = yyvsp[0].program;
		}
break;
case 2:
#line 103 "gram.y"
{
		  struct brw_program_instruction *list_entry =
		    calloc(sizeof(struct brw_program_instruction), 1);
		  list_entry->instruction = yyvsp[-2].instruction;

		  list_entry->next = yyvsp[0].program.first;
		  yyvsp[0].program.first = list_entry;

		  yyval.program = yyvsp[0].program;
		}
break;
case 3:
#line 114 "gram.y"
{
		  struct brw_program_instruction *list_entry =
		    calloc(sizeof(struct brw_program_instruction), 1);
		  list_entry->instruction = yyvsp[-1].instruction;

		  list_entry->next = NULL;

		  yyval.program.first = list_entry;
		}
break;
case 4:
#line 124 "gram.y"
{
		  yyval.program = yyvsp[0].program;
		}
break;
case 10:
#line 140 "gram.y"
{
		  yyval.instruction.header.opcode = yyvsp[-6].integer;
		  yyval.instruction.header.saturate = yyvsp[-5].integer;
		  yyval.instruction.header.destreg__conditionalmod = yyvsp[-4].integer;
		  yyval.instruction.header.execution_size = yyvsp[-3].integer;
		  yyval.instruction.bits1 = yyvsp[-1].instruction.bits1;
		  /* XXX: more */
		}
break;
case 11:
#line 150 "gram.y"
{ yyval.integer = BRW_OPCODE_MOV; }
break;
case 12:
#line 156 "gram.y"
{
		  yyval.instruction.header.opcode = yyvsp[-7].integer;
		  yyval.instruction.header.saturate = yyvsp[-6].integer;
		  yyval.instruction.header.destreg__conditionalmod = yyvsp[-5].integer;
		  yyval.instruction.header.execution_size = yyvsp[-4].integer;
		  /* XXX: more */
		}
break;
case 13:
#line 165 "gram.y"
{ yyval.integer = BRW_OPCODE_MUL; }
break;
case 14:
#line 166 "gram.y"
{ yyval.integer = BRW_OPCODE_MAC; }
break;
case 15:
#line 171 "gram.y"
{
		  yyval.instruction.header.opcode = yyvsp[-7].integer;
		  yyval.instruction.header.saturate = yyvsp[-6].integer;
		  yyval.instruction.header.destreg__conditionalmod = yyvsp[-5].integer;
		  yyval.instruction.header.execution_size = yyvsp[-4].integer;
		}
break;
case 16:
#line 179 "gram.y"
{ yyval.integer = BRW_OPCODE_ADD; }
break;
case 18:
#line 187 "gram.y"
{
		  yyval.instruction.header.opcode = BRW_OPCODE_SEND;
		  yyval.instruction.header.execution_size = yyvsp[-8].integer;
		  yyval.instruction.header.destreg__conditionalmod = yyvsp[-9].integer;
		}
break;
case 19:
#line 194 "gram.y"
{
		  yyval.instruction.header.opcode = BRW_OPCODE_NOP;
		}
break;
case 21:
#line 202 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_NULL; }
break;
case 22:
#line 203 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_SAMPLER; }
break;
case 23:
#line 204 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_MATH; }
break;
case 24:
#line 205 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_GATEWAY; }
break;
case 25:
#line 206 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_DATAPORT_READ; }
break;
case 26:
#line 207 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_DATAPORT_WRITE; }
break;
case 27:
#line 208 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_URB; }
break;
case 28:
#line 209 "gram.y"
{ yyval.integer = BRW_MESSAGE_TARGET_THREAD_SPAWNER; }
break;
case 31:
#line 218 "gram.y"
{
		  /* Returns an instruction with just the destination register
		   * filled in.
		   */
		  yyval.instruction.bits1 = yyvsp[-2].instruction.bits1;
		  yyval.instruction.bits1.da1.dest_reg_type = yyvsp[-1].integer; /* XXX */
		  /* XXX: $3 */
		}
break;
case 32:
#line 229 "gram.y"
{
		  /* Returns an instruction with just the destination register
		   * filled in.
		   */
		  yyval.instruction.bits1.da1.dest_reg_file = yyvsp[-2].direct_gen_reg.reg_file;
		  yyval.instruction.bits1.da1.dest_reg_nr = yyvsp[-2].direct_gen_reg.reg_nr;
		  yyval.instruction.bits1.da1.dest_subreg_nr = yyvsp[-2].direct_gen_reg.subreg_nr;
		  /* XXX: $2 $3 */
		}
break;
case 33:
#line 239 "gram.y"
{
		  /* Returns an instruction with just the destination register
		   * filled in.
		   */
		  yyval.instruction.bits1.da1.dest_reg_file = yyvsp[0].direct_gen_reg.reg_file;
		  yyval.instruction.bits1.da1.dest_reg_nr = yyvsp[0].direct_gen_reg.reg_nr;
		  yyval.instruction.bits1.da1.dest_subreg_nr = yyvsp[0].direct_gen_reg.subreg_nr;
		}
break;
case 34:
#line 251 "gram.y"
{
		  yyval.instruction.bits1.da1.dest_reg_file = yyvsp[0].direct_gen_reg.reg_file;
		  yyval.instruction.bits1.da1.dest_reg_nr = yyvsp[0].direct_gen_reg.reg_nr;
		  yyval.instruction.bits1.da1.dest_subreg_nr = yyvsp[0].direct_gen_reg.subreg_nr;
		}
break;
case 37:
#line 263 "gram.y"
{
		  yyval.instruction.bits1.da1.src0_reg_file = BRW_IMMEDIATE_VALUE;
		  switch (yyvsp[0].integer) {
		  case BRW_REGISTER_TYPE_UD:
		    yyval.instruction.bits3.ud = yyvsp[-1].imm32;
		    break;
		  case BRW_REGISTER_TYPE_D:
		    yyval.instruction.bits3.id = yyvsp[-1].imm32;
		    break;
		  case BRW_REGISTER_TYPE_F:
		    yyval.instruction.bits3.fd = yyvsp[-1].imm32;
		    break;
		  }
		}
break;
case 40:
#line 285 "gram.y"
{
		  yyval.instruction.bits1.da1.src0_reg_file = BRW_IMMEDIATE_VALUE;
		  switch (yyvsp[0].integer) {
		  case BRW_REGISTER_TYPE_UD:
		    yyval.instruction.bits3.ud = yyvsp[-1].imm32;
		    break;
		  case BRW_REGISTER_TYPE_D:
		    yyval.instruction.bits3.id = yyvsp[-1].imm32;
		    break;
		  case BRW_REGISTER_TYPE_F:
		    yyval.instruction.bits3.fd = yyvsp[-1].imm32;
		    break;
		  }
		}
break;
case 43:
#line 311 "gram.y"
{
		  /* Returns a source operand in the src0 fields of an
		   * instruction.
		   */
		  yyval.instruction.bits1.da1.src0_reg_file = yyvsp[-2].direct_gen_reg.reg_file;
		  yyval.instruction.bits1.da1.src0_reg_type = yyvsp[0].integer;
		  yyval.instruction.bits2.da1.src0_subreg_nr = yyvsp[-2].direct_gen_reg.subreg_nr;
		  yyval.instruction.bits2.da1.src0_reg_nr = yyvsp[-2].direct_gen_reg.reg_nr;
		  yyval.instruction.bits2.da1.src0_vert_stride = yyvsp[-1].region.vert_stride;
		  yyval.instruction.bits2.da1.src0_width = yyvsp[-1].region.width;
		  yyval.instruction.bits2.da1.src0_horiz_stride = yyvsp[-1].region.horiz_stride;
		}
break;
case 44:
#line 326 "gram.y"
{
		  yyval.integer = yyvsp[0].integer;
		}
break;
case 45:
#line 330 "gram.y"
{
		  /* Default to subreg 0 if unspecified. */
		  yyval.integer = 0;
		}
break;
case 46:
#line 338 "gram.y"
{
		  /* Returns an instruction with just the destination register
		   * fields filled in.
		   */
		  yyval.direct_gen_reg.reg_file = BRW_GENERAL_REGISTER_FILE;
		  yyval.direct_gen_reg.reg_nr = yyvsp[-1].integer;
		  yyval.direct_gen_reg.subreg_nr = yyvsp[0].integer;
		}
break;
case 47:
#line 348 "gram.y"
{
		  /* Returns an instruction with just the destination register
		   * fields filled in.
		   */
		  yyval.direct_gen_reg.reg_file = BRW_GENERAL_REGISTER_FILE;
		  yyval.direct_gen_reg.reg_nr = yyvsp[-1].integer;
		  yyval.direct_gen_reg.subreg_nr = yyvsp[0].integer;
		}
break;
case 48:
#line 359 "gram.y"
{
		  /* Returns an instruction with just the destination register
		   * fields filled in.
		   */
		  yyval.direct_gen_reg.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  yyval.direct_gen_reg.reg_nr = BRW_ARF_ACCUMULATOR | yyvsp[-1].integer;
		  yyval.direct_gen_reg.subreg_nr = yyvsp[0].integer;
		}
break;
case 49:
#line 370 "gram.y"
{
		  /* Returns an instruction with just the destination register
		   * fields filled in.
		   */
		  yyval.direct_gen_reg.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  yyval.direct_gen_reg.reg_nr = BRW_ARF_ADDRESS | yyvsp[-1].integer;
		  yyval.direct_gen_reg.subreg_nr = yyvsp[0].integer;
		}
break;
case 50:
#line 381 "gram.y"
{
		  yyval.direct_gen_reg.reg_file = BRW_ARCHITECTURE_REGISTER_FILE;
		  yyval.direct_gen_reg.reg_nr = BRW_ARF_NULL;
		  yyval.direct_gen_reg.subreg_nr = 0;
		}
break;
case 51:
#line 390 "gram.y"
{
		  /* Returns a value for a horiz_stride field of an
		   * instruction.
		   */
		  if (yyvsp[-1].integer != 1 && yyvsp[-1].integer != 2 && yyvsp[-1].integer != 4) {
		    fprintf(stderr, "Invalid horiz size %d\n", yyvsp[-1].integer);
		  }
		  yyval.integer = ffs(yyvsp[-1].integer);
		}
break;
case 52:
#line 402 "gram.y"
{
		  yyval.region.vert_stride = yyvsp[-5].integer;
		  yyval.region.width = yyvsp[-3].integer;
		  yyval.region.horiz_stride = yyvsp[-1].integer;
		}
break;
case 53:
#line 414 "gram.y"
{ yyval.integer = BRW_REGISTER_TYPE_F; }
break;
case 54:
#line 415 "gram.y"
{ yyval.integer = BRW_REGISTER_TYPE_UD; }
break;
case 55:
#line 416 "gram.y"
{ yyval.integer = BRW_REGISTER_TYPE_D; }
break;
case 56:
#line 417 "gram.y"
{ yyval.integer = BRW_REGISTER_TYPE_UW; }
break;
case 57:
#line 418 "gram.y"
{ yyval.integer = BRW_REGISTER_TYPE_UW; }
break;
case 58:
#line 419 "gram.y"
{ yyval.integer = BRW_REGISTER_TYPE_UB; }
break;
case 59:
#line 420 "gram.y"
{ yyval.integer = BRW_REGISTER_TYPE_B; }
break;
case 64:
#line 433 "gram.y"
{
		  /* Returns a value for the execution_size field of an
		   * instruction.
		   */
		  if (yyvsp[-1].integer != 1 && yyvsp[-1].integer != 2 && yyvsp[-1].integer != 4 && yyvsp[-1].integer != 8 && yyvsp[-1].integer != 16 &&
		      yyvsp[-1].integer != 32) {
		    fprintf(stderr, "Invalid execution size %d\n", yyvsp[-1].integer);
		    YYERROR;
		  }
		  yyval.integer = ffs(yyvsp[-1].integer);
		}
break;
case 65:
#line 446 "gram.y"
{ yyval.integer = 0; }
break;
case 66:
#line 447 "gram.y"
{ yyval.integer = 1; }
break;
case 68:
#line 456 "gram.y"
{ yyval.instruction = yyvsp[-1].instruction; }
break;
#line 969 "y.tab.c"
    }
    yyssp -= yym;
    yystate = *yyssp;
    yyvsp -= yym;
    yym = yylhs[yyn];
    if (yystate == 0 && yym == 0)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: after reduction, shifting from state 0 to\
 state %d\n", YYPREFIX, YYFINAL);
#endif
        yystate = YYFINAL;
        *++yyssp = YYFINAL;
        *++yyvsp = yyval;
        if (yychar < 0)
        {
            if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
            if (yydebug)
            {
                yys = 0;
                if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
                if (!yys) yys = "illegal-symbol";
                printf("%sdebug: state %d, reading %d (%s)\n",
                        YYPREFIX, YYFINAL, yychar, yys);
            }
#endif
        }
        if (yychar == 0) goto yyaccept;
        goto yyloop;
    }
    if ((yyn = yygindex[yym]) && (yyn += yystate) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yystate)
        yystate = yytable[yyn];
    else
        yystate = yydgoto[yym];
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: after reduction, shifting from state %d \
to state %d\n", YYPREFIX, *yyssp, yystate);
#endif
    if (yyssp >= yysslim && yygrowstack())
    {
        goto yyoverflow;
    }
    *++yyssp = yystate;
    *++yyvsp = yyval;
    goto yyloop;
yyoverflow:
    yyerror("yacc stack overflow");
yyabort:
    return (1);
yyaccept:
    return (0);
}
