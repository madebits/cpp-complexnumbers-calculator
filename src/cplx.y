/*
(c) Vasian CEPA, http://madebits.com
*/
%{

#include "cplx-b.h"
#define YYERROR_VERBOSE 1

void showHelp(void);
void showInternalHelp(void);
int nextHelpScreen(void);
void showAbout(void);

SYMREC init[] = {
		"set", 		KEYWORD, SET, (SYMREC*)0,
		"delete",	KEYWORD, DEL, (SYMREC*)0,
		"echo", 	KEYWORD, ECHO, (SYMREC*)0,
		"pi", 		CONSTANT, 0, (SYMREC*)0,
		"e", 		CONSTANT, 0, (SYMREC*)0,
		"re", 		FUNCTION, (int)re, (SYMREC*)0,
		"im", 		FUNCTION, (int)im, (SYMREC*)0,
		"arg", 		FUNCTION, (int)arg, (SYMREC*)0,
		"mod", 		FUNCTION, (int)mod, (SYMREC*)0,
		"list", 	COMMAND, LIST, (SYMREC*)0,
		"help", 	COMMAND, HELP, (SYMREC*)0,
		"quit", 	COMMAND, QUIT, (SYMREC*)0,
		"exit", 	COMMAND, QUIT, (SYMREC*)0,
		"q", 		COMMAND, QUIT, (SYMREC*)0,
		"print", 	COMMAND, PRINT, (SYMREC*)0,
		"about", 	COMMAND, ABOUT, (SYMREC*)0,
	};

#define PRINT_RULE(a) printRule("%r ", a)
#define NEXT_HELP_SCREEN() if(!nextHelpScreen()) return

%}

%union {
	int 	vint;
	char	*string;
	double 	val;
	CPLX 	complex;
}

%token <vint>	FUNC LIST HELP QUIT PRINT ABOUT
%token <vint>	ITAG SET DEL ECHO
%token <val>	NUMBER
%token <string>	VARNAME STRING
%type <val>	imag
%type <complex>	expr cplx
%left	'+' '-'
%left	','
%left	'*' '/'
%right	UMINUS

%%

lines :	lines stmt '\n'
	| lines '\n'
	| /* empty */	
	| error '\n' 	{ yyerrok;  }
	;

stmt : 	expr		{ printCplx($1); }
	| vardec		
	| vardel		
	| varecho		
	| command
	;

expr :	expr '+' expr		{ 
					$$ = calc(ADD, $1, $3);
					printRule("%r %c <= %c + %c\n", "E->E+E", $$, $1, $3);
				}
	| expr '-' expr		{
					$$ = calc(SUB, $1, $3);
					printRule("%r %c <= %c - %c\n", "E->E-E", $$, $1, $3);
				}
	| expr '*' expr		{ 
					$$ = calc(MUL, $1, $3);
					printRule("%r %c <= %c * %c\n", "E->E*E", $$, $1, $3);
				}
	| expr '/' expr		{ 
					double t = $3.r * $3.r + $3.i * $3.i;
					PRINT_RULE("E->E/E");
					if(0.0 == t){
						yyerror("divide by zero");
						YYERROR;
					}
					$$ = calc(DIV, $1, $3);
					printRule("%c <= %c / %c\n", $$, $1, $3);
				}
	| '(' expr ')'		{
					$$.r = $2.r; $$.i = $2.i;
					printRule("%r %c <= ( %c )\n", "E->(E)", $$, $2);
				}
	| '-' expr %prec UMINUS { 
					$$.r = -$2.r; $$.i = -$2.i;
					printRule("%r %c <= - %c\n", "E->-E", $$, $2);
				}
	| '+' expr		{ 
					$$.r = $2.r; $$.i = $2.i;
					printRule("%r %c <= + %c\n", "E->+E", $$, $2);
				}	
	| cplx			{ 
					$$.r = $1.r; $$.i = $1.i;
					printRule("%r %c <= %c\n", "E->C", $$, $1);
				}
	| VARNAME		{ 	
					SYMREC* sym = getsym($1);
					PRINT_RULE("E->V");
					if(sym != (SYMREC*)0){
						$$.r = sym->value.vcomplex.r;
						$$.i = sym->value.vcomplex.i;
					} else {
						printf("%s = ??? ", $1);
						yyerror("no such variable");
						free($1);
						YYERROR;
					}
					printRule("%c <= %s\n", $$, $1);
					free($1);
				}
	| FUNC '(' expr ')' 	{
					CPLX (*func)(CPLX) = (CPLX (*)(CPLX))$1;
					CPLX c = func($3);
					$$.r = c.r; $$.i = c.i;
					printRule("%r %c <= %c\n", "E->F(E)", $$, $3);
				}
	;

cplx : 	imag			{ 
					$$.r = 0.0; $$.i = $1;
					printRule("%r %c <= %n\n", "C->I", $$, $1);
				}
	| NUMBER		{ 
					$$.r = $1; $$.i = 0.0;
					printRule("%r %c <= %n\n", "C->R", $$, $1);
				}
	| NUMBER ',' NUMBER	{ 
					double arg = kfangle($3);
					$$.r = $1 * cos(arg); $$.i = $1 * sin(arg);
					printRule("%r %c <= %n , %n\n", "C->R,R", $$, $1, $3);
				}
	| NUMBER ',' '-' NUMBER	{ 
					double arg = kfangle(-$4);
					$$.r = $1 * cos(arg); $$.i = $1 * sin(arg);
					printRule("%r %c <= %n , - %n\n", "C->R,-R", $$, $1, $4);
				}
	| NUMBER ';' NUMBER	{
					$$.r = $1; $$.i = $3;
					printRule("%r %c <= %n ; %n\n", "C->R;R", $$, $1, $3);
				}
	| NUMBER ';' '-' NUMBER	{
					$$.r = $1; $$.i = -$4;
					printRule("%r %c <= %n ; - %n\n", "C->R;-R", $$, $1, $4);
				}
	;
	
imag :	ITAG NUMBER		{ 	
					$$ = $2;
					printRule("%r %n <= j %n\n", "I->IT R", $$, $2);
					
				}
	| NUMBER ITAG		{ 
					/* $$ = $1; */
					printRule("%r %n <= %n j\n", "I->R IT", $$, $1);
					
				}
	| ITAG			{ 	
					
					$$ = 1.0;
					printRule("%r %n <= j\n", "I->IT", $$);
				}	
	;

vardec : SET VARNAME '=' expr	{
					SYMREC* sym = getsym($2);
					printRule("%r %s <= %c\n", "SET V=E", $2, $4);
					if(sym == (SYMREC*)0){
						sym = putsym($2, VARIABLE);
						if(sym == (SYMREC*)0){
							free($2);
							printCplx($4);
							yyerror("out of memory");
							YYERROR;
						}
					}
					sym->value.vcomplex.r = $4.r;
					sym->value.vcomplex.i = $4.i;
					free($2);
				}
	;

vardel : DEL VARNAME		{
					printRule("%r %s\n", "DEL V", $2);
					delsym($2);
					free($2);
				}
	;

varecho : ECHO VARNAME		{ 	
					SYMREC* sym = getsym($2);
					printRule("%r %s\n", "ECHO V", $2);
					free($2);
					if(sym != (SYMREC*)0){
						printCplx(sym->value.vcomplex);
					} else {
						yyerror("no such variable");
						YYERROR;
					}
				}
	| ECHO STRING		{
					printRule("%r %s\n", "ECHO S", $2);
					printf("%s\n", $2);
					free($2);
				}
	;

command : LIST			{ list_table();	}
	| HELP			{ showInternalHelp(); }
	| QUIT			{ return 0; }
	| PRINT			{ 
					longPrint = (longPrint) ? 0 : 1;
					printf("# Result format set to %s!\n", (longPrint) ? "long": "short");
				}
	| ABOUT			{ showAbout(); }
	;

%%

int main(int argc, char** argv){
	int i, r;
	fprintf(stderr, "*** complex calculus calculator ***\n");
	fprintf(stderr, "(c) Vasian CEPA, http://madebits.com\n\n");
	for(i = 1; i < argc; i++){
		char *arg = argv[i];
		if('-' == arg[0]){
			char c = arg[1];	
			if('?' == c){
				showHelp();
				return 0;
			} else if('v' == c){ 
				verbose = 1;
			} else if('t' == c){
				yydebug = 1;
			}	
		} else {
			printf("Type -? for help.");
			return 1;
		}
	}
	init_table(sizeof(init)/sizeof(SYMREC));
	r = yyparse();
	destroy_table();
	return r;
}

int yyerror(char * err){
	printf("! Error: %s.\nType 'help' for syntax details or 'q' to quit!\n", err);
	return 0;
}

/* ---------------------------------- */

void showHelp(){
	puts("Usage: cplx [-? -v -t]");
	puts("\n\t-? this help\n");
	puts("\n\t-v verbose\n");
	puts("\n\t-t very verbose (same as bison -t) \n");
	puts("Use cplx < test.txt for batch mode");
}

void showInternalHelp(){
	puts("! *** cplx calculator ***");
	#include "cplx.help"
	puts("Done!");
}

int nextHelpScreen(){
	puts("Press 's' to stop or any other key to continue, ...");
	if(getch() == 's'){
		puts("Done!");
		return 0;
	}
	return 1;
}

void showAbout(void){
	puts("    ____   _____  _   _  _     ____");
	puts("   //  /  //  // //   \\ //    //  /");
	puts("  //     //__// //     //  o //");
	puts(" //___/ //     //___/ // \\  //___/");
 	puts("(c) Vasian CEPA, http://madebits.com");
 	puts("");
}