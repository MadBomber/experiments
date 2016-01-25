	.section	__TEXT,__text,regular,pure_instructions
	.align	4, 0x90
__ZN4main20h9857f58f3d415793taaE:
	.cfi_startproc
	cmpq	%gs:816, %rsp
	ja	LBB0_2
	movabsq	$8, %r10
	movabsq	$0, %r11
	callq	___morestack
	retq
LBB0_2:
	pushq	%rbp
Ltmp0:
	.cfi_def_cfa_offset 16
Ltmp1:
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
Ltmp2:
	.cfi_def_cfa_register %rbp
	popq	%rbp
	retq
	.cfi_endproc

	.globl	_main
	.align	4, 0x90
_main:
	.cfi_startproc
	movq	%rsi, %rax
	movq	%rdi, %rcx
	leaq	__ZN4main20h9857f58f3d415793taaE(%rip), %rdi
	movq	%rcx, %rsi
	movq	%rax, %rdx
	jmp	__ZN2rt10lang_start20hcc2503dafa718fc022wE
	.cfi_endproc


.subsections_via_symbols
