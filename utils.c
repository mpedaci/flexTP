#include "utils.h"

void removeChar(char* str, char charToRemove){
    int i, j;
    int len = strlen(str);
    for(i=0; i<len; i++)
    {
        if(str[i] == charToRemove)
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

void copiar(FILE* dst, FILE* src){
    char ch = fgetc(src);
    while (ch != EOF)
    {
        fputc(ch,dst);
        ch = fgetc(src);
    }
}