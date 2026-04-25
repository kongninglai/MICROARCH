; vector_audio_mix
;
; Mix signed-ish 16-bit lanes with paddw, then saturate/pack to bytes.
; Expected: DS:[0x40..0x47] = word mix, DS:[0x48..0x4f] = packed bytes

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
cld

call audio_mix
hlt

audio_mix:
movq mm0, [ebx]
movq mm1, [ebx + 0x08]
paddw mm0, mm1
movq [ebx + 0x40], mm0
movq mm2, [ebx + 0x10]
packsswb mm2, mm0
movq [ebx + 0x48], mm2
ret
