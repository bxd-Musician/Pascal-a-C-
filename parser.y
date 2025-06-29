%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern int yylex(void);
extern FILE *yyin;

int yydebug = 0;
extern int yylineno;

char* yy_current_function_name = NULL;

void set_current_function_name(char* name_token) {
    if (yy_current_function_name) {
        free(yy_current_function_name);
    }
    yy_current_function_name = name_token ? strdup(name_token) : NULL;
}

void clear_current_function_name() {
    if (yy_current_function_name) {
        free(yy_current_function_name);
        yy_current_function_name = NULL;
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Error de sintaxis en linea %d: %s\n", yylineno, s);
}

void generate_clrscr() {
    fprintf(stdout, "    
}

extern int yyparse();

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("Error al abrir el archivo de entrada");
            return 1;
        }
    } else {
        fprintf(stderr, "Uso: %s <archivo_pascal>\n", argv[0]);
        return 1;
    }

    if (argc > 2 && strcmp(argv[2], "-d") == 0) {
        yydebug = 1;
    }

    fprintf(stderr, "Iniciando analisis del archivo: %s\n", argv[1]);

    int result = yyparse();

    if (yyin) {
        fclose(yyin);
    }

    if (result == 0) {
        fprintf(stderr, "Analisis completado exitosamente.\n");
    } else {
        fprintf(stderr, "Analisis fallo.\n");
    }

    return result;
}
%}

%union {
    char* str;
    int ival;
}

%token <str> ID NUM STR
%token READ REAL
%token PROGRAM VAR INTEGER STRING CHAR BEGIN_ END READLN WRITELN WRITE WHILE DO ASSIGN LT GT EQ NE LE GE
%token FOR TO DOWNTO IF THEN ELSE FUNCTION USES TRUE_KEYWORD
%token SEMI COLON COMMA LPAREN RPAREN SUM POR REST DIVISION
%token DOT
%token REPEAT UNTIL CASE OF PROCEDURE_KEYWORD 
%token PLUS_ASSIGN VAR_KEYWORD
%token AND OR NOT ELSE_CASE
%token DOTDOT

%type <str> program uses_block optional_var_block var_declarations var_declaration
%type <str> function_declarations function_declaration procedure_declaration parameter_list parameter_groups parameter_group id_list
%type <str> block statements statement expr condition args for_loop_control type_specifier
%type <str> assignment_statement
%type <str> repeat_until_statement case_statement case_options case_option

%left EQ NE LT LE GT GE
%left SUM REST
%left POR DIVISION
%right UMINUS
%left OR
%left AND
%right NOT

%nonassoc THEN
%nonassoc ELSE

%%

program:
    PROGRAM ID SEMI
    uses_block
    optional_var_block
    function_declarations
    block DOT
    {
        printf("// Codigo C++ generado desde Pascal\n");
        printf("#include <iostream>\n");
        printf("#include <cmath>\n");
        printf("#include <string>\n");
		printf("#include <unistd.h>  // Para sleep()\n"); 
		printf("#include <iomanip>  // Para setprecision y setw\n");
        printf("using namespace std;\n\n");

        if ($6 && strlen($6) > 0) {
            printf("%s", $6);
            free($6);
        }

        printf("int main() {\n");
        if ($5 && strlen($5) > 0) {
            printf("%s", $5);
            free($5);
        }
        printf("%s", $7);
        printf("    return 0;\n");
        printf("}\n");

        free($2);
        free($4);
    }
    | PROGRAM ID LPAREN ID COMMA ID RPAREN SEMI
    uses_block
    optional_var_block
    function_declarations
    block DOT
    {
        printf("// Codigo C++ generado desde Pascal\n");
        printf("#include <iostream>\n");
        printf("#include <cmath>\n");
        printf("#include <string>\n");
		printf("#include <unistd.h>  // Para sleep()\n"); 
		printf("#include <iomanip>  // Para setprecision y setw\n");
        printf("using namespace std;\n\n");

        if ($11 && strlen($11) > 0) {  
            printf("%s", $11);
            free($11);
        }

        printf("int main() {\n");
        if ($10 && strlen($10) > 0) {  
            printf("%s", $10);
            free($10);
        }
        printf("%s", $12);  
        printf("    return 0;\n");
        printf("}\n");

        free($2);  
        free($4);  
        free($6);  
        free($9);  
    }
;

uses_block:
    /* epsilon */ { $$ = strdup(""); }
    | USES ID SEMI {
        $$ = strdup("");
        free($2);
    }
;

optional_var_block:
    /* epsilon */ { $$ = strdup(""); }
    | VAR_KEYWORD var_declarations { $$ = $2; }
;

var_declarations:
    var_declarations var_declaration {
        char* temp = (char*)malloc(strlen($1) + strlen($2) + 1);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s%s", $1, $2);
        $$ = temp;
        free($1); free($2);
    }
    | var_declaration { $$ = $1; }
;

var_declaration:
    id_list COLON type_specifier SEMI {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 32);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    %s %s;\n", $3, $1);
        $$ = temp;
        free($1); free($3);
    }
;

type_specifier:
    INTEGER { $$ = strdup("int"); }
	| STRING { $$ = strdup("string"); }
	| CHAR { $$ = strdup("char"); }
	| REAL { $$ = strdup("double"); }
;

function_declarations:
    /* epsilon */ { $$ = strdup(""); }
    | function_declarations function_declaration {
        char* temp = (char*)malloc(strlen($1) + strlen($2) + 1);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s%s", $1, $2);
        $$ = temp;
        free($1); free($2);
    }
    | function_declarations procedure_declaration {
        char* temp = (char*)malloc(strlen($1) + strlen($2) + 1);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s%s", $1, $2);
        $$ = temp;
        free($1); free($2);
    }
;

function_declaration:
    FUNCTION ID { set_current_function_name($2); free($2); } LPAREN parameter_list RPAREN COLON type_specifier SEMI
    optional_var_block
    block SEMI
    {
        char* func_name = yy_current_function_name;
        char* temp_params = ($5 && strlen($5) > 0) ? $5 : strdup("");
        char* return_type = $8;
        char* func_var_decls = ($10 && strlen($10) > 0) ? $10 : strdup("");
        char* func_body = $11;

        char* temp = (char*)malloc(strlen(func_name) + strlen(temp_params) + strlen(return_type) +
                                     strlen(func_var_decls) + strlen(func_body) + 512);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }

        char return_var_decl[256];
        sprintf(return_var_decl, "    %s %s_result = 0;\n", return_type, func_name);

        sprintf(temp, "\n%s %s(%s) {\n%s%s%s    return %s_result;\n}\n",
                return_type,
                func_name,
                temp_params,
                return_var_decl,
                func_var_decls,
                func_body,
                func_name);

        $$ = temp;
        if (temp_params && temp_params != $5) free(temp_params);
        free(return_type);
        if (func_var_decls && func_var_decls != $10) free(func_var_decls);
        free(func_body);
        clear_current_function_name();
    }
;

procedure_declaration:
    PROCEDURE_KEYWORD ID { set_current_function_name($2); free($2); } LPAREN parameter_list RPAREN SEMI
    optional_var_block
    block SEMI
    {
        char* func_name = yy_current_function_name;
        char* temp_params = $5;
        char* func_var_decls = $8;
        char* func_body = $9;  

        char* temp = (char*)malloc(strlen(func_name) + strlen(temp_params) + strlen(func_var_decls) + strlen(func_body) + 512);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }

        sprintf(temp, "\nvoid %s(%s) {\n%s%s}\n", func_name, temp_params, func_var_decls, func_body);

        $$ = temp;
        free(temp_params); free(func_var_decls); free(func_body);
        clear_current_function_name();
    }
    | PROCEDURE_KEYWORD ID { set_current_function_name($2); free($2); } SEMI
    optional_var_block  
    block SEMI
    {
        char* func_name = yy_current_function_name;
        char* func_var_decls = $5;  
        char* func_body = $6;      

        char* temp = (char*)malloc(strlen(func_name) + strlen(func_var_decls) + strlen(func_body) + 512);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }

        sprintf(temp, "\nvoid %s() {\n%s%s}\n", func_name, func_var_decls, func_body);

        $$ = temp;
        free(func_var_decls); free(func_body);
        clear_current_function_name();
    }
;

parameter_list:
    /* epsilon */ { $$ = strdup(""); }
    | parameter_groups { $$ = $1; }
;

parameter_groups:
    parameter_groups SEMI parameter_group {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 3);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s, %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | parameter_group { $$ = $1; }
;

parameter_group:
    VAR_KEYWORD id_list COLON type_specifier {
        char* id_list_str_original = $2;
        char* type_str = $4;
        char* result = NULL;
        char* temp_id_list_copy_for_len = strdup(id_list_str_original);
        if (!temp_id_list_copy_for_len) { yyerror("Memory allocation failed"); exit(1); }
        
        size_t total_len = 0;
        char* current_id_len_calc = strtok(temp_id_list_copy_for_len, ",");
        while (current_id_len_calc != NULL) {
            total_len += strlen(type_str) + strlen(current_id_len_calc) + 4; 
            current_id_len_calc = strtok(NULL, ",");
        }
        free(temp_id_list_copy_for_len);
        
        result = (char*)malloc(total_len + 1);
        if (!result) { yyerror("Memory allocation failed"); exit(1); }
        result[0] = '\0';
        
        char* id_list_str_working_copy = strdup(id_list_str_original);
        if (!id_list_str_working_copy) { yyerror("Memory allocation failed"); exit(1); }
        
        char* current_id = strtok(id_list_str_working_copy, ",");
        int first = 1;
        while (current_id != NULL) {
            while (isspace((unsigned char)*current_id)) current_id++;
            char* end = current_id + strlen(current_id) - 1;
            while (end >= current_id && isspace((unsigned char)*end)) end--;
            *(end + 1) = '\0';
            
            if (!first) {
                strcat(result, ", ");
            }
            sprintf(result + strlen(result), "%s& %s", type_str, current_id);
            first = 0;
            current_id = strtok(NULL, ",");
        }
        $$ = result;
        free(id_list_str_original);
        free(id_list_str_working_copy);
        free(type_str);
    }
    | id_list COLON type_specifier {
        char* id_list_str_original = $1;
        char* type_str = $3;
        char* result = NULL;
        char* temp_id_list_copy_for_len = strdup(id_list_str_original);
        if (!temp_id_list_copy_for_len) { yyerror("Memory allocation failed"); exit(1); }
        
        size_t total_len = 0;
        char* current_id_len_calc = strtok(temp_id_list_copy_for_len, ",");
        while (current_id_len_calc != NULL) {
            total_len += strlen(type_str) + strlen(current_id_len_calc) + 3;
            current_id_len_calc = strtok(NULL, ",");
        }
        free(temp_id_list_copy_for_len);
        
        result = (char*)malloc(total_len + 1);
        if (!result) { yyerror("Memory allocation failed"); exit(1); }
        result[0] = '\0';
        
        char* id_list_str_working_copy = strdup(id_list_str_original);
        if (!id_list_str_working_copy) { yyerror("Memory allocation failed"); exit(1); }
        
        char* current_id = strtok(id_list_str_working_copy, ",");
        int first = 1;
        while (current_id != NULL) {
            while (isspace((unsigned char)*current_id)) current_id++;
            char* end = current_id + strlen(current_id) - 1;
            while (end >= current_id && isspace((unsigned char)*end)) end--;
            *(end + 1) = '\0';
            
            if (!first) {
                strcat(result, ", ");
            }
            sprintf(result + strlen(result), "%s %s", type_str, current_id);
            first = 0;
            current_id = strtok(NULL, ",");
        }
        $$ = result;
        free(id_list_str_original);
        free(id_list_str_working_copy);
        free(type_str);
    }
;

id_list:
    ID { $$ = strdup($1); free($1); }
    | id_list COMMA ID {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 3);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s,%s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
;

block:
    BEGIN_ statements END { $$ = $2; }
    | statement { $$ = $1; }
;

statements:
    statements SEMI statement {
        char* s1 = ($1) ? $1 : strdup("");
        char* s3 = ($3) ? $3 : strdup("");

        if (strlen(s3) > 0) {
            char* temp = (char*)malloc(strlen(s1) + strlen(s3) + 1);
            if (!temp) { yyerror("Memory allocation failed"); exit(1); }
            sprintf(temp, "%s%s", s1, s3);
            $$ = temp;
            if ($1) free($1); if ($3) free($3);
        } else {
            $$ = s1;
            if ($3) free($3);
        }
    }
    | statements statement {  
        char* s1 = ($1) ? $1 : strdup("");
        char* s2 = ($2) ? $2 : strdup("");

        if (strlen(s2) > 0) {
            char* temp = (char*)malloc(strlen(s1) + strlen(s2) + 1);
            if (!temp) { yyerror("Memory allocation failed"); exit(1); }
            sprintf(temp, "%s%s", s1, s2);
            $$ = temp;
            if ($1) free($1); if ($2) free($2);
        } else {
            $$ = s1;
            if ($2) free($2);
        }
    }
    | statements SEMI {
        $$ = $1;
    }
    | statement {
        $$ = $1;
    }
    | /* epsilon */ { $$ = strdup(""); }
;

statement:
    READLN LPAREN ID RPAREN {
        char* temp = (char*)malloc(256);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    cin >> %s;\n", $3);
        $$ = temp;
        free($3);
    }
    | READLN LPAREN RPAREN {
        char* temp = (char*)malloc(64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    cin.get();\n");
        $$ = temp;
    }
    | READ LPAREN ID RPAREN {
        char* temp = (char*)malloc(256);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    cin >> %s;\n", $3);
        $$ = temp;
        free($3);
    }
    | WRITELN LPAREN RPAREN {
        char* temp = (char*)malloc(64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    cout << endl;\n");
        $$ = temp;
    }
    | WRITELN LPAREN args RPAREN {
		char* args_str = $3;

		size_t len = strlen(args_str);
		char* temp = (char*)malloc(len + 128);
		if (!temp) { yyerror("Memory allocation failed"); exit(1); }
		
		char* escaped = (char*)malloc(len * 2 + 4); 
		if (!escaped) { yyerror("Memory allocation failed"); exit(1); }
		
		int j = 0;
		escaped[j++] = '"';
		
		int start = (args_str[0] == '"') ? 1 : 0;
		int end = len - ((args_str[len-1] == '"') ? 1 : 0);
		
		for (int i = start; i < end; i++) {
			if (args_str[i] == '\\') {
				escaped[j++] = '\\';
				escaped[j++] = '\\';
			} else if (args_str[i] == '"') {
				escaped[j++] = '\\';
				escaped[j++] = '"';
			} else {
				escaped[j++] = args_str[i];
			}
		}
		escaped[j++] = '"';
		escaped[j] = '\0';
		
		sprintf(temp, "    cout << %s << endl;\n", escaped);
		$$ = temp;
		
		free(escaped);
		free($3);
	}
    | WRITE LPAREN args RPAREN {
        char* temp = (char*)malloc(strlen($3) + 32);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    cout << %s;\n", $3);
        $$ = temp;
        free($3);
    }
    | assignment_statement { $$ = $1; }
    | ID {
        char* temp = (char*)malloc(strlen($1) + 64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        if (strcmp($1, "clrscr") == 0) {
            sprintf(temp, "    // clrscr(); (Not portable, equivalent not generated)\n");
        } else {
            sprintf(temp, "    %s();\n", $1);
        }
        $$ = temp;
        free($1);
    }
    | WHILE condition DO block {
        char* temp = (char*)malloc(strlen($2) + strlen($4) + 64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    while (%s) {\n%s    }\n", $2, $4);
        $$ = temp;
        free($2); free($4);
    }
    | FOR ID ASSIGN expr for_loop_control expr DO block {
        char* temp = (char*)malloc(strlen($2) + strlen($4) + strlen($6) + strlen($8) + 128);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        const char* op = (strcmp($5, "<=") == 0) ? "<=" : ">=";
        const char* incr = (strcmp($5, "<=") == 0) ? "++" : "--";
        sprintf(temp, "    for (%s = %s; %s %s %s; %s%s) {\n%s    }\n",
                $2, $4, $2, op, $6, $2, incr, $8);
        $$ = temp;
        free($2); free($4); free($5); free($6); free($8);
    }
    | IF condition THEN statement %prec THEN {
		char* temp = (char*)malloc(strlen($2) + strlen($4) + 64);
		if (!temp) { yyerror("Memory allocation failed"); exit(1); }
		sprintf(temp, "    if (%s) {\n%s    }\n", $2, $4);
		$$ = temp;
		free($2); free($4);
	}
    | IF condition THEN statement ELSE statement {
		char* temp = (char*)malloc(strlen($2) + strlen($4) + strlen($6) + 128);
		if (!temp) { yyerror("Memory allocation failed"); exit(1); }
		sprintf(temp, "    if (%s) {\n%s    } else {\n%s    }\n", $2, $4, $6);
		$$ = temp;
		free($2); free($4); free($6);
	}
    | ID LPAREN args RPAREN {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        if (strcmp($1, "clrscr") == 0) {
            sprintf(temp, "    // clrscr(); (Not portable, equivalent not generated)\n");
        } else if (strcmp($1, "delay") == 0) {
            int ms = atoi($3);
            if (ms >= 1000) {
                sprintf(temp, "    sleep(%d);\n", ms / 1000);
            } else {
                sprintf(temp, "    // delay(%s); // Delay too short for sleep()\n", $3);
            }
        } else {
            sprintf(temp, "    %s(%s);\n", $1, $3);
        }
        $$ = temp;
        free($1); free($3);
    }
    | ID LPAREN RPAREN {
        char* temp = (char*)malloc(strlen($1) + 16);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        if (strcmp($1, "clrscr") == 0) {
            sprintf(temp, "    // clrscr(); (Not portable, equivalent not generated)\n");
        } else {
            sprintf(temp, "    %s();\n", $1);
        }
        $$ = temp;
        free($1);
    }
    | repeat_until_statement { $$ = $1; }
    | case_statement { $$ = $1; }
;

assignment_statement:
    ID PLUS_ASSIGN expr {
        
        char* assigned_id = $1;
        char* expression_str = $3;
        char* temp = NULL;
        
        if (yy_current_function_name != NULL && strcmp(assigned_id, yy_current_function_name) == 0) {
            temp = (char*)malloc(strlen(assigned_id) * 2 + strlen(expression_str) + 48);
            if (!temp) { yyerror("Memory allocation failed"); exit(1); }
            sprintf(temp, "    %s_result = %s_result + %s;\n", assigned_id, assigned_id, expression_str);
        } else {
            temp = (char*)malloc(strlen(assigned_id) * 2 + strlen(expression_str) + 32);
            if (!temp) { yyerror("Memory allocation failed"); exit(1); }
            sprintf(temp, "    %s = %s + %s;\n", assigned_id, assigned_id, expression_str);
        }
        $$ = temp;
        free(assigned_id);
        free(expression_str);
    }
    | ID ASSIGN expr {
      
        char* assigned_id = $1;
        char* expression_str = $3;
        char* temp = NULL;
        
        if (yy_current_function_name != NULL && strcmp(assigned_id, yy_current_function_name) == 0) {
            temp = (char*)malloc(strlen(assigned_id) + strlen(expression_str) + 32);
            if (!temp) { yyerror("Memory allocation failed"); exit(1); }
            sprintf(temp, "    %s_result = %s;\n", assigned_id, expression_str);
        } else {
            temp = (char*)malloc(strlen(assigned_id) + strlen(expression_str) + 32);
            if (!temp) { yyerror("Memory allocation failed"); exit(1); }
            sprintf(temp, "    %s = %s;\n", assigned_id, expression_str);
        }
        $$ = temp;
        free(assigned_id);
        free(expression_str);
    }
;

for_loop_control:
    TO { $$ = strdup("<="); }
    | DOWNTO { $$ = strdup(">="); }
;

args:
    args COMMA expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s << %s", $1, $3); 
        $$ = temp;
        free($1); free($3);
    }
    | args COMMA expr COLON NUM COLON NUM {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 128);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s << fixed << setprecision(%s) << setw(%s) << %s", 
                $1, $7, $5, $3);
        $$ = temp;
        free($1); free($3); free($5); free($7);
    }
    | expr COLON NUM COLON NUM {
        char* temp = (char*)malloc(strlen($1) + 128);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "fixed << setprecision(%s) << setw(%s) << %s", 
                $5, $3, $1);
        $$ = temp;
        free($1); free($3); free($5);
    }
    | expr {
        $$ = $1;
    }
;

expr:
    expr SUM expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "(%s + %s)", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr REST expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "(%s - %s)", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr POR expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "(%s * %s)", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr DIVISION expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "(%s / %s)", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | REST expr %prec UMINUS {
        char* temp = (char*)malloc(strlen($2) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "(-%s)", $2);
        $$ = temp;
        free($2);
    }
    | LPAREN expr RPAREN {
        $$ = $2;
    }
    | ID { $$ = $1; }
    | NUM { $$ = $1; }
    | STR { $$ = $1; }
    | ID LPAREN args RPAREN {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 16);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s(%s)", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | ID LPAREN RPAREN {
        char* temp = (char*)malloc(strlen($1) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s()", $1);
        $$ = temp;
        free($1);
    }
;

condition:
    expr LT expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s < %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr GT expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s > %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr EQ expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s == %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr NE expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s != %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr LE expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s <= %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | expr GE expr {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s >= %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | condition AND condition {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s && %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | condition OR condition {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s || %s", $1, $3);
        $$ = temp;
        free($1); free($3);
    }
    | NOT condition {
        char* temp = (char*)malloc(strlen($2) + 8);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "!(%s)", $2);
        $$ = temp;
        free($2);
    }
    | TRUE_KEYWORD { $$ = strdup("true"); }
    | LPAREN condition RPAREN {
        char* temp = (char*)malloc(strlen($2) + 4);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "(%s)", $2);
        $$ = temp;
        free($2);
    }
;

repeat_until_statement:
    REPEAT statements UNTIL condition {
        char* temp = (char*)malloc(strlen($2) + strlen($4) + 128);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        
        sprintf(temp, "    do {\n%s    } while (!(%s));\n", $2, $4);
        $$ = temp;
        free($2);
        free($4);
    }
;

case_statement:
    CASE expr OF case_options END {
        char* temp = (char*)malloc(strlen($2) + strlen($4) + 128);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "    switch (%s) {\n%s    }\n", $2, $4);
        $$ = temp;
        free($2);
        free($4);
    }
;

case_options:
    case_option {
        $$ = $1;
    }
    | case_options SEMI case_option {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 1);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s%s", $1, $3);
        $$ = temp;
        free($1);
        free($3);
    }
    | case_options SEMI { 
        $$ = $1;
    }
    | case_options ELSE_CASE statement {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s        default:\n%s            break;\n", $1, $3);
        $$ = temp;
        free($1);
        free($3);
    }
    | case_options SEMI ELSE_CASE statement {
        char* temp = (char*)malloc(strlen($1) + strlen($4) + 64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "%s        default:\n%s            break;\n", $1, $4);
        $$ = temp;
        free($1);
        free($4);
    }
;

case_option:
    NUM COLON statement {
        char* temp = (char*)malloc(strlen($1) + strlen($3) + 64);
        if (!temp) { yyerror("Memory allocation failed"); exit(1); }
        sprintf(temp, "        case %s:\n%s            break;\n", $1, $3);
        $$ = temp;
        free($1);
        free($3);
    }
    | NUM DOTDOT NUM COLON statement {
        int start = atoi($1);
        int end = atoi($3);

        int total_cases = end - start + 1;
        int size_needed = total_cases * 20 + strlen($5) + 64;
        
        char* range_cases = (char*)malloc(size_needed);
        if (!range_cases) { yyerror("Memory allocation failed"); exit(1); }
        
        range_cases[0] = '\0';
        
        for (int i = start; i <= end; i++) {
            char case_line[32];
            sprintf(case_line, "        case %d:\n", i);
            strcat(range_cases, case_line);
        }
        
        sprintf(range_cases + strlen(range_cases), "%s            break;\n", $5);
        
        $$ = range_cases;
        free($1); free($3); free($5);
    }
;

%%
