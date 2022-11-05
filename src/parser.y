%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    #define START_STRING "Comienzo de cadena"
    #define YYERROR_VERBOSE 1

    extern int yylineno;
    extern char* yytext;
    extern int yyleng;
    extern FILE *yyin;
    extern int yylex(void);
    void yyerror(const char*);

    typedef struct NodoTS{
        char identificador[32];
        int valor;
        int reservada;
        struct NodoTS* siguiente;
    } NodoTS;

    typedef struct VE{
        int valor;
        struct VE* siguiente;
    } VE;
    

    void errorIdentificadorNoDeclarado(char*);
    void errorPalabraReservada(char*);
    
    void inicializarVariables();
    void iniciarTablaDeSimbolos();
    void cargarIdentificador(char*);
    void agregarIdentificadorACompletar(char*);
    void completarIdentificadores();
    NodoTS* ultimoNodoTablaSimbolos();

    void escribirValores();

    void finalizarPrograma(void);
    void mostrarTablaDeSimbolos();

    int leerValorIdentificador(char*);
    int existeIdentificador(char*);
    int esPalabraReservada(char*);
    int existeIdentificadorYNoEsPalabraReservada(char*);
    NodoTS* crearNodoTS(char*, int, int);

    int valorIdentificador(char*);
    void asignarValorIdentificador(char*, int);

    void cargarValorExpresion(int);
    VE* leerValorExpresion(int);

    NodoTS* tablaSimbolos = NULL;
    NodoTS* identificadoresACompletar = NULL;  
    VE* valoresDeExpresiones = NULL;
%}

%union {
    int     int_val;
    char*   str_val;
}

%token INICIO FIN SUMA RESTA ASIGNACION PARENTESISIZQ PARENTESISDER PUNTOYCOMA LEER ESCRIBIR COMA FDT
%token <int_val> CONSTANTE
%token <str_val> IDENTIFICADOR

%type <str_val> sentencia listaDeIds ID;
%type <int_val> expresion primaria listaDeExpresiones;

%left SUMA RESTA

%%

input:          INICIO programa;

programa:       sentencias FIN FDT {finalizarPrograma();};

sentencias:     sentencia | sentencias sentencia;

sentencia:      ID ASIGNACION expresion PUNTOYCOMA { asignarValorIdentificador($1, $3); } |
                LEER PARENTESISIZQ listaDeIds PARENTESISDER PUNTOYCOMA { completarIdentificadores(); } |
                ESCRIBIR PARENTESISIZQ listaDeExpresiones PARENTESISDER PUNTOYCOMA { escribirValores(); }

listaDeIds:             listaDeIds COMA ID { agregarIdentificadorACompletar($3); } |
                        ID { agregarIdentificadorACompletar($1); };

listaDeExpresiones:     listaDeExpresiones COMA expresion { cargarValorExpresion($1); } | 
                        expresion { cargarValorExpresion($1); };

expresion:          primaria { $$ = $1; } |
                    expresion SUMA primaria { $$ = $1 + $3; } | 
                    expresion RESTA primaria { $$ = $1 - $3; };

primaria:           ID { if (existeIdentificadorYNoEsPalabraReservada($1) == 1) { $$ = valorIdentificador($1); } } | 
                    CONSTANTE {$$ = $1;} | 
                    PARENTESISIZQ expresion PARENTESISDER { $$ = $2; };

ID:                 IDENTIFICADOR { $$ = $1; };
%%

void yyerror(const char* texto) {
    printf("Error: %s en la linea %d.\n", texto, yylineno);
    finalizarPrograma();
}

void errorIdentificadorNoDeclarado(char* identificador){
    printf("Error: identificador \"%s\" no declarado, en linea %d.\n", identificador, yylineno);
    finalizarPrograma();
}

void errorPalabraReservada(char* palabra){
    printf("Error: identificador %s es una palabra reservada, en linea %d.\n", palabra, yylineno);
    finalizarPrograma();
}

void inicializarVariables(){
    yylval.str_val = malloc(strlen(START_STRING));
}

void iniciarTablaDeSimbolos(){
    inicializarVariables();

    NodoTS *nodoINICIO = crearNodoTS("inicio", 0, 1);
    NodoTS *nodoFIN = crearNodoTS("fin", 0, 1);
    NodoTS *nodoESCRIBIR = crearNodoTS("escribir", 0, 1);
    NodoTS *nodoLEER = crearNodoTS("leer", 0, 1);

    nodoESCRIBIR->siguiente = nodoLEER;
    nodoFIN->siguiente = nodoESCRIBIR;
    nodoINICIO->siguiente = nodoFIN;

    tablaSimbolos = nodoINICIO;
}

void agregarIdentificadorACompletar(char* identificador){
    if (identificadoresACompletar == NULL){
        identificadoresACompletar = crearNodoTS(identificador, 0, 0);
    } else {
        NodoTS* nodo = identificadoresACompletar;
        while(nodo->siguiente != NULL){
            nodo = nodo->siguiente;
        }
        nodo->siguiente = crearNodoTS(identificador, 0, 0);
    }
}

void completarIdentificadores(){
    NodoTS* nodo = identificadoresACompletar;
    while(nodo != NULL){
        cargarIdentificador(nodo->identificador);
        nodo = nodo->siguiente;
    }
    identificadoresACompletar = NULL;
}

NodoTS* ultimoNodoTablaSimbolos(){
    NodoTS* nodo = tablaSimbolos;
    while(nodo->siguiente != NULL){
        nodo = nodo->siguiente;
    }
    return nodo;
}

void cargarIdentificador(char* identificador){
    NodoTS* nodo = ultimoNodoTablaSimbolos();

    int valor = leerValorIdentificador(identificador);

    NodoTS* nodoNuevo = crearNodoTS(identificador, valor, 0);
    nodo->siguiente = nodoNuevo;
}

int leerValorIdentificador(char* identificador){
    int valor;
    printf("Ingrese el valor para el identificador %s: ", identificador);
    scanf("%d", &valor);
    return valor;
}

NodoTS* crearNodoTS(char* identificador, int valor, int reservada){
    NodoTS *nodo;
    nodo = (NodoTS*)malloc(sizeof(NodoTS));

    if (nodo == NULL){
        printf("Error: no se pudo crear el nodo de la tabla de simbolos.\n");
        finalizarPrograma();
    }
    
    strcpy(nodo->identificador, identificador);
    nodo->valor = valor;
    nodo->reservada = reservada;
    nodo->siguiente = NULL;

    return nodo;
}

void escribirValores(){
    VE* nodo = valoresDeExpresiones;
    
    while(nodo != NULL){
        printf("%d ", nodo->valor);
        nodo = nodo->siguiente;
    }
    printf("\n");
    valoresDeExpresiones = NULL;
}

void finalizarPrograma(){   
    mostrarTablaDeSimbolos();
    exit(0);
}

void mostrarTablaDeSimbolos(){
    NodoTS* nodo = tablaSimbolos;
    printf("\n====TABLA DE SIMBOLOS====\n");
    while(nodo != NULL){
        printf("%s ##### %d ##### %d\n", nodo->identificador, nodo->valor, nodo->reservada);
        nodo = nodo->siguiente;
    }
    printf("=========================\n\n");
}

int existeIdentificador(char* identificador){
    NodoTS* nodo = tablaSimbolos;
    while(nodo != NULL){
        if (strcmp(nodo->identificador, identificador) == 0){
            return 1;
        }
        nodo = nodo->siguiente;
    }
    return 0;
}

int esPalabraReservada(char* identificador){
    NodoTS* nodo = tablaSimbolos;
    while(nodo != NULL){
        if (strcmp(nodo->identificador, identificador) == 0){
            return nodo->reservada;
        }
        nodo = nodo->siguiente;
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

int valorIdentificador(char* identificador){
    NodoTS* nodo = tablaSimbolos;
    while(nodo != NULL){
        if(strcmp(nodo->identificador, identificador) == 0){
            return nodo->valor;
        }
        nodo = nodo->siguiente;
    }
}

void asignarValorIdentificador(char* identificador, int valor){
    NodoTS* nodo = tablaSimbolos;
    while(nodo != NULL){
        if(strcmp(nodo->identificador, identificador) == 0){
            nodo->valor = valor;
        }
        nodo = nodo->siguiente;
    }

    nodo = tablaSimbolos;
    while(nodo->siguiente != NULL){
        nodo = nodo->siguiente;
    }
    nodo->siguiente = crearNodoTS(identificador, valor, 0);
}

void cargarValorExpresion(int valor){
    if (valoresDeExpresiones == NULL){
        valoresDeExpresiones = leerValorExpresion(valor);
    } else {
        VE* nodo = valoresDeExpresiones;
        while(nodo->siguiente != NULL){
            nodo = nodo->siguiente;
        }
        nodo->siguiente = leerValorExpresion(valor);
    }
}

VE* leerValorExpresion(int valor){
    VE* nodo;
    nodo = (VE*)malloc(sizeof(VE));
    nodo->valor = valor;
    nodo->siguiente = NULL;
    return nodo;
}

int main(int argc, char** argv) {
    printf("Para analizar desde un archivo ejecute progrma.exe archivo.txt\n");
    if(argc > 1){
        yyin = fopen(argv[1], "r");
    }
    iniciarTablaDeSimbolos();
    yyparse();
    
    return 0;
}