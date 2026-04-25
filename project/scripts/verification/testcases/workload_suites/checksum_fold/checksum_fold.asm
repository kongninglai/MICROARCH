; checksum_fold
;
; Internet/storage-style additive checksum over 16 dwords.
; Expected: DS:[0x40] = low sum 0x30b90e21, DS:[0x44] = carry count 0x0000000a

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
mov ecx, 0x00000010
mov eax, 0x00000000
mov edx, 0x00000000
call checksum_dwords
mov [ebx + 0x40], eax
mov [ebx + 0x44], edx
hlt

checksum_dwords:
add eax, [esi]
adc edx, 0x00
add esi, 0x04
add ecx, -1
jne checksum_dwords
ret
