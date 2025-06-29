%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "parser.hpp"
extern void yyerror(const char *s);
int in_case_context = 0;
%}
%option nounput
%option case-insensitive
%option noyywrap
%option yylineno
%%
"+="                { return PLUS_ASSIGN; }
"program"           { return PROGRAM; }
"var"               { return VAR_KEYWORD; }  
"integer"           { return INTEGER; }
"string"            { return STRING; }
"char"              { return CHAR; }
"read"              { return READ; }
"real"              { return REAL; }
"begin"             { return BEGIN_; }
"end"               { 
                      if (in_case_context) {
                          in_case_context = 0;
                      }
                      return END; 
                    }
"readln"            { return READLN; }
"writeln"           { return WRITELN; }
"write"             { return WRITE; }
"while"             { return WHILE; }
"do"                { return DO; }
"for"               { return FOR; }
"to"                { return TO; }
"downto"            { return DOWNTO; }
"if"                { return IF; }
"then"              { return THEN; }
"else"              { 
                      if (in_case_context) {
                          return ELSE_CASE;
                      } else {
                          return ELSE;
                      }
                    }
"function"          { return FUNCTION; }
"uses"              { return USES; }
"true"              { return TRUE_KEYWORD; }
"repeat"            { return REPEAT; }
"until"             { return UNTIL; }
"case"              {
                      in_case_context = 1; 
                      return CASE;
                    }
"of"                { return OF; }
"procedure"         { return PROCEDURE_KEYWORD; }
".."                { return DOTDOT; }
"and"               { return AND; }
"or"                { return OR; }
"not"               { return NOT; }
"input"             { yylval.str = strdup(yytext); return ID; }
"output"            { yylval.str = strdup(yytext); return ID; }

":="                { return ASSIGN; }
"<"                 { return LT; }
">"                 { return GT; }
"="                 { return EQ; }
"<>"                { return NE; }
"<="                { return LE; }
">="                { return GE; }
";"                 { return SEMI; }
":"                 { return COLON; }
","                 { return COMMA; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
"."                 { return DOT; }
"*"                 { return POR; }
"+"                 { return SUM; }
"-"                 { return REST; }
"/"                 { return DIVISION; }
"{"[^}]*"}"         ; 
[0-9]+(\.[0-9]+)?   {
                        yylval.str = strdup(yytext);
                        return NUM;
                    }
[a-zA-Z_][a-zA-Z0-9_]* {
                        yylval.str = strdup(yytext);
                        return ID;
                    }
\'([^'\\]|\\.)*\' {
                        size_t len = strlen(yytext);
                        char* transformed = (char*)malloc(len + 3); 
                        if (!transformed) {
                            yyerror("Memory allocation failed for string");
                            exit(1);
                        }
                        
                        if (len == 3) {
                            strcpy(transformed, yytext); 
                        } else {
                            transformed[0] = '"';
                            int j = 1;
                            for (size_t i = 1; i < len - 1; i++) {
                                if (yytext[i] == '\\') {
                                    transformed[j++] = yytext[i];
                                    if (i + 1 < len - 1) {
                                        transformed[j++] = yytext[++i];
                                    }
                                } else {
                                    transformed[j++] = yytext[i];
                                }
                            }
                            transformed[j++] = '"';
                            transformed[j] = '\0';
                        }
                        
                        yylval.str = transformed;
                        return STR;
                    }
[ \t\r\n]+          ;
"//".* ;
"(*"([^*]|\*+[^*)])*\*+")" ;
.                   {
                        fprintf(stderr, "Caracter inesperado: '%c' (ASCII: %d) en linea %d\n",
                                 yytext[0], (int)yytext[0], yylineno);
                    }
%%
