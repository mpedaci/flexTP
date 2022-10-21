%{
    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>
    #define START_STRING "Comienzo de cadena"
    extern char* yytext;
    extern int yylex(void);
    extern int yyleng;
    void yyerror(const char*);
    void finalizarPrograma();
    void escribirExpresionAsignacion(char* identificador, char* expresion);
    void escribirExpresionEscribir(char* listaIdentificadores);
    void escribirExpresionLeer(char* listaIdentificadores);
    char* agregar(char* lista,char* elemento, char separator);
    char* copiarValor();
    extern char buff;
    void start();
%}

%union{
    char* expression;
    char* identifier;
}

%token INICIO FIN SEPARADOR IGUAL PARENTESISDER PARENTESISIZQ LEER ESCRIBIR FDT
%token<expression> IDENTIFICADOR CONSTANTE
%left OPERADOR COMA
%type<expression> expresion listaExpresiones listaIdentificadores primaria
%type<expression> ID

%%

input:
INICIO programa

programa:
listaSentencias FIN FDT {finalizarPrograma();}
;

listaSentencias:
sentencia
| listaSentencias sentencia {};

sentencia:
ID IGUAL expresion SEPARADOR {escribirExpresionAsignacion($1,$3);}
| LEER PARENTESISIZQ listaIdentificadores PARENTESISDER SEPARADOR {escribirExpresionLeer($3);}
| ESCRIBIR PARENTESISIZQ listaExpresiones PARENTESISDER SEPARADOR {escribirExpresionEscribir($3);}
;

ID:
IDENTIFICADOR {$$ = copiarValor();}

listaIdentificadores:
listaIdentificadores COMA ID {$$ = agregar($1,$3,',');}
| ID
;

listaExpresiones:
listaExpresiones COMA expresion {$$ = agregar($1,$3,',');}
| expresion
;

expresion:
primaria {$$ = copiarValor();}
| expresion OPERADOR primaria {$$ = agregar($1,$3,buff);}
;

primaria:
IDENTIFICADOR
| CONSTANTE
;
%%


void finalizarPrograma(){
    printf("Finalizado!\n");
}

void escribirExpresionAsignacion(char* identificador, char* expresion){
    printf("%s := %s; \n", identificador, expresion);
}

void escribirExpresionEscribir(char* listaIdentificadores){
    printf("escribir(%s);\n",listaIdentificadores);
}

void escribirExpresionLeer(char* listaIdentificadores){
    printf("leer(%s);\n",listaIdentificadores);
}

char* agregar(char* lista,char* elemento, char separator){
    char* newList = malloc(strlen(lista) + strlen(elemento) + 2);
    sprintf(newList,"%s%c%s",lista,separator,elemento);
    free(lista);
    return newList;
}


char* copiarValor(){
    int size = strlen(yylval.expression);
    char* newValor =  malloc(size);
    strcpy(newValor,yylval.expression);
    return newValor;
}


void yyerror(const char* charset){
    printf("FUCK: %s\n",charset);
}

void start(){
    yylval.expression = malloc(strlen(START_STRING));
    strcpy(yylval.expression,START_STRING);
}

int main(void){
    start();
    yyparse();
}

