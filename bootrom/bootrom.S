#define BOOT_START 0xc0000000
#define CORE_1_SPIN 0x80000000

	.text
	.globl _start
_start:
	csrr a0, mhartid
	beq a0, zero, _skip
	li a0, CORE_1_SPIN
	la a1, _core_1_loop
	sd a1, 0(a0)
_core_1_loop:
	ld a1, 0(a0)
	jr a1
	#beq zero, zero, _start
_skip:
	la a1, _dtb
	li t0, BOOT_START
	jr t0

        .align 3, 0
c1tgt:  .dword _start

	.data
	.globl _dtb
	.align 5, 0
_dtb:
	.incbin "devicetree.dtb"
