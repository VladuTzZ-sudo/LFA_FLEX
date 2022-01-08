/*	Matei Vlad Cristian - 331CC	 */

%{
	#include <stdio.h>
	#include <iostream>
	#include <queue>
	#include <unordered_set>
	#include <unordered_map>
	#include <bits/stdc++.h>
	using namespace std;

	/* Coada ce retine variabilele enumerate temporar, doar pentru o linie.	*/
	queue<string> temporary_var;
	
	/* Dictionar ce retine pentru o variabila globala tipul ei. */
	unordered_map <string, string> var_types_global;

	/* Dictionar ce retine pentru o variabila, cu scope-ul o functie, tipul ei. */
	unordered_map <string, string> var_types_function;
	
	/* Multimea numelor variabilelor dintr-o functie. */
	unordered_set <string> var_name_from_function;
	
	/* Multimea numelor variabilelor globale. */
	unordered_set <string> var_name_global;

	/* Multimea numelor functiilor din program. */
	unordered_set <string> function_names;
	
	/* Exista un tip de return la functia curenta. */
	bool returnExist = false;

	/* Tipul de return al functiei curente. */
	string returnString;

	/* Numele functiei curente. */
	string currentFunctionName;

	/* In momentul curent, programul analizeaza interiorul unei functii. */
	bool inFunction = false;
	
	/* Linia din fisier care este analizata. */
	int line = 1;

	/* Se analizeaza un cuvant care se presupune a fi parte dintr-un shortcut
	(shortcut -> ":="), astfel ca daca este intalnita eroarea specifica expresiei
	de shortcut, flag-ul -> true si se va afisa cand se garanteaza ca a fost 
	vorba despre o expresie de tip shortcut. */
	bool shortcut_temp_flag = false;

	/* Afiseaza mai multe comentarii ajutatoare pentru a vedea pasii executiei. */
	bool debugMode = false;

	/* Functie care goleste coada temporara. */
	queue<string> clear_queue(queue<string> q){
		while (!q.empty()){
			q.pop();
		}
		return q;
	}
%}

Digit 		[0-9]
Semn 		[+-]?
Natural 	{Digit}+
Integer		{Semn}{Natural}
Real 		{Semn}{Natural}\.{Natural}?
Bool		"true"|"false"
Word  	[A-Za-z][A-Za-z0-9]*
String		[^"\""]*
Apostrophe 	"\""
CommSimp 	"//"
CommStart 	"/*"
CommEnd 	"*/"
Var 		"var"
Func		"func"
Space 		" "|"\t"
PointEqual	":="
Equal 		"="
Comma 		","
Newline		"\n"
int 		"int"
float32		"float32"
string		"string"
bool		"bool"
Type		"bool"|"string"|"float32"|"int"
Return		"return"


%x COMMENTARY_SHORT
%x COMMENTARY_LONG
%x VAR
%x VAR_ENUMERATION
%x INFERATION
%x GIVE_TYPE
%x END_GIVE_TYPE
%x STRING
%x INFERATION_ENUMERATION
%x ERROR
%x ERROR_FUNC
%x SHORTCUT
%x SHORTCUT_ENUMERATION
%x FUNC
%x ARGUMENTS_NAME
%x ARGUMENTS_TYPE
%x FUNC_RETURN_TYPE
%x INSIDE_FUNC
%x INFERATION_RETURN

%option stack

%%
{CommSimp} {
	yy_push_state(COMMENTARY_SHORT);
}

{CommStart} {
	yy_push_state(COMMENTARY_LONG);
}

{Var}{Space}+ {
	yy_push_state(VAR);
}

{Func}{Space}+ {
	if (debugMode) {
		printf("line %d:	*	[FUNC] KEYWORD	*\n", line);
	}

	yy_push_state(FUNC);
}

 /* Poate fi inceputul unui shortcut corect sau poate fi o simpla eroare. De aceea folosesc				*
  * shortcut_temp_flag, in caz ca se va confirma ca este un shortcut se va afisa ce este necesar. 	*/
{Word} {
	if (debugMode) {
		printf("line %d:	*	[ShortCut] - (%s)	*\n", line, yytext);
	}

	/* Pentru functionarea recursivitatii, din enumerare se va da doar un pop() pentru a	* 
	 *  mai astepta un shortcut, in caz ca se termina enumerarea, se vor da doua pop-uri. 	*/
	yy_push_state(SHORTCUT);
	yy_push_state(SHORTCUT_ENUMERATION);
	
	shortcut_temp_flag = false;
	temporary_var.push(yytext);
	if (var_name_global.find(yytext) == var_name_global.end()) {
		var_name_global.insert(yytext);
	}else{
		shortcut_temp_flag = true;
	}
}

<COMMENTARY_SHORT>{Newline} {
	yy_pop_state();

	if (debugMode){
		printf("line %d:	*	A iesit din comentariu simplu	*\n", line);
	}

	line++;
}

<COMMENTARY_SHORT>. {}

<COMMENTARY_LONG>{CommEnd} {
	yy_pop_state();

	if(debugMode){
		printf("line %d:	*	A iesit din comentariu lung	*\n", line);
	}
}

<COMMENTARY_LONG>. {}

<COMMENTARY_LONG>{Newline} { line++; }

 /* Daca pentru o expresie shortcut exista o enumerare de termeni, aceasta stare ajuta la adaugarea *
  * de noi variabile ce vor initiate dupa ":=".														*/
<SHORTCUT>{Word} {
	yy_push_state(SHORTCUT_ENUMERATION);
	shortcut_temp_flag = false;

	/* Se inregistreaza in multimea potrivita aparitia acestei variabile. */
	if (inFunction == true ){
		if (var_name_from_function.find(yytext) == var_name_from_function.end()) {
			var_name_from_function.insert(yytext);
		}else{
			shortcut_temp_flag = true;
		}
	}else{
		if (var_name_global.find(yytext) == var_name_global.end()) {
			var_name_global.insert(yytext);
		}else{
			shortcut_temp_flag = true;
		}
	}
	temporary_var.push(yytext);

	if (debugMode) {
		printf("line %d:	*	[SHORTCUT] variabila - (%s)	*\n", line, yytext);
	}
}

 /* Nu poate fi o variabila, atunci este o greseala de sintaxa si nu se analizeaza restul liniei. 	*/
<SHORTCUT>. {
	yy_pop_state();
	yy_push_state(ERROR);

	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[SHORTCUT] ERROR [SHORTCUT]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}
 
 /* Este necesara o stare noua fata de cea anterioara, intrucat daca se intalneste direct \n, trebuie 	*
  * contorizat numarul liniei. (starea ERROR nu ar putea rezolva asta, in cazul acesta). 				*/
<SHORTCUT>{Newline} {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[SHORTCUT] ERROR [SHORTCUT]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}

<SHORTCUT_ENUMERATION>{Space}*{Comma}{Space}* {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[SHORTCUT_ENUMERATION] space + virgula - (%s)	*\n", line, yytext);
	}
}

 /* Daca exista variabila, deja in acest punct exista certitudinea ca face parte dintr-o expresie 	*
  *	shortcut si se afiseaza eroare caracteristica. 													*/
<SHORTCUT_ENUMERATION>{Space}*{PointEqual}{Space}* {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(INFERATION);

	if ( shortcut_temp_flag == true ){
		printf("line %d: No new variables on the left side of :=\n", line);
	}

	if (debugMode) {	
		printf("line %d:	*	[SHORTCUT_ENUMERATION] space + := - (%s)	*\n", line, yytext);
	}
}
 
 /* Nu se afiseaza erori in cazul =, deoarece chiar daca variabila/lele s-a/au mai gasit aici este vorba *
  * despre o atribuire de valoare care va fi verificata la INFERATION, nu este o declarare+initializare. */
<SHORTCUT_ENUMERATION>{Space}*{Equal}{Space}* {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(INFERATION);
	
	if (debugMode) {
		printf("line %d:	*	[SHORTCUT_ENUMERATION] space + = - (%s)	*\n", line, yytext);
	}
}

 /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<SHORTCUT_ENUMERATION>. {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(ERROR);

	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[SHORTCUT_ENUMERATION] ERROR [SHORTCUT_ENUMERATION]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}
 
<SHORTCUT_ENUMERATION>{Newline} {
	yy_pop_state();
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[SHORTCUT_ENUMERATION] ERROR [SHORTCUT_ENUMERATION]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}
 
 /* Se verifica daca se afla intr-o functie sau nu si se actualizeaza multimea corepunzatoare cu 		*
  * variabila noua sau se afiseaza o eroare. Este nevoie de alta stare VAR_ENUMERATION diferita de 		*
  * SHORTCUT_ENUMERATION, deoarece doar cu "var" in fata o variabila poate primi si un tip (GIVE_TYPE)  */
<VAR>{Word} {
	yy_push_state(VAR_ENUMERATION);

	if (inFunction == true ){
		if (var_name_from_function.find(yytext) == var_name_from_function.end()) {
			var_name_from_function.insert(yytext);
		}else{
			printf("line %d: '%s' redeclared in this block\n",line , yytext);
		}
	}else{
		if (var_name_global.find(yytext) == var_name_global.end()) {
			var_name_global.insert(yytext);
		}else{
			printf("line %d: '%s' redeclared in this block\n",line , yytext);
		}
	}
	temporary_var.push(yytext);

	if (debugMode) {
		printf("line %d:	*	[VAR] variabila - (%s)	*\n", line, yytext);
	}
}

 /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<VAR>. {
	yy_pop_state();
	yy_push_state(ERROR);
	
	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[VAR] ERROR [VAR]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}

<VAR>{Newline} {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[VAR] ERROR [VAR]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}

 /* Se intoarce in starea VAR pentru a primi o alta variabila. */
<VAR_ENUMERATION>{Space}*{Comma}{Space}* {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[VAR_ENUMERATION] space + virgula - (%s)	*\n", line, yytext);
	}
}

 /* Poate trece in starea INFERATION si cu '=' si cu ':=' */
<VAR_ENUMERATION>{Space}*{Equal}{Space}* {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(INFERATION);
	
	if (debugMode) {
		printf("line %d:	*	[VAR_ENUMERATION] space + egal - (%s)	*\n", line, yytext);
	}
}

<VAR_ENUMERATION>{Space}*{PointEqual}{Space}* {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(INFERATION);

	if (debugMode) {
		printf("line %d:	*	[VAR_ENUMERATION] space + egal - (%s)	*\n", line, yytext);
	}
}
 
 /* Daca nu exista nici virgula, nici = sau :=, dar exista cel putin un space, atunci incearca sa 	*
  * treca in starea GIVE_TYPE pentru a analiza tipul. 											 	*/
<VAR_ENUMERATION>{Space}+ {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(GIVE_TYPE);
	
	if (debugMode) {
		printf("line %d:	*	[VAR_ENUMERATION] space simplu - (%s)	*\n", line, yytext);
	}
}

 /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<VAR_ENUMERATION>. {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(ERROR);
	
	if (debugMode) {
		printf("line %d:	*	[VAR_ENUMERATION] ERROR [VAR_ENUMERATION]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	temporary_var = clear_queue(temporary_var);
}

<VAR_ENUMERATION>{Newline} {
	yy_pop_state();
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[VAR_ENUMERATION] ERROR [VAR_ENUMERATION]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}

 /* Pentru ca primeste un Type, atribuie tipul tuturor variabilelor din enumerare salvate in coada	*
  *	temporary_var si sunt actualizate dictionarele corespunzatoare. De asemenea, coada o sa ramana	*
  *	neschimbata pentru ca este nevoie de analiza ei si in starea INFERATION.							*/
<GIVE_TYPE>{Type} {
	yy_pop_state();
	yy_push_state(END_GIVE_TYPE);
	
	if (debugMode) {
		printf("line %d:	*	[GIVE_TYPE] VAR TYPE SET (%s)	*\n", line, yytext);
	}

	queue<string> tmp_q;

	while (!temporary_var.empty()){
		string key = temporary_var.front();
		if (inFunction == false ){
			if (var_types_global.find(key) == var_types_global.end()) {
				var_types_global[key] = yytext;
			}
		}else{
			if (var_types_function.find(key) == var_types_function.end()) {
				var_types_function[key] = yytext;
			}
		}

		temporary_var.pop();
		tmp_q.push(key);
	}

	while(!tmp_q.empty())
    {
        temporary_var.push(tmp_q.front()); 
        tmp_q.pop(); 
    }
}

 /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<GIVE_TYPE>. {
	yy_pop_state();
	yy_push_state(ERROR);
	
	if (debugMode) {
		printf("line %d:	*	[GIVE_TYPE] ERROR [GIVE_TYPE]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	temporary_var = clear_queue(temporary_var);
}

<GIVE_TYPE>{Newline} {
	yy_pop_state();
	
	if (debugMode) {
		printf("line %d:	*	[GIVE_TYPE] ERROR [GIVE_TYPE]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}

 /* Se verifica cum se termina linia: simplu sau (dupa GIVE_TYPE) se mai poate primi doar '='.	*/
<END_GIVE_TYPE>{Space}*{Newline} {
	yy_pop_state();
	
	if (debugMode) {
		printf("line %d:	*	[END_GIVE_TYPE] SIMPLE ENDING.	*\n", line);
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}

<END_GIVE_TYPE>{Space}*{Equal}{Space}* {
	yy_pop_state();
	yy_push_state(INFERATION);

	if (debugMode) {
		printf("line %d:	*	[END_GIVE_TYPE] VAR INFERATION- (%s)	*\n", line, yytext);
	}
}

 /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<END_GIVE_TYPE>. {
	yy_pop_state();
	yy_push_state(ERROR);
	
	if (debugMode) {
		printf("line %d:	*	[END_GIVE_TYPE] ERROR [END_GIVE_TYPE]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	temporary_var = clear_queue(temporary_var);
}

 /* Se verifica inferarea variabilelor din coada cu instantierea potrivita. Se verifica cazul in care	*
  *	numarul variabilelor din coada este mai mic decat numarul initializarilor sau daca initializarea se *
  *	face cu tipul gresit, in caz ca variabila deja exista. Daca nu, este atribuit simplu tipul citit. */
<INFERATION>{Integer} {
	yy_push_state(INFERATION_ENUMERATION);
	
	if (debugMode) {
		printf("line %d:	*	[INFERATION] INTEGER. - (%s)	*\n", line, yytext);
	}

	if (!temporary_var.empty()){
		string key = temporary_var.front();
		if (inFunction == false){
			if (var_types_global.find(key) == var_types_global.end()) {
				var_types_global[key] = "int";
			}
			else{
				if (var_types_global[key] != "int" ){
					cout << "line " << line << ": (int) cannot be represented by the (" << var_types_global[key] << ")"<< endl;
				}
			}
		}
		else{
			if (var_types_function.find(key) == var_types_function.end()) {
				var_types_function[key] = "int";
			}
			else{
				if (var_types_function[key] != "int" ){
					cout << "line " << line << ": (int) cannot be represented by the (" << var_types_function[key] << ")"<< endl;
				}
			}
		}
		temporary_var.pop();
	}
	else{
		cout << "line " << line << ": Not enough variables to initialize with " << yytext << endl;
	}
}

<INFERATION>{Real} {
	yy_push_state(INFERATION_ENUMERATION);

	if (debugMode) {
		printf("line %d:	*	[INFERATION] REAL. - (%s)	*\n", line, yytext);
	}

	if (!temporary_var.empty()){
		string key = temporary_var.front();
		if (inFunction == false){
			if (var_types_global.find(key) == var_types_global.end()) {
				var_types_global[key] = "float32";
			}
			else{
				if (var_types_global[key] != "float32" ){
					cout << "line " << line << ": (float32) cannot be represented by the (" << var_types_global[key] << ")"<< endl;
				}
			}
		} 
		else{
			if (var_types_function.find(key) == var_types_function.end()) {
				var_types_function[key] = "float32";
			}
			else{
				if (var_types_function[key] != "float32" ){
					cout << "line " << line << ": (float32) cannot be represented by the (" << var_types_function[key] << ")"<< endl;
				}
			}
		}
		temporary_var.pop();
	}
	else{
		cout << "line " << line << ": Not enough variables to initialize with " << yytext << endl;
	}
}

<INFERATION>{Bool} {
	yy_push_state(INFERATION_ENUMERATION);

	if (debugMode) {
		printf("line %d:	*	[INFERATION] BOOL. - (%s)	*\n", line, yytext);
	}

	if (!temporary_var.empty()){
		string key = temporary_var.front();
		if (inFunction == false ){
			if (var_types_global.find(key) == var_types_global.end()) {
				var_types_global[key] = "bool";
			}
			else{
				if (var_types_global[key] != "bool" ){
					cout << "line " << line << ": (bool) cannot be represented by the (" << var_types_global[key] << ")"<< endl;
				}
			}
		} else{
			if (var_types_function.find(key) == var_types_function.end()) {
				var_types_function[key] = "bool";
			}
			else{
				if (var_types_function[key] != "bool" ){
					cout << "line " << line << ": (bool) cannot be represented by the (" << var_types_function[key] << ")"<< endl;
				}
			}
		}
		temporary_var.pop();
	}
	else{
		cout << "line " << line << ": Not enough variables to initialize with " << yytext << endl;
	}
}
 
 /* Ce difera la acest caz diferit de restul inferarilor este faptul ca se verifica inainte daca variabila 	*
  * initializatoare a mai fost analizata pana acum, declarata. Altfel, genereaza eroare.				   	*/
<INFERATION>{Word} {
	yy_push_state(INFERATION_ENUMERATION);

	if (debugMode) {
		printf("line %d:	*	[INFERATION] Variabile sau eroare. - (%s)	*\n", line, yytext);
	}

	if (!temporary_var.empty()){

		if (inFunction == false){
			if (var_types_global.find(yytext) == var_types_global.end()) {
				cout << "line " << line << ": the variable (" << yytext << ") has not been declared" << endl;
			}else{
				string key = temporary_var.front();
				if (var_types_global.find(key) == var_types_global.end()) {
					var_types_global[key] = var_types_global[yytext];
				}else{
					if (var_types_global[key] != var_types_global[yytext]){
						cout << "line " << line << ": (" << var_types_global[yytext] << ") cannot be represented by the (" << var_types_global[key] << ")"<< endl;
					}
				}
			temporary_var.pop();
			}
		}
		else{
			if (var_types_function.find(yytext) == var_types_function.end()) {
				cout << "line " << line << ": the variable (" << yytext << ") has not been declared" << endl;
			}else{
				string key = temporary_var.front();
				if (var_types_function.find(key) == var_types_function.end()) {
					var_types_function[key] = var_types_function[yytext];
				}else{
					if (var_types_function[key] != var_types_function[yytext]){
						cout << "line " << line << ": (" << var_types_function[yytext] << ") cannot be represented by the (" << var_types_function[key] << ")"<< endl;
					}
				}
			temporary_var.pop();
			}
		}
	}
	else{
		cout << "line " << line << ": Not enough variables to initialize with " << yytext << endl;
	}
}

 /* Daca se intalneste un apostrof, atunci ori este un string, ori o eroare cu impact asupra textului.  * 
  * Verificarea se va face in starea STRING.															*/
<INFERATION>{Apostrophe} {
	yy_push_state(INFERATION_ENUMERATION);
	yy_push_state(STRING);
}
 
 /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<INFERATION>. {
	yy_pop_state();
	yy_push_state(ERROR);

	if (debugMode) {
		printf("line %d:	*	[INFERATION] ERROR [INFERATION]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	temporary_var = clear_queue(temporary_var);
}

<INFERATION>{Newline} {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[INFERATION] ERROR [INFERATION]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}
 
 /* Se parseaza astfel, continutul string-ului (gasindu-se si apostroful din urma).Analog pentru restul. */
<STRING>{String}/{Apostrophe} {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[STRING] STRING. - (%s)	*\n", line, yytext);
	}

	if (!temporary_var.empty()){
		string key = temporary_var.front();
		
		if (inFunction == false){
			if (var_types_global.find(key) == var_types_global.end()) {
				var_types_global[key] = "string";
			}
			else{
				if (var_types_global[key] != "string" ){
					cout << "line " << line << ": (string) cannot be represented by the (" << var_types_global[key] << ")"<< endl;
				}
			}
		}
		else{
			if (var_types_function.find(key) == var_types_function.end()) {
				var_types_function[key] = "string";
			}
			else{
				if (var_types_function[key] != "string" ){
					cout << "line " << line << ": (string) cannot be represented by the (" << var_types_function[key] << ")"<< endl;
				}
			}
		}
		temporary_var.pop();
	}
	else{
		cout << "line " << line << ": Not enough variables to initialize with '" << yytext << "'" << endl;
	}

	/* Intrucat se accepta ca string-ul sa fie un text pe mai multe linii, se numara liniile. */
	string verify;
	verify.assign(yytext, yyleng);
	size_t n = std::count(verify.begin(),verify.end(), '\n');

	line += n;
	yyless(yyleng+1);
}

  /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<STRING>. {
	yy_pop_state();
	yy_pop_state();
	yy_pop_state();
	yy_push_state(ERROR);

	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[STRING] ERROR-STRING [STRING]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}

<STRING>{Newline} {
	yy_pop_state();
	yy_pop_state();
	yy_pop_state();
	
	if (debugMode) {
		printf("line %d:	*	[STRING] ERROR-STRING [STRING]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
	temporary_var = clear_queue(temporary_var);
}

 /* Este necesara o stare noua fata de enumerarile anterioare, intrucat nu se accepta '=' sau ':='	*/
<INFERATION_ENUMERATION>{Space}*{Comma}{Space}* {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[INFERATION_ENUMERATION] space virgula - (%s)	*\n", line, yytext);
	}
}

<INFERATION_ENUMERATION>{Space}*{Newline} {
	yy_pop_state();
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[INFERATION_ENUMERATION] space simplu - (%s)	*\n", line, yytext);
	}

	/* 	Daca linia s-a terminat, dar au fost enumerate mai multe variabile decat au fost initializate,	*
	 *	atunci se afiseaza eroarea si se curata coada de variabile temporare.							*/
	if (!temporary_var.empty()){
		cout << "line " << line << ": There are uninitialized variables" << endl; 
		temporary_var = clear_queue(temporary_var);
	}
	line++;
}
 
 /* Pentru orice eroare de sintaxa care strica linia, coada temporary_var va fi golita.	*/
<INFERATION_ENUMERATION>. {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(ERROR);

	if (debugMode) {
		printf("line %d:	*	[INFERATION_ENUMERATION] ERROR-COMMA [INFERATION_ENUMERATION]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	temporary_var = clear_queue(temporary_var);
}
 
 /* Se citeste numele functiei si caracterul '(' care va fi parsat folosind yyless(). De asemenea, se 	*
  *	seteaza numele functiei curente ca fiind acesta si se verifica daca mai exista acest nume. 			*/
<FUNC>{Word}"("/{Space}* {
	yy_pop_state();
	yy_push_state(ARGUMENTS_NAME);
	yyless(yyleng-1);

	if (debugMode) {
		printf("line %d:	*	[FUNC] name - (%s)	*\n", line, yytext);
	}

	currentFunctionName.assign(yytext, yyleng);
	if (function_names.find(yytext) == function_names.end()) {
		function_names.insert(yytext);
	}else{
		cout << "line " << line << ": " << "'" << yytext << "'" << " redeclared in this file" << endl; 
	}
	
	yyless(yyleng+1);
}

 /* Este nevoie de doua stari pentru a gestiona eroarea intrucat este necesara numararea liniilor. */
<FUNC>. {
	yy_pop_state();
	yy_push_state(ERROR);

	if (debugMode) {
		printf("line %d:	*	EROARE - FUNC NAME	*\n", line);
	}else{
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}

<FUNC>{Newline} {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	EROARE - FUNC NAME	*\n", line);
	}else{
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
}
 
 /* Daca intra in aceasta stare inseamna ca functia nu are argumente. returnExista = false, deoarece  	 *
  * aceasta este initializarea dinainte de FUNC_RETURN_TYPE unde se va verifica daca exista return type. */
<ARGUMENTS_NAME>")"{Space}* {
	yy_pop_state();
	yy_push_state(FUNC_RETURN_TYPE);
	returnExist = false;
}
 
 /* Se restrictioneaza modul in care se poate ajunge in starea ARGUMENTS_TYPE. Ori exista spatii si	 	*
  * virgula, ori exista cel putin un spatiu si un tip, altfel daca se primeste doar spatii, nu este  	*
  * eroare ,dar daca se primeste ceva diferit intra in starea de eroare. 		      				*/
<ARGUMENTS_NAME>{Word}/{Space}*{Comma}{Space}* {
	yy_push_state(ARGUMENTS_TYPE);
	
	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_NAME]1 - (%s)	*\n", line, yytext);
	}

	/* Se adauga fiecare argument al functiei in coada de variabile a argumentelor. Atunci cand se va 	*
	 * primi si tipul lor, se vor insera in dictionarul de variabile al functiei.						*/
	temporary_var.push(yytext);
}

<ARGUMENTS_NAME>{Word}/{Space}+({Type}) {
	yy_push_state(ARGUMENTS_TYPE);
	
	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_NAME]2 - (%s)	*\n", line, yytext);
	}

	/* Se adauga fiecare argument al functiei in coada de variabile a argumentelor. Atunci cand se va 	*
	 * primi si tipul lor, se vor insera in dictionarul de variabile al functiei.						*/
	temporary_var.push(yytext);
}

<ARGUMENTS_NAME>{Space}* {}

 /* Daca s-a stricat linia, s-a stricat intreaga functie, deci vor fi curatate structurile. */
<ARGUMENTS_NAME>. {
	yy_pop_state();
	yy_push_state(ERROR);
	
	temporary_var = clear_queue(temporary_var);
	var_types_function.clear();
	var_name_from_function.clear();

	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_NAME] ERROR [ARGUMENTS_NAME]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}

<ARGUMENTS_NAME>{Newline} {
	yy_pop_state();

	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_NAME] ERROR [ARGUMENTS_NAME]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	temporary_var = clear_queue(temporary_var);
	var_name_from_function.clear();
	var_types_function.clear();

	line++;
}

 /* Se verifica intr-un mod restrictionant daca exista tip in varianta corecta, in caz afirmativ se va 	*
  * citi in starile urmatoare. Procedura de a scapa de spatii implica urmatoarele doua stari. 			*/
<ARGUMENTS_TYPE>{Space}+/{Type}{Space}*[","|")"] {
	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_TYPE] 1 (%s)	*\n", line, yytext);
	}
}

<ARGUMENTS_TYPE>{Type}/{Space}*[","|")"] {
	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_TYPE] 2 (%s)	*\n", line, yytext);
	}

	/* Pentru toate argumentele primite pana acum se actualizeaza dictionarul functiei cu tipul primit. */
	while (!temporary_var.empty()){
		string key = temporary_var.front();
		
		if (var_name_from_function.find(key) != var_name_from_function.end()) {
        	std::cout << "Key found " << key << " ";
    	}else{
			var_types_function[key] = yytext;
			var_name_from_function.insert(key);
		}

		temporary_var.pop();
	}
}

 /* Daca nu este vorba despre a primi un tip, atunci se incearca o enumerare. */
<ARGUMENTS_TYPE>{Space}*{Comma}{Space}* {
	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_TYPE] - space,comma	*\n", line);
	}

	yy_pop_state();
}
 
 /* In cele din urma se incearca inchiderea parantezei. */
<ARGUMENTS_TYPE>{Space}*")"{Space}* {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(FUNC_RETURN_TYPE);

	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_TYPE] - space, paran	*\n", line);
	}

	temporary_var = clear_queue(temporary_var);
	returnExist = false;
}
 
 /* Daca s-a stricat linia, s-a stricat intreaga functie, deci vor fi curatate structurile. */
<ARGUMENTS_TYPE>. {
	yy_pop_state();
	yy_pop_state();
	yy_push_state(ERROR);

	var_name_from_function.clear();
	var_types_function.clear();
	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_TYPE] ERROR [ARGUMENTS_TYPE]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}

<ARGUMENTS_TYPE>{Newline} {
	yy_pop_state();
	yy_pop_state();

	var_name_from_function.clear();
	var_types_function.clear();
	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[ARGUMENTS_TYPE] ERROR [ARGUMENTS_TYPE]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
}
 
 /* Daca exista un tip urmat si de '\n' ( se accepta maxim unul ) atunci se seteazaz tipul in			* 
  * variabila returnString si returnExist devine true. "line++", deoarece in starea in care se			*
  * poate citi newline-ul nu se garanteaza existenta lui ( = ? ). Aceea (a 3-a stare) este o stare		*
  * care uneste primele doua stari in care se poate ajunge de aici. Ea citeste spatiile si eventualul	*
  * newline care nu este citit aici si "}".														    	*/
<FUNC_RETURN_TYPE>{Type}/{Space}*{Newline}{Space}*"{"{Space}* {
	if (debugMode) {
		printf("line %d:	*	[FUNC_RETURN_TYPE] (%s) cu type *\n", line, yytext);
	}

	returnString.assign(yytext, yyleng);
	
	returnExist = true;
	line++;
}

<FUNC_RETURN_TYPE>{Type}/{Space}*"{"{Space}* {
	if (debugMode) {
		printf("line %d:	*	[FUNC_RETURN_TYPE] (%s) cu type *\n", line, yytext);
	}

	returnExist = true;
	returnString.assign(yytext, yyleng);
}

<FUNC_RETURN_TYPE>{Space}*{Newline}?{Space}*"{"{Space}* {
	yy_pop_state();
	yy_push_state(INSIDE_FUNC);

	if (debugMode) {
		printf("line %d:	*	[FUNC_RETURN_TYPE] a intrat in f *\n", line);
	}

	inFunction = true;
}

 /* Daca s-a stricat linia, s-a stricat intreaga functie, deci vor fi curatate structurile. */
<FUNC_RETURN_TYPE>. {
	yy_pop_state();
	yy_push_state(ERROR);

	var_name_from_function.clear();
	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[FUNC_RETURN_TYPE] ERROR [FUNC_RETURN_TYPE]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}
}

<FUNC_RETURN_TYPE>{Newline} {
	yy_pop_state();
	var_name_from_function.clear();
	var_types_function.clear();
	temporary_var = clear_queue(temporary_var);

	if (debugMode) {
		printf("line %d:	*	[FUNC_RETURN_TYPE] ERROR [FUNC_RETURN_TYPE]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	line++;
}
 
 /* Din interiorul unei functii se poate intampla ce se intampla si in afara ei cu exceptia declararii 	*
  * unei alte functii.																					*/
<INSIDE_FUNC>{CommSimp} {
	yy_push_state(COMMENTARY_SHORT);
}

<INSIDE_FUNC>{CommStart} {
	yy_push_state(COMMENTARY_LONG);
}

<INSIDE_FUNC>{Var}{Space}+ {
	yy_push_state(VAR);

	if (debugMode) {
		printf("line %d:	*	[INSIDE_FUNC] var *\n", line);
	}
}

<INSIDE_FUNC>{Word} {
	if (debugMode) {
		printf("line %d:	*	[INSIDE_FUNC][ShortCut] - (%s)	*\n", line, yytext);
	}

	yy_push_state(SHORTCUT);
	yy_push_state(SHORTCUT_ENUMERATION);
	
	shortcut_temp_flag = false;
	if (var_name_from_function.find(yytext) == var_name_from_function.end()) {
		var_name_from_function.insert(yytext);
	}else{
		shortcut_temp_flag = true;
	}
	temporary_var.push(yytext);
}
 
 /* Aceasta reprezinta o iesire din functie in care nu s-a intalnit return. Sunt reinitializate	* 
  * structurile si flag-urile.																	*/
<INSIDE_FUNC>{Space}*"}"{Space}*{Newline} {
	yy_pop_state();

	if (debugMode){
		printf("line %d:	*	[INSIDE_FUNC] a iesit din func	*\n", line);
	}

	inFunction = false;
	var_types_function.clear();
	var_name_from_function.clear();
	line++;
}

 /* Aceasta este o stare in care sigur exista un return urmat poate de cateva spatii dar apoi newline.  *
  *	Astfel, va urma o stare ERROR_FUNC in care nu va mai conta nimic pana la gasirea '}'.				*/
<INSIDE_FUNC>{Space}*{Return}{Space}*{Newline} {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);
    
	/* Daca trebuia sa existe ceva de returnat se afiseaza eroare. */
	if (returnExist){
		cout << "line " << line << ": " << "Nothing to return for function '" << currentFunctionName << "'" << endl;
	} else {
		cout << "line " << line << ": " << "Too many arguments to return" << endl;
	}

	line++;
}

 /* Aceasta stare gaseste cuvantul 'return' si trimite catre o stare INFERATION_RETURN in care se incearca *
  * inferarea tipului daca acesta exista. 																   */
<INSIDE_FUNC>{Space}*{Return}{Space}* {
	yy_pop_state();
	yy_push_state(INFERATION_RETURN);

	/* Daca nu se asteapta un return, atunci se afiseaza eroarea. */
	if (!returnExist){
		cout << "line " << line << ": " << "Too many arguments to return" << endl;
	}
}

 /* Se accepta oricate spatii, fara a ajunge intr-o stare de eroare. */
<INSIDE_FUNC>{Space}* {}
 
 /* De asemenea, se accepta oricate newline-uri, dar se numara. */
<INSIDE_FUNC>{Newline} {
	line++;
}

 /* Orice altceva ce se poate primi este o eroare si strica intreaga linie. */
<INSIDE_FUNC>. {
	if (debugMode) {
		printf("line %d:	*	[INSIDE_FUNC] ERROR [INSIDE_FUNC]	*\n", line);
	}else {
		cout << "line " << line << ": Syntax Error" << endl; 
	}

	yy_push_state(ERROR);
}
 
 /* Se infereaza tipul returnat si se verifica daca coincide cu cel asteptat, in caz negativ se afiseaza o *
  * eroare. */
<INFERATION_RETURN>{Integer}{Space}* {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);

	if (returnExist){
		if (returnString != "int"){
			cout << "line " << line << ": " << "Invalid return type for function '" << currentFunctionName << "'" << endl; 
		}
	}
}

<INFERATION_RETURN>{Bool}{Space}* {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);

	if (returnExist){
		if (returnString != "bool"){
			cout << "line " << line << ": " << "Invalid return type for function '" << currentFunctionName << "'" << endl; 
		}
	}
}

<INFERATION_RETURN>{Real}{Space}* {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);

	if (returnExist){
		if (returnString != "float32"){
			cout << "line " << line << ": " << "Invalid return type for function '" << currentFunctionName << "'" << endl; 
		}
	}
}

 /* In cazul return-ului am gandit ca nu trebuia acceptat un string pe mai multe linii. */
<INFERATION_RETURN>{Apostrophe}.*{Apostrophe}{Space}* {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);

	if (returnExist){
		if (returnString != "string"){
			cout << "line " << line << ": " << "Invalid return type for function '" << currentFunctionName << "'" << endl; 
		}
	}
}
 
 /* Daca nu se gaseste apostroful final atunci nu mai conteaza nimic pana la gasirea '}' (see ERROR_FUNC). */
<INFERATION_RETURN>{Apostrophe}. {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);
	
	cout <<"line " << line << ": " << "Wrong string format" << endl;
}
 
 /* Daca se gaseste un cuvant, se verifica sa fie o variabila si se verifica si ca tipul ei sa coincida *
  * cu cel dorit. */
<INFERATION_RETURN>{Word}/{Space}* {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);

	if (returnExist){
		if (var_types_function.find(yytext) == var_types_function.end()) {
			cout << "NU EXISTA VARIABILA" << endl;
		}else{
			if (var_types_function[yytext] != returnString){
				cout << "line " << line << ": " << "Invalid return type for function '" << currentFunctionName << "'" << endl; 
			}
		}	
	}
}

<INFERATION_RETURN>{Space}* {}

 /* Daca s-a stricat linia se asteapta '}' */
<INFERATION_RETURN>. {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);
}

<INFERATION_RETURN>{Newline} {
	yy_pop_state();
	yy_push_state(ERROR_FUNC);
	
	line++;
}

 /* O stare de eroare ce parcurge o linie fara sa mai analizeze input-ul pana la 'newline'. */
<ERROR>. {}

<ERROR>{Newline} {
	yy_pop_state();

	line++;
}

 /* O stare de eroare ce parcurge textul dintr-o functie fara sa mai analizeze input-ul pana la '}'. *
 /* Daca se ajunge la '}' asta inseamna iesirea din functie, deci curatarea structurilor. 			 */ 
<ERROR_FUNC>"}" {
	if (debugMode) {
		printf("line %d:	*	[INSIDE_FUNC] a iesit din func	*\n", line);
	}

	inFunction = false;
	var_types_function.clear();
	var_name_from_function.clear();

	yy_pop_state();
}

<ERROR_FUNC>. {}

<ERROR_FUNC>{Newline} {
	line++;
}

 /* Orice altceva (global) nu mai conteaza, doar contorizarea spatiilor. */
. {}

{Newline} {
	line++;
}

%%

int yywrap(){
	return(1);
}

int main(int argc, char** argv) {
	yyin = fopen(argv[1], "r");

	/* Daca se doreste afisarea pasilor de analiza ale algoritmilor se poate selecta	 	*
	 * modul debug printr-o rulare in care al 3-lea argument(0,1,2) este "on". (mod DEBUG). */
	if (argc > 2) {
		if (strcmp(argv[2], "on") == 0){
			debugMode = true;
		}
	}
	
	yylex();
	return 0;
}
