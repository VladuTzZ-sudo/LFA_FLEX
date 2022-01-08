Matei Vlad Cristian - 331CC

                                ####    TEMA FLEX   ####

Platforma sub care s-a realizat programul : Visual Studio Code + FLEX/LEX plugin
Am folosit limbajul C++, dar si ceva elemente ajutatoare din C (precum printf())

!! Am construit un script care ruleaza codul pentru cele 4 teste afisate. De 
asemenea, exista si o varianta de run_debug a codului, in care apar mai multe
print-uri pentru a intelege mai bine pasii algoritmului. Makefile-ul contine
o astfel de regula : "make run_debug".

                            ::::    Probleme Intalnite    ::::
    =   A trebuit sa ma bazez doar pe flex in ce priveste decizia de a trece dintr-o
    stare in alta. Nu am incercat doar sa transmit o cale flex-ului de interpreta
    textul primit ca input, ci am urmarit sa nu las nicio eroare de sintaxa sa 
    se strecoare neobservata in cod.
    =   Datorita faptului ca am vrut sa restrictionez foarte mult calea
    algoritmului printre starile descrise astfel incat sa fie identificata orice
    posibila eroare, a fost nevoie sa declar mai multe stari diferite care sa
    interpreteze spatiile, virgulele sau posibilele = sau := dintr-o enumerare de 
    variabile. Astfel exista stari diferite precum : 
        - VAR_ENUMERATION
        - INFERATION_ENUMERATION
        - SHORTCUT_ENUMERATION
        - (ARGUMENTS_TYPE intr-o masura)
    
    =   La inceput am folosit mai mult functia BEGIN(), atunci cand am creat codul
    pentru interpretarea variabilelor, dar apoi cand am ajuns la functii
    am realizat ca am nevoie sa citesc mai multe linii cu interpretare de
    variabile si dupa aceea sa raman tot in functie pana la intalnirea "}".
    Deci in loc de perechea  BEGIN(STATE) ... BEGIN (INITIAL) , am folosit doar
    yy_push_state si yy_pop_state().

                              ::::    Idei Importante    ::::
    =   Nu se accepta spatiu intre numele functiei si paranteza deschisa '('.
    =   Nu se accepta mai multe de un '\n' intre linia cu antetul unei functii
    si acolada deschisa '{'.
    =   Pentru rularea in mod run_debug trebuie adaugat argumentul 'on'.
    =   Pentru initializarea unei variabile cu string se accepta orice fel de text 
    in interiorul apostroafelor, chiar text pe mai multe linii. Doar in cazul in
    care se face -> return "exemplu de text", nu se permite ca string-ul sa fie pe
    mai multe linii.
    =   Pentru erori precum caractere random puse intr-un loc gresit se va printa
    o eroare generala : "Syntax error". ex: -> var a ,c.,lop00cx int
    =   Pe langa erorile obligatorii din cerinta temei, am adaugat in cazul unei
    interferari in care numarul variabilelor de dinainte de := nu este egal cu
    numarul de initializari 2 erori ce descriu evenimentul.
    =   Atunci cand exista o eroare care nu poate fi interpretata usor, de exemplu
    niste caractere random puse in mijlocul unei declarari obisnuite a unei
    variabile, linia se considera distrusa si se va intra intr-o stare de eroare
    pana la intalnirea '\n'.
    =   Exista o stare ERROR, stare de eroare pentru o linie si ERROR_FUNC, stare
    de eroare pentru o functie. ERROR citeste pana intalneste '\n', ERROR_FUNC 
    citeste pana intalneste '}'.
    =   Dupa intalnirea unui return intr-o functie, nu mai conteaza nimic pana la
    intalnirea unui '}'.

                            ::::    Logica Programului    ::::

    * Din starea initial se poate ajunge:
        ->  cu 'var' intr-o analiza de declarare de variabila.
        ->  cu / sau /* intr-o stare de comentariu.
        ->  cu 'func' intr-o analiza de analiza a antetului.
        ->  cu orice cuvant intr-o stare ce analizeaza o posibila inferare.

    * Odata ajuns intr-o functie, starea se numeste 'INSIDE_FUNC' si de acolo
    se poate ajunge:
        ->  cu 'var' intr-o analiza de declarare de variabila.
        ->  cu / sau /* intr-o stare de comentariu.
        ->  cu orice cuvant intr-o stare ce analizeaza o posibila inferare.
        ->  cu 'return' intr-o stare de analiza a return-ului.
        ->  cu '}' se intoarce in starea initial.

    * SHORTCUT = posibilitatea de initializare a variabilelor prin metoda 
    ':=' sau pur si simpla asignare de valoare unei variabile deja existente 
    prin metoda '='.

    * In starea SHORTCUT se poate ajunge din INITIAL | INSIDE_FUNC.
    * Din starea SHORTCUT exista variantele:
        1. SHORTCUT <--> SHORTCUT_ENUMERATION pentru enumerare de variabile.
            > pentru retinerea lor in ordine se foloseste o coada de string-uri.
        2. SHORTCUT -> SHORTCUT_ENUMERATION + '=' :
            > nu va avea loc o initializare de variabila ci poate doar o asignare
            de valoare unei variabile deja existente. De aici se va ajunge in
            starea INFERATION care va verifica daca tipul variabilei deja
            existente va fi acelasi cu tipul asignat aici.
        3. SHORTCUT -> SHORTCUT_ENUMERATION + ':=' :
            > va avea probabil loc o inferare, astfel incat conteaza daca
            variabila intalnita a mai fost declarata intai intrucat INFERAREA 
            este o declarare si o initializare. Apoi se va duce in starea 
            INFERATION.

    * VAR = posibilitatea de declarare a variabilelor, dar si de inferare
    precum arata in exemplul 1 din cerinta , linia 13 : 
    "13:        var a, b, c := 2, 3, 4".

    * Numai din VAR va exista posibilitatea de a ajunge in starea GIVE_TYPE
    prin care se va initializa tipul variabilelor declarate. Dar acest lucru nu 
    este obligatoriu, din VAR se poate ajunge direct in INFERATION.
    * Din starea VAR exista variantele:
        1. VAR <--> VAR_ENUMERATION pentru enumerare de variabile.
            > pentru retinerea lor in ordine se foloseste o coada de string-uri.
        2. VAR -> VAR_ENUMERATION + minim un spatiu -> GIVE_TYPE
        3. VAR -> VAR_ENUMERATION + '=' -> INFERATION
        4. VAR -> VAR_ENUMERATION + ':=' -> INFERATION

    * GIVE_TYPE + END_GIVE_TYPE sunt doua stari care permit initializarea de tip
    a unor variabile (GIVE_TYPE) si deciderea urmatoarei stari (END_GIVE_TYPE).

    * GIVE_TYPE -> pentru ca primeste un Type, atribuie tipul tuturor variabilelor
    din enumerare, salvate in coada temporary_var, si sunt actualizate
    dictionarele corespunzatoare. De asemenea, coada o sa ramana neschimbata pentru
    ca este nevoie de analiza ei si in starea INFERATION.

    DE CE ESTE NEVOIE DE COADA IN STAREA INFERATION ?
        - pentru ca este posibil ca si dupa GIVE_TYPE sa poate exista o inferare si
        atunci trebuie parcurse doar variabilele de pe linia curente, adica din coada
        si verificate, initializate.

    * END_GIVE_TYPE nu poate primi ':=', deoarece daca s-a primit deja tipul
    variabilelor in starea GIVE_TYPE, nu se poate infera un nou tip prin ':=', ci doar
    se poate atribui o valoare prin '='
    * Din starea GIVE exista variantele:
        1. GIVE_TYPE -> END_GIVE_TYPE + endline (INITIAL sau INSIDE_FUNC).
        2. GIVE_TYPE -> END_GIVE_TYPE + '=' -> INFERATION. ( diferenta dintre o 
        inferare si o atribuire de variabila este doar posibilitatea de a afisa o 
        eroare in plus pentru cazul ':=', in cazul in care variabila exista deja).
    
    * INFERATION verifica pentru fiecare variabila din coada ca valoarea atribuita
    acesteia sa fie conforma cu tipul acesteia daca a fost declarat anterior, daca nu
    se seteaza tipul valorii atribuite. De asemenea, verifica ca numarul variabilelor
    sa nu fie mai mic decat numarul valorilor atribuite.
    * Din starea INFERATION exista variantele:
        1. INFERATION <--> INFERATION_ENUMERATION pentru enumerare de valori.
        2. INFERATION -> INFERATION_ENUMERATION + endline (INITIAL sau INSIDE_FUNC).

    * FUNC citeste si salveaza numele functiei si verifica daca acesta mai exista
    declarat. Din starea FUNC se poate ajunge doar in starea ARGUMENTS_NAME.

    * ARGUMENTS_NAME(TYPE) permite trecerea peste citirea argumenteleor si a tipurilor
    acestora daca acestea nu exista sau permite o enumerare de variabile cu conditia
    obligatorie ca la sfarsit sa existe un tip atribuit acestora. Toate aceste arg 
    trebuie sa existe intre '(')'. Numele variabilelor arg sunt adaugate in multimea
    de variabile a functiei, iar atunci cand este primit si tipul lor sunt adaugate si
    in dictionarul de tipuri(var-type) pentru functia in cauza.
    * Din ARGUMENTS_NAME existe variantele:
        1. ARGUMENTS_NAME <--> ARGUMENTS_TYPE pentru enumerari de arg name si type.
        2. ARGUMENTS_NAME -> FUNC_RETURN_TYPE pentru cazul fara argumente.
        3. ARGUMENTS_NAME -> ARGUMENTS_TYPE -> FUNC_RETURN_TYPE pentru cazul cu arg.

    * FUNC_RETURN_TYPE este o stare in care se verifica daca exista un return type dorit
    si se impune conditia ca sa nu existe mai mult de un '\n' intre antetul functiei si 
    '{', care este obligatoriu. DIN FUNC_RETURN_TYPE se poate ajunge doar in INSIDE_FUNC.

    * INFERATION_RETURN este o stare in care se ajunge doar daca s-a intalnit
    cuvantul 'return'. Inainte de starea aceasta, se verifica in INSIDE_FUNC daca era 
    de asteptat un 'return', si se printeaza erorile asteptate in functie de 
    necesitatea unui 'return'. In starea aceasta doar se verifica daca tipul returnat
    coincide cu ce se dorea ( daca se dorea ).

    INFORMATIILE DIN README NU SUNT IDENTICE CU COMENTARIILE DIN COD, 
    ACESTEA SUNT COMPLEMENTARE !