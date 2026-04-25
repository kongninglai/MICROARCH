; vector_accumulate
;
; Packed 32-bit counter accumulation with paddd.
; Expected: DS:[0x40] = 1, DS:[0x44] = 4

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
cld

call accum2
hlt

accum2:
movq mm0, [ebx]
movq mm1, [ebx + 0x08]
paddd mm0, mm1
movq [ebx + 0x40], mm0
ret
