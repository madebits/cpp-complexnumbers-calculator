CFILES = lex.yy.c cplx.tab.c cplx-b.c

cplx: $(CFILES)
	gcc $(CFILES) -o cplx.exe

lex.yy.c: fl cplx.tab.h cplx-bl.h
cplx.tab.c cplx.tab.h: bs

cplx.tab.c cplx-b.c: cplx-b.h
cplx.tab.c: cplx.help

fl: cplx.l
	flex cplx.l
	
bs: cplx.y
	bison -t cplx.y
