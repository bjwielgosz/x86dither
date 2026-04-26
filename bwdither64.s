; Dithering algorithm: Floyd-Steinberg
; Input: 8-bit grayscale image
; Output: 1-bit black and white dithered image

; REGISTERS
; RDI - current pixel pointer
; ESI - width
; EDX - saved, height
; ECX - stride
; EAX - x coordinate 
; EBX - y coordinate 
; R8 - pixel value
; R9 - error value
; R10 - flags - (firstColumn, lastColumn, lastRow)
; R11 - temp value
; R12 - saved, flag temp / current pixel pointer secondary
; R13 - saved, error for given pixel
; R14
; R15

        section .text
        global bwdither64
bwdither64:
        ; void bwdither(void *img, uint32_t width, uint32_t height, uint32_t stride);
        push    rbx
        push    r12
        push    r13

        ; RDI - img pointer
        ; ESI - width
        ; EDX - height
        ; ECX - stride

        xor     ebx, ebx        ; y = 0
        xor     eax, eax        ; x = 0
        
loop:
        movzx   r8d, byte [rdi]        ; load pixel value
        ;     compute new pixel value and error:
        ;     new = (value > 128) ? 255 : 0
        cmp     r8d, 128
        setle   r9b
        dec     r9b
        mov     byte [rdi], r9b
        xor     r10b, r10b
        ; compute error:
        sub     r8b, r9b         ; r8b = error = value - new

        test    eax, eax        ; check first column
        sete    r10b              ; r10b = 1 if x == 0

        lea     r11d, [esi - 1]
        cmp     eax, r11d
        sete    r12b
        shl     r12b, 1           ; r10b = 2 if x == width-1
        or      r10b, r12b          ; set bit 1

        lea     r11d, [edx - 1]           ; edi = height - 1
        cmp     ebx, r11d
        sete    r12b
        shl     r12b, 2           ; r10b = 4 if y == height-1
        or      r10b, r12b          ; set bit 2

        mov     r12, rdi        ; save current pixel address
        test    ebx, 1          ; check direction (even = right, odd = left)

        jnz     dist1Left

dist1Right:
        test    r10b, 2          ; check last column
        jnz     dist2Right

        ; img[x+1, y] += error * 7/16
        lea     rdi, [r12 + 1]

        movsx   r13w, r8b        ; sign-extend error from 8-bit to 16-bit
        imul    r13w, 7
        sar     r13w, 4
        call    clampPixel
        
dist2Right:
        test    r10b, 5          ; check first column or last row
        jnz     dist3Right

        ; img[x-1, y+1] += error * 3/16
        lea     rdi, [r12 + rcx - 1]

        movsx   r13w, r8b
        imul    r13w, 3
        sar     r13w, 4
        call    clampPixel

dist3Right:
        test    r10b, 4
        jnz     dist4Right

        ; img[x, y+1] += error * 5/16
        lea     rdi, [r12 + rcx]

        movsx   r13w, r8b
        imul    r13w, 5
        sar     r13w, 4
        call    clampPixel
        
dist4Right:
        test    r10b, 6
        jnz     loopEndRight

        ; img[x+1, y+1] += error * 1/16
        lea     rdi, [r12 + rcx + 1]

        movsx   r13w, r8b
        sar     r13w, 4
        call    clampPixel

loopEndRight:
        mov     rdi, r12        ; restore pixel address

        inc     eax             ; x++
        inc     rdi             ; move to next pixel
        cmp     eax, esi        ; compare x with width
        jl      loop
        ; reached end of line
        inc     ebx             ; y++
        cmp     ebx, edx        ; check if eof
        jge     fin
        ; move to next line
        lea     rdi, [rdi + rcx - 1] ; rdi = rdi + stride - 1
        dec     eax
        jmp     loop






dist1Left:
        test    r10w, 1          ; check first column
        jnz     dist2Left  

        ; img[x-1, y] += error * 7/16
        lea     rdi, [r12 - 1]

        movsx   r13w, r8b
        imul    r13w, 7
        sar     r13w, 4
        call    clampPixel

dist2Left:
        test    r10w, 6          ; check last column or first row
        jnz     dist3Left

        ; img[x+1, y+1] += error * 3/16
        lea     rdi, [r12 + rcx + 1]

        movsx   r13w, r8b
        imul    r13w, 3
        sar     r13w, 4
        call    clampPixel

dist3Left:
        test    r10w, 4       ; check last row
        jnz     dist4Left

        ; img[x, y+1] += error * 5/16
        lea     rdi, [r12 + rcx]

        movsx   r13w, r8b
        imul    r13w, 5
        sar     r13w, 4
        call    clampPixel

dist4Left:
        test    r10w, 5     ; check last row or first column
        jnz     loopEndLeft

        ; img[x-1, y+1] += error * 1/16
        lea     rdi, [r12 + rcx - 1] ; add stride 
        movsx   r13w, r8b
        sar     r13w, 4
        call    clampPixel

loopEndLeft:
        mov     rdi, r12        ; restore pixel address

        dec     eax             ; x--
        dec     rdi             ; move to previous pixel
        cmp     eax, -1         ; compare x with -1
        jg      loop
        ; reached beginning of line
        inc     ebx             ; y++
        cmp     ebx, edx        ; check if eof
        jge     fin
        ; move to next line
        lea     rdi, [rdi + rcx + 1] ; rdi = rdi + stride + 1
        xor     eax, eax        ; x = 0
        jmp     loop

fin:

        pop     r13
        pop     r12
        pop     rbx
        ret


clampPixel:
        ;r13w = error
        ;rdi = pixel address
        movzx   r11w, byte [rdi] ; load pixel
        add     r11w, r13w        ; add error

        xor     r13w, r13w        ; clear r13w for comparison
        test    r11w, r11w
        cmovs   r11w, r13w        ; if r11w < 0, set r11w = 0

        mov     r13w, 255
        cmp     r11w, r13w
        cmovg   r11w, r13w        ; if r11w > 255, set r11w = 255
        mov     byte [rdi], r11b
        ret