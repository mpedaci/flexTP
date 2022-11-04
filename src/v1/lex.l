%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
int getIdentificador(char* texto);
void copyToVal(char* texto);
void copyToOp(char* texto);
char buff;
%}
%option yylineno

identificador [a-zA-z]([a-zA-Z]|[0-9])*
constante [1-9][0-9]+
operador [+-]
%%
{identificador} {copyToVal(yytext); return getIdentificador(yytext);}
{constante} {copyToVal(yytext); return CONSTANTE;}
":=" {return IGUAL;}
";" {return SEPARADOR;}
"," {return COMA;}
"(" {return PARENTESISIZQ;}
")" {return PARENTESISDER;}
{operador} {copyToOp(yytext); return OPERADOR;}
" " {}
"\n" {return FDT;}
. {return -1;} ;
%%

int yywrap(){return 1;}

int getIdentificador(char* texto){
    if (strcmp(texto,"leer") == 0) return LEER;
    else if (strcmp(texto,"escribir") == 0) return ESCRIBIR;
    else if (strcmp(texto, "inicio") == 0) return INICIO;
    else if (strcmp(texto, "fin") == 0) return FIN;
    else return IDENTIFICADOR;
}

void copyToVal(char* texto){
    int size = strlen(yylval.expression);
    if (strlen(texto) > size){
        free(yylval.expression);
        yylval.expression = malloc(size*2);
    }
    strcpy(yylval.expression,texto);
}

void copyToOp(char* texto){
    buff = texto[0];
}





