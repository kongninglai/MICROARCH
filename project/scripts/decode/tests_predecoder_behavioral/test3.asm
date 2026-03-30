add dword ptr [eax], 1
; mod=00 r/m=000 → ModRM only, no SIB, no disp

add dword ptr [eax+4], 1
; mod=01 r/m=000 → ModRM + disp8

add dword ptr [esp], 1
; mod=00 r/m=100 → ModRM + SIB (ESP forces SIB)

add dword ptr [esp+8], 1
; mod=01 r/m=100 → ModRM + SIB + disp8

add dword ptr [ebp+0], 1
; mod=01 r/m=101 → disp8 = 0 REQUIRED
; [ebp] ≠ mod=00 form

add dword ptr [0x12345678], 1
; mod=00 r/m=101 → disp32 ONLY (no base register)

add dword ptr [ebp+8], 1
; mod=01 r/m=101 → disp8

add dword ptr [ebp+0x1234], 1
; mod=10 r/m=101 → disp32

add dword ptr [esp+0], 1
; mod=01 r/m=100 → SIB + disp8=0

add dword ptr [esp+0x12345678], 1
; mod=10 r/m=100 → SIB + disp32

add dword ptr [eax*4 + 0x20], 1
; mod=00 r/m=100
; SIB base=101 → no base
; disp32 required

