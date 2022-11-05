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
        struct NodoTS* siguiente;
    } NodoTS;

    typedef struct VE{
        int valor;
        struct VE* siguiente;
    } VE;
    

    void errorIdentificadorNoDeclarado(char* identificador);
    void errorPalabraReservada(char* palabra);
    
    void inicializarVariables();
    void iniciarTablaDeSimbolos();
    void cargarIdentificador(char*);
    void agregarIdentificadorACompletar(char*);
    void completarIdentificadores();
    NodoTS* ultimoNodoTablaSimbolos();

    void escribirValores();

    void mensajeFin(void);
    void mostrarTablaDeSimbolos();

    int leerValorIdentificador(char* identificador);
    NodoTS* crearNodoTS(char*, int);

    int valorIdentificador(char*);
    void asignarValorIdentificador(char*, int);

    void cargarValorExpresion(int);
    VE* leerValorExpresion(int);

    int escribir=0;
    int leer=0;

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

%type <str_val> sentencia listaDeIds;
%type <int_val> expresion primaria listaDeExpresiones;

%left SUMA RESTA

%start objetivo

%%

objetivo:       programa FDT {mensajeFin();};

programa:       INICIO {iniciarTablaDeSimbolos();} sentencias FIN;

sentencias:     sentencia | sentencias sentencia;

sentencia:      IDENTIFICADOR ASIGNACION expresion PUNTOYCOMA { asignarValorIdentificador($1, $3); } |
                LEER {leer = 1;} PARENTESISIZQ listaDeIds PARENTESISDER PUNTOYCOMA { completarIdentificadores(); leer = 0; } |
                ESCRIBIR {escribir = 1;} PARENTESISIZQ listaDeExpresiones PARENTESISDER PUNTOYCOMA { escribirValores(); escribir = 0; }

listaDeIds:             listaDeIds COMA IDENTIFICADOR { if(leer == 1) agregarIdentificadorACompletar($3); }  |
                        IDENTIFICADOR { if(leer == 1) agregarIdentificadorACompletar($1); };

listaDeExpresiones:     listaDeExpresiones COMA expresion { if(escribir == 1) cargarValorExpresion($1); } | 
                        expresion { if(escribir == 1) cargarValorExpresion($1); };

expresion:          expresion SUMA primaria {$$ = $1 + $3;} | 
                    expresion RESTA primaria {$$ = $1 - $3;} |
                    primaria {$$ = $1;};

primaria:           IDENTIFICADOR { if(valorIdentificador($1) == -1){ errorPalabraReservada($1); } else { $$ = valorIdentificador($1); } } | 
                    CONSTANTE {$$ = $1;} | 
                    PARENTESISIZQ expresion PARENTESISDER {$$ = $2;};

%%

void yyerror(const char* texto) {
    printf("Error: %s en la linea %d.\n", texto, yylineno);
    exit(0);
}

void errorIdentificadorNoDeclarado(char* identificador){
    printf("Error: identificador \"%s\" no declarado, en linea %d.\n", identificador, yylineno);
    exit(0);
}

void errorPalabraReservada(char* palabra){
    printf("Error: identificador %s es una palabra reservada, en linea %d.\n", palabra, yylineno);
    exit(0);
}

void inicializarVariables(){
    yylval.str_val = malloc(strlen(START_STRING));
}

void iniciarTablaDeSimbolos(){
    inicializarVariables();

    NodoTS *nodoINICIO = crearNodoTS("inicio", -1);
    NodoTS *nodoFIN = crearNodoTS("fin", -1);
    NodoTS *nodoESCRIBIR = crearNodoTS("escribir", -1);
    NodoTS *nodoLEER = crearNodoTS("leer", -1);

    nodoESCRIBIR->siguiente = nodoLEER;
    nodoFIN->siguiente = nodoESCRIBIR;
    nodoINICIO->siguiente = nodoFIN;

    tablaSimbolos = nodoINICIO;
}

void agregarIdentificadorACompletar(char* identificador){
    if (identificadoresACompletar == NULL){
        identificadoresACompletar = crearNodoTS(identificador, 0);
    } else {
        NodoTS* nodo = identificadoresACompletar;
        while(nodo->siguiente != NULL){
            nodo = nodo->siguiente;
        }
        nodo->siguiente = crearNodoTS(identificador, 0);
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

    NodoTS* nodoNuevo = crearNodoTS(identificador, valor);
    nodo->siguiente = nodoNuevo;
}

int leerValorIdentificador(char* identificador){
    int valor;
    printf("Ingrese el valor para el identificador %s: ", identificador);
    scanf("%d", &valor);
    return valor;
}

NodoTS* crearNodoTS(char* identificador, int valor){
    NodoTS *nodo;
    nodo = (NodoTS*)malloc(sizeof(NodoTS));

    if (nodo == NULL){
        printf("Error: no se pudo crear el nodo de la tabla de simbolos.\n");
        exit(0);
    }
    
    strcpy(nodo->identificador, identificador);
    nodo->valor = valor;
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

void mensajeFin(){   
    mostrarTablaDeSimbolos();
    exit(0);
}

void mostrarTablaDeSimbolos(){
    NodoTS* nodo = tablaSimbolos;
    printf("\n====TABLA DE SIMBOLOS====\n");
    while(nodo != NULL){
        printf("%s ##### %d\n", nodo->identificador, nodo->valor);
        nodo = nodo->siguiente;
    }
    printf("========================\n\n");
}

int valorIdentificador(char* identificador){
    NodoTS* nodo = tablaSimbolos;
    while(nodo != NULL){
        if(strcmp(nodo->identificador, identificador) == 0){
            return nodo->valor;
        }
        nodo = nodo->siguiente;
    }
    errorIdentificadorNoDeclarado(identificador);
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
    nodo->siguiente = crearNodoTS(identificador, valor);
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
    yyparse();
    return 0;
}