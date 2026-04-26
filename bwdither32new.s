; Dithering algorithm: line dithering with error carry
; Input: 8-bit grayscale image
; Output: 1-bit black and white dithered image

        section text
        global bwdither32new
bwdither32new:
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
        add     dx, cx         ; add error from previous pixel
        ; compute new pixel value
        ; new = (value > 128) ? 255 : 0
        cmp     dx, 128
        setle   cl
        dec     cl
        mov     byte [esi], cl

        ; compute error:
        sub     dx, cx          ; dx = error = value - new
        mov     cx, dx          ; save error in cx for distribution
        sar     cx, 2           ; divide error by 4 for distribution

        test    ebx, 1          ; check which direction
        jnz     goLeft

        ; left to right
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


goLeft:
        ; right to left
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