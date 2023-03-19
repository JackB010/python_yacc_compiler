%{
    #include <stdio.h>
    #include <string.h>
    #include <ctype.h>
    #include <stdlib.h>

    #include "ts.h"
    #include "yacc_C.tab.h"
    #include "yacc_C.tab.c"
    // #include "yacc_C_2.tab.h"
    // #include "yacc_C_2.tab.c"

    extern YYSTYPE yylval;
    extern void yyerror(char  *msg);
    int num_line=1, num_col=1;
    int space_count = 0;   
    int indent_level = 0;
    int did_newline = 0;
    int i;
    int sig  = 0;
%}

%x START

%option noyywrap

%%
" "             { space_count++; num_col++;}
"#".*\n         { space_count=0; num_line++; num_col=1;}                                                                   
\n              { space_count=0; num_line++; num_col=1;}
. {     
    unput(*yytext);
    sig = 0;

        if(space_count%4==0){
            if(space_count> indent_level){
                    indent_level = indent_level+4;
                    recherche("INDENT", KEYWORD_TYPE, 1);
                    return INDENT;
                }
            if(space_count< indent_level || (space_count==0 && indent_level!=0)){
                indent_level = indent_level-4;
                recherche("UNDENT", KEYWORD_TYPE, 1);
                BEGIN(INITIAL);
                return UNDENT;
                }       
        }else
            yyerror("erreur lexicale");
    
    BEGIN(START);
}

<<EOF>> {
        if ((head_idf!=NULL || head_sp!=NULL || head_mc!=NULL)&&did_newline==0){
                did_newline=1;
                return NEWLINE;
            }
        if (indent_level!=0){
            recherche("UNDENT", KEYWORD_TYPE, 1);
            indent_level -=4; 
            return UNDENT;
        }else
             yyterminate();
}
                /************* declaration Mot cle *************/ 

<START>{                                                       
"#".*           { }                                                        
\n              { space_count=0; num_line++; num_col=1; BEGIN(INITIAL); return NEWLINE;}
[ \t]*          { num_col +=yyleng; }

"int"           { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return INT;}
"float"         { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return FLOAT;}
"char"          { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return CHAR;}
"bool"          { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return BOOL;}
"in"            { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return IN;}
"for"           { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return FOR;}
"range"         { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return RANGE;}
"if"            { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return IF;}
"else"          { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return ELSE;}
"while"         { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; return WHILE;}

"true"          { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; yylval.str = "true"; return TRUE;}
"false"         { recherche(yytext, KEYWORD_TYPE, 1);  num_col+=yyleng; yylval.str = "false"; return FALSE;}

"or"            { recherche(yytext, KEYWORD_TYPE, 1); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return OR;}
"and"           { recherche(yytext, KEYWORD_TYPE, 1); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return AND;}
"not"           { recherche(yytext, KEYWORD_TYPE, 1); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return NOT;}

"-"             { sig = sig+1; recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return SUB;}
"+"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return ADD;}
"*"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return MUL;}
"/"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return DIV;}  
 
">"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return GT;}
"<"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return LT;}
">="            { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return GE;}
"<="            { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return LE;}
"=="            { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return EQL;}
"!="            { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; yylval.str = (char *) strdup(yytext); return NEQL;}

":"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; return TWOD;}  
","             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; return COMMA;}  
"="             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; return ASSIGN;}
"("             { sig=sig+1; recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; return LPAREN;}
")"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; return RPAREN;}
"["             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; return LBRACKET;}
"]"             { recherche(yytext, KEYWORD_TYPE, 2); num_col+=yyleng; return RBRACKET;}

"'"."'"         { yylval.str = (char *) strdup(yytext); num_col+=yyleng; return CHAR_VAL;}
"'".*"'"        { yyerror("erreur lexicale");
                    printf("\033[1;31m"); printf("\t\t\t\t\t > %s\n", yytext); printf("\033[0m");}

[[:digit:]]+    {  
                    int only_z =1;
                    if(yytext[0]=='0'){
                        for(int i=0; i<yyleng; i++)
                            if(yytext[i]!='0'){
                                only_z=0;
                                break;
                        }
                    }
                    if((atoi(yytext)>32767 && sig!=2) || (atoi(yytext)>32768 && sig==2)  || !only_z)
                        yyerror("erreur lexicale");
                    else{ 
                        num_col+=yyleng;
                        if(yytext[0]=='0' && only_z){
                            yylval.str = "0";
                        } else{
                            yylval.str = (char *) strdup(yytext);
                        }
                        return INT_NUM;
                      }}
[[:digit:]]+"."[[:digit:]]*  {  
                                int count_z =0;
                                int i = 0;
                                if(yytext[0]=='0'){
                                    for(i; i<yyleng; i++){
                                        if(yytext[i]!='0'){
                                            if (yytext[i]=='.')
                                                count_z = i-1;
                                            break;
                                        }
                                        count_z = count_z+1;}
                                }
                                num_col+=yyleng; 
                                yylval.str = (char *) strdup((yytext+count_z));
                                return FLOAT_NUM;
                             }    
            
[[:upper:]][[:alnum:]]*       { if(yyleng>8){
                                    yyerror("erreur lexicale");
                                    printf("\033[1;36m"); printf("\t\t\t\t\t > %s\n", yytext); printf("\033[0m");
                                }else{
                                    recherche(yytext, NONE_TYPE, 0);
                                    num_col+=yyleng;
                                    yylval.str = (char *) strdup(yytext);
                                    return ID;
                               }}
[a-zA-Z0-9&éàçèù$_][a-zA-Z0-9&éàçèù$_]*       { yyerror("erreur lexicale");
                        printf("\033[1;31m"); printf("\t\t\t\t\t > %s\n", yytext); printf("\033[0m");}     

.                     { yyerror("erreur lexicale");}

}
%%