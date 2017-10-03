/*
(c) Vasian CEPA
*/
#ifndef MY_CPLX_B_H
#define MY_CPLX_B_H

#define _USE_MATH_DEFINES 1

#include <stdio.h>
#include <math.h>
#include <stdarg.h>
#include <malloc.h>

#include "cplx-bl.h"

#ifndef M_PI
#define M_PI	3.1415926535897932384626433832795
#endif
#ifndef M_E
#define M_E		2.71828182845904523536
#endif

void printCplx(CPLX);
void printRule(char*,...);
double kfangle(double);
void init_table(int);
void init_constants(void);

typedef enum{ADD, SUB, MUL, DIV}OPTYPE;

CPLX calc(OPTYPE, CPLX, CPLX);
CPLX re(CPLX);
CPLX im(CPLX);
CPLX mod(CPLX);
CPLX arg(CPLX);

/* global variables */
extern int verbose;
extern int globalCount;
extern int longPrint;
extern SYMREC init[];

extern int yylex(void);

#endif