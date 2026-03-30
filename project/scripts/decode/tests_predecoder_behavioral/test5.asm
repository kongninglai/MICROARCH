; =========================
; IMMEDIATE TO AL / AX / EAX
; =========================
add al, 0x12        ; 04 ib
add ax, 0x1234      ; 05 iw
add eax, 0x12345678 ; 05 id

; =========================
; ADD r/m8 / r/m16 / r/m32
; =========================
add byte ptr [eax], 0x12 ; 80 /0 ib
add word ptr [eax], 0x1234 ; 81 /0 iw
add dword ptr [eax], 0x12345678 ; 81 /0 id
add word ptr [eax], 0x12 ; 83 /0 ib
add dword ptr [eax], 0x12 ; 83 /0 ib

; =========================
; ADD r/m8 / r/m16 / r/m32 from register
; =========================
add byte ptr [eax], al ; 00 /r
add word ptr [eax], ax ; 01 /r
add dword ptr [eax], eax ; 01 /r
add al, byte ptr [eax] ; 02 /r
add ax, word ptr [eax] ; 03 /r
add eax, dword ptr [eax] ; 03 /r

; =========================
; AND AL/AX/EAX with immediate
; =========================
and al, 0x12        ; 24 ib
and ax, 0x1234      ; 25 iw
and eax, 0x12345678 ; 25 id

; =========================
; AND r/m8 / r/m16 / r/m32 with immediate
; =========================
and byte ptr [eax], 0xFF ; 80 /4 ib
and word ptr [eax], 0x1234 ; 81 /4 iw
and dword ptr [eax], 0x12345678 ; 81 /4 id
and word ptr [eax], byte -128 ; 83 /4 ib
and dword ptr [eax], byte -1 ; 83 /4 ib

; =========================
; AND r/m8 / r/m16 / r/m32 from register
; =========================
and byte ptr [eax], al ; 20 /r
and word ptr [eax], ax ; 21 /r
and dword ptr [eax], eax ; 21 /r
and al, byte ptr [eax] ; 22 /r
and ax, word ptr [eax] ; 23 /r
and eax, dword ptr [eax] ; 23 /r

; =========================
; BIT SCAN
; =========================
bsf ax, bx          ; 0F BC  (BSF r16,r/m16)
bsf eax, ebx        ; 0F BC  (BSF r32,r/m32)
bsf eax, dword ptr [eax] ; OF BC (BSF r32,r/m32) 

; =========================
; CALL immediate / relative
; =========================
call short label1    ; E8 cw
call label2          ; E8 cd
call bx              ; FF /2
call ebx             ; FF /2
call far [data_ptr]  ; 9A cp

; =========================
; FLAGS / CONTROL
; =========================
cld                  ; FC
cmovc ax, bx         ; 0F 42 /r
cmovc eax, ebx       ; 0F 42 /r
cmpxchg bl, cl       ; 0F B0 /r
cmpxchg bx, cx       ; 0F B1 /r
cmpxchg ebx, ecx     ; 0F B1 /r
daa                  ; 27
hlt                  ; F4
iret                 ; CF

; =========================
; CONDITIONAL JUMPS
; =========================
jnbe short label3     ; 77 cb
jne short label4      ; 75 cb
jnbe label5           ; 0F 87 cw/cd
jne label7            ; 0F 85 cw / cd

; =========================
; MOV register / memory
; =========================
mov byte ptr [eax], bl ; 88 /r
mov word ptr [eax], bx ; 89 /r
mov dword ptr [eax], ebx ; 89 /r
mov bl, byte ptr [eax] ; 8A /r
mov bx, word ptr [eax] ; 8B /r
mov ebx, dword ptr [eax] ; 8B /r
mov word ptr [eax], ds ; 8C /r
mov ds, word ptr [eax] ; 8E /r
mov al, 0x82           ; B0+ rb
mov ax, 0x8234         ; B8+ rw
mov eax, 0x82345678    ; B8+ rd
mov byte ptr [eax], 0x12 ; C6 /0
mov word ptr [eax], 0x1234 ; C7 /0
mov dword ptr [eax], 0x12345678 ; C7 /0

; =========================
; MMX MOV
; =========================
movq mm0, mm1                 ; 0F 6F /r
movq qword ptr [eax], mm0     ; 0F 7F /r

; =========================
; STRING
; =========================
movsb                  ; A4
movsw                  ; A5
movsd                  ; A5

; =========================
; NOT
; =========================
not bl                  ; F6 /2
not bx                  ; F7 /2
not ebx                 ; F7 /2

; =========================
; OR
; =========================
or al, 0x12             ; 0C ib
or ax, 0x1234           ; 0D iw
or eax, 0x12345678      ; 0D id
or byte ptr [eax], 0x12 ; 80 /1 ib
or word ptr [eax], 0x1234 ; 81 /1 iw
or dword ptr [eax], 0x12345678 ; 81 /1 id
or word ptr [eax], 0x12 ; 83 /1 ib
or dword ptr [eax], 0x12 ; 83 /1 ib
or byte ptr [eax], bl    ; 08 /r
or word ptr [eax], bx    ; 09 /r
or dword ptr [eax], ebx  ; 09 /r
or al, byte ptr [eax]    ; 0A /r
or ax, word ptr [eax]    ; 0B /r
or eax, dword ptr [eax]  ; 0B /r

; =========================
; MMX ARITH
; =========================
paddw mm0, mm1           ; 0F FD /r
paddd mm0, mm1           ; 0F FE /r
packsswb mm0, mm1        ; 0F 63 /r
packssdw mm0, mm1        ; 0F 6B /r
punpckhbw mm0, mm1       ; 0F 68 /r
punpckhwd mm0, mm1       ; 0F 69 /r

; =========================
; POP / PUSH
; =========================
pop word ptr [eax]         ; 8F /0
pop dword ptr [eax]       ; 8F /0 
pop ax                    ; 58+ rw
pop eax                   ; 58+ rd
pop ds                    ; 1F
pop es                    ; 07
pop ss                    ; 17
pop fs                    ; 0F A1
pop gs                    ; 0F A9
push word ptr [eax]       ; FF /6
push dword ptr [eax]
push ax                   ; 50+ rw
push eax                  ; 50+ rd
push 0x12                 ; 6A
push 0x1234               ; 68
push 0x12345678           ; 68
push cs                    ; 0E
push ss                    ; 16
push ds                    ; 1E
push es                    ; 06
push fs                    ; 0F A0
push gs                    ; 0F A8
rep movsb                  ; F3 A4
rep movsw                  ; F3 A5
rep movsd                  ; F3 A5

; =========================
; RET
; =========================
ret                        ; C3
retf                       ; CB
ret 0x12                     ; C2 iw
retf 12                    ; CA iw

; =========================
; SHIFT LEFT (SAL)
; =========================
sal bl, 1                  ; D0 /4
sal bl, cl                 ; D2 /4
sal bl, 3                  ; C0 /4 ib
sal bx, 1                  ; D1 /4
sal bx, cl                 ; D3 /4
sal bx, 3                  ; C1 /4 ib
sal ebx, 1                 ; D1 /4
sal ebx, cl                ; D3 /4
sal ebx, 3                 ; C1 /4 ib

; =========================
; SHIFT RIGHT (SAR)
; =========================
sar bl, 1                  ; D0 /7
sar bl, cl                 ; D2 /7
sar bl, 3                  ; C0 /7 ib
sar bx, 1                  ; D1 /7
sar bx, cl                 ; D3 /7
sar bx, 3                  ; C1 /7 ib
sar ebx, 1                 ; D1 /7
sar ebx, cl                ; D3 /7
sar ebx, 3                 ; C1 /7 ib

; =========================
; FLAGS / NOP / XCHG
; =========================
std                        ; FD
xchg ax, bx                ; 90+ rw
xchg eax, ebx              ; 90+ rd
xchg bl, cl                ; 86 /r
xchg bx, cx                ; 87 /r
xchg ebx, ecx              ; 87 /r
