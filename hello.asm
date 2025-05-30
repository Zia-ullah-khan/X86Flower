BITS 32
        GLOBAL  WinMain
        EXTERN  GetModuleHandleA, RegisterClassExA, CreateWindowExA
        EXTERN  ShowWindow, UpdateWindow
        EXTERN  GetMessageA, TranslateMessage, DispatchMessageA
        EXTERN  DefWindowProcA, PostQuitMessage, ExitProcess
        EXTERN  BeginPaint, EndPaint, GetStockObject, SelectObject, DeleteObject
        EXTERN  CreatePen, CreateSolidBrush, Polygon, Ellipse
        EXTERN  SetTimer, KillTimer, InvalidateRect, SetWindowTextA

%define WNDCLASSEX_size 48
%define MSG_size        28
%define PAINTSTRUCT_size 64
NULL                equ 0
CS_HREDRAW          equ 0002h
CS_VREDRAW          equ 0001h
WS_OVERLAPPEDWINDOW equ 00CF0000h
CW_USEDEFAULT       equ 80000000h
SW_SHOWNORMAL       equ 1
COLOR_WINDOW        equ 5
WM_DESTROY          equ 0002h
WM_PAINT            equ 000Fh
WM_TIMER            equ 0113h
WM_KEYDOWN          equ 0100h
WM_COMMAND          equ 0111h
PS_SOLID            equ 0
FCX                 equ 200
FCY                 equ 150

TIMER_ID            equ 1
TIMER_INTERVAL      equ 50

SECTION .data
className   db "MyNasmClass",0
caption     db "X86 Animated Flower",0

animationEnabled    dd 1

buttonTextOn    db "Pause Animation",0
buttonTextOff   db "Resume Animation",0
BUTTON_CLASS    db "BUTTON",0
buttonHwnd      dd 0
BUTTON_ID       equ 1001

petal1Offsets:
    dd   0, -70
    dd -20, -50
    dd -15, -20
    dd   0,   0
    dd  15, -20
    dd  20, -50

petal2Offsets:
    dd  70,   0
    dd  50, -20
    dd  20, -15
    dd   0,   0
    dd  20,  15
    dd  50,  20

petal3Offsets:
    dd   0,  70
    dd  20,  50
    dd  15,  20
    dd   0,   0
    dd -15,  20
    dd -20,  50

petal4Offsets:
    dd -70,   0
    dd -50,  20
    dd -20,  15
    dd   0,   0
    dd -20, -15
    dd -50, -20

petalPointCount   equ 6

centerRect:
    dd FCX - 15, FCY - 15
    dd FCX + 15, FCY + 15

PINK_COLOR        equ 0x00FFC0CB
GREEN_COLOR       equ 0x00008000
YELLOW_COLOR      equ 0x0000FFFF
BLACK_COLOR       equ 0x00000000

animationScale      dd 100
animationDirection  dd 1
minScale            equ 80
maxScale            equ 120
scaleStep           equ 2

SECTION .bss
hInstance   resd 1
wc          resb WNDCLASSEX_size
msg         resb MSG_size
ps          resb PAINTSTRUCT_size
tempPetalPoints resd petalPointCount * 2
hMainWnd    resd 1

SECTION .text
WinMain:
    push    dword NULL
    call    [GetModuleHandleA]
    mov     [hInstance], eax

    mov     dword [wc+0],  WNDCLASSEX_size
    mov     dword [wc+4],  CS_HREDRAW | CS_VREDRAW
    mov     dword [wc+8],  WndProc
    xor     eax, eax
    mov     [wc+12], eax
    mov     [wc+16], eax
    mov     eax, [hInstance]
    mov     [wc+20], eax
    mov     dword [wc+24], NULL
    mov     dword [wc+28], NULL
    mov     dword [wc+32], COLOR_WINDOW+1
    mov     dword [wc+36], NULL
    mov     dword [wc+40], className
    mov     dword [wc+44], NULL

    push    wc
    call    [RegisterClassExA]
    push    dword NULL
    push    dword [hInstance]
    push    dword NULL
    push    dword NULL
    push    dword 300
    push    dword 400
    push    dword CW_USEDEFAULT
    push    dword CW_USEDEFAULT
    push    dword WS_OVERLAPPEDWINDOW
    push    dword caption
    push    dword className
    push    dword NULL
    call    [CreateWindowExA]
    mov     [hMainWnd], eax
    mov     ebx, eax

    push    dword 0
    push    dword 0
    push    dword [hInstance]
    push    dword buttonTextOn
    push    dword 0x50010000
    push    dword 40
    push    dword 140
    push    dword 20
    push    dword 20
    push    dword BUTTON_CLASS
    push    dword [hMainWnd]
    push    dword BUTTON_ID
    push    dword NULL
    call    [CreateWindowExA]
    mov     [buttonHwnd], eax

    push    dword SW_SHOWNORMAL
    push    ebx
    call    [ShowWindow]

    push    ebx
    call    [UpdateWindow]

    push    dword NULL
    push    dword TIMER_INTERVAL
    push    dword TIMER_ID
    push    dword [hMainWnd]
    call    [SetTimer]

msg_loop:
    push    dword 0
    push    dword 0
    push    dword NULL
    push    dword msg
    call    [GetMessageA]
    test    eax, eax
    jz      exit_loop

    push    msg
    call    [TranslateMessage]
    push    msg
    call    [DispatchMessageA]
    jmp     msg_loop

exit_loop:
    mov     eax, [msg+8]
    push    eax
    call    [ExitProcess]

WndProc:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    mov     eax, [ebp+12]
    cmp     eax, WM_DESTROY
    je      .wm_destroy

    cmp     eax, WM_PAINT
    je      .wm_paint

    cmp     eax, WM_TIMER
    je      .wm_timer

    cmp     eax, WM_KEYDOWN
    je      .wm_keydown

    cmp     eax, WM_COMMAND
    je      .wm_command

    jmp     .defproc

.wm_destroy:
    push    dword TIMER_ID
    push    dword [ebp+8]
    call    [KillTimer]

    push    dword 0
    call    [PostQuitMessage]
    xor     eax, eax
    jmp     .epilog

.wm_timer:
    cmp     dword [ebp+16], TIMER_ID
    jne     .defproc

    cmp     dword [animationEnabled], 0
    je      .skip_animation

    mov     eax, [animationScale]
    mov     ecx, [animationDirection]
    mov     edx, scaleStep
    imul    edx, ecx
    add     eax, edx

    cmp     eax, maxScale
    jge     .hit_max_scale
    cmp     eax, minScale
    jle     .hit_min_scale
    jmp     .scale_updated

.hit_max_scale:
    mov     eax, maxScale
    mov     dword [animationDirection], -1
    jmp     .scale_updated

.hit_min_scale:
    mov     eax, minScale
    mov     dword [animationDirection], 1

.scale_updated:
    mov     [animationScale], eax

    push    dword 1
    push    dword 0
    push    dword [ebp+8]
    call    [InvalidateRect]
    xor     eax, eax
    jmp     .epilog

.skip_animation:
    xor     eax, eax
    jmp     .epilog

.wm_paint:
    push    ps
    push    dword [ebp+8]
    call    [BeginPaint]
    mov     ebx, eax

    push    dword GREEN_COLOR
    push    dword 1
    push    dword PS_SOLID
    call    [CreatePen]
    mov     esi, eax

    push    dword PINK_COLOR
    call    [CreateSolidBrush]
    mov     edi, eax

    push    esi
    push    ebx
    call    [SelectObject]
    push    eax

    push    edi
    push    ebx
    call    [SelectObject]
    push    eax

    mov     edx, [animationScale]

    lea     ecx, [petal1Offsets]
    call    ScaleAndDrawPetal

    lea     ecx, [petal2Offsets]
    call    ScaleAndDrawPetal

    lea     ecx, [petal3Offsets]
    call    ScaleAndDrawPetal

    lea     ecx, [petal4Offsets]
    call    ScaleAndDrawPetal

    pop     eax
    push     eax
    push    ebx
    call    [SelectObject]

    pop     eax
    push    eax
    push    ebx
    call    [SelectObject]
    push    edi
    call    [DeleteObject]
    push    esi
    call    [DeleteObject]

    push    dword BLACK_COLOR
    push    dword 1
    push    dword PS_SOLID
    call    [CreatePen]
    mov     esi, eax

    push    dword YELLOW_COLOR
    call    [CreateSolidBrush]
    mov     edi, eax

    push    esi
    push    ebx
    call    [SelectObject]
    push    eax

    push    edi
    push    ebx
    call    [SelectObject]
    push    dword [centerRect+12]
    push    dword [centerRect+8]
    push    dword [centerRect+4]
    push    dword [centerRect]
    push    ebx
    call    [Ellipse]

    pop     eax
    push    eax
    push    ebx
    call    [SelectObject]

    pop     eax
    push    eax
    push    ebx
    call    [SelectObject]
    push    edi
    call    [DeleteObject]
    push    esi
    call    [DeleteObject]

    push    ps
    push    dword [ebp+8]
    call    [EndPaint]
    xor     eax, eax
    jmp     .epilog

.wm_keydown:
    mov     eax, [ebp+16]
    cmp     eax, 32
    jne     .defproc
    mov     eax, [animationEnabled]
    xor     eax, 1
    mov     [animationEnabled], eax
    xor     eax, eax
    jmp     .epilog

.wm_command:
    mov     eax, [ebp+16]
    and     eax, 0FFFFh
    cmp     eax, BUTTON_ID
    jne     .defproc
    mov     eax, [animationEnabled]
    xor     eax, 1
    mov     [animationEnabled], eax
    cmp     eax, 0
    jne     .set_pause
    push    dword buttonTextOff
    jmp     .set_text
.set_pause:
    push    dword buttonTextOn
.set_text:
    push    dword 0
    push    eax
    push    dword [buttonHwnd]
    call    [SetWindowTextA]
    xor     eax, eax
    jmp     .epilog

.defproc:
    push    dword [ebp+20]
    push    dword [ebp+16]
    push    dword [ebp+12]
    push    dword [ebp+8]
    call    [DefWindowProcA]

.epilog:
    pop     edi
    pop     esi
    pop     ebx
    leave
    ret     16

ScaleAndDrawPetal:
    pushad
    mov     esi, ecx
    lea     edi, [tempPetalPoints]
    mov     ecx, petalPointCount

.scale_loop:
    mov     eax, [esi]
    imul    eax, edx
    push    edx
    mov     ebp, 100
    cdq
    idiv    ebp
    pop     edx
    add     eax, FCX
    mov     [edi], eax

    mov     eax, [esi+4]
    imul    eax, edx
    push    edx
    mov     ebp, 100
    cdq
    idiv    ebp
    pop     edx
    add     eax, FCY
    mov     [edi+4], eax

    add     esi, 8
    add     edi, 8
    loop    .scale_loop

    push    dword petalPointCount
    push    dword tempPetalPoints
    push    ebx
    call    [Polygon]

    popad
    ret