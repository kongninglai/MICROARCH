; memcmp_scan
;
; Dominant behavior modeled:
;   string/table comparison where most data matches and the scan exits at the
;   first differing dword.
;
; Memory layout:
;   DS 0x0200: left buffer at offset 0x000, result record at offset 0x040
;   ES 0x0400: right buffer at offset 0x080
;   SS 0x0b00: stack starts at offset 0x100
;
; Expected final result:
;   DS:[0x040] = 0x00000001  ; mismatch found
;   DS:[0x044] = 0x0000002c  ; ESI advanced past mismatching dword
;   DS:[0x048] = 0x000000ac  ; EDI advanced past mismatching dword
;   DS:[0x04c] = 0x00000005  ; five dwords remained untested

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
mov edi, 0x00000080
mov ecx, 0x00000010
call memcmp_dwords

mov [ebx + 0x40], eax
mov [ebx + 0x44], esi
mov [ebx + 0x48], edi
mov [ebx + 0x4c], ecx
hlt

memcmp_dwords:
repe cmpsd
mov eax, 0x00000000
jne .mismatch
ret
.mismatch:
mov eax, 0x00000001
ret
