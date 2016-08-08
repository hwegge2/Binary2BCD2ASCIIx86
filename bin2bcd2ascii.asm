; multi-segment executable file template.

data segment
    SUM DB 4 DUP(0)
    NOTSUM db 4 dup(0)
    NOTDIFF db 4 dup(0)
    DIFF1 DB 4 DUP(0)
    NUMBER DB 12 DUP(0)
    DECIMAL_IN_ASCII db 11 dup(0)
    A DB 4 DUP(0)
    usenotsum db 0
    usenotdiff db 0
    Aneg db 4 dup(0)
    result db 11 dup(0)
    asign db 0
    bsign db 0
    B DB 4 DUP(0)
    Bneg db 4 dup(0)
    pkey db "press any key...$"
    entera db "Enter A: $"
    enterb db "Enter B: $"
    aplusb db "A + B = $"
    aminusb db "A - B = $"
ends

stack segment
    dw   128  dup(0)
ends

code segment
main proc far
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax ;
    
    again:
    mov ah, 0h
    mov al, 3h
    int 10h     ;set video mode
    
    mov asign, 0
    mov bsign, 0
    mov usenotsum, 0
    mov usenotdiff, 0
    
    mov ah, 9h
    mov dx, offset entera
    int 21h                 ;display 'enter A'
    
    mov ch, 2  ; when 1, conv_ uses B instead of A
    call INPUT_NUMBER
    cmp [di+2], 'Q'
    jz done
    cmp [di+2], 'q'
    jz done
    call CONV_ASC2BIN
    
    mov ah, 2
    mov bh, 0
    mov dx, 0100h
    int 10h
    
    mov ah, 9
    mov dx, offset enterb
    int 21h                 ;display 'enter B'
    
    call INPUT_NUMBER
    mov ch, 1
    call CONV_ASC2BIN    
    
    cmp asign, 0
    je testB
    lea di, A
    lea si, Aneg 
    call COMPLEMENT
    
    testB:
    cmp bsign, 0
    je addsubtract
    lea di, B
    lea si, Bneg
    call COMPLEMENT
    
    addsubtract:
    cmp asign, 1
    je chos_aneg
    mov si, offset A
    jmp chosb
    chos_aneg:
    mov si, offset Aneg
    
    chosb:
    cmp bsign, 1
    je chos_bneg
    mov bx, offset B
    jmp addandsubtract
    chos_bneg:
    mov bx, offset Bneg
    
    addandsubtract:
    cmp bsign, 1
    je subtractnotadd
    mov di, offset SUM
    call ADD_A_B
    jmp skipother
    
    subtractnotadd:
    mov si, offset Aneg
    cmp asign, 1
    je contin
    mov si, offset A
    contin:
    mov bx, offset B
    mov di, offset SUM
    call SUB_A_B
    
    skipother:
    lea di, sum
    cmp [di+3], 0FFh
    jne conv2dec:
    lea si, NOTSUM
    call COMPLEMENT
    lea si, usenotsum
    mov [si], 1
    
    conv2dec:
    cmp usenotsum, 0
    je sumpositive
    lea si, notsum
    jmp conv2asc
    sumpositive:
    lea si, sum
    
    conv2asc:
    call BIN2DEC2ASC
    
    cmp bsign, 0
    je subtractlikenormal
    mov bx, offset B
    mov di, offset diff1
    mov si, offset A
    cmp asign, 0
    je addd
    mov si, offset Aneg
    addd: 
    call ADD_A_B
    jmp donesubtracting
    
    subtractlikenormal:
    mov bx, offset B
    mov si, offset A
    cmp asign, 0
    je subtractposA
    mov si, offset Aneg
    
    subtractposA:
    mov di, offset DIFF1
    call SUB_A_B
    
    donesubtracting:
    lea di, diff1
    cmp [di+3], 0FFh
    jne donotcompB
    lea si, NOTDIFF
    call COMPLEMENT
    lea si, usenotdiff
    mov [si], 1    
    
    donotcompB:
    mov ah, 2
    mov bh, 0
    mov dh, 4
    mov dl, 1
    int 10h         ;new line
    
    mov ah, 9
    mov dx, offset aplusb
    int 21h                       ;display a + b
    
    cmp usenotsum, 0
    je displaysum
    mov ah, 2
    mov dl, '-'                ;display '-' for negative sum
    int 21h    
    
    displaysum:
    mov ah, 9
    mov dx, offset DECIMAL_IN_ASCII
    int 21h
   
    mov ah, 2
    mov bh, 0
    mov dh, 5
    mov dl, 1
    int 10h
    
    mov ah, 9
    mov dx, offset aminusb
    int 21h
    
    cmp usenotdiff, 0
    je displayminus2
    mov ah, 2
    mov dl, '-'                ;display '-' for negative diff
    int 21h
    
    displayminus2:
    cmp usenotdiff, 0
    je diffpositive
    lea si, notdiff
    jmp displayB
    diffpositive:
    lea si, diff1
    
    displayB:
    call BIN2DEC2ASC
    
    mov ah, 9
    mov dx, offset DECIMAL_IN_ASCII
    int 21h
    
    mov ah, 2
    mov bh, 0
    mov dh, 7
    mov dl, 1
    int 10h
    
    lea dx, pkey
    mov ah, 9
    int 21h        ; output string at ds:dx
    
    ; wait for any key....    
    mov ah, 1
    int 21h
    
    jmp again
    
    done: call CLC_SCREEN                    
    
    mov ax, 4c00h ; exit to operating system.
    int 21h    
main endp

ADD_A_B proc near
    push cx                     ;A into si
    push ax                     ;B into bx
    push si                     ;output into di
    push bx
    mov cx, 4
    mov ax, 0
    clc
    adding: mov al, [si]
    adc al, [bx]
    mov [di], al
    inc si
    inc bx
    inc di 
    dec cx
    jnz adding
    pop bx
    pop si
    pop ax
    pop cx
    ret 
ADD_A_B endp

            
SUB_A_B proc near
    push cx
    push ax
    push si
    push bx
    mov cx, 4
    mov ax, 0
    clc
    subtracting: mov al, [si]
    sbb al, [bx]
    mov [di], al
    inc si
    inc bx
    inc di 
    dec cx
    jnz subtracting
    pop bx
    pop si
    pop ax
    pop cx
    ret            
SUB_A_B endp

INPUT_NUMBER proc near
    mov di, offset NUMBER
    mov [di], 10
    mov ah, 0Ah
    mov dx, offset NUMBER
    int 21h
    ret        
INPUT_NUMBER endp
   
CONV_ASC2BIN proc near
    mov si, offset NUMBER
    mov cl, [si+1]
    
    cmp [si+2], '-'
    jne positive        ;jump past -, dec length
    inc si
    dec cl
    cmp ch, 1
    jg anegative
    mov bsign, 1
    jmp positive
    anegative:
    mov asign, 1
    
    positive:
    cmp cl, 1
    jnz continue     ;fixed inputs with only 1 digit
    push [si+2]
    mov [si+2], 30h
    pop dx
    mov [si+3], dx  
    mov cl, 2
    mov dx, 0
     
    Continue:
    dec cl      ;end fix
    add si, 2
    mov ax, 0
    mov bp, 10
    clc
    mov dx, 0
    conv: mov bl, [si]
    sub bl, 30h
    
    add ax, bx
    adc dx, 0
    
    push ax
    mov ax, dx
    mul bp
    
    mov di, ax
    pop ax
    mul bp
    add dx, di
        
    inc si
    dec cl
    jnz conv
    clc
    dec ch
    jz Bnum
    mov bl, [si]
    sub bl, 30h
    add al, bl
    adc ah, 0
    adc dx, 0
    mov si, offset A
    mov [si], ax
    mov [si+2], dx
    ret
    Bnum: mov bl, [si]
    sub bl, 30h
    add al, bl
    adc ah, 0
    adc dx, 0
    mov si, offset B
    mov [si], ax
    mov [si+2], dx 
    ret
CONV_ASC2BIN endp

CLC_SCREEN proc near
    push ax
    mov ax, 0003h
    int 10h
    pop ax
    ret
CLC_SCREEN endp 

COMPLEMENT proc near
    mov ax, [di]
    mov dx, [di+2]            ;original # at DI

    mov bx, 0FFFFh
    sub bx, dx
    mov cx, 0FFFFh
    sub cx, ax

    add cx, 1
    adc bx, 0
          
    mov [si], cx           ;result in SI
    mov [si+2], bx
    ret
COMPLEMENT endp

BIN2DEC2ASC proc near
    mov bp, 000Ah            ;use si as input
    lea di, result
    
    againb2d:
    mov dx, 0
    mov ax, [si+2]
    div bp
    
    mov [si+2], ax
    mov ax, [si]
    div bp
    mov [si], ax
    
    mov [di], dx
    add [di], 30h
    
    cmp ax, 0
    je nextb2d
    inc di
    jne againb2d
    
    nextb2d:
    lea si, result
    lea bx, DECIMAL_IN_ASCII
    switchb2d:
    mov al, [di]
    mov [bx], al
    inc bx
    dec di
    cmp di, si
    jnl switchb2d
    mov [bx], '$'
    ret
BIN2DEC2ASC endp        
     
ends

end main ; set entry point and stop the assembler.
