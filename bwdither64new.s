; Dithering algorithm: line dithering with error carry
; Input: 8-bit grayscale image
; Output: 1-bit black and white dithered image

        section .text
        global bwdither64new
bwdither64new:
        ; void bwdither(void *img, uint32_t width, uint32_t height, uint32_t stride);
        push    rbx           ; save rbx

        ; Save parameters BEFORE overwriting registers
        mov     r8d, esi        ; width
        mov     r9d, edx        ; height
        mov     r10d, ecx       ; stride
        mov     rsi, rdi        ; img pointer

        xor     rbx, rbx        ; y = 0
        xor     rax, rax        ; x = 0
        xor     rcx, rcx        ; error = 0
        
loop:
        movzx   dx, byte [rsi]        ; load pixel value
        add     dx, cx         ; add error from previous pixel
        ; compute new pixel value
        ; new = (value > 128) ? 255 : 0
        cmp     dx, 128
        setle   cl
        dec     cl
        mov     byte [rsi], cl

        ; compute error:
        sub     dx, cx          ; dx = error = value - new
        mov     cx, dx          ; save error in cx for distribution
        sar     cx, 2           ; divide error by 4 for distribution

        test    ebx, 1          ; check which direction
        jnz     goLeft

        ; left to right
        inc     eax             ; x++
        inc     rsi             ; move to next pixel
        cmp     eax, r8d        ; compare x with width
        jl      loop
        ; reached end of line
        inc     ebx             ; y++
        cmp     ebx, r9d        ; check if eof
        jge     fin
        ; move to next line
        lea     rsi, [rsi + r10 - 1] ; rsi = rsi + stride - 1
        dec     eax
        jmp     loop


goLeft:
        ; right to left
        dec     eax             ; x--
        dec     rsi             ; move to previous pixel
        cmp     eax, -1         ; compare x with -1
        jg      loop
        ; reached beginning of line
        inc     ebx             ; y++
        cmp     ebx, r9d   ; check if eof
        jge     fin
        ; move to next line
        lea     rsi, [rsi + r10 + 1] ; rsi = rsi + stride + 1
        xor     eax, eax        ; x = 0
        jmp     loop

fin:
        pop     rbx
        ret