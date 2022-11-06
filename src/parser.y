%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>

    #define YYERROR_VERBOSE 1
    #define MODO_CONVERT_C 1
    #define MODO_LIVE 0

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

    typedef struct NodoValorExp{
        int valor;
        struct NodoValorExp* siguiente;
    } NodoValorExp;
    
    void removeChar(char*, char);
    void parseError(char*);

    void errorIdentificadorNoDeclarado(char*);
    void errorPalabraReservada(char*);
    
    void iniciarTablaDeSimbolos();
    void cargarIdentificador(char*, int);
    void agregarIdentificadorACompletar(char*);
    void completarIdentificadores();
    void limpiarIdentificadoresACompletar();
    NodoTS* ultimoNodoTablaSimbolos();

    void escribirValores();

    void finalizarPrograma(void);
    void mostrarTablaDeSimbolos();

    void escribirExpresionLeer();
    void escribirExpresionEscribir();

    int leerValorIdentificador(char*);
    int existeIdentificador(char*);
    int esPalabraReservada(char*);
    int existeIdentificadorYNoEsPalabraReservada(char*);
    NodoTS* crearNodoTS(char*, int, int);

    int valorIdentificador(char*);
    void asignarValorIdentificador(char*, int);
    void agregarAExpresion(char*);

    void compilarC();
    void copiar(FILE*, FILE*);

    void cargarValorExpresion(int);
    void limpiarValoresDeExpresiones();
    NodoValorExp* leerValorExpresion(int);

    NodoTS* tablaSimbolos = NULL;
    NodoTS* identificadoresACompletar = NULL;  
    NodoValorExp* valoresDeExpresiones = NULL;

    int operar(int, char, int);

    // Conversion a C
    int convert_mode = MODO_CONVERT_C;
    FILE *buffer;
    char *expresion = NULL;
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

sentencia:              IDENTIFICADOR ASIGNACION expresion PUNTOYCOMA { asignarValorIdentificador($1, $3); } |
                        LEER PARENTESISIZQ listaDeIds PARENTESISDER PUNTOYCOMA { completarIdentificadores(); } |
                        ESCRIBIR PARENTESISIZQ listaDeExpresiones PARENTESISDER PUNTOYCOMA { escribirValores(); } ;

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
                            char bufferChar[33];
                            itoa($1, bufferChar, 10);
                            agregarAExpresion(bufferChar);
                            $$ = $1;
                        };
%%

void copiar(FILE* dst, FILE* src){
    char ch = fgetc(src);
    while (ch != EOF)
    {
        fputc(ch,dst);
        ch = fgetc(src);
    }
}

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

void removeChar(char* str, char charToRemmove){
    int i, j;
    int len = strlen(str);
    for(i=0; i<len; i++)
    {
        if(str[i] == charToRemmove)
        {
            for(j=i; j<len; j++)
            {
                str[j] = str[j+1];
            }
            len--;
            i--;
        }
    }
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

void iniciarTablaDeSimbolos(){
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
        int valor = 0;
        if (convert_mode == MODO_CONVERT_C) {
            escribirExpresionLeer(nodo->identificador);
        } else if (convert_mode == MODO_LIVE){
            valor = leerValorIdentificador(nodo->identificador);
        }
        cargarIdentificador(nodo->identificador, valor);
        nodo = nodo->siguiente;
    }

    limpiarIdentificadoresACompletar();
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

void escribirExpresionLeer(char *identificador){
    fprintf(buffer, "int %s;\n", identificador);
    fprintf(buffer, "scanf(\"%%d\", &%s);\n", identificador);
}

NodoTS* ultimoNodoTablaSimbolos(){
    NodoTS* nodo = tablaSimbolos;
    while(nodo->siguiente != NULL){
        nodo = nodo->siguiente;
    }
    return nodo;
}

void cargarIdentificador(char* identificador, int valor){
    NodoTS* nodo = ultimoNodoTablaSimbolos();
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

void agregarAExpresion(char *caracteres){
    char *expresionTemp = malloc(strlen(expresion) + strlen(caracteres) + 2);
    sprintf(expresionTemp,"%s%s",expresion,caracteres);
    free(expresion);
    expresion = expresionTemp;
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

void escribirExpresionEscribir(){
    char* token = strtok(expresion, ",");
    while (token != NULL){
        fprintf(buffer,"printf(\"%%d\\n\", %s);\n", token);
        token = strtok(NULL, ",");
    }
    expresion[0] = '\0';
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

void finalizarPrograma(){   
    if (convert_mode == MODO_CONVERT_C){
        fclose(buffer);
        remove("buffer.f");
    }
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
    if (nodo == NULL){
        nodo = ultimoNodoTablaSimbolos();
        nodo->siguiente = crearNodoTS(identificador, valor, 0);
    }
    if (convert_mode == MODO_CONVERT_C){
        fprintf(buffer, "int %s = %s;\n", identificador, expresion);
        expresion[0] = '\0';
    }
}

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

void help(char *programa){
    fprintf (stderr, "MICRO PARSER\n\n");
    fprintf (stderr, "Uso %s [OPCIONES]\n", programa);
    fprintf (stderr, "    -?, -H\t\tPresenta esta ayuda en pantalla.\n");
    fprintf (stderr, "    -l\t\tActiva el parser en vivo.\n");
    fprintf (stderr, "    -f [archivo]\t\tEspecifica el nombre del archivo a parserar.\n");
    fprintf (stderr, "    -c [archivo]\t\tEspecifica el nombre del archivo a parserar y convertir a c.\n");
    exit(2);  
}

int main(int argc, char *argv[]) {
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
                convert_mode = 1;
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

    iniciarTablaDeSimbolos();
    yyparse();
    
    return 0;
}