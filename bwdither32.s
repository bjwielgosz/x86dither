; Dithering algorithm: Floyd-Steinberg
; Input: 8-bit grayscale image
; Output: 1-bit black and white dithered image

; REGISTERS
; ESI - pointer to current pixel
; EAX - x coordinate / clamp placeholder
; EBX - y coordinate / error value
; CH - flags - (firstColumn, lastColumn, lastRow)       CX - temp error value
; CL - flag setting temp
; DX - error value / pixel value
; EDI - big temp / ref pixel value during distribution

        section text
        global bwdither32
bwdither32:
        ; void bwdither(void *img, uint32_t width, uint32_t height, uint32_t stride);
        push    ebp             ; save caller's frame pointer
        mov     ebp, esp

        push    ebx             ; save callee-saved registers
        push    esi
        push    edi

        mov     esi, [ebp+8]    ; img pointer
        ;mov     ?, [ebp+12]   ; width
        ;mov     ?, [ebp+16]   ; height
        ;mov     ?, [ebp+20]   ; stride

        xor     ebx, ebx        ; y = 0
        xor     eax, eax        ; x = 0
        xor     cx, cx          ; error = 0
        
loop:
        movzx   dx, byte [esi]        ; load pixel value
        ;     compute new pixel value and error:
        ;     new = (value > 128) ? 255 : 0
        cmp     dx, 128
        setle   cl
        dec     cl
        mov     byte [esi], cl
        xor     ch, ch
        ; compute error:
        sub     dx, cx          ; dx = error = value - new

        test    eax, eax        ; check first column
        sete    ch              ; ch = 1 if x == 0

        mov     edi, [ebp+12]
        dec     edi             ; edi = width - 1
        cmp     eax, edi
        sete    cl
        shl     cl, 1           ; cl = 2 if x == width-1
        or      ch, cl          ; set bit 1

        mov     edi, [ebp+16]
        dec     edi             ; edi = height - 1
        cmp     ebx, edi
        sete    cl
        shl     cl, 2           ; cl = 4 if y == height-1
        or      ch, cl          ; set bit 2

        push    eax             ; save x

        mov     edi, esi        ; save current pixel address
        test    ebx, 1          ; check direction (even = right, odd = left)

        push    ebx             ; save y
        jnz     dist1Left

dist1Right:
        test    ch, 2          ; check last column
        jnz     dist2Right

        ; img[x+1, y] += error * 7/16
        mov     esi, edi
        inc     esi             ; move to img[x+1, y]
        mov     bx, dx
        imul    bx, 7
        sar     bx, 4
        call    clampPixel
        
dist2Right:
        test    ch, 5          ; check first column or last row
        jnz     dist3Right

        ; img[x-1, y+1] += error * 3/16
        mov     esi, edi
        dec     esi     ; move to img[x-1, y]
        add     esi, [ebp+20] ; add stride

        mov     bx, dx
        imul    bx, 3
        sar     bx, 4
        call    clampPixel

dist3Right:
        test    ch, 4
        jnz     dist4Right

        ; img[x, y+1] += error * 5/16
        mov     esi, edi
        add     esi, [ebp+20] ; add stride

        mov     bx, dx
        imul    bx, 5
        sar     bx, 4
        call    clampPixel
        
dist4Right:
        test    ch, 6
        jnz     loopEndRight

        ; img[x+1, y+1] += error * 1/16
        mov     esi, edi
        inc     esi     ; move to img[x+1, y+1]
        add     esi, [ebp+20] ; add stride


        mov     bx, dx
        sar     bx, 4
        call    clampPixel

loopEndRight:
        pop     ebx             ; restore y
        pop     eax             ; restore x

        mov     esi, edi        ; restore pixel address

        inc     eax             ; x++
        inc     esi             ; move to next pixel
        cmp     eax, [ebp+12]   ; compare x with width
        jl      loop
        ; reached end of line
        inc     ebx             ; y++
        cmp     ebx, [ebp+16]   ; check if eof
        jge     fin
        ; move to next line
        mov     edi, [ebp+20]   ; stride
        lea     esi, [esi + edi - 1] ; esi = esi + stride - 1
        dec     eax
        jmp     loop






dist1Left:
        test    ch, 1          ; check first column
        jnz     dist2Left  

        ; img[x-1, y] += error * 7/16
        mov     esi, edi
        dec     esi             ; move to img[x-1, y]
        mov     bx, dx
        imul    bx, 7
        sar     bx, 4
        call    clampPixel

dist2Left:
        test    ch, 6          ; check last column or first row
        jnz     dist3Left

        ; img[x+1, y+1] += error * 3/16
        mov     esi, edi
        inc     esi     ; move to img[x+1, y]
        add     esi, [ebp+20] ; add stride
        mov     bx, dx
        imul    bx, 3
        sar     bx, 4
        call    clampPixel

dist3Left:
        test    ch, 4       ; check last row
        jnz     dist4Left

        ; img[x, y+1] += error * 5/16
        mov     esi, edi
        add     esi, [ebp+20] ; add stride
        mov     bx, dx
        imul    bx, 5
        sar     bx, 4
        call    clampPixel

dist4Left:
        test    ch, 5     ; check last row or first column
        jnz     loopEndLeft

        ; img[x-1, y+1] += error * 1/16
        mov     esi, edi
        dec     esi     ; move to img[x-1, y+1]
        add     esi, [ebp+20] ; add stride 
        mov     bx, dx
        sar     bx, 4
        call    clampPixel

loopEndLeft:
        pop     ebx             ; restore y
        pop     eax             ; restore x

        mov     esi, edi        ; restore pixel address

        dec     eax             ; x--
        dec     esi             ; move to previous pixel
        cmp     eax, -1         ; compare x with -1
        jg      loop
        ; reached beginning of line
        inc     ebx             ; y++
        cmp     ebx, [ebp+16]   ; check if eof
        jge     fin
        ; move to next line
        mov     edi, [ebp+20]   ; stride
        lea     esi, [esi + edi + 1] ; esi = esi + stride - 1
        xor     eax, eax        ; x = 0
        jmp     loop

fin:

        pop     edi             ; restore callee-saved registers
        pop     esi
        pop     ebx
        mov     esp, ebp
        pop     ebp             ; restore caller's frame pointer
        ret


clampPixel:
        ;bx = error
        ;esi = pixel address
        movzx   ax, byte [esi] ; load pixel
        add     ax, bx        ; add error

        xor     bx, bx        ; clear bx for comparison
        test    ax, ax
        cmovs   ax, bx        ; if ax < 0, set ax = 0

        mov     bx, 255
        cmp     ax, bx
        cmovg   ax, bx        ; if ax > 255, set ax = 255

        mov     byte [esi], al
        ret