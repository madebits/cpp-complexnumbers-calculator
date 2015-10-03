/*
(c) Vasian CEPA, http://madebits.com
*/
#include "cplx-b.h"

static void printShort(double);

/* global variables */
int verbose = 0;
int globalCount = 0;
int longPrint = 1;
SYMREC *sym_table = (SYMREC*)0;

/* ---------------------------------- */

double kfangle(double rDegree){
	double t = 2 * M_PI;
	if(rDegree > 0) while(rDegree > t) rDegree-=t;
	else while(rDegree < -t) rDegree+=t;
	return rDegree;
}

CPLX calc(OPTYPE op , CPLX z, CPLX v){
	CPLX t = {0.0, 0.0};
	double tt;
	switch(op){
		case ADD: t.r = z.r + v.r; t.i = z.i + v.i; break;
		case SUB: t.r = z.r - v.r; t.i = z.i - v.i; break;
		case MUL: t.r = z.r * v.r - z.i * v.i;
				  t.i = z.r * v.i + z.i * v.r;
				  break;
		case DIV: tt = v.r * v.r + v.i * v.i;
				  if(0.0 != tt){
				  	t.r = (z.r * v.r + z.i * v.i) / tt;
					t.i = (z.i * v.r - z.r * v.i) / tt;
				  }
				  break;
	}
	return t;
}

/* ---------------------------------- */

void printCplx(CPLX c){
	char *sign = ((c.i >= 0.0) ? "+" : "-");
	double i = fabs(c.i);
	if(!longPrint){
		printf("  ->   ");
		printShort(c.r);
		printf(" %s ", sign);
		printShort(i);
		printf("j\n");
	} else {
		char *formatReImgN  = "%16.10lf %s %16.10lfj";
		char *formatReImgS  = "%16.5e %s %16.5ej";
		char *formatModArgN = "%16.10lf, %16.10lf";
		char *formatModArgS = "%16.5e, %16.5e";
		double m = sqrt(c.r * c.r + c.i * c.i);
		double a = atan2(c.i, c.r);
		if(globalCount == 0)
			printf("  -> |  %-15s    %-15s  |  %-15s   %-15s\n", "Re", "Img", "Mod", "Arg");
		printf("%4d | ",(++globalCount));
		printf(formatReImgN, c.r, sign, i);
		printf(" | ");
		printf(formatModArgN, m, a);
		printf(" \n   s | ");
		printf(formatReImgS, c.r, sign, i);
		printf(" | ");
		printf(formatModArgS, m, a);
		printf("\n");
		if(9999 == globalCount) globalCount = 0;
	}
}

static void printShort(double d){
	double t = floor(d);
	if((d - t) == 0.0) printf("%ld", (long)d);
	else printf("%.15lf", d);
}

void printRule(char* f,...){
	int i = -1;
	char c = '\0';
	va_list list;
	if(!verbose) return;
	va_start(list, f);
	while((c = f[++i]) != '\0'){
		if('%' == c){
			char next = f[++i];
			if('r' == next) printf("# %-12s |", va_arg(list, char*));
			else if('s' == next) printf("%s", va_arg(list, char*));
			else if('c' == next) {
				CPLX c = va_arg(list, CPLX);
				printf("[%lf;%lf]", c.r, c.i);
			} else if('n' == next) printf("%lf", va_arg(list, double));
			else if('%' == next) printf("%");
			else {
				printf("!\n");
				return;
			}
		} else printf("%c", c);
	}
	va_end(list);
}

/* ---------------------------------- */

SYMREC *putsym(char *name, int type){
	SYMREC *temp;
	if(name == NULL) return 0;
	temp = (SYMREC*)malloc(sizeof(SYMREC));
	if(NULL == temp) return 0;
	temp->name = (char*)malloc(strlen(name) + 1);
	if(NULL == temp->name) {
		free(temp);
		return 0;
	}
	strcpy(temp->name, name);
	temp->type = type;
	temp->value.vcomplex.r = temp->value.vcomplex.i = 0.0;
	temp->next = (SYMREC*)sym_table;
	sym_table = temp;
	return temp;
}


SYMREC *getsym(char *name){
	SYMREC *temp;
	if(name == NULL) return 0;
	for(temp = sym_table; temp != (SYMREC*)0; temp = (SYMREC*)temp->next){
		if(0 == strcmp(temp->name, name)) return temp;
	}
	return 0;
}

void delsym(char *name){
	SYMREC *temp;
	SYMREC *previous = sym_table;
	for(temp = sym_table; temp != (SYMREC*)0; temp = (SYMREC*)temp->next){
		if(0 == strcmp(temp->name, name)) {
			if(VARIABLE != temp->type) return;
			if(temp == sym_table){
				sym_table = temp->next;
			} else {
				previous->next = temp->next;
			}
			free(temp->name);
			free(temp);
			return;
		}
		previous = temp;
	}
}

void list_table(){
	SYMREC *temp;
	for(temp = sym_table; temp != (SYMREC*)0; temp = (SYMREC*)temp->next){
		if(temp->type == VARIABLE){
			printf(" %-10s = [%lf;%lf]\n", temp->name,temp->value.vcomplex.r, temp->value.vcomplex.i);
		}
	}
}

void init_table(int size){
	int i;
	for(i = 1; i < size; i++){
		init[i].next = &init[i - 1];
	}
	sym_table = &(init[i - 1]);
	init_constants();
}

void init_constants(){
	SYMREC *temp;
	temp = getsym("pi");
	if(temp != (SYMREC*)0){
		temp->value.vcomplex.r = M_PI;
		temp->value.vcomplex.i = 0.0;
	}
	temp = getsym("e");
		if(temp != (SYMREC*)0){
			temp->value.vcomplex.r = M_E;
			temp->value.vcomplex.i = 0.0;
	}
}

void destroy_table(){
	SYMREC *temp;
	SYMREC *next = sym_table;
	for(temp = sym_table; next != (SYMREC*)0; temp = next){
		next = temp->next;
		if(VARIABLE != temp->type) break; /* contniue */
		free(temp->name);
		free(temp);
	}
}

/* ---------------------------------- */

CPLX re(CPLX c){
	CPLX t = {c.r, 0.0};
	return t;
}

CPLX im(CPLX c){
	CPLX t = {0.0, c.i};
	return t;
}

CPLX mod(CPLX c){
	CPLX t = {sqrt(c.r * c.r + c.i * c.i), 0.0};
	return t;
}

CPLX arg(CPLX c){
	CPLX t;
	t.r =  atan2(c.i, c.r); /* y,x */
	t.i = 0.0;
	return t;
}