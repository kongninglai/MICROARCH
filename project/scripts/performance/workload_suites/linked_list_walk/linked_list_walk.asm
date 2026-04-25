; linked_list_walk
;
; Pointer-chasing traversal over four nodes: {value,next_offset}.
; Expected: DS:[0x40] = 26

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
cld

mov esi, 0x00000000
mov eax, 0x00000000
call sum_nodes
mov [ebx + 0x40], eax
hlt

sum_nodes:
add eax, [esi]
mov esi, [esi + 0x04]
add esi, 0x00
jne sum_nodes
ret
