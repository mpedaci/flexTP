%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    #define START_STRING "Comienzo de cadena"

    extern int yylineno;
    extern int yylex();
    void yyerror(const char*);

    typedef struct NodoTS{
        char* identificador;
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

    void escribirValores();

    void mensajeFin(void);
    void mostrarTablaDeSimbolos();

    int leerValorIdentificador(char* identificador);
    NodoTS* crearNodoTS(char*, int);

    int existeIdentificador(char*);
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

%error-verbose

%union {
    int     int_val;
    char*   str_val;
}

%token <int_val> INICIO FIN SUMA RESTA ASIGNACION PARENTESISIZQ PARENTESISDER PUNTOYCOMA LEER ESCRIBIR COMA CONSTANTE
%token <str_val> IDENTIFICADOR

%type <str_val> sentencia listaDeIds;
%type <int_val> expresion primaria listaDeExpresiones;

%left SUMA RESTA

%start programa

%%

programa:       INICIO {iniciarTablaDeSimbolos();} sentencias FIN {mensajeFin();};

sentencias:     sentencias sentencia | sentencia;

sentencia:      LEER {leer = 1;} PARENTESISIZQ listaDeIds PARENTESISDER PUNTOYCOMA { completarIdentificadores(); leer = 0; } |
                ESCRIBIR {escribir = 1;} PARENTESISIZQ listaDeExpresiones PARENTESISDER PUNTOYCOMA { escribirValores(); escribir = 0; } |
                IDENTIFICADOR ASIGNACION expresion PUNTOYCOMA { asignarValorIdentificador($1, $3); }

listaDeExpresiones:     expresion { if(escribir == 1) cargarValorExpresion($1); } COMA listaDeExpresiones | 
                        expresion { if(escribir == 1) cargarValorExpresion($1); };

listaDeIds:             IDENTIFICADOR { if(leer == 1) agregarIdentificadorACompletar($1); } COMA listaDeIds |
                        IDENTIFICADOR { if(leer == 1) agregarIdentificadorACompletar($1); };

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
    printf("Error: identificador %s no declarado, en linea %d.\n", identificador, yylineno);
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

void cargarIdentificador(char* identificador){
    NodoTS* nodo = tablaSimbolos;
    while(nodo->siguiente != NULL){
        nodo = nodo->siguiente;
    }
    nodo->siguiente = crearNodoTS(identificador, leerValorIdentificador(identificador));
    mostrarTablaDeSimbolos();
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

    nodo->identificador = identificador;
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

int existeIdentificador(char* identificador){
    NodoTS* nodo = tablaSimbolos;
    while(nodo != NULL){
        if(strcmp(nodo->identificador, identificador) == 0){
            return 1;
        }
        nodo = nodo->siguiente;
    }
    return 0;
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
