;SERBOI FLOREA-DAN 325CB

%include "io.inc"

extern getAST
extern freeAST

section .data
    numere:    times 1000    dd 0
    operatori:    times 1000    db 0
    lungime dd 0
    
section .bss
    ; La aceasta adresa, scheletul stocheaza radacina arborelui
    root: resd 1
    
section .text
;realizeaza o operatie, operanzii sunt in ESI si EDI
;rezultatul e tinut minte in ESI
;primeste ca parametru un operator
operatie:
    push ebp
    mov ebp, esp
    
    mov ecx, [ebp + 8]
    mov bl, cl
    ;verificam ce operator avem si facem saltul catre operatia corespunzatoare    
    cmp bl, '+'
    je aduna
    
    cmp bl, '-'
    je scade 
    
    cmp bl, '*'
    je inmulteste

    cmp bl, '/'
    je imparte
    
    ;operanzii sunt esi si edi si rezultatul il tinem minte in esi
aduna:
    add esi, edi
    jmp termina_op
    
scade:
    sub esi, edi
    jmp termina_op    

inmulteste:
    mov eax, esi
    imul edi
    mov esi, eax
    jmp termina_op

imparte:
    xor edx, edx
    mov eax, esi
    cdq
    idiv edi
    mov esi, eax
    jmp termina_op
    
termina_op:
    leave
    ret
;atoi converteste un string primit ca parametru intr-un intreg
atoi:
    push ebp
    mov ebp, esp        
    
    ;aici retin intregul
    mov esi, 0
    ;retin adresa string-ului
    mov ecx, [ebp + 8]
    ;verific daca numarul e negativ
    xor ebx, ebx
    mov bl, [ecx]
    push ebx
    cmp bl,'-'
    jnz parc
    ;daca e negativ, trebuie sa sar peste minus
    inc ecx
    ;parcurg string-ul si compun rezultatul
parc:
    ;pun caracterul in bl
    xor ebx, ebx
    mov bl, [ecx]
    ;daca caracterul e nul, inseamna ca am terminat de parcurs sirul
    cmp bl, 0
    jz negativ
    
    xor eax, eax
    xor edx, edx
    ;obtin valoarea cifrei        
    sub bl, '0'
    ;inmultesc rezultatul anterior cu 10
    mov eax, 10
    mul esi
    mov esi, eax
    ;adaug cifra
    add esi, ebx
    inc ecx
    jmp parc
    
;daca e negativ, fac complementul fata de 2(trebuie sa neg si sa adaug 1) 
negativ:
    pop ebx
    cmp bl, '-'
    jnz termina_atoi
    not esi
    inc esi
    
termina_atoi:
    xor eax, eax
    xor ebx, ebx
    xor edx, edx
    leave
    ret


;din arbore o sa retin intr-un vector numerele si intr-un alt vector operatorii
;pastram pozitiile din parcurgerea in preordine
arbore:
    push ebp
    mov ebp, esp

    ;retin adresa nodului	
    mov ecx, [ebp + 8]	
    ;daca e nul, ma opresc din recursivitate
    cmp ecx, 0
    jz termina
    
    mov eax, [lungime]
    inc eax
    mov [lungime], eax
    ;valoare nod curent
    mov ecx, [ebp + 8]
    mov ecx, [ecx]
    ;verific daca primul caracter e vreun operator
    mov bl, [ecx]
    cmp bl, '0'
    ;daca nu e operator, convertesc numarul
    jae atoi_operand
    ;verific daca al doilea caracter e nul(e posibil sa am minus)
    inc ecx
    mov bl, [ecx]
    cmp bl, 0
    ;daca nu am nul, inseamna ca am numar negativ
    jnz operand_negativ
    dec ecx
    ;operatorul il pun in vectorul b
    xor ebx, ebx             
    mov bl, [ecx]
    mov eax, [lungime]
    dec eax
    mov [operatori + eax], bl
    xor eax, eax
    jmp apeluri
    ;dupa ce fac atoi obtin valoarea intreaga in ESI
operand_negativ:
    dec ecx
atoi_operand:
    push ecx
    call atoi
    ;operandul il pun in vectorul a        
    mov eax, [lungime]
    dec eax
    mov [numere + 4*eax], esi
    xor eax, eax

apeluri:                                                                                                                                                                                                                                                                                                                                                 
    ;apelez pentru subarborele stang
    mov ecx, [ebp + 8]
    mov ecx, [ecx + 4]
    push ecx
    call arbore
    
    ;apelez pentru subarborele drept
    mov ecx, [ebp + 8]
    mov ecx, [ecx + 8]
    push ecx
    call arbore

termina:
    leave    
    ret
    
global main
main:
    mov ebp, esp; for correct debugging
    ; NU MODIFICATI
    push ebp
    mov ebp, esp
    
    ; Se citeste arborele si se scrie la adresa indicata mai sus
    call getAST
    mov [root], eax
    
    xor esi, esi
    xor edi, edi
    
    push dword[root]
    call arbore

    mov ecx, [lungime]
    dec ecx
;parcurgem vectorii de la sfarsit spre inceput
;tocmai pentru a respecta ordinea operatiilor
parcurgere_vectori:
    ;daca nu am operand, nu calculez
    cmp byte[operatori + ecx], 0
    jz nu_calculez
    ;altfel pun in esi operandul stang si in edi operandul drept
    mov esi, dword[numere + 4*(ecx+1)]
    mov edi, dword[numere + 4*(ecx+2)]
    push ecx
    xor ebx, ebx
    mov bl, byte[operatori + ecx]
    push ebx
    call operatie
    pop ebx
    pop ecx
    ;rezultatul in urma operatiei il am esi
    ;si il pun in vectorul a la indicele unde in vectorul b am operatorul
    mov [numere + 4*ecx], esi
    ;trebuie sa copiez peste operanzii care au fost implicati in operatie
    ;valorile din vector de dupa ei
    mov ebx, ecx
    mov eax, [lungime]
    sub eax, 3
actualizez_vector:
    inc ebx
    cmp ebx, eax
    jg nu_calculez
    mov esi, [numere + 4*(ebx+2)]
    mov [numere + 4*ebx], esi
    jmp actualizez_vector
nu_calculez:
    dec ecx
    cmp ecx, 0
    jge parcurgere_vectori
    
    ;pe prima pozitie din numere avem retinut rezultatul
    PRINT_DEC 4, [numere]
    
    push dword [root]
    call freeAST

    xor eax, eax
    leave
    ret