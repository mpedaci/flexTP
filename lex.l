%{
#include <stdio.h>
int total = 0;
int numberValue = 0;
%}

number [0-9]

%%
{number} {numberValue = 10 * numberValue + atoi(yytext);}
\+ {total += numberValue; numberValue = 0;}
\n {total += numberValue;printf("%d\n",total);printf("Done!");}
%%

int yywrap(){return 1;}

int main(){
    yylex();
}
