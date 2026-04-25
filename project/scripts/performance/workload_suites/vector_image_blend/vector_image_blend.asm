; vector_image_blend
;
; Average two 8-byte pixel blocks with MMX pavgb.
; Expected: DS:[0x40..0x47] = eight bytes of 0x32

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
mov edi, 0x00000080
cld

call blend8
hlt

blend8:
movq mm0, [ebx]
movq mm1, es:[edi]
pavgb mm0, mm1
movq [ebx + 0x40], mm0
ret
