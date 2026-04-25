; long_atomic_counter
;
; Repeated lock acquire/update/release loop using CMPXCHG.
;
; Expected:
;   DS:[0x00] = 0x00000000  ; lock released
;   DS:[0x04] = 0x00000020  ; counter incremented 32 times
;   DS:[0x08] = 0x00000000  ; loop counter drained

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
cld

mov esi, 0x00000020
.outer:
mov eax, 0x00000000
mov edx, 0x00000001
call acquire_lock
mov ecx, [ebx + 0x04]
add ecx, 0x01
mov [ebx + 0x04], ecx
mov dword [ebx], 0x00000000
add esi, -1
jne .outer
mov [ebx + 0x08], esi
hlt

acquire_lock:
cmpxchg [ebx + 0x00], edx
jne acquire_lock
ret
