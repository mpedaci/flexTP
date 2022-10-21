%{
#include <stdio.h>
#include "parser.tab.h"
int total = 0;
int numberValue = 0;
%}


number [0-9]

%%
{number}+ {yyval.num = atoi(yytext()); return NUMBER;}
\+ {return PLUS;}
\* {return MULT;}
\- {return MINUS;}
\/ {return DIV;}
\n {return EOL;}
%%

int yywrap(){return 1;}

int main(){
    yylex();
}
