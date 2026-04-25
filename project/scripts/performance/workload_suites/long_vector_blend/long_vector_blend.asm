; long_vector_blend
;
; 16-iteration MMX blend loop over 128 bytes.
;
; Expected:
;   DS:[0x100..0x17f] = 128 bytes of 0x80

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
mov edi, 0x00000100
mov edx, 0x00000100
mov ecx, 0x00000010
call blend_loop
hlt

blend_loop:
movq mm0, [esi]
movq mm1, es:[edi]
pavgb mm0, mm1
movq [edx], mm0
add esi, 0x08
add edi, 0x08
add edx, 0x08
add ecx, -1
jne blend_loop
ret
