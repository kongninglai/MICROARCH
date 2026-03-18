add al, 0x12
add ax, 0x1234
add eax, 0x12345678

add byte ptr [eax], 0x12
add word ptr [eax], 0x1234
add dword ptr [eax], 0x12345678
add word ptr [eax], 0x12
add dword ptr [eax], 0x12

add byte ptr [eax], al
add word ptr [eax], ax
add dword ptr [eax], eax
add al, byte ptr [eax]
add ax, word ptr [eax]
add eax, dword ptr [eax]

and al, 0x12
and ax, 0x1234
and eax, 0x12345678

and byte ptr [eax], 0xFF
and word ptr [eax], 0x1234
and dword ptr [eax], 0x12345678
and word ptr [eax], byte -128
and dword ptr [eax], byte -1

and byte ptr [eax], al
and word ptr [eax], ax
and dword ptr [eax], eax
and al, byte ptr [eax]
and ax, word ptr [eax]
and eax, dword ptr [eax]

bsf ax, bx
bsf eax, ebx
bsf eax, dword ptr [eax]

call short label1
call label2
call bx
call ebx
call far [data_ptr]

cld
cmovc ax, bx
cmovc eax, ebx
cmpxchg bl, cl
cmpxchg bx, cx
cmpxchg ebx, ecx
daa
hlt
iret

jnbe short label3
jne short label4
jnbe label5
jne label7

mov byte ptr [eax], bl
mov word ptr [eax], bx
mov dword ptr [eax], ebx
mov bl, byte ptr [eax]
mov bx, word ptr [eax]
mov ebx, dword ptr [eax]
mov word ptr [eax], ds
mov ds, word ptr [eax]
mov al, 0x82
mov ax, 0x8234
mov eax, 0x82345678
mov byte ptr [eax], 0x12
mov word ptr [eax], 0x1234
mov dword ptr [eax], 0x12345678

movq mm0, mm1
movq qword ptr [eax], mm0

movsb
movsw
movsd

not bl
not bx
not ebx

or al, 0x12
or ax, 0x1234
or eax, 0x12345678
or byte ptr [eax], 0x12
or word ptr [eax], 0x1234
or dword ptr [eax], 0x12345678
or word ptr [eax], 0x12
or dword ptr [eax], 0x12
or byte ptr [eax], bl
or word ptr [eax], bx
or dword ptr [eax], ebx
or al, byte ptr [eax]
or ax, word ptr [eax]
or eax, dword ptr [eax]

paddw mm0, mm1
paddd mm0, mm1
packsswb mm0, mm1
packssdw mm0, mm1
punpckhbw mm0, mm1
punpckhwd mm0, mm1

pop word ptr [eax]
pop dword ptr [eax]
pop ax
pop eax
pop ds
pop es
pop ss
pop fs
pop gs
push word ptr [eax]
push dword ptr [eax]
push ax
push eax
push 0x12
push 0x1234
push 0x12345678
push cs
push ss
push ds
push es
push fs
push gs
rep movsb
rep movsw
rep movsd

ret
retf
ret 0x12
retf 12

sal bl, 1
sal bl, cl
sal bl, 3
sal bx, 1
sal bx, cl
sal bx, 3
sal ebx, 1
sal ebx, cl
sal ebx, 3

sar bl, 1
sar bl, cl
sar bl, 3
sar bx, 1
sar bx, cl
sar bx, 3
sar ebx, 1
sar ebx, cl
sar ebx, 3

std
xchg ax, bx
xchg eax, ebx
xchg bl, cl
xchg bx, cx
xchg ebx, ecx
