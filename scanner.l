%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "y.tab.h"

    int yyparse();

    void errorLexico();
    void errorMaxLenChars();

    void copyToVal(char*, int);

%}

%option yylineno

identificador [a-zA-Z][a-zA-Z0-9]*
constante [0-9]+
espurio [ \t\n]+
operador [+-]

%%
"EOF"               {return FDT;}
{espurio}           {};
"inicio"            {return INICIO;}
"fin"               {return FIN;}
"escribir"          {return ESCRIBIR;}
"leer"              {return LEER;}
{identificador}     { copyToVal(yytext, 1); return IDENTIFICADOR; }
{constante}         { copyToVal(yytext, 2); return CONSTANTE; }
":="                {return ASIGNACION;}
";"                 {return PUNTOYCOMA;}
","                 {return COMA;}
"("                 {return PARENTESISIZQ;}
")"                 {return PARENTESISDER;}
{operador}          { copyToVal(yytext, 1); return OPERADOR; }
.                   {errorLexico();}

%%

int yywrap(){ return 1; }

void copyToVal(char *texto, int type){
    if (strlen(texto) > 31){
        errorMaxLenChars();
    }
    switch(type){
        case 1:
            strcpy(yylval.str_val, texto);
            break;
        case 2:
            yylval.int_val = atoi(texto);
            break;
    }
}

void errorMaxLenChars(){
    printf("Error: Se supero el maximo de caracteres permitidos en un identificador.\n");
    exit(0);
}

void errorLexico(){
    printf("Error Lexico: caracter %s invalido. En linea %d.\n", yytext, yylineno);
    exit(0);
}