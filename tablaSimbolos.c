#include "tablaSimbolos.h"

extern NodoTS* tablaSimbolos;

// TABLA DE SIMBOLOS

// METODOS PARA CREAR NODOS
void agregarPalabraReservada(char* identificador){
    NodoTS* nodo = crearNodoTS(identificador, 0, ICONSTANTE);
    if (tablaSimbolos == NULL){
        tablaSimbolos = nodo;
    } else {
        NodoTS* ultimoNodo = ultimoNodoTablaSimbolos();
        ultimoNodo->siguiente = nodo;   
    }
}

NodoTS* crearNodoTS(char* identificador, int valor, int reservada){
    NodoTS *nodo;
    nodo = (NodoTS*)malloc(sizeof(NodoTS));
    
    strcpy(nodo->identificador, identificador);
    nodo->valor = valor;
    nodo->reservada = reservada;
    nodo->siguiente = NULL;

    return nodo;
}

// METODOS PARA AGREGAR NODOS
void asignarIdentificador(char* identificador, int valor){
    NodoTS* nodo = buscarIdentificador(identificador);
    if (nodo != NULL){
        nodo->valor = valor;
    } else {
        nodo = ultimoNodoTablaSimbolos();
        nodo->siguiente = crearNodoTS(identificador, valor, IVARIABLE);
    }
}

// METODOS PARA MOSTRAR
void mostrarTablaDeSimbolos(){
    NodoTS* nodo = tablaSimbolos;
    printf("\n====TABLA DE SIMBOLOS====\n");
    while(nodo != NULL){
        printf("%s ##### %d ##### %d\n", nodo->identificador, nodo->valor, nodo->reservada);
        nodo = nodo->siguiente;
    }
    printf("=========================\n\n");
}

// METODOS DE BUSQUEDA
NodoTS* ultimoNodoTablaSimbolos(){
    NodoTS* nodo = tablaSimbolos;
    while(nodo->siguiente != NULL){
        nodo = nodo->siguiente;
    }
    return nodo;
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

NodoTS* buscarIdentificador(char* identificador){
    NodoTS* nodo = tablaSimbolos;
    while(nodo != NULL){
        if (strcmp(nodo->identificador, identificador) == 0){
            return nodo;
        }
        nodo = nodo->siguiente;
    }
    return NULL;
}

int valorIdentificador(char* identificador){
    NodoTS* nodo = buscarIdentificador(identificador);
    if (nodo != NULL){
        return nodo->valor;
    }
    return 0;
}
