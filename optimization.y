Parser.y
%{
/*defini(ons*/
#include <stdio.h>
#include<string.h>
#include<stdlib.h>
#include<ctype.h>
#include <limits.h>
// #include"lex.yy.c" // this is crea(ng mul(ple defini(ons // Declara(on of tree
struct node {
int num_children; // Number of children
struct node **children; // Array of pointers to child nodes
char *token; // Token associated with the node
};
struct node *head;
struct node* mknode(int num_children, struct node **children, char *token) ;
void prinCree(struct node* tree);
void printInorder(struct node *tree);
void add(char);
void insert_type();
int search(char *);
void check_declaraEon(char *);
void check_return_type(char *);
char *get_type(char *);
char *get_datatype(char *);
struct dataType {
char * id_name;
int used; // for op(miza(on stage - to check if the declared variable is used anywhere else in the program
char * data_type;
char * type;
int line_no;
int thisscope;
int num_params;
int range[10][2]; // [start index of first computa(on in icg,end index of assignment in icg for that chunk]
int range_count;
} symbol_table[10000];
int count=0;
int q;
char type[10];
extern int countn;
extern int scope;
int curr_num_params=0;
int curr_num_args=0;
extern char* yy_text;
char exp_type[30]; // will be empty if no expression is there
int sem_errors=0;
char buff[10000];
char errors[10][10000];
int oldscope=-1;
// Intermediate code genera(on
int ic_idx=0; // used to index the intermediate 3 address codes to show them together later in output
int label[10000]; // label stack to store the order of labels in the intermediate code
// label number in the intermediate code -> GOTO L4
// LABEL L4: ....
int ifelsetracker=-1; // used to store the ending label for an if-elseLadder
int jumpcorrecEon[10000]; // jumpcorrec(on[instruc(on number] = label number aUer a if-else Ladder
int lastjumps[10000];
int lastjumpstackpointer=0;
int laddercounts[10000];
int laddercountstackpointer=0;
int stackpointer=0; // used to index the label stack
int labelsused=0; // used to keep track of the number of labels used in the intermediate code
int looplabel[10000]; // another stack
int looplabelstackpointer=0; // another stack pointer
int insNumOfLabel[10000]; // used to store the instruc(on number of each label
int gotolabel[10000]; // another stack
int gotolabelstackpointer=0; // another stack pointer
int rangestart=-1,rangeend=-1; // used to store the range of instruc(ons for a chunk of variable declara(on/assignment code temperorily
int uselessranges[10000][2]; // used to store the range of instruc(ons for a chunk of useless variable declara(on/assignment code overall
int uselessrangescount=0;
char icg[10000][20]; // stores the intermediate code instruc(ons themselves as strings
int isleader[10000]; // stores whether the instruc(on is a leader or not
int registerIndex=0; // used to index the registers used in the intermediate code
int registers[10000]; // stores the registers used in the intermediate code
int regstackpointer=0; // used to index the register stack
int firstreg=-1,secondreg=-1,thirdreg=-1; // used to track regIndices in exp*exp //finish wri(ng the reserved words,there are more reserved words

const int reserved_count = 13; // why is this not working for reserved[reserved_count][20]???
char reserved[13][20] = {"purnank", "nahi", "afar", "pani", "purnank", "bilkul",};
// Func(on to mark a variable as used if found in the symbol table
void markVariableAsUsed(const char *id_name) {
for(inti=0;i<10000;++i){
if (symbol_table[i].id_name != NULL && strcmp(symbol_table[i].id_name, id_name) ==0){
symbol_table[i].used = 1;
return;
}
}
}
// Func(on to search for an iden(fier in the symbol table and return its index if found int findIdenEfierIndex(char *id_name) {
for(inti=0;i<10000;i++){
if (symbol_table[i].id_name != NULL && strcmp(symbol_table[i].id_name, id_name) ==0){
return i; // Return the index if found
}
}
return -1; // Return -1 if not found
}
// Func(on to swap two ranges
void swapRanges(int range1[], int range2[]) {
int tempStart = range1[0];
int tempEnd = range1[1];
range1[0] = range2[0];
range1[1] = range2[1];
range2[0] = tempStart;
range2[1] = tempEnd;
}
// Func(on to sort the 2D array of ranges
void sortRanges(int ranges[][2], int rangeCount) { for(inti=0;i<rangeCount-1;i++){
for(intj=0;j<rangeCount-i-1;j++){
if (ranges[j][0] > ranges[j + 1][0]) {
swapRanges(ranges[j], ranges[j + 1]);
}
}
}
}
%}

%error-verbose %union {
struct var_name { char name[10000]; struct node* nd;
} nd_obj;
}
%token<nd_obj> EOL Hindi_INT Hindi_FLOAT Hindi_ARITHMETIC_OPERATOR Hindi_COMPARISON_OPERATOR Hindi_ASSIGNMENT_OPERATOR Hindi_LOGICAL_OPERATOR
%token<nd_obj> Hindi_DATATYPE Hindi_IF Hindi_ELIF Hindi_ELSE Hindi_WHILE Hindi_OPEN_FLOOR_BRACKET Hindi_CLOSED_FLOOR_BRACKET
%token<nd_obj> Hindi_IDENTIFIER Hindi_STRING Hindi_OPEN_CURLY_BRACKET Hindi_CLOSED_CURLY_BRACKET Hindi_OPEN_SQUARE_BRACKET Hindi_CLOSED_SQUARE_BRACKET
%token<nd_obj> Hindi_PUNCTUATION_COMMA Hindi_NEWLINE Hindi_FINISH Hindi_FUNCTION Hindi_RETURN Hindi_CHARACTER Hindi_PRINT
Hindi_IMPORT Hindi_INPUT
%type<nd_obj> program,input,exp,condiEon,if_statement,while_loop,variable_declaraEon,paramete rs_repeat,equaEon,parameters_line,funcEon_declaraEon,funcEon_content,bunch_o f_stat
ements,elif_repeat, else_statement,if_else_ladder,empty_lines,funcEon_call,idenEfiers_line,idenEfiers_r epeat,Hindi_print,print_content,print_statement,Hindi_constant
%type<nd_obj> Hindi_idenEfier_declaring,eol,Hindi_int, Hindi_float, Hindi_arithmeEc_operator, Hindi_comparison_operator, Hindi_assignment_operator,
Hindi_logical_operator, Hindi_datatype, Hindi_if, Hindi_elif, Hindi_else,
Hindi_while, Hindi_idenEfier, Hindi_string, Hindi_open_curly_bracket, Hindi_closed_curly_bracket, Hindi_open_square_bracket, Hindi_closed_square_bracket,
Hindi_open_floor_bracket, Hindi_funcEon_name,Hindi_funcEon_name_call,Hindi_closed_floor_bracket, Hindi_punctuaEon_comma, Hindi_newline, Hindi_finish, Hindi_funcEon, Hindi_return, Hindi_character,Hindi_import,Hindi_input,Hindi_imported_library
%%
program:
input {int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
// Assigning children nodes
children[0] = $1.nd; // Assuming $1 represents the parse tree node for symbol1

// Assign more children if needed
// Create the parse tree node for the produc(on rule
$$.nd = mknode(num_children, children, "program");
head = $$.nd;}
eol:
EOL {$$.nd = mknode(NULL, NULL, "newline");}
Hindi_idenEfier:
Hindi_IDENTIFIER {prins("CHECKING FOR %s\n",$1.name);check_declaraEon($1.name); prins("saw pure id2");$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_funcEon_name: // only for func(ons being declared
Hindi_IDENTIFIER {prins("parser saw HindiFuncNamex");
$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_funcEon_name_call: // only for func(ons being called
Hindi_IDENTIFIER {prins("parser saw HindiFuncNameCall");
$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_idenEfier_declaring: // only for iden(fiers being declared
Hindi_IDENTIFIER { prins("saw varDeclareid");add('V');$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_imported_library: // only for iden(fiers being declared
Hindi_IDENTIFIER { add('L');$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_print:
Hindi_PRINT {add('K');$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_int:
Hindi_INT {$$.nd = mknode(NULL, NULL, $1.name);add('i');}
Hindi_input: // cin>> , scanf()
Hindi_INPUT {add('K');$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_float:
Hindi_FLOAT {add('f');$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_import:
Hindi_IMPORT {$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_constant:
Hindi_INT {$$.nd = mknode(NULL, NULL, $1.name);add('i');}
| Hindi_FLOAT {$$.nd = mknode(NULL, NULL, $1.name);add('f');}
| Hindi_STRING {$$.nd = mknode(NULL, NULL, $1.name);add('s');}
| Hindi_CHARACTER {$$.nd = mknode(NULL, NULL, $1.name);add('c');} Hindi_arithmeEc_operator:
Hindi_ARITHMETIC_OPERATOR {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_comparison_operator:
Hindi_COMPARISON_OPERATOR {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_assignment_operator:
Hindi_ASSIGNMENT_OPERATOR {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_logical_operator:

Hindi_LOGICAL_OPERATOR {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_datatype:
Hindi_DATATYPE {insert_type();$$.nd = mknode(NULL, NULL, $1.name);} Hindi_if:
Hindi_IF {add('K');$$.nd = mknode(NULL, NULL, "if");} Hindi_elif:
Hindi_ELIF {add('K');$$.nd = mknode(NULL, NULL, "elif");} Hindi_else:
Hindi_ELSE {add('K');$$.nd = mknode(NULL, NULL, "else");} Hindi_while:
Hindi_WHILE {add('K');$$.nd = mknode(NULL, NULL,"while");} Hindi_string:
Hindi_STRING {add('s');$$.nd = mknode(NULL, NULL, $1.name);} Hindi_open_curly_bracket:
Hindi_OPEN_CURLY_BRACKET {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_closed_curly_bracket:
Hindi_CLOSED_CURLY_BRACKET {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_open_square_bracket:
Hindi_OPEN_SQUARE_BRACKET {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_closed_square_bracket:
Hindi_CLOSED_SQUARE_BRACKET {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_open_floor_bracket:
Hindi_OPEN_FLOOR_BRACKET {$$.nd = mknode(NULL, NULL, $1.name);scope++;} // increase scope for variables
Hindi_closed_floor_bracket:
Hindi_CLOSED_FLOOR_BRACKET {$$.nd = mknode(NULL, NULL, $1.name); //here we need to remove all the variables declared in this scope
// change all of their scope to INT_MAX
int i;
for(i=count-1; i>=0; i--) {
if(symbol_table[i].thisscope == scope &&
strcmp(symbol_table[i].type, "Variable")==0) {
symbol_table[i].thisscope = INT_MAX;
prins("\nERASING %s from symbol table as its CURRENT SCOPE is FINISHED\n", symbol_table[i].id_name);
}
}
scope--;
} // decrease scope for variables
Hindi_punctuaEon_comma:
Hindi_PUNCTUATION_COMMA {$$.nd = mknode(NULL, NULL, $1.name);} Hindi_newline:
Hindi_NEWLINE {$$.nd = mknode(NULL, NULL, $1.name);}

Hindi_finish:
Hindi_FINISH {$$.nd = mknode(NULL, NULL, $1.name);
strcpy(exp_type," ");
} // resecng exp_type string
Hindi_funcEon:
Hindi_FUNCTION {add('K');$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_return:
Hindi_RETURN {add('K');$$.nd = mknode(NULL, NULL, $1.name);}
Hindi_character:
Hindi_CHARACTER {add('c');$$.nd = mknode(NULL, NULL, $1.name);}
input: // input can be empty also
{ $$.nd = mknode(NULL, NULL, "empty"); }
| input eol {
prins("Parser found input-eol\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "input-eol");
}
| eol input {
prins("Parser found eol-input\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "eol-input");
}
| input Hindi_import Hindi_imported_library Hindi_finish {
//add('H');
prins("Parser found input-import-lib-;\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "input-import-lib-;");
}
| Hindi_import Hindi_imported_library Hindi_finish input {

//add('H');
prins("Parser found import-lib-;-input\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "import-lib-;-input");
}
| input bunch_of_statements input {
prins("Parser found input-bunch_of_stmts-input\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
$$.nd = mknode(num_children, children, "input-bunch-input");
}
| input {insNumOfLabel[labelsused]=ic_idx; sprins(icg[ic_idx++], "LABEL L%d:\n", labelsused++);} funcEon_declaraEon input {
//add('F');
prins("Parser found input-funcEonDec-input\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $3.nd;
children[2] = $4.nd;
$$.nd = mknode(num_children, children, "input-funDec-input");
}
;
empty_lines:
EOL
| empty_lines EOL
exp: // empty not allowed
Hindi_int {
if(strcmp(exp_type," ")==0) {
strcpy(exp_type, "sankhya");
}
else if(strcmp(exp_type, "theek")==0) {

sprins(errors[sem_errors], "Line %d: operaEon among int and string in expression not allowed\n", countn+1);
sem_errors++;
}
prins("Parser found int\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "INT");
// if(firstreg == -1){
// firstreg = registerIndex++;
// sprini(icg[ic_idx++], "R%d = %s\n", firstreg, $1.name);
//}
// else{
// secondreg = registerIndex++;
// sprini(icg[ic_idx++], "R%d = %s\n", secondreg, $1.name);
//}
registers[regstackpointer++]=registerIndex;
sprins(icg[ic_idx++], "MOV R%d , %s\n", registerIndex++, $1.name);
}
| Hindi_float {
if(strcmp(exp_type," ")==0) {
strcpy(exp_type, "nahi");
}
else if(strcmp(exp_type, "theek")==0) {
sprins(errors[sem_errors], "Line %d: operaEon among float and string in expression not allowed\n", countn+1);
sem_errors++;
}
prins("Parser found float\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "FLOAT"); registers[regstackpointer++]=registerIndex;
sprins(icg[ic_idx++], "MOV R%d , %s\n", registerIndex++, $1.name);
}
| Hindi_character {
prins("Parser found character\n");
int num_children = 1; // Number of children

struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "CHAR"); registers[regstackpointer++]=registerIndex;
sprins(icg[ic_idx++], "MOV R%d , %s\n", registerIndex++, $1.name); }
| Hindi_string {
if(strcmp(exp_type," ")==0) {
strcpy(exp_type, "theek");
}
else if(strcmp(exp_type, "sankhya")==0 || strcmp(exp_type, "theek")==0) { sprins(errors[sem_errors], "Line %d: operaEon among string and int/float in expression not allowed\n", countn+1);
sem_errors++;
}
prins("Parser found string\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "STRING"); registers[regstackpointer++]=registerIndex;
sprins(icg[ic_idx++], "MOV R%d , %s\n", registerIndex++, $1.name);
}
| Hindi_idenEfier {
prins("Parser found idenEfier\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "ID"); registers[regstackpointer++]=registerIndex;
sprins(icg[ic_idx++], "MOV R%d , %s\n", registerIndex++, $1.name); markVariableAsUsed($1.name); // op(miza(on stage
}
| funcEon_call {
prins("Parser found funcCall\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "funcCall");

}
| Hindi_idenEfier Hindi_open_square_bracket exp Hindi_closed_square_bracket { prins("Parser found id[exp]\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "ID[exp]"); //registers[regstackpointer++]=registerIndex;
sprins(icg[ic_idx++], "MOV R%d , %s+R%d\n", registerIndex-1 , $1.name,registerIndex-1);
}
| Hindi_open_curly_bracket exp Hindi_closed_curly_bracket {
prins("Parser found (exp)\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
// Assigning children nodes
children[0] = $1.nd; // Assuming $1 represents the parse tree node for symbol1 children[1] = $2.nd; // Assuming $2 represents the parse tree node for symbol2 children[2] = $3.nd;
$$.nd = mknode(num_children, children, "(exp)");
// Free the memory allocated for the array of children
//free(children);
}
| exp {firstreg = registerIndex-1;registers[registerIndex-1]=firstreg;} Hindi_arithmeEc_operator exp
{secondreg = registerIndex-1;registers[registerIndex-1]=secondreg;} { prins("Parser found exp-arithmeEcOp-exp\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
// Assigning children nodes
children[0] = $1.nd; // Assuming $1 represents the parse tree node for symbol1 children[1] = $3.nd; // Assuming $2 represents the parse tree node for symbol2 children[2] = $4.nd;
// Assign more children if needed
// Create the parse tree node for the produc(on rule
$$.nd = mknode(num_children, children, "AthemaEcOp");
// Free the memory allocated for the array of children

//free(children);
//regstackpointer--;
if(($3.name)[0] == '+')
sprins(icg[ic_idx++], "ADD R%d , R%d\n", secondreg , registers[--regstackpointer]-1); else if(($3.name)[0] == '-')
sprins(icg[ic_idx++], "SUB R%d , R%d\n", secondreg , registers[--regstackpointer]-1); else if(($3.name)[0] == '*')
sprins(icg[ic_idx++], "MUL R%d , R%d\n", secondreg , registers[--regstackpointer]-1); else if(($3.name)[0] == '/')
sprins(icg[ic_idx++], "DIV R%d , R%d\n", secondreg , registers[--regstackpointer]-1); else if(($3.name)[0] == '%')
sprins(icg[ic_idx++], "MOD R%d , R%d\n", secondreg , registers[--regstackpointer]-1); else{
sprins(icg[ic_idx++], "R%d = R%d %c R%d\n", secondreg , registers[-- regstackpointer]-1, ($3.name)[0],secondreg);
}
//secondreg = firstreg;
//first = registers[regstackpointer];
}
| exp {firstreg = registerIndex-1;} Hindi_logical_operator exp {secondreg = registerIndex-1;} {
prins("Parser found exp-logicalOp-exp\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $3.nd;
children[2] = $4.nd;
$$.nd = mknode(num_children, children, "LogicalOp");
//sprini(icg[ic_idx++], "R%d = R%d %s R%d\n", secondreg , firstreg, $3.name, secondreg);
if (strcmp($3.name, "mariyu") == 0) {
sprins(icg[ic_idx++], "AND R%d , R%d\n", secondreg , firstreg);
}
else if (strcmp($3.name, "leda") == 0) {
sprins(icg[ic_idx++], "OR R%d , R%d\n", secondreg , firstreg);
}
// else if (strcmp($3.name, "kaadu") == 0) {
// sprini(icg[ic_idx++], "NOT R%d , R%d\n", secondreg , firstreg);
//}
else if (strcmp($3.name, "pratyekam") == 0) {
sprins(icg[ic_idx++], "XOR R%d , R%d\n", secondreg , firstreg);
}

else{
sprins(icg[ic_idx++], "R%d = R%d %s R%d\n", secondreg , firstreg, $3.name,secondreg);
}
}
| exp {firstreg = registerIndex-1;} Hindi_comparison_operator exp {secondreg = registerIndex-1;} {
prins("Parser found exp-compOp-exp\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $3.nd;
children[2] = $4.nd;
$$.nd = mknode(num_children, children, "CompOp");
//sprini(icg[ic_idx++], "R%d = R%d %s R%d\n", secondreg , firstreg, $3.name, secondreg);
if (strcmp($3.name, "chinnadi") == 0) {
sprins(icg[ic_idx++], "LT R%d , R%d\n", secondreg , firstreg);
}
else if (strcmp($3.name, "peddadi") == 0) {
sprins(icg[ic_idx++], "GT R%d , R%d\n", secondreg , firstreg);
}
// else if (strcmp($3.name, "kaadu") == 0) {
// sprini(icg[ic_idx++], "NOT R%d , R%d\n", secondreg , firstreg);
//}
else if (strcmp($3.name, "peddadiLedaSamanam") == 0) {
sprins(icg[ic_idx++], "GE R%d , R%d\n", secondreg , firstreg);
}
else if (strcmp($3.name, "chinnadiLedaSamanam") == 0) {
sprins(icg[ic_idx++], "LE R%d , R%d\n", secondreg , firstreg);
}
else if (strcmp($3.name, "samanam") == 0) {
sprins(icg[ic_idx++], "EQ R%d , R%d\n", secondreg , firstreg);
}
else if (strcmp($3.name, "bhinnam") == 0) {
sprins(icg[ic_idx++], "NE R%d , R%d\n", secondreg , firstreg);
}
else{
sprins(icg[ic_idx++], "R%d = R%d %s R%d\n", secondreg , firstreg, $3.name,secondreg);
}
}

| Hindi_idenEfier Hindi_open_square_bracket exp {registers[regstackpointer++]=registerIndex;
sprins(icg[ic_idx++], "MOV R%d , %s + R%d\n", registerIndex-1 , $1.name, registerIndex-1);} Hindi_closed_square_bracket {
prins("Parser found id[exp]\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $5.nd;
$$.nd = mknode(num_children, children, "id[exp]");
//sprini(icg[ic_idx++], "MOV R%d , %s + R%d\n", firstreg , $1.name, firstreg);
}
;
bunch_of_statements: //can be empty
{ $$.nd = mknode(NULL, NULL, "empty"); }
| eol bunch_of_statements {
prins("Parser found EOL-bunch\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "eol-bunch");
}
| bunch_of_statements eol {
prins("Parser found bunch-EOL\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "bunch-eol");
}
| bunch_of_statements if_else_ladder {
insNumOfLabel[labelsused]=ic_idx;
sprins(icg[ic_idx++], "LABEL L%d:\n", labelsused++); //lastjumps[lastjumpstackpointer++] = label[stackpointer-2];
int index = ic_idx - 1;
int count = laddercounts[laddercountstackpointer-1]; // Number of itera(ons for(inti=index;i>=0&&count>0;i--){

prins("icg[%d] = %s\n", i, icg[i]);
if (strncmp(icg[i], "JUMP ", 5) == 0) { // Check if the prefix matches "JUMP " prins("...................\n");
char jump_str[20]; // Assuming the number won't exceed 20 digits sprins(jump_str, "%d", labelsused-1); // Convert number to string
snprins(icg[i], 20, "JUMPx L%s\n", jump_str); // Set icg[i] to "JUMP" followed by the number
count--;
}
}
lastjumpstackpointer--; // forgecng the current ifelseLadder's lastjump and counts laddercountstackpointer--;
} bunch_of_statements {
}{
prins("Parser found bunch_of_statement if_else_ladder bunch\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $4.nd;
$$.nd = mknode(num_children, children, "bunch-IfElse-bunch");
}
| bunch_of_statements Hindi_input Hindi_open_curly_bracket Hindi_idenEfier Hindi_closed_curly_bracket Hindi_finish bunch_of_statements {
prins("Parser found bunch_of_statement-inputscan-bunch\n");
int num_children = 7; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
children[4] = $5.nd;
children[5] = $6.nd;
children[6] = $7.nd;
$$.nd = mknode(num_children, children, "bunch-inputScan-bunch");
}
| bunch_of_statements while_loop bunch_of_statements {
prins("Parser found bunch_of_statement while_loop bunch\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));

children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
$$.nd = mknode(num_children, children, "bunch-while-bunch"); }
| bunch_of_statements print_statement Hindi_finish bunch_of_statements { prins("Parser found bunch-printStmt-finish\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "bunch-printStmt-;-bunch"); }
| bunch_of_statements variable_declaraEon Hindi_finish bunch_of_statements { prins("Parser found bunch-varDeclare-finish\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "bunch-varDeclare-;-bunch"); }
| bunch_of_statements Hindi_open_floor_bracket bunch_of_statements Hindi_closed_floor_bracket bunch_of_statements {
prins("parser found bunch {bunch}\n");
int num_children = 5; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
children[4] = $5.nd;
$$.nd = mknode(num_children, children, "bunch-{bunch}-bunch"); }
| bunch_of_statements funcEon_call Hindi_finish bunch_of_statements { prins("Parser found bunch-funcEonCall-;\n");
int num_children = 4; // Number of children

struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "bunch-funcEonCall-;-bunch");
}
| bunch_of_statements equaEon Hindi_finish bunch_of_statements { prins("Parser found bunch-equaEon-finish\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "bunch-equaEon-;-bunch");
}
| error Hindi_finish {
prins("PARSER ERROR: syntax error \n");
int num_children = 0; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
$$.nd = mknode(num_children, children, "error-;");
}
condiEon: // for if_statement and while loop, empty not allowed
exp {
prins("Parser found exp as condiEon\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "condiEon");
}
| exp {firstreg = registerIndex-1;} Hindi_comparison_operator exp {secondreg = registerIndex-1;} {
prins("Parser found exp-compareOp-exp\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $3.nd;

children[2] = $4.nd;
$$.nd = mknode(num_children, children, "condiEon");
//sprini(icg[ic_idx++], "R%d = R%d %s R%d\n", secondreg , firstreg, $3.name, secondreg);
if (strcmp($3.name, "chinnadi") == 0) {
sprins(icg[ic_idx++], "LT R%d R%d R%d\n", registerIndex++ , firstreg, secondreg);
}
else if (strcmp($3.name, "peddadi") == 0) {
sprins(icg[ic_idx++], "GT R%d R%d R%d\n", registerIndex++ , firstreg, secondreg); }
else if (strcmp($3.name, "chinnadiLedaSamanam") == 0) {
sprins(icg[ic_idx++], "LTE R%d R%d R%d\n", registerIndex++ , firstreg, secondreg); }
else if (strcmp($3.name, "peddadiLedaSamanam") == 0) {
sprins(icg[ic_idx++], "GTE R%d R%d R%d\n", registerIndex++ , firstreg, secondreg); }
else if (strcmp($3.name, "samanam") == 0) {
sprins(icg[ic_idx++], "EQ R%d R%d R%d\n", registerIndex++ , firstreg, secondreg); }
else{
sprins(icg[ic_idx++], "R%d = R%d %s R%d\n", secondreg , firstreg, $3.name, secondreg);
registerIndex++; // is this needed?
}
}
| exp {firstreg = registerIndex-1;} Hindi_logical_operator exp {secondreg = registerIndex-1;} {
prins("Parser found exp-logicalOp-exp\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $3.nd;
children[2] = $4.nd;
$$.nd = mknode(num_children, children, "condiEon");
sprins(icg[ic_idx++], "R%d = R%d %s R%d\n", secondreg , firstreg, $3.name, secondreg);
}
if_statement:
Hindi_if Hindi_open_curly_bracket condiEon {
sprins(icg[ic_idx++], "if NOT (R%d) GOTO L%d\n",registerIndex- 1,labelsused);isleader[insNumOfLabel[labelsused]]=1;isleader[ic_idx]=1;

label[stackpointer++]=labelsused++;} Hindi_closed_curly_bracket Hindi_open_floor_bracket bunch_of_statements {sprins(icg[ic_idx++], "JUMP L%d\n",label[stackpointer-
1]);} Hindi_closed_floor_bracket {
prins("Parser found if(cond){bunch}\n");
int num_children = 7; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $5.nd;
children[4] = $6.nd;
children[5] = $7.nd;
children[6] = $9.nd;
$$.nd = mknode(num_children, children, "if(cond){bunch}"); insNumOfLabel[label[stackpointer-1]]=ic_idx;
sprins(icg[ic_idx++], "LABEL L%d:\n", label[--stackpointer]); laddercounts[laddercountstackpointer++]=1;
}
elif_repeat: //can be empty
{ $$.nd = mknode(NULL, NULL, "empty"); }
| eol elif_repeat {
prins("Parser found eol elif_repeat\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "EOL-elifrepeat");
}
| elif_repeat Hindi_elif Hindi_open_curly_bracket condiEon
{sprins(icg[ic_idx++], "if NOT (R%d) GOTO L%d\n",registerIndex- 1,labelsused);isleader[insNumOfLabel[labelsused]]=1;isleader[ic_idx]=1;label[stackpo inter++]=labelsused++;}
Hindi_closed_curly_bracket Hindi_open_floor_bracket bunch_of_statements {sprins(icg[ic_idx++], "JUMP L%d\n",label[stackpointer-1]);} Hindi_closed_floor_bracket
{insNumOfLabel[label[stackpointer-1]]=ic_idx; sprins(icg[ic_idx++], "LABEL L%d:\n", label[--stackpointer]);} elif_repeat {
prins("Parser found elif(cond){bunch}\n");
int num_children = 9; // Number of children

struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
children[4] = $6.nd;
children[5] = $7.nd;
children[6] = $8.nd;
children[7] = $10.nd;
children[8] = $12.nd;
$$.nd = mknode(num_children, children, "elif(cond){bunch}"); laddercounts[laddercountstackpointer-1]++;
}
else_statement: //can be empty
{ $$.nd = mknode(NULL, NULL, "empty"); }
| eol else_statement {
prins("Parser found EOL-else\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "EOL-else");
}
| Hindi_else Hindi_open_floor_bracket bunch_of_statements Hindi_closed_floor_bracket {
prins("Parser found else{bunch}\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "else{bunch}");
}
if_else_ladder:
if_statement elif_repeat
{
lastjumps[lastjumpstackpointer++] = label[stackpointer-1];
}
else_statement {

prins("Parser found ifElseLadder\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $4.nd;
$$.nd = mknode(num_children, children, "ifElseLadder");
// lastjumpstackpointer--; // forgecng the current ifelseLadder's lastjump and counts // laddercountstackpointer--;
}
| if_statement elif_repeat
{
lastjumps[lastjumpstackpointer++] = label[stackpointer-1];
// int index = ic_idx - 1;
// int count = laddercounts[laddercountstackpointer-1]; // Number of itera(ons //for(inti=index;i>=0&&count>0;i--){
// if (strncmp(icg[i], "JUMP ", 5) == 0) { // Check if the prefix matches "JUMP "
// char jump_str[20]; // Assuming the number won't exceed 20 digits
// sprini(jump_str, "%d", lastjumps[lastjumpstackpointer-1]); // Convert number to string
// snprini(icg[i], 20, "JUMPx L%s\n", jump_str); // Set icg[i] to "JUMP" followed by the number
// count--;
//}
//}
}
{ // without the else statement
prins("Parser found ifElseLadder\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "ifElseLadder");
}
while_loop:
Hindi_while Hindi_open_curly_bracket condiEon { looplabel[looplabelstackpointer++] = labelsused; insNumOfLabel[labelsused]=ic_idx; sprins(icg[ic_idx++], "LABEL
L%d:\n", labelsused++);
gotolabel[gotolabelstackpointer++]=labelsused; sprins(icg[ic_idx++], "if NOT (R%d) GOTO L%d\n",registerIndex-1,labelsused++);isleader[insNumOfLabel[labelsused-

1]]=1;isleader[ic_idx]=1;
} Hindi_closed_curly_bracket Hindi_open_floor_bracket bunch_of_statements { sprins(icg[ic_idx++], "JUMPtoLOOP L%d\n",looplabel[--looplabelstackpointer]);
} Hindi_closed_floor_bracket {insNumOfLabel[gotolabel[gotolabelstackpointer- 1]]=ic_idx; sprins(icg[ic_idx++], "LABEL L%d:\n", gotolabel[--gotolabelstackpointer]);} {
prins("Parser found while(cond){bunch}\n");
int num_children = 7; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $5.nd;
children[4] = $6.nd;
children[5] = $7.nd;
children[6] = $9.nd;
$$.nd = mknode(num_children, children, "while(cond){bunch}");
}
variable_declaraEon:
Hindi_datatype Hindi_idenEfier_declaring Hindi_assignment_operator {rangestart = ic_idx;} exp {
//add('V'); // this is taking ';' as a variable
prins("Parser found datatypeId=exp\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $5.nd;
$$.nd = mknode(num_children, children, "datatypeId=exp"); if(strcmp(exp_type,$1.name)!=0 && strcmp(exp_type, " ")!=0){
sprins("$1name=%s and exp_type=%s\n", $1.name,exp_type); sprins(errors[sem_errors], "Line %d: Data type casEng not allowed in declaraEon\n", countn);
sem_errors++;
}
rangeend = ic_idx;
prins("QQQQQQQQQQQQQQQQQQQQQ rangestart=%d rangeend=%d\n",rangestart,rangeend);
int idIndexinSymbolTable = findIdenEfierIndex($2.name);

symbol_table[idIndexinSymbolTable].range[symbol_table[idIndexinSymbolTable].ran ge_count][0] = rangestart; symbol_table[idIndexinSymbolTable].range[symbol_table[idIndexinSymbolTable].ran ge_count++][1] = rangeend; //stack counter is increased
sprins(icg[ic_idx++], "MOV %s , R%d\n", $2.name, registerIndex-1); }
| Hindi_datatype Hindi_idenEfier_declaring {
prins("Parser found datatype Id\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "datatypeId");
//// not needed here
// rangestart = ic_idx;
// rangeend = ic_idx;
// int idIndexinSymbolTable = findIden(fierIndex($2.name);
// symbol_table[idIndexinSymbolTable].range[symbol_table[idIndexinSymbolTable].ran ge_count][0] = rangestart;
// symbol_table[idIndexinSymbolTable].range[symbol_table[idIndexinSymbolTable].ran ge_count++][1] = rangeend; //stack counter is increased
}
| Hindi_datatype Hindi_idenEfier_declaring Hindi_open_square_bracket exp Hindi_closed_square_bracket {
prins("Parser found datatype Id\n");
int num_children = 5; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
children[4] = $5.nd;
$$.nd = mknode(num_children, children, "datatype Id[exp]");
}
parameters_repeat: // can be empty 0 or more occurences
{ $$.nd = mknode(NULL, NULL, "empty"); }
| parameters_repeat Hindi_datatype Hindi_idenEfier_declaring Hindi_punctuaEon_comma {
prins("Parser found paramRepDatatypeIdComma\n");

curr_num_params++;
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "paramRepDatatypeIdComma");
}
parameters_line: // can be empty
{ $$.nd = mknode(NULL, NULL, "empty"); }
| {scope++;} parameters_repeat Hindi_datatype Hindi_idenEfier_declaring {scope--;} {
prins("Parser found parameters_line\n");
curr_num_params++;
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $2.nd;
children[1] = $3.nd;
children[2] = $4.nd;
$$.nd = mknode(num_children, children, "paramLine");
}
idenEfiers_repeat: // abc,x,y,p can be empty
{ $$.nd = mknode(NULL, NULL, "empty"); }
| Hindi_idenEfier {
curr_num_args++;
prins("Parser found lastparam\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "paramEnd");
sprins(icg[ic_idx++], "PARAM %s\n", $1.name);
}
| Hindi_constant {
curr_num_args++;
prins("Parser found lastparam\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;

$$.nd = mknode(num_children, children, "paramEnd"); sprins(icg[ic_idx++], "PARAM %s\n", $1.name);
}
|exp{
curr_num_args++;
prins("Parser found lastparam\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "paramEnd");
sprins(icg[ic_idx++], "PARAM %s\n", $1.name);
}
| idenEfiers_repeat Hindi_punctuaEon_comma idenEfiers_repeat { curr_num_args++;
prins("Parser found id-comma-prep\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
$$.nd = mknode(num_children, children, "paramRep");
sprins(icg[ic_idx++], "PARAM %s\n", $1.name);
}
idenEfiers_line: // for func(on call,can be empty
idenEfiers_repeat {
prins("Parser found idLine\n");
int num_children = 1; // Number of childreni how are you sir
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "idline");
}
equaEon:
Hindi_idenEfier Hindi_assignment_operator { strcpy(exp_type," "); } {rangestart = ic_idx;} exp {
prins("Parser found equaEon\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;

children[2] = $5.nd;
$$.nd = mknode(num_children, children, "id=exp");
//check if iden(fier type and exp_type mismatch -> if yes then typecast is happening prins("type of idenEfier: %s XXXXXXXXXXXXXXXXX exp_type=%s\n\n", get_type($1.name),exp_type);
if(strcmp(get_datatype($1.name) , exp_type) && strcmp(exp_type, " ")){ sprins(errors[sem_errors], "Line %d: Data type casEng not allowed in equaEon\n", countn);
sem_errors++;
}
// a = exp ---> t1=exp, a=t1
rangeend = ic_idx;
prins("ZZZZZZZZZZ rangestart=%d rangeend=%d\n",rangestart,rangeend);
int idIndexinSymbolTable = findIdenEfierIndex($1.name); symbol_table[idIndexinSymbolTable].range[symbol_table[idIndexinSymbolTable].ran ge_count][0] = rangestart; symbol_table[idIndexinSymbolTable].range[symbol_table[idIndexinSymbolTable].ran ge_count++][1] = rangeend; //stack counter is increased
sprins(icg[ic_idx++], "%s = R%d\n", $1.name, registerIndex-1);
}
| Hindi_idenEfier Hindi_open_square_bracket exp {thirdreg = registerIndex-1;} Hindi_closed_square_bracket Hindi_assignment_operator exp {
prins("Parser found id[exp]=exp\n");
int num_children = 6; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $5.nd;
children[4] = $6.nd;
children[5] = $7.nd;
$$.nd = mknode(num_children, children, "id[exp]=exp");
sprins(icg[ic_idx++], "MOV %s+R%d , R%d\n", $1.name,thirdreg ,registerIndex-1);
}
funcEon_content: // can be empty also, return not needed
funcEon_content eol {
prins("Parser found funContentEOL\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;

$$.nd = mknode(num_children, children, "funContentEOL"); }
| eol funcEon_content {
prins("Parser found EOL-funContent\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "EOL-funContent");
}
| bunch_of_statements funcEon_content bunch_of_statements {
prins("Parser found bunch_funcEon_content_bunch\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
$$.nd = mknode(num_children, children, "bunch-content-bunch");
}
| bunch_of_statements {
prins("Parser found bunch_funcEon_content_bunch\n");
int num_children = 1; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
$$.nd = mknode(num_children, children, "bunch-content-bunch");
}
| bunch_of_statements Hindi_return Hindi_finish bunch_of_statements { prins("Parser found bunchReturnFinish\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "bunchReturnFinish");
}
| bunch_of_statements Hindi_return exp Hindi_finish bunch_of_statements { prins("Parser found bunchReturnExpFinish\n");
int num_children = 5; // Number of children

struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
children[4] = $5.nd;
$$.nd = mknode(num_children, children, "bunchReturnExpFinish"); }
| bunch_of_statements funcEon_call Hindi_finish bunch_of_statements { prins("Parser found bunchReturnExpFinish\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "bunchFunCallFinish"); }
print_content: // can be empty also
| print_content eol {
prins("Parser found print_contentEOL\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "print_content-EOL");
}
| eol print_content { // take care of infinite loop
prins("Parser found EOL-print_content\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "EOL-printContent");
}
| print_content Hindi_string {
prins("Parser found print_content-String\n");
int num_children = 2; // Number of children

struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "printContent-String"); }
| print_content exp {
prins("Parser found print_content-exp\n");
int num_children = 2; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
$$.nd = mknode(num_children, children, "printContent-exp");
}
| print_content Hindi_punctuaEon_comma Hindi_string {
prins("Parser found print_content-comma-String\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
$$.nd = mknode(num_children, children, "print_content-comma-String");
}
| print_content Hindi_punctuaEon_comma exp {
prins("Parser found print_content-comma-exp\n");
int num_children = 3; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;
children[2] = $3.nd;
$$.nd = mknode(num_children, children, "print_content-comma-exp");
}
print_statement:
Hindi_print Hindi_open_curly_bracket print_content Hindi_closed_curly_bracket { prins("Parser found printStatement\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $2.nd;

children[2] = $3.nd;
children[3] = $4.nd;
$$.nd = mknode(num_children, children, "printStatement");
}
funcEon_declaraEon:
Hindi_funcEon {oldscope=scope;scope=0;} Hindi_funcEon_name {add('F');scope=oldscope;} Hindi_open_curly_bracket parameters_line Hindi_closed_curly_bracket
Hindi_open_floor_bracket funcEon_content Hindi_closed_floor_bracket { prins("Parser found equaEon\n");
int num_children = 8; // Number of childrenfunc(on_call
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $3.nd;
children[2] = $5.nd;
children[3] = $6.nd;
children[4] = $7.nd;
children[5] = $8.nd;
children[6] = $9.nd;
children[7] = $10.nd;
$$.nd = mknode(num_children, children, "func-id-(param){content}"); symbol_table[count-curr_num_params-3].num_params= curr_num_params; if(symbol_table[count-curr_num_params-3].num_params>=0){
prins("XXXX changed num_params of %s to %d\n",symbol_table[count- curr_num_params-3].id_name,symbol_table[count-curr_num_params- 3].num_params);
curr_num_params=0;
}
}
funcEon_call:
Hindi_idenEfier { check_declaraEon($1.name); } Hindi_open_curly_bracket idenEfiers_line Hindi_closed_curly_bracket {
prins("Parser found id(idLine)Finish\n");
int num_children = 4; // Number of children
struct node **children = (struct node **)malloc(num_children * sizeof(struct node *));
children[0] = $1.nd;
children[1] = $3.nd;
children[2] = $4.nd;
children[3] = $5.nd;
$$.nd = mknode(num_children, children, "id(idLine)Finish");
for(int i=0;i<count;i++){

if(strcmp(symbol_table[i].id_name,$1.name)==0){ // found the corresponding func(on
if(symbol_table[i].num_params==-1){
prins("ERROR: %s is not a funcEon\n",$1.name);
sprins(errors[sem_errors], "Line %d: %s is not a funcEon\n", countn+1,$1.name); sem_errors++;
break;
}
// if(symbol_table[i].num_params!=curr_num_args){
// prini("ERROR: Number of parameters do not match\n");
// sprini(errors[sem_errors], "Line %d: need %d arguments but found %d args\n", countn+1,symbol_table[i].num_params,curr_num_args);
// sem_errors++;
// break;
//}
}
}
curr_num_args=0;
sprins(icg[ic_idx++], "CALL %s\n", $1.name);
}
%%
int main(){
for(int i=0;i<10000;i++){
laddercounts[i]=0;
isleader[i]=0;
insNumOfLabel[i]=-1;
}
isleader[0]=1;
strcpy(exp_type," ");
prins("\n\n");
prins("\t\t\t\t\t\t\t\t PHASE 1: LEXICAL ANALYSIS \n\n");
for(int i=0;i<10000;i++){
symbol_table[i].used = 0;
symbol_table[i].range_count = 0;
// for(int j=0;j<10000;j++){
// symbol_table[i].range[j][0]=-1;
// symbol_table[i].range[j][1]=-1; // dummy values
//}
}
yyparse();
prins("\nSYMBOL DATATYPE TYPE LineNUMBER SCOPE numParams\n"); prins("_______________________________________\n\n");
int i=0;

// for(i=0; i<count; i++) {
// prini("%s\t%s\t%s\t%d\t%d\t%d\n", symbol_table[i].id_name, symbol_table[i].data_type, symbol_table[i].type, symbol_table[i].line_no,symbol_table[i].thisscope,symbol_table[i].num_params); //}
for(i=0;i<count;i++){
prins("%s\t%s\t%s\t%d\t%d\t%d\t%s\n", symbol_table[i].id_name, symbol_table[i].data_type, symbol_table[i].type, symbol_table[i].line_no, symbol_table[i].thisscope,
symbol_table[i].num_params, symbol_table[i].used ? "Used" : "unUsed");
}
prins("\n\n");
prins("\t\t\t\t\t\t\t\t PHASE 2: SYNTAX ANALYSIS \n\n");
prinCree(head);
prins("\n\n\n\n");
prins("\t\t\t\t\t\t\t\t PHASE 3: SEMANTIC ANALYSIS \n\n");
if(sem_errors>0) {
prins("SemanEc analysis completed with %d errors\n", sem_errors);
for(int i=0; i<sem_errors; i++){
prins("\t - %s", errors[i]);
}
}else{
prins("SemanEc analysis completed with no errors");
}
prins("\n\n");
prins("\t\t\t\t\t\t\t PHASE 4: INTERMEDIATE CODE GENERATION \n\n");
for(int i=0; i<ic_idx; i++){
if(icg[i][0]=='L' && icg[i][0]=='A'){
prins("\n");
}
prins("%d %s", i,icg[i]);
}
prins("\n\n");
// Assuming icg[] contains the strings "LABEL L15", "LABEL L20", etc. for(inti=0;i<ic_idx;i++){
// Check if the string starts with "LABEL L"
if (strncmp(icg[i], "LABEL L", 7) == 0) {
// Extract the label number from the string
int labelNumber = atoi(icg[i] + 7); // Skip "LABEL L" and convert the rest to integer // Use the label number to index into insNumOfLabel array insNumOfLabel[labelNumber] = i;
}
}

for(int i=0;i<ic_idx;i++){
if (strncmp(icg[i], "if NOT (", 8) == 0) {
char *ptr = strstr(icg[i], "L"); // Find the first occurrence of "L" in the string
int labelNumber = atoi(ptr + 1); // Convert the substring aUer "L" to integer //prini("Extracted label number: %d\n", labelNumber); isleader[insNumOfLabel[labelNumber]] = 1;
if(i+1<10000)
isleader[i+1]=1;
}
}
prins("\t\t\tBLOCKS:\n\n");
int prev=-1,blockcount=0;
for(int i=0;i<10000;i++){
// if(insNumOfLabel[i]!=-1){
// prini("Label %d is at %d\n",i,insNumOfLabel[i]);
//}
if(isleader[i]){
if(prev!=-1)
prins("block %d: %d to %d\n",blockcount++,prev,i-1);
//prini("Leader %d\n",i);
prev=i;
}
}
prins("\n\n");
// Iterate over the symbol table to print ranges for unused variables for(inti=0;i<count;i++){
if (symbol_table[i].used <= 0 && strcmp(symbol_table[i].type, "Variable") == 0) { prins("Variable %s declared but not used\n", symbol_table[i].id_name); prins("Ranges for %s:\n", symbol_table[i].id_name);
for (int j = 0; j < symbol_table[i].range_count; j++) {
prins("[%d, %d]\n", symbol_table[i].range[j][0], symbol_table[i].range[j][1]); uselessranges[uselessrangescount][0] = symbol_table[i].range[j][0]; uselessranges[uselessrangescount++][1] = symbol_table[i].range[j][1];
}
prins("\n");
}
}
for(i=0;i<count;i++) {
free(symbol_table[i].id_name); // symbol is needed, so dont free yet free(symbol_table[i].type);
}
//prini("done");
// Sort uselessranges

sortRanges(uselessranges, uselessrangescount);
int uselessrangesidx = 0;
prins(" uselessrangescount=%d\n", uselessrangescount);
prins("\t\t\t\t\t\t\t PHASE 5: OPTIMIZATION \n\n");
for(int i=0; i<ic_idx; i++){
if (uselessrangesidx < uselessrangescount && i == uselessranges[uselessrangesidx][0]) {
uselessrangesidx++;
i=uselessranges[uselessrangesidx-1][1];
//prini("skipping from %d to %d\n", uselessranges[uselessrangesidx-1][0], uselessranges[uselessrangesidx-1][1]);
conEnue;
}
if(icg[i][0]=='L' && icg[i][0]=='A'){
prins("\n");
}
prins("%d %s",i, icg[i]);
}
prins("\n\n");
return 0;
}
int yyerror(char *s){
prins("PARSER ERROR: %s\n",s);
//return 0;
}
struct node* mknode(int num_children, struct node **children, char *token) { struct node *newnode = (struct node *)malloc(sizeof(struct node)); newnode->num_children = num_children;
newnode->children = children;
newnode->token = strdup(token);
return newnode;
}
void prinCree(struct node* tree) {
prins("\n\n Inorder traversal of the Parse Tree: \n\n");
printInorder(tree);
prins("\n\n");
}
void printInorder(struct node *tree) {
if (tree) {
prins("%s, ", tree->token);
for (int i = 0; i < tree->num_children; i++) {
printInorder(tree->children[i]);
}

}
}
///////////////////////////////////// SYMBOL TABLE & SEMANTIC ANALYSIS PART int search(char *type) {
int i;
for(i=count-1; i>=0; i--) {
if(strcmp(symbol_table[i].id_name, type)==0) {
return symbol_table[i].thisscope;
break;
}
}
return 0;
}
void check_declaraEon(char *c) {
q = search(c);
// if(!q) {
// sprini(errors[sem_errors], "Line %d: Variable \"%s\" not declared before usage!\n", countn+1, c);
// sem_errors++;
//}
}
char *get_type(char *var){
for(int i=0; i<count; i++) {
// Handle case of use before declara(on
if(!strcmp(symbol_table[i].id_name, var)) {
return symbol_table[i].type;
}
}
}
char *get_datatype(char *var){
for(int i=0; i<count; i++) {
// Handle case of use before declara(on
if(!strcmp(symbol_table[i].id_name, var)) {
return symbol_table[i].data_type;
}
}
}
void add(char c) {
if(c == 'V'){ // variable
for(int i=0; i<reserved_count; i++){
if(!strcmp(reserved[i], strdup(yy_text))){
sprins(errors[sem_errors], "Line %d: Variable name \"%s\" is a reserved keyword!\n", countn+1, yy_text);

sem_errors++; return;
}
}
}
q=search(yy_text);
if(!q) { // insert into symbol table only if not already present if(c == 'H') { //header symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup(type); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("Header"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;
}
else if(c == 'K') { //keyword symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup("N/A"); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("Keyword\t"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;
}
else if(c == 'V') { //variable
prins("yytext: %s\n", yy_text); symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup(type); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("Variable"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;
}
else if(c == 'C') { //constant sankhya symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup("CONST"); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("constantx"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;

}
else if(c == 'i') { //constant sankhya symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup("CONST"); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("sankhya"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;
}
else if(c == 'f') { //constant float thelu symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup("CONST"); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("naam"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;
}
else if(c == 'c') { //constant character aksharam symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup("CONST"); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("aksharam"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;
}
else if(c == 's') { //constant string theega symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup("CONST"); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("theek"); symbol_table[count].thisscope=scope; symbol_table[count].num_params=-1;
count++;
}
else if(c == 'F') { symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup(type); symbol_table[count].line_no=countn; symbol_table[count].type=strdup("FuncEon"); symbol_table[count].thisscope=scope;

prins("\nSETTING %s's params to %d\n", symbol_table[count- curr_num_params].id_name, curr_num_params); symbol_table[count-curr_num_params].num_params=curr_num_params; curr_num_params=0;
count++;
}
else if(c == 'L') {
symbol_table[count].id_name=strdup(yy_text); symbol_table[count].data_type=strdup(type);
symbol_table[count].line_no=countn;
symbol_table[count].type=strdup("Library");
symbol_table[count].thisscope=scope;
symbol_table[count].num_params=0;
count++;
}
}
elseif(c=='V'&&q){
if(q != INT_MAX){
sprins(errors[sem_errors], "Line %d: MulEple declaraEons of \"%s\" not allowed!\n", countn+1, yy_text);
sem_errors++;
}
else{ // its scope is already destroyed, now it can be redeclared again into the symbol table with current scope
// search again for that symbol table value
int i;
for(i=count-1; i>=0; i--) {
if(strcmp(symbol_table[i].id_name, type)==0) {
symbol_table[i].thisscope = scope;
symbol_table[count].line_no=countn;
symbol_table[count].num_params=0;
prins("\nReinserted %s because its previous scope is finished\n", type);
break;
}
}
}
}
}
void insert_type() {
strcpy(type, yy_text);
}