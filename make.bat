@REM rd /s /q .\compiled\
bison -yd parser.y
flex scanner.l
mkdir compiled
gcc utils.c tablaSimbolos.c y.tab.c lex.yy.c -o compiled/program.exe
del lex.yy.c y.tab.c y.tab.h