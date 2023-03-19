struct quad{
    char *operation;
    char *operator1;
    char *operator2;
    char *result;
    struct quad *next;
};

int qc = 0;
struct quad *head_quad = NULL;
struct quad *rear = NULL;


void insert_quad(char* oprt, char *opr1, char *opr2, char *result){
        struct quad *item = (struct quad*) malloc(sizeof(struct quad));
        item->operation = strdup(oprt);
        item->operator1 = strdup(opr1);
        item->operator2 = strdup(opr2);
        item->result = strdup(result);
        item->next = NULL;
        struct quad *current = head_quad;
        if(current == NULL){
            head_quad = item;
            rear = item;
        }else{
            rear->next = item;
            rear = item;
        }
        qc++;
}
struct quad *getQuad(int pos){
   struct quad *current = head_quad;
   int i = 0;
   while(current != NULL) {
         if(i==pos)
               return current;
         current = current->next;
         i++;
      }  
      return NULL;
}
void free_quad(){
    struct quad *ptr;
    while(head_quad != NULL) {
        ptr = head_quad->next;
        free(head_quad);
        head_quad = ptr;
    }
}
void afficher_quad(){
    if(head_quad!=NULL){
        
    printf("\n\t\t\t/***************Table des Quadruples*************/\n");
    printf("\t#==============#==============#===============#===============#===============#\n");
    printf("\t|     Index    |  operation   |  operator1    |  operator2    |   result      |\n");
    printf("\t#==============#==============#===============#===============#===============#\n");
    struct quad *ptr = head_quad;
    int i=0;
    while(ptr != NULL) {
        printf("\t|%13d | %12s |%14s |%14s |%14s |\n",i,
                                    ptr->operation,
                                    ptr->operator1,
                                    ptr->operator2,
                                    ptr->result);
        printf("\t#-----------------------------------------------------------------------------#\n");
        ptr = ptr->next;
        i++;
    }
    
}
}
