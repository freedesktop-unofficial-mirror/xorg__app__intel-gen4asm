/* -*- c-basic-offset: 8 -*- */
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
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <unistd.h>

#include "gen4asm.h"

extern FILE *yyin;

extern int errors;

long int gen_level = 4;
int advanced_flag = 0; /* 0: in unit of byte, 1: in unit of data element size */
int binary_like_output = 0; /* 0: default output style, 1: nice C-style output */
int need_export = 0;
char *input_filename = "<stdin>";
char *export_filename = NULL;

const char const *binary_prepend = "static const char gen_eu_bytes[] = {\n";

struct brw_program compiled_program;
struct program_defaults program_defaults = {.register_type = BRW_REGISTER_TYPE_F};

#define HASH_SIZE 37

struct hash_item {
	char *key;
	void *value;
	struct hash_item *next;
};

typedef struct hash_item *hash_table[HASH_SIZE];

static hash_table declared_register_table;

struct label_item {
	char *name;
	int addr;
	struct label_item *next;
};
static struct label_item *label_table;

static const struct option longopts[] = {
	{"advanced", no_argument, 0, 'a'},
	{"binary", no_argument, 0, 'b'},
	{"export", required_argument, 0, 'e'},
	{"input_list", required_argument, 0, 'l'},
	{"output", required_argument, 0, 'o'},
	{"gen", required_argument, 0, 'g'},
	{ NULL, 0, NULL, 0 }
};

// jump distance used in branch instructions as JIP or UIP
static int jump_distance(int offset)
{
    // Gen4- bspec: the jump distance is in number of sixteen-byte units
    // Gen5+ bspec: the jump distance is in number of eight-byte units
    if(gen_level >= 5)
        offset *= 2;
    return offset;
}

static void usage(void)
{
	fprintf(stderr, "usage: intel-gen4asm [options] inputfile\n");
	fprintf(stderr, "OPTIONS:\n");
	fprintf(stderr, "\t-a, --advanced                       Set advanced flag\n");
	fprintf(stderr, "\t-b, --binary                         C style binary output\n");
	fprintf(stderr, "\t-e, --export {exportfile}            Export label file\n");
	fprintf(stderr, "\t-l, --input_list {entrytablefile}    Input entry_table_list file\n");
	fprintf(stderr, "\t-o, --output {outputfile}            Specify output file\n");
	fprintf(stderr, "\t-g, --gen <4|5|6|7>                  Specify GPU generation\n");
}

static int hash(char *key)
{
    unsigned ret = 0;
    while(*key)
        ret = (ret << 1) + (*key++);
    return ret % HASH_SIZE;
}

static void *find_hash_item(hash_table t, char *key)
{
    struct hash_item *p;
    for(p = t[hash(key)]; p; p = p->next)
	if(strcasecmp(p->key, key) == 0)
	    return p->value;
    return NULL;
}

static void insert_hash_item(hash_table t, char *key, void *v)
{
    int index = hash(key);
    struct hash_item *p = malloc(sizeof(*p));
    p->key = key;
    p->value = v;
    p->next = t[index];
    t[index] = p;
}

static void free_hash_table(hash_table t)
{
    struct hash_item *p, *next;
    int i;
    for (i = 0; i < HASH_SIZE; i++) {
	p = t[i];
	while(p) {
	    next = p->next;
	    free(p->key);
	    free(p->value);
	    free(p);
	    p = next;
	}
    }
}

struct declared_register *find_register(char *name)
{
    return find_hash_item(declared_register_table, name);
}

void insert_register(struct declared_register *reg)
{
    insert_hash_item(declared_register_table, reg->name, reg);
}

void add_label(char *name, int addr)
{
    struct label_item **p = &label_table;
    while(*p)
        p = &((*p)->next);
    *p = calloc(1, sizeof(**p));
    (*p)->name = name;
    (*p)->addr = addr;
}

/* Some assembly code have duplicated labels.
   Start from start_addr. Search as a loop. Return the first label found. */
int label_to_addr(char *name, int start_addr)
{
    /* return the first label just after start_addr, or the first label from the head */
    struct label_item *p;
    int r = -1;
    for(p = label_table; p; p = p->next) {
        if(strcmp(p->name, name) == 0) {
            if(p->addr >= start_addr) // the first label just after start_addr
                return p->addr;
            else if(r == -1) // the first label from the head
                r = p->addr;
        }
    }
    if(r == -1) {
        fprintf(stderr, "Can't find label %s\n", name);
        exit(1);
    }
    return r;
}

static void free_label_table(struct label_item *p)
{
    if(p) {
        free_label_table(p->next);
        free(p);
    }
}

struct entry_point_item {
	char *str;
	struct entry_point_item *next;
} *entry_point_table;

static int read_entry_file(char *fn)
{
	FILE *entry_table_file;
	char buf[2048];
	struct entry_point_item **p = &entry_point_table;
	if (!fn)
		return 0;
	if ((entry_table_file = fopen(fn, "r")) == NULL)
		return -1;
	while (fgets(buf, sizeof(buf)-1, entry_table_file) != NULL) {
		// drop the final char '\n'
		if(buf[strlen(buf)-1] == '\n')
			buf[strlen(buf)-1] = 0;
		*p = calloc(1, sizeof(struct entry_point_item));
		(*p)->str = strdup(buf);
		p = &((*p)->next);
	}
	fclose(entry_table_file);
	return 0;
}

static int is_entry_point(char *s)
{
	struct entry_point_item *p;
	for (p = entry_point_table; p; p = p->next) {
	    if (strcmp(p->str, s) == 0)
		return 1;
	}
	return 0;
}

static void free_entry_point_table(struct entry_point_item *p) {
	if (p) {
		free_entry_point_table(p->next);
		free(p->str);
		free(p);
	}
}

static void
print_instruction(FILE *output, struct brw_program_instruction *entry)
{
	if (binary_like_output) {
		fprintf(output, "\t0x%02x, 0x%02x, 0x%02x, 0x%02x, "
				"0x%02x, 0x%02x, 0x%02x, 0x%02x,\n"
				"\t0x%02x, 0x%02x, 0x%02x, 0x%02x, "
				"0x%02x, 0x%02x, 0x%02x, 0x%02x,\n",
			((unsigned char *)(&entry->instruction))[0],
			((unsigned char *)(&entry->instruction))[1],
			((unsigned char *)(&entry->instruction))[2],
			((unsigned char *)(&entry->instruction))[3],
			((unsigned char *)(&entry->instruction))[4],
			((unsigned char *)(&entry->instruction))[5],
			((unsigned char *)(&entry->instruction))[6],
			((unsigned char *)(&entry->instruction))[7],
			((unsigned char *)(&entry->instruction))[8],
			((unsigned char *)(&entry->instruction))[9],
			((unsigned char *)(&entry->instruction))[10],
			((unsigned char *)(&entry->instruction))[11],
			((unsigned char *)(&entry->instruction))[12],
			((unsigned char *)(&entry->instruction))[13],
			((unsigned char *)(&entry->instruction))[14],
			((unsigned char *)(&entry->instruction))[15]);
	} else {
		fprintf(output, "   { 0x%08x, 0x%08x, 0x%08x, 0x%08x },\n",
			((int *)(&entry->instruction))[0],
			((int *)(&entry->instruction))[1],
			((int *)(&entry->instruction))[2],
			((int *)(&entry->instruction))[3]);
	}
}
int main(int argc, char **argv)
{
	char *output_file = NULL;
	char *entry_table_file = NULL;
	FILE *output = stdout;
	FILE *export_file;
	struct brw_program_instruction *entry, *entry1, *tmp_entry;
	int err, inst_offset;
	char o;
	while ((o = getopt_long(argc, argv, "e:l:o:g:ab", longopts, NULL)) != -1) {
		switch (o) {
		case 'o':
			if (strcmp(optarg, "-") != 0)
				output_file = optarg;

			break;

		case 'g':
			gen_level = strtol(optarg, NULL, 0);

			if (gen_level < 4 || gen_level > 7) {
				usage();
				exit(1);
			}

			break;

		case 'a':
			advanced_flag = 1;
			break;
		case 'b':
			binary_like_output = 1;
			break;

		case 'e':
			need_export = 1;
			if (strcmp(optarg, "-") != 0)
				export_filename = optarg;
			break;

		case 'l':
			if (strcmp(optarg, "-") != 0)
				entry_table_file = optarg;
			break;

		default:
			usage();
			exit(1);
		}
	}
	argc -= optind;
	argv += optind;
	if (argc != 1) {
		usage();
		exit(1);
	}

	if (strcmp(argv[0], "-") != 0) {
		input_filename = argv[0];
		yyin = fopen(input_filename, "r");
		if (yyin == NULL) {
			perror("Couldn't open input file");
			exit(1);
		}
	}

	err = yyparse();

	if (strcmp(argv[0], "-"))
		fclose(yyin);

	yylex_destroy();

	if (err || errors)
		exit (1);

	if (output_file) {
		output = fopen(output_file, "w");
		if (output == NULL) {
			perror("Couldn't open output file");
			exit(1);
		}

	}

	if (read_entry_file(entry_table_file)) {
		fprintf(stderr, "Read entry file error\n");
		exit(1);
	}
	inst_offset = 0 ;
	for (entry = compiled_program.first;
		entry != NULL; entry = entry->next) {
	    entry->inst_offset = inst_offset;
	    entry1 = entry->next;
	    if (entry1 && entry1->islabel && is_entry_point(entry1->string)) {
		// insert NOP instructions until (inst_offset+1) % 4 == 0
		while (((inst_offset+1) % 4) != 0) {
		    tmp_entry = calloc(sizeof(*tmp_entry), 1);
		    tmp_entry->instruction.header.opcode = BRW_OPCODE_NOP;
		    entry->next = tmp_entry;
		    tmp_entry->next = entry1;
		    entry = tmp_entry;
		    tmp_entry->inst_offset = ++inst_offset;
		}
	    }
	    if (!entry->islabel)
              inst_offset++;
	}

	for (entry = compiled_program.first; entry; entry = entry->next)
	    if (entry->islabel)
		add_label(entry->string, entry->inst_offset);

	if (need_export) {
		if (export_filename) {
			export_file = fopen(export_filename, "w");
		} else {
			export_file = fopen("export.inc", "w");
		}
		for (entry = compiled_program.first;
			entry != NULL; entry = entry->next) {
		    if (entry->islabel) 
			fprintf(export_file, "#define %s_IP %d\n",
				entry->string, (gen_level == 5 ? 2 : 1)*(entry->inst_offset));
		}
		fclose(export_file);
	}

	for (entry = compiled_program.first; entry; entry = entry->next) {
	    struct brw_instruction *inst = & entry->instruction;

	    if (inst->first_reloc_target)
		inst->first_reloc_offset = label_to_addr(inst->first_reloc_target, entry->inst_offset) - entry->inst_offset;

	    if (inst->second_reloc_target)
		inst->second_reloc_offset = label_to_addr(inst->second_reloc_target, entry->inst_offset) - entry->inst_offset;

	    if (inst->second_reloc_offset) {
		// this is a branch instruction with two offset arguments
		entry->instruction.bits3.branch_2_offset.JIP = jump_distance(inst->first_reloc_offset);
		entry->instruction.bits3.branch_2_offset.UIP = jump_distance(inst->second_reloc_offset);
	    } else if (inst->first_reloc_offset) {
		// this is a branch instruction with one offset argument
		int offset = inst->first_reloc_offset;
		/* bspec: Unlike other flow control instructions, the offset used by JMPI is relative to the incremented instruction pointer rather than the IP value for the instruction itself. */
		if(entry->instruction.header.opcode == BRW_OPCODE_JMPI)
		    offset --;
		entry->instruction.bits3.JIP = jump_distance(offset);
		if(entry->instruction.header.opcode == BRW_OPCODE_ELSE)
		    entry->instruction.bits3.branch_2_offset.UIP = 1;
	    }
	}

	if (binary_like_output)
		fprintf(output, "%s", binary_prepend);

	for (entry = compiled_program.first;
		entry != NULL;
		entry = entry1) {
	    entry1 = entry->next;
	    if (!entry->islabel)
		print_instruction(output, entry);
	    else
		free(entry->string);
	    free(entry);
	}
	if (binary_like_output)
		fprintf(output, "};");

	free_entry_point_table(entry_point_table);
	free_hash_table(declared_register_table);
	free_label_table(label_table);

	fflush (output);
	if (ferror (output)) {
	    perror ("Could not flush output file");
	    if (output_file)
		unlink (output_file);
	    err = 1;
	}
	return err;
}
