; call_stack_tree
;
; Nested function calls with stack traffic while summing two memory leaves.
; Expected: DS:[0x40] = 18

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
cld

call tree_sum
mov [ebx + 0x40], eax
hlt

tree_sum:
call left_leaf
push eax
call right_leaf
pop edx
add eax, edx
ret
left_leaf:
mov eax, [ebx]
ret
right_leaf:
mov eax, [ebx + 0x04]
ret
