%{
    #include "quad_funcs.h"

    extern int num_line, num_col;
    extern int yylex();
    void yyerror(char  *msg);
    int errors=0;
    int temp=1;
    int used_type;
    char result[10] = "\0";
    char result2[10]= "\0";
%}

%union 
{ 
    char* str;
    struct {
        char* val;
        int type; /*int => 0, float =>1, char =>2 */
    }NT;
};

%token  INT FLOAT BOOL CHAR   
%token  WHILE IF ELSE RANGE FOR NEWLINE NOT
%token  INDENT UNDENT TWOD COMMA LBRACKET RBRACKET LPAREN RPAREN

%token  <str> ID  
%token  <str> TRUE FALSE  
%token  <str> INT_NUM
%token  <str> FLOAT_NUM
%token  <str> CHAR_VAL

%type <NT> exprl expr types
%type <NT> ListIdfs if_core if_condition while_condition for_in_condition for_range_condition

%left OR AND GT GE LT LE EQL NEQL IN
%left ADD SUB 
%left MUL DIV 
%right ASSIGN

%start S

%%
NEWLINE_BLOCK: /* empty */ |  NEWLINE_BLOCK  NEWLINE ;
S   :   /* empty */ |  NEWLINE_BLOCK statements  NEWLINE_BLOCK 
    ;
statements
    :    statements NEWLINE_BLOCK statement              
    |    statement 
    ;
block
    :   TWOD NEWLINE_BLOCK INDENT statements NEWLINE_BLOCK UNDENT  
    ;

statement    
    :   if_core else_block {
                        sprintf(getQuad($1.type)->operator1, "(%d)", qc); 
                    }

    |   for_range_condition block{
                        strcpy(result,"\0");
                        insert_quad("+",  "1",  getQuad($1.type-1)->result, getQuad($1.type-1)->result);
                        sprintf(result, "(%d)", $1.type); 
                        insert_quad("BR",  result,  "", "");
                        sprintf(getQuad($1.type+1)->operator1, "(%d)", qc); 
    }
    |   for_in_condition block {
                        strcpy(result,"\0");
                        insert_quad("+",  "1",  $1.val, $1.val);
                        sprintf(result, "(%d)", $1.type); 
                        insert_quad("BR",  result,  "", "");
                        sprintf(getQuad($1.type)->operator1, "(%d)", qc);
    }
    |   while_condition block {
                        strcpy(result,"\0");
                        sprintf(result, "(%d)", $1.type); 
                        insert_quad("BR",  result,  "", "");
                        sprintf(getQuad($1.type)->operator1, "(%d)", qc); 
                        }
    // ID ASSIGNING
    |   declaration NEWLINE
    ;
else_block: | ELSE block ;
// BLOCK IF
if_core : if_condition block {
                                $$.type=qc; 
                                insert_quad("BR",  "",  "", "");
                                sprintf(getQuad($1.type)->operator1, "(%d)", qc);   
                            }; 
//if_condition : IF exprl {
//                        $$.type=qc; 
//                        insert_quad("BZ",  "",  $2.val, ""); 
//                    };
if_condition : IF LPAREN exprl RPAREN{
                        $$.type=qc; 
                        insert_quad("BZ",  "",  $3.val, ""); 
                    };
// BLOCK WHILE
while_condition : WHILE LPAREN exprl RPAREN {
                            $$.type=qc; 
                            insert_quad("BZ",  "",  $3.val, "");    };
// BLOCK FOR RANGE
for_range_condition:FOR ID IN RANGE LPAREN INT_NUM COMMA INT_NUM RPAREN {
                                    if(getType($2) == NONE_TYPE)
                                        setType($2, INT_TYPE);
                                    else if(getType($2)!=INT_TYPE){
                                        yyerror("erreur semantique incompatibilite des types");                                
                                    }
                                    insert_quad("=",  $6,  "", $2);    
                                    $$.type=qc;
                                    sprintf(result, "T%d", temp);
                                    insert_quad("-", $2, $8, result);
                                    insert_quad("BPZ",  "",  result, "");    
                                    temp++; 
};
// BLOCK FOR IN
for_in_condition:FOR ID IN ID {     
                                int ty2 = getType($2), ty4=getType($4);
                                if( ty4 == INT_ARR_TYPE || ty4==FLOAT_ARR_TYPE || ty4==CHAR_ARR_TYPE){
                                    
                                    if(ty2==NONE_TYPE){
                                        if(ty4 == INT_ARR_TYPE) setType($2, INT_TYPE);
                                        if(ty4 == FLOAT_ARR_TYPE) setType($2, FLOAT_TYPE);
                                        if(ty4 == CHAR_ARR_TYPE) setType($2, CHAR_TYPE);
                                    }else{
                                        if( (ty4==INT_ARR_TYPE && ty2 != INT_TYPE)|| 
                                        (ty4==FLOAT_ARR_TYPE && ty2 != FLOAT_TYPE)|| 
                                        (ty4==CHAR_ARR_TYPE  && ty2 != CHAR_TYPE) ) 
                                             yyerror("erreur semantique incompatibilite des types");
                                    }
                                    sprintf(result, "T%d", temp);
                                    insert_quad("=","" , "0", result);
                                    
                                    strcpy($$.val, result);
                                    sprintf(result, "taille(%s)", $4);
                                    $$.type=qc; 
                                    insert_quad("BZ",  "",  $$.val, result);
                                    sprintf(result, "%s[T%d]",$4, temp);
                                    insert_quad("=","" , result, $2);
                                    
                                    temp++;
                                }else if(ty4 == NONE_TYPE)
                                   yyerror("erreur semantique array non declare");
                                else
                                    yyerror("erreur semantique incompatibilite des types");
                                    
};
types 
    :   INT     {  used_type= INT_TYPE;}
    |   FLOAT   {  used_type= FLOAT_TYPE;}
    |   CHAR    {  used_type= CHAR_TYPE;}
    |   BOOL    {  used_type= INT_TYPE;}
    ;

ListIdfs 
    :   ID  COMMA ListIdfs { ifNoneSetType($1, used_type); }
    |   ID  { ifNoneSetType($1, used_type);}
    ;

declaration
    :   ID        ASSIGN exprl {if(getType($1)==$3.type || getType($1)==NONE_TYPE){
                                    setType($1, $3.type);
                                    insert_quad("=", $3.val, "", $1);
                                }else                                
                                   yyerror("erreur semantique incompatibilite des types");

                            }
    |   types     ListIdfs
    |   types     ID ASSIGN exprl {     if (used_type != $4.type)
                                            yyerror("erreur semantique incompatibilite des types");
                                        ifNoneSetType($2, used_type); 
                                        insert_quad("=", $4.val, "", $2);}
    |   types     ID LBRACKET expr RBRACKET {    
                                               int  i = qc-1;
                                                if(i>=0 && getQuad(i)->operation[0]=='-' && getQuad(i)->operator1[0]=='0'){ 
                                                    yyerror("erreur semantique  size of array is negative");
                                                }
                                                if(used_type == INT_TYPE)
                                                     ifNoneSetType($2, INT_ARR_TYPE);
                                                if(used_type == FLOAT_TYPE)
                                                     ifNoneSetType($2, FLOAT_ARR_TYPE);
                                                if(used_type == CHAR_TYPE)
                                                     ifNoneSetType($2, CHAR_ARR_TYPE);
                                                if ($4.type!=INT_TYPE){
                                                    yyerror("erreur semantique incompatibilite des types");
                                                }
                                                    insert_quad("BOUNDS", "0", $4.val, "");
                                                    insert_quad("ADEC", $2, "", "");
                                               }
    ;

exprl      
    :   exprl OR exprl  {              
                                    
                                    sprintf(result, "(%d)", qc+4);
                                    insert_quad("BNZ", result,   $1.val, "");
                                    insert_quad("BNZ", result,   $3.val, "");
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++;    }
    |   exprl AND  exprl {
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    sprintf(result, "(%d)", qc+4);
                                    insert_quad("BZ", result,   $1.val, "");
                                    insert_quad("BZ", result,   $3.val, "");
                                        insert_quad("=", "1" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "0" , "", $$.val);
                                    result[0]= '\0';
                                    temp++; }
    |   exprl LE   exprl  {
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    
                                    sprintf(result, "(%d)", qc+3);
                                    insert_quad("BPZ", result,  $1.val, $3.val);
                                    
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++; }
    |   exprl GE   exprl  {        
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    sprintf(result, "(%d)", qc+3);
                                    insert_quad("BMZ", result,     $1.val, $3.val);
                                    
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++; }
    |   exprl GT   exprl  {
                                   
                                
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    sprintf(result, "(%d)", qc+3);
                                    insert_quad("BM", result,   $1.val, $3.val);
                                    
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++; }
    |   exprl LT   exprl  {
                                   
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    sprintf(result, "(%d)", qc+3);
                                    insert_quad("BP", result,   $1.val, $3.val);
                                    
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++; }
   
    |   exprl EQL  exprl  {
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    sprintf(result, "(%d)", qc+3);
                                    insert_quad("BZ", result,    $1.val, $3.val);
                                    
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++; }
    |   exprl NEQL exprl  {
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    sprintf(result, "(%d)", qc+3);
                                    insert_quad("BNZ", result,     $1.val, $3.val);
                                    
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++; }
    |   exprl IN   exprl  {
                                    if( ($3.type==INT_ARR_TYPE && $1.type == INT_TYPE)|| 
                                        ($3.type==FLOAT_ARR_TYPE && $1.type == FLOAT_TYPE)|| 
                                        ($3.type==CHAR_ARR_TYPE  && $1.type == CHAR_TYPE) ){                           
                                    sprintf(result, "T%d", temp);
                                    sprintf(result2, "taille(%s)", $3.val);

                                        insert_quad("-", "1", result2, result);
                                    sprintf(result2, "%s[%s]", $3.val, result);
                                    temp++; 
                                    sprintf(result, "T%d", temp);

                                        insert_quad("-", $1.val, result2, result);
                                    sprintf(result2, "(%d)", qc+5);
                                        insert_quad("BZ", result2, result, "");

                                        insert_quad("-", "1", result, result);
                                    sprintf(result2, "(%d)", qc-3);
                                        insert_quad("BNZ", result2, result, "");
                                    
                                    $$.val = strdup(result);
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    result2[0]= '\0';
                                    temp++;
                                    }else
                                        yyerror("erreur semantique incompatibilite des types");

                                     }
    |   expr  { $$ = $1;}
    ;
expr
    :   expr ADD expr { 
                        if($1.type==$3.type) {
                            if($1.type==CHAR_TYPE || ($1.type==INT_ARR_TYPE)|| ($1.type==FLOAT_ARR_TYPE)|| ($1.type==CHAR_ARR_TYPE)){
                                yyerror("erreur semantique incompatibilite des types");
                                
                            }
                            else{
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    insert_quad("+", $1.val, $3.val, $$.val);
                                    result[0]= '\0';
                                    temp++;
                            }
                    }else{
                        
                        yyerror("erreur semantique incompatibilite des types");
                    }
    }
    |   expr SUB expr { if($1.type==$3.type) {
                            if($1.type==CHAR_TYPE || ($1.type==INT_ARR_TYPE)|| ($1.type==FLOAT_ARR_TYPE)|| ($1.type==CHAR_ARR_TYPE)){
                                
                                yyerror("erreur semantique incompatibilite des types");
                            }
                            else{
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    insert_quad("-", $1.val, $3.val, $$.val);
                                    result[0]= '\0';
                                    temp++;
                            }
                    }else{
                        
                        yyerror("erreur semantique incompatibilite des types");
                    }
    }
    |   expr MUL expr  { if($1.type==$3.type) {
                            if($1.type==CHAR_TYPE || ($1.type==INT_ARR_TYPE)|| ($1.type==FLOAT_ARR_TYPE)|| ($1.type==CHAR_ARR_TYPE))
                                yyerror("erreur semantique incompatibilite des types");
                        
                            else{
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    insert_quad("*", $1.val, $3.val, $$.val);
                                    result[0]= '\0';
                                    temp++;
                            }
                    }else
                        yyerror("erreur semantique incompatibilite des types");
                    
    }
    |   expr DIV expr { if($1.type==$3.type) {
                            if($1.type==CHAR_TYPE || ($1.type==INT_ARR_TYPE)|| ($1.type==FLOAT_ARR_TYPE)|| ($1.type==CHAR_ARR_TYPE))
                                yyerror("erreur semantique incompatibilite des types");
                            else if(strcmp($3.val, "0")==0)
                                   yyerror("warning division par zero");
                            else{
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    insert_quad("/", $1.val, $3.val, $$.val);
                                    result[0]= '\0';
                                    temp++;
                            }
                    }else{
                        yyerror("erreur semantique incompatibilite des types");
                    }
    }
    |   NOT LPAREN exprl RPAREN   {    
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    sprintf(result, "(%d)", qc+3);
                                        insert_quad("BZ", result,  $3.val, "");
                                    
                                        insert_quad("=", "0" , "", $$.val);
                                    sprintf(result, "(%d)", qc+2);
                                        insert_quad("BR", result , "", "");
                                        insert_quad("=", "1" , "", $$.val);
                                    result[0]= '\0';
                                    temp++;        
    }
    |   LPAREN exprl RPAREN              {$$ = $2;}
    |   LPAREN SUB expr RPAREN   {
                                    sprintf(result, "T%d", temp);
                                    $$.val = strdup(result);
                                    $$.type = $3.type;
                                    insert_quad("-", "0", $3.val, $$.val);
                                    result[0]= '\0';
                                    temp++; 
                                }
    |   ID          {   if(getType($1)==NONE_TYPE)
                            yyerror("erreur semantique (non declare)");
                        else{   $$.val = $1;
                                $$.type= getType($1);}
                        }
    |   TRUE        {$$.val = $1; $$.type=INT_TYPE;}
    |   FALSE       {$$.val = $1; $$.type=INT_TYPE;}
    |   INT_NUM     {$$.val = $1; $$.type=INT_TYPE;}
    |   FLOAT_NUM   {$$.val = $1; $$.type=FLOAT_TYPE;}
    |   CHAR_VAL    {$$.val = $1; $$.type=CHAR_TYPE;}
    ;
%%
void yyerror(char  *msg){
    printf("\033[1;101m");
    printf("%s  ligne = %d  colonne = %d", msg, num_line-s, num_col);
    printf("\033[0m");
    puts("");
    errors = errors+1;
}


int main(int argc, char *argv[]){
    extern FILE *yyin;
    if(argc>1){
        char *test = argv[1],ext[5];
        test = strrev(test);
        strncpy(ext, test, 4);
        if (strcmp(ext, "ypm.")==0){
                test = strrev(test);
                yyin = fopen(argv[1], "r");
                if(yyin!=NULL){
                    yyparse ();
                    if(!errors){
                        printf("\033[0;93m");
                        afficher_ts();
                        afficher_quad();
                        printf("\033[0m");
                    }else{
                        printf("\033[1;39m");
                        printf("** Nomber de(s) errors est : %d \n", errors);
                        printf("\033[0m");
                    }
                    fclose(yyin);
                    free_quad();
                    free_ts();
            }else
                printf("file : not found at %s",argv[1]);
        }else
            printf("error file type !!  \nUsage: %s [filename.mpy]", argv[0]);
    }else
        printf("%s [filename.mpy]", argv[0]);

return 0;
}