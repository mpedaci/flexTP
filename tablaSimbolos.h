#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ICONSTANTE 1
#define IVARIABLE 0

typedef struct NodoTS{
    char identificador[32];
    int valor;
    int reservada;
    struct NodoTS* siguiente;
} NodoTS;

// METODOS PARA CREAR NODOS
void agregarPalabraReservada(char*);
NodoTS* crearNodoTS(char*, int, int);

// METODOS PARA MODIFICAR - AGREGAR NODOS
void asignarIdentificador(char*, int);

// METODOS PARA MOSTRAR
void mostrarTablaDeSimbolos();

// METODOS DE BUSQUEDA
NodoTS* ultimoNodoTablaSimbolos();
int existeIdentificador(char*);
int esPalabraReservada(char*);
NodoTS* buscarIdentificador(char*);
int valorIdentificador(char*);
