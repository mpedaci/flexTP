%{
#include <iostream>
#include "parser.tab.h"
    int yylex();
    void yyerror(const char*);
%}

%union{
    int number;
    char symbol;
}

%token EOL
%token PLUS
%token MINUS
%token MULT
%token DIV
%type<number> EXP MUEXP
%token<number> NUMBER

%%

input:
EXP EOL {printf("%d",$1);}
| EOL;

EXP : MUEXP PLUS EXP  {$$ = $1 + $3;}
    | MUEXP MINUS EXP {$$ = $1 - $3;}
    | MUEXP {$$ = $1;}
;

MUEXP : NUMBER MULT MUEXP {$$ = $1 * $3;}
    | NUMBER DIV MUEXP {$$ = $1 / $3;}
    | NUMBER {$$ = $1;}
;

%%

int main(){
    yyparse();
}
