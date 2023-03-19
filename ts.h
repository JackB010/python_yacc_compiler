#define NONE_TYPE      -1
#define KEYWORD_TYPE    3
#define INT_TYPE        0
#define FLOAT_TYPE      1
#define CHAR_TYPE       2
#define INT_ARR_TYPE    4
#define FLOAT_ARR_TYPE  5
#define CHAR_ARR_TYPE   6

extern void yyerror(char  *msg);

struct element{
   char name[20];
   int type;
   struct element *next;
 };
struct element *head_idf = NULL;
struct element *head_sp = NULL;
struct element *head_mc = NULL;
struct element *rear_idf = NULL;
struct element *rear_sp = NULL;
struct element *rear_mc = NULL;


void inserer (char name[], int type, int y){
    struct element *item = (struct element*) malloc(sizeof(struct element));
    strcpy(item->name, name);
    item->type= type;
    item->next= NULL;
        if(y==0){
                if(head_idf == NULL){
                    head_idf = item;
                    rear_idf = item;
                }else{
                    rear_idf->next = item;
                    rear_idf = item;
                }
        }else if(y==1){
            if(head_mc == NULL){
                    head_mc = item;
                    rear_mc = item;
                }else{
                    rear_mc->next = item;
                    rear_mc = item;
                }
        }else{
            if(head_sp == NULL){
                    head_sp = item;
                    rear_sp = item;
                }else{
                    rear_sp->next = item;
                    rear_sp = item;
                }
            }
   }
void recherche (char name[], int type, int y) {
    struct element *current = NULL;
    int found = 0;
    if(y==0) 
        current = head_idf; 
    else if(y==1)
        current = head_mc;
    else 
        current = head_sp;

    while(current != NULL) {
        if(strcmp(current->name,name)==0)
            found = 1;    
        current = current->next;
    }  
    if(!found)
        inserer(name, type,  y);    
} 
struct element *searchIDF(char name[]){
   struct element *current = head_idf;
   while(current != NULL) {
         if(strcmp(current->name,name)==0)
               return current;
         current = current->next;
      }  
      return NULL;
}
void setType(char name[], int type){
        struct element *i = searchIDF(name);
        i->type = type;
}
int getType(char name[]){
        struct element *i = searchIDF(name);
        return i->type;
}
void ifNoneSetType(char name[], int type){
      if(getType(name)!=NONE_TYPE)
           yyerror("erreur semantique double declaration");
      else
          setType(name, type);
}
void free_ts(){
    struct element *ptr;
    while(head_idf != NULL) {
        ptr = head_idf->next;
        free(head_idf);
        head_idf = ptr;
    }
    while(head_mc != NULL) {
        ptr = head_mc->next;
        free(head_mc);
        head_mc = ptr;
    }
    while(head_sp != NULL) {
        ptr = head_sp->next;
        free(head_sp);
        head_sp = ptr;
    }
}


void afficher_ts(){  
    struct element *ptr;
    if(head_idf != NULL){
        printf("\t/***************Table des symboles IDF*************/\n");
        printf("\t\t\t#==============#===============#\n");
        printf("\t\t\t|  Nom_Entite  |  Type_Entite  |\n");
        printf("\t\t\t#==============#===============#\n");
        ptr = head_idf;
         while(ptr != NULL) {
              printf("\t\t\t|%13s |%14d |\n",ptr->name,ptr->type);
              ptr = ptr->next;
           }     
           printf("\t\t\t#==============================#\n");
       }
     if(head_mc != NULL){
        printf("\n\t/***************Table des symboles mots clés*************/\n");

        printf("\t\t\t#=========================#\n");
        printf("\t\t\t| NomEntite |  CodeEntite | \n");
        printf("\t\t\t#=========================#\n");

         ptr = head_mc;
         while(ptr != NULL) {
              printf("\t\t\t|%10s |%12d |\n",ptr->name,ptr->type);
              ptr = ptr->next;
           } 
        printf("\t\t\t#=========================#\n");
        }    
}


