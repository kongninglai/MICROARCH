; atomic_counter_lock
;
; Acquire a lock with cmpxchg, increment a protected counter, release it.
; Expected: DS:[0x00] = 0, DS:[0x04] = 42

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
cld

mov eax, 0x00000000
mov edx, 0x00000001
call acquire_lock
mov ecx, [ebx + 0x04]
add ecx, 0x01
mov [ebx + 0x04], ecx
mov dword [ebx], 0x00000000
hlt

acquire_lock:
cmpxchg [ebx + 0x00], edx
jne acquire_lock
ret
