/*
(c) Vasian CEPA, http://madebits.com
*/
%{

#include "cplx-bl.h"
#include "cplx.tab.h"

%}

number [0-9]+(\.[0-9]+)?((e|E)((\+)?|\-)[0-9]+)?

%%

[ \t]+				/* skip */

#.*\n				{ /* single line comment */ return '\n'; }

{number}			{ sscanf(yytext, "%lf", &yylval.val); return NUMBER; }

"i"|"j"|"I"|"J"			{ return ITAG; }

\"(.)*\"$			{
					int len = strlen(yytext);
					yylval.string = (char*)malloc(len - 1);
					if(yylval.string != NULL){
						*(yytext + len - 1) = '\0';
						strcpy(yylval.string, yytext + 1);
					}
					return STRING;
				}

[[:alpha:]][[:alnum:]]*		{ 
					SYMREC* sym = getsym(yytext);
					if(sym != (SYMREC*)0){
						switch(sym->type){
							case KEYWORD:
							case COMMAND:
								return sym->value.vint;
							case CONSTANT:
								yylval.complex = sym->value.vcomplex;
								return NUMBER;
							case FUNCTION:
								yylval.vint = sym->value.vint;
								return FUNC;
						}
					}
					yylval.string = (char*)malloc(strlen(yytext) + 1);
					if(yylval.string != NULL)
						strcpy(yylval.string, yytext);
					return VARNAME;
				}

\n|.				{ return (int)(yytext[0]); } /* return all other chars to parser */

<<EOF>>				{ yyterminate(); }


%%

int yywrap(){
	return 1;
}