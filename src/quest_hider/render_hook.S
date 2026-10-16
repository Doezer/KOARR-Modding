.text
.globl _qh_render_hook
.def _qh_render_hook; .scl 2; .type 32; .endef
_qh_render_hook:
    pushfl
    pushal
    movl %esp, %eax
    subl $528, %esp
    andl $-16, %esp
    fxsave (%esp)
    movl %eax, 512(%esp)
    pushl %ebp
    pushl %edi
    call _qh_should_hide_marker
    addl $8, %esp
    testl %eax, %eax
    fxrstor (%esp)
    movl 512(%esp), %esp
    jnz .Lhidden
    popal
    popfl
    testb $1, 4(%ebp)
    jnz .Lskip
    jmp *_qh_render_continue
.Lhidden:
    popal
    popfl
.Lskip:
    jmp *_qh_render_skip
