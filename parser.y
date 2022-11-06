%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>
    #include "tablaSimbolos.h"
    #include "utils.h"

    #define YYERROR_VERBOSE 1
    #define MODO_CONVERT_C 1
    #define MODO_LIVE 0

    extern int yylineno;
    extern char* yytext;
    extern int yyleng;
    extern FILE *yyin;
    extern int yylex(void);

    typedef struct NodoValorExp{
        int valor;
        struct NodoValorExp* siguiente;
    } NodoValorExp;
    
    // ERRORES
    void yyerror(const char*);

    void errorIdentificadorNoDeclarado(char*);
    void errorPalabraReservada(char*);
    void parseError(char*);

    // COMPILAR C
    void compilarC();
    
    void escribirExpresionLeer(char*);
    void escribirExpresionEscribir();
    void escribirExpresionAsignar(char*);
    int existeIdentificadorYNoEsPalabraReservada(char*);

    // FUNCIONES PARA COMPILAR A C
    void agregarAExpresion(char*);
    void agregarAExpresionConstante(int);

    // FUNCIONES PARA SEMANTICA
    int operar(int, char, int);

    // IDENTIFICADORES
    void agregarIdentificadorACompletar(char*);
    void completarIdentificadores();
    void limpiarIdentificadoresACompletar();
    int leerValorIdentificador(char*);
    void escribirValores();

    // EXPRESIONES
    void cargarValorExpresion(int);
    NodoValorExp* leerValorExpresion(int);
    void limpiarValoresDeExpresiones();

    // START FUNCTION
    void iniciarTablaDeSimbolos();

    // END FUNCTION
    void finalizarPrograma();

    // MENU & MAIN FUNCTIONS
    void help(char*);
    void menu(int, char*[]);
    int main(int, char*[]);

    // VARIABLES GLOBALES
    NodoTS* tablaSimbolos = NULL;
    NodoTS* identificadoresACompletar = NULL;  
    NodoValorExp* valoresDeExpresiones = NULL;
    // VARIABLES PARA CONVERTIR A C
    FILE *buffer;
    char *expresion = NULL;
    int convert_mode = MODO_LIVE;
%}

%union {
    int     int_val;
    char    str_val[33];
}

%token INICIO FIN SUMA RESTA ASIGNACION PARENTESISIZQ PARENTESISDER PUNTOYCOMA LEER ESCRIBIR COMA FDT
%token <int_val> CONSTANTE
%token <str_val> IDENTIFICADOR OPERADOR

%type <str_val> sentencia listaDeIds;
%type <int_val> expresion primaria listaDeExpresiones;

%left SUMA RESTA

%%

input:                  INICIO programa;

programa:               sentencias FIN FDT { compilarC(); finalizarPrograma(); };

sentencias:             sentencia | sentencias sentencia;

sentencia:              IDENTIFICADOR ASIGNACION expresion PUNTOYCOMA { escribirExpresionAsignar($1); asignarIdentificador($1, $3); } |
                        LEER PARENTESISIZQ listaDeIds PARENTESISDER PUNTOYCOMA { completarIdentificadores(); } |
                        ESCRIBIR PARENTESISIZQ listaDeExpresiones PARENTESISDER PUNTOYCOMA { escribirExpresionEscribir(); escribirValores(); } ;

listaDeIds:             IDENTIFICADOR { agregarIdentificadorACompletar($1); } |
                        listaDeIds COMA IDENTIFICADOR { agregarIdentificadorACompletar($3); } ;

listaDeExpresiones:     expresion { cargarValorExpresion($1); } |
                        listaDeExpresiones COMA { agregarAExpresion(","); } expresion { cargarValorExpresion($4); } ;

expresion:              primaria |
                        expresion OPERADOR { agregarAExpresion($2); } primaria { $$ = operar($1, $2[0], $4); } ;

primaria:               IDENTIFICADOR {
                            existeIdentificadorYNoEsPalabraReservada($1);
                            agregarAExpresion($1);
                            $$ = valorIdentificador($1);
                        } | 
                        CONSTANTE {
                            agregarAExpresionConstante($1);
                            $$ = $1;
                        };
%%

// ERRORES
void yyerror(const char* texto) {
    char* textoError = strdup(texto);
    printf("Error Sintactico: ");
    parseError(textoError);   
    printf("en la linea %d.\n", yylineno);
    finalizarPrograma();
}

void errorIdentificadorNoDeclarado(char* identificador){
    printf("Error Semantico: identificador \"%s\" no declarado, en linea %d.\n", identificador, yylineno);
    finalizarPrograma();
}

void errorPalabraReservada(char* palabra){
    printf("Error Semantico: identificador %s es una palabra reservada, en linea %d.\n", palabra, yylineno);
    finalizarPrograma();
}

void parseError(char* textoError){
    removeChar(textoError, ',');
    char* token = strtok(textoError, " ");
    while(token != NULL) {
        if (strcmp(token, "syntax") != 0 && strcmp(token, "error") != 0){
            if (strcmp(token, "unexpected") == 0){
                token = strtok(NULL, " ");
                printf("se recibio %s y se esperadaba ", token);
            } else if (strcmp(token, "expecting") == 0 || strcmp(token, "or") == 0) {
                if (strcmp(token, "or") == 0){
                    printf("o ");
                }
                token = strtok(NULL, " ");
                printf("%s ", token);
            }
        }
        token = strtok(NULL, " ");
    }
}

int existeIdentificadorYNoEsPalabraReservada(char* identificador){
    if (existeIdentificador(identificador) == 0){
        errorIdentificadorNoDeclarado(identificador);
    }
    if (esPalabraReservada(identificador) == 1){
        errorPalabraReservada(identificador);
    }
    return 1;
}

// COMPILAR C
void compilarC(){
    if(convert_mode == MODO_CONVERT_C){
        fclose(buffer);
        FILE* buffer_lectura = fopen("buffer.f","r");
        FILE *outputC = fopen("output.c", "w+");
        fprintf(outputC, "#include <stdio.h>\n");
        fprintf(outputC, "#include <stdlib.h>\n");
        fprintf(outputC, "\n");
        fprintf(outputC, "int main(){\n");
        copiar(outputC, buffer_lectura);
        fprintf(outputC, "\n");
        fprintf(outputC, "return 0;\n");
        fprintf(outputC, "}\n");
        fclose(outputC);
        fclose(buffer_lectura);
    }
}

void escribirExpresionLeer(char* identificador){
    if (convert_mode == MODO_CONVERT_C){
        fprintf(buffer, "int %s;\n", identificador);
        fprintf(buffer, "scanf(\"%%d\", &%s);\n", identificador);
    }
}

void escribirExpresionEscribir(){
    if (convert_mode == MODO_CONVERT_C){
        char* token = strtok(expresion, ",");
        while (token != NULL){
            fprintf(buffer,"printf(\"%%d\\n\", %s);\n", token);
            token = strtok(NULL, ",");
        }
        expresion[0] = '\0';
    }
}

void escribirExpresionAsignar(char* identificador){
    if (convert_mode == MODO_CONVERT_C){
        fprintf(buffer, "int %s = %s;\n", identificador, expresion);
        expresion[0] = '\0';
    }
}

// FUNCIONES PARA COMPILAR A C
void agregarAExpresion(char *caracteres){
    if (convert_mode == MODO_CONVERT_C){
        char *expresionTemp = malloc(strlen(expresion) + strlen(caracteres) + 2);
        sprintf(expresionTemp,"%s%s",expresion,caracteres);
        free(expresion);
        expresion = expresionTemp;
    }
}

void agregarAExpresionConstante(int numero){
    if (convert_mode == MODO_CONVERT_C){
        char bufferChar[33];
        itoa(numero, bufferChar, 10);
        agregarAExpresion(bufferChar);
    }
}

// FUNCIONES PARA SEMANTICA
int operar(int a, char op, int b){
    int resultado = 0;
    switch(op){
        case '+':
            resultado = a + b;
            break;
        case '-':
            resultado = a - b;
            break;
        default:
            break;
    }
    return resultado;
}

// IDENTIFICADORES
void agregarIdentificadorACompletar(char* identificador){
    NodoTS* nodo = crearNodoTS(identificador, 0, IVARIABLE);
    if (identificadoresACompletar == NULL){
        identificadoresACompletar = nodo;
    } else {
        NodoTS* nodo = identificadoresACompletar;
        while(nodo->siguiente != NULL){
            nodo = nodo->siguiente;
        }
        nodo->siguiente = nodo;
    }
}

void completarIdentificadores(){
    NodoTS* nodo = identificadoresACompletar;
    while(nodo != NULL){
        int valor = 0;
        escribirExpresionLeer(nodo->identificador);
        if (convert_mode == MODO_LIVE){
            valor = leerValorIdentificador(nodo->identificador);
        }
        asignarIdentificador(nodo->identificador, valor);
        nodo = nodo->siguiente;
    }

    limpiarIdentificadoresACompletar();
}

int leerValorIdentificador(char* identificador){
    int valor;
    printf("Ingrese el valor para el identificador %s: ", identificador);
    scanf("%d", &valor);
    return valor;
}

void limpiarIdentificadoresACompletar(){
    NodoTS* nodo = identificadoresACompletar;
    while(nodo != NULL){
        NodoTS* nodoAEliminar = nodo;
        nodo = nodo->siguiente;
        free(nodoAEliminar);
    }
    identificadoresACompletar = NULL;
}

// EXPRESIONES
void cargarValorExpresion(int valor){
    if (valoresDeExpresiones == NULL){
        valoresDeExpresiones = leerValorExpresion(valor);
    } else {
        NodoValorExp* nodo = valoresDeExpresiones;
        while(nodo->siguiente != NULL){
            nodo = nodo->siguiente;
        }
        nodo->siguiente = leerValorExpresion(valor);
    }
}

NodoValorExp* leerValorExpresion(int valor){
    NodoValorExp* nodo;
    nodo = (NodoValorExp*)malloc(sizeof(NodoValorExp));
    nodo->valor = valor;
    nodo->siguiente = NULL;
    return nodo;
}

void limpiarValoresDeExpresiones(){
    NodoValorExp* nodo = valoresDeExpresiones;
    while(nodo != NULL){
        NodoValorExp* nodoAEliminar = nodo;
        nodo = nodo->siguiente;
        free(nodoAEliminar);
    }

    valoresDeExpresiones = NULL;
}

void escribirValores(){
    if (convert_mode == MODO_CONVERT_C){
        escribirExpresionEscribir();
    } else {
        NodoValorExp* nodo = valoresDeExpresiones;
        while(nodo != NULL){
            printf("%d ", nodo->valor);
            nodo = nodo->siguiente;
        }
        printf("\n");
    }

    limpiarValoresDeExpresiones();
}

// START FUNCTION
void iniciarTablaDeSimbolos(){
    agregarPalabraReservada("inicio");
    agregarPalabraReservada("fin");
    agregarPalabraReservada("leer");
    agregarPalabraReservada("escribir");
}

// END FUNCTION
void finalizarPrograma(){   
    if (convert_mode == MODO_CONVERT_C){
        fclose(buffer);
        remove("buffer.f");
    }
    mostrarTablaDeSimbolos();
    exit(0);
}

// MENU & MAIN FUNCTIONS

void help(char *programa){
    fprintf (stderr, "MICRO PARSER\n\n");
    fprintf (stderr, "Uso %s [OPCIONES]\n", programa);
    fprintf (stderr, "    -?, -H\t\tPresenta esta ayuda en pantalla.\n");
    fprintf (stderr, "    -l\t\tActiva el parser en vivo.\n");
    fprintf (stderr, "    -f [archivo]\t\tEspecifica el nombre del archivo a parserar.\n");
    fprintf (stderr, "    -c [archivo]\t\tEspecifica el nombre del archivo a parserar y convertir a c.\n");
    exit(2);  
}

void menu(int argc, char *argv[]){
    extern char* optarg;
    int c;
    while ((c = getopt(argc, argv, "lf:c:H")) != -1){
        switch (c) {
            case 'l':
                /* LIVE MODE */
                printf("Modo parser en vivo activado.\n\n");
                break;
            case 'f':
                /* FILE MODE */
                printf("Modo parser de archivo activado.\n\n");
                yyin = fopen(optarg, "r");
                break;
            case 'c':
                /* CONVERSOR MODE */
                printf("Modo parser de archivo a C activado.\n\n");
                convert_mode = MODO_CONVERT_C;
                expresion = malloc(1);
                expresion[0] = '\0';
                buffer = fopen("buffer.f","w+");
                yyin = fopen(optarg, "r");
                break;
            case 'H':
                help(argv[0]);
                break;
            default:
                help(argv[0]);
                exit(1);
        }
    }
}

int main(int argc, char *argv[]) {
    menu(argc, argv);
    iniciarTablaDeSimbolos();
    yyparse();
    
    return 0;
}