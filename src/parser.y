%{
    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>
    #define START_STRING "Comienzo de cadena"
    extern char* yytext;
    extern int yylex(void);
    extern int yyleng;

    #define YYERROR_VERBOSE 1
    extern int yylineno;

    void yyerror(const char*);
    void finalizarPrograma();
    void escribirExpresionAsignacion(char* identificador, char* expresion);
    void escribirExpresionEscribir(char* listaIdentificadores);
    void escribirExpresionLeer(char* listaIdentificadores);
    char* agregar(char* lista,char* elemento, char separator);
    char* copiarValor();
    extern char buff;
    void start();
    void buscarIdentificador(char* str);
    FILE* buffer;
    int listSize = 0;


    typedef struct Diccionario{
        char** vals;
        int size;
    } Diccionario;

    Diccionario diccionario;
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
| listaSentencias sentencia ;

sentencia:
ID IGUAL expresion SEPARADOR {escribirExpresionAsignacion($1,$3);}
| LEER PARENTESISIZQ listaIdentificadores PARENTESISDER SEPARADOR {escribirExpresionLeer($3);}
| ESCRIBIR PARENTESISIZQ listaExpresiones PARENTESISDER SEPARADOR {escribirExpresionEscribir($3);}
;

listaIdentificadores:
listaIdentificadores COMA ID {$$ = agregar($1,$3,',');}
| ID
;

listaExpresiones:
listaExpresiones COMA expresion {$$ = agregar($1,$3,',');}
| expresion
;

expresion:
primaria
| expresion OPERADOR primaria {$$ = agregar($1,$3,buff);}
;

primaria:
ID
| CONSTANTE {$$ = copiarValor(); listSize++;}
;

ID:
IDENTIFICADOR {$$ = copiarValor(); buscarIdentificador($$);}
;
%%

char* agregar(char* lista,char* elemento, char separator){
    char* newList = malloc(strlen(lista) + strlen(elemento) + 2);
    sprintf(newList,"%s%c%s",lista,separator,elemento);
    free(lista);
    listSize++;
    return newList;
}

char* copiarValor(){
    int size = strlen(yylval.expression);
    char* newValor =  malloc(size);
    strcpy(newValor,yylval.expression);
    return newValor;
}


void yyerror(const char* charset){
    /* printf("FUCK: %s\n",charset); */
    fprintf(stderr,"error: %s in line %d\n", charset, yylineno);
    fprintf(stderr,"near to ==> %s", yylval.expression);
    fprintf(stderr,"\n");
}

void copiar(FILE* dst, FILE* src){
    char ch = fgetc(src);

    while (ch != EOF)
    {
        fputc(ch,dst);
        ch = fgetc(src);
    }
}

void finalizarPrograma(){
    fclose(buffer);

    FILE* programa = fopen("PROGRAMA_COMPILADO.c","w+");
    FILE* buffer_lectura = fopen("buffer.f","r");
    FILE* codigo = fopen("file.c","r");

    fprintf(programa,"#include<stdlib.h>\n#include<string.h>\n");
    copiar(programa,codigo);
    fprintf(programa, "int main(){\n");
    copiar(programa,buffer_lectura);
    fprintf(programa,"}");

    fclose(buffer_lectura);
    fclose(codigo);
    fclose(programa);
}

void buscarIdentificador(char* identificador){
    for (int i =0; i < diccionario.size; i++){
        if (strcmp(identificador,diccionario.vals[i]) == 0){
            return;
        }
    }
    diccionario.vals[diccionario.size] = malloc(strlen(identificador) + 1);
    sprintf(diccionario.vals[diccionario.size],"%s",identificador);
    fprintf(buffer,"int %s;\n",identificador);
    diccionario.size++;
}

void escribirExpresionAsignacion(char* identificador, char* expresion){
    fprintf(buffer,"%s = %s;\n",identificador,expresion);
}


void escribirExpresionEscribir(char* listaIdentificadores){
   char* token = strtok(listaIdentificadores,",");
     for(int i = 0; i < listSize; i++){
        fprintf(buffer,"printf(%s,%s);\n","\"\%d \\n\"",token);
        token = strtok(NULL,",");
    }
    listSize = 0;
}

void escribirExpresionLeer(char* listaIdentificadores){
    char* token = strtok(listaIdentificadores,",");
    for(int i = 0; i < listSize; i++){
        fprintf(buffer,"char* param%d = NULL;\n param%d = scan_line(param%d);\n ", i,i,i);
        fprintf(buffer,"%s = atoi(param%d);\n",token,i);
        token = strtok(NULL,",");
    }
    listSize = 0;
}

void start(){
    yylval.expression = malloc(strlen(START_STRING));
    buffer = fopen("buffer.f","w+");
    diccionario.vals = malloc(sizeof(char*) * 100);
    diccionario.size = 0;
}

int main(void){
    start();
    yyparse();
}

