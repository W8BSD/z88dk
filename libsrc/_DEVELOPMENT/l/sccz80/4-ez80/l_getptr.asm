;       Z88 Small C+ Run Time Library 
;
;       Get Long Pointer from Near Memory

SECTION code_clib
SECTION code_l_sccz80
PUBLIC    l_getptr


;Fetch 3 byte pointer from (hl)

.l_getptr
    defb $ed, $17	;ld de,(hl)
    inc hl
    inc hl
    defb $ed, $27	;ld hl,(hl)
    ld  h,0
    ex  de,hl
    ret
