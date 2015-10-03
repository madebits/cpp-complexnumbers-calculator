/*
(c) Vasian CEPA, http://madebits.com
*/
#ifndef MY_CPLX_BL_H
#define MY_CPLX_BL_H

#include <stdio.h>
#include <string.h>

#define KEYWORD		3666
#define FUNCTION	3667
#define VARIABLE	3668
#define COMMAND		3669
#define CONSTANT	3670

typedef struct cplx{
	double r;
	double i;
}CPLX;

typedef struct symrec{
	char *name;
	int type;
	union {
		int vint;
		CPLX vcomplex;
		double vdouble;
	} value;
	struct symrec *next;
}SYMREC;

extern SYMREC *sym_table;
SYMREC *putsym(char*, int);
SYMREC *getsym(char*);
void delsym(char*);

#endif