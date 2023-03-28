	incdir inc:
	include exec/execbase.i
	include exec/memory.i
	include exec/exec_lib.i
	include exec/io.i
	include devices/keyboard.i

start	movem.l	a5-a6,-(sp)

	move.l	4.w,a6
	jsr	-120(a6)	; Disable()
	lea	super(pc),a5
	jsr	-30(a6)		; Supervisor()
	jsr	-126(a6)

	move.w	AttnFlags(a6),d0
	btst	#2,d0		; 68030
	beq	.skip

	bsr	read_matrix
	lea 	matrix,a0
	btst	#4,$c(a0)	; left alt
	beq	.normal

	move.w	#0,d0	
.loop2	move.w	#100,d1
.loop1	move.w	d0,$dff180
	nop
	dbra	d1,.loop1

	add.w	#1,d0
	cmp.w	#4095,d0
	bne	.loop2

	jsr	_LVODisable(a6)
	lea	disable_tsunami(pc),a5
	jsr	_LVOSupervisor(a6)
	jsr	_LVOEnable(a6)

.normal	move.l	local_mem(pc),a0
	cmp.l	#$8000000,a0
	beq	.skip

	move.l	exec_ver(pc),d0	; high word version, low word minor
	swap	d0
	cmp.w	#40,d0	; 40 = kick 3.1
	bcc	.skip

	jsr	_LVODisable(a6)
	lea	addmem(pc),a5
	jsr	_LVOSupervisor(a6)
	jsr	_LVOEnable(a6)

.skip	move.l	entry_count(pc),d0
	movem.l	(sp)+,a5-a6
	rts
	
addmem	movem.l	d0-d2/a0-a6,-(sp)

	move.l	4.w,a6
	jsr	_LVOForbid(a6)

	lea 	$8000000,a0
	move.l	#$4000000,d0
	move.l	#MEMF_PUBLIC+MEMF_FAST,d1
	move.l	#40,d2
	sub.l	a1,a1
	jsr	_LVOAddMemList(a6)

	jsr	_LVOPermit(a6)

	movem.l	(sp)+,d0-d2/a0-a6
	rte

super		movem.l	d0-d2/a0-a5,-(sp)

		move.l	4.w,a6
		clr.l	d0
		move.w	LIB_VERSION(a6),d0	; major
		swap 	d0
		move.w	SoftVer(a6),d0		; minor
		move.l	d0,exec_ver

		lea	MemList(a6),a0
		lea	entries(pc),a3
		moveq	#0,d0
		move.l	LH_HEAD(a0),a1
		lea	LH_TAIL(a0),a2

.loop		cmp.l	a1,a2
		beq	.end

		move.l	d0,d1
		lsl.l	#2,d1
		move.l	a1,0(a3,d1)	; save mem entry ptr
		addq.l	#1,d0

		cmp.l	#$8000000,a1
		bne	.continue
		move.l	a1,local_mem

.continue	cmp.w	#16,d0
		bcc	.end

		move.l	LN_SUCC(a1),a1
		bra	.loop

.end		move.l	d0,entry_count			
		
		movem.l	(sp)+,d0-d2/a0-a5
		rte	

exec_ver		dc.l	0
entries			ds.l	16
entry_count		dc.l	0
local_mem		dc.l	0


disable_tsunami		lea 	$bfe001,a3

			move.l	#$11114ef9,0.w
			nop
			move.l	#$f800d2,4.w
			nop

			movec	dfc,d0
			move.l	#6,d1
			movec	d1,dfc

			move.w	#$cafe,d1
			move.l	#$80f00000,a0

			move.b	#3,$200(a3)	; set led/ovl output
			move.b	#-1,$000(a3)	; set led/ovl 
			moves.w	d1,(a0)		; magic
			reset			


read_matrix		movem.l	a5-a6,-(sp)

			lea	keyb_io(pc),a0
			lea	keyb_msgport(pc),a1
			jsr	create_io

			move.l	4.w,a6
			lea	keyb_device(pc),a0	; name
			clr.l	d0			; unit
			lea	keyb_io(pc),a1		; ioreq
			clr.l	d1			; flags
			jsr	_LVOOpenDevice(a6)
			tst.l	d0
			bne	.nodev
			
			lea	keyb_io,a1
			move.w	#KBD_READMATRIX,IO_COMMAND(a1)
			lea	matrix,a0
			move.l	a0,IO_DATA(a1)
			move.l	#16,IO_LENGTH(a1)
			jsr 	_LVODoIO(a6)

.fail			lea	keyb_io,a1		; ioreq
			jsr	_LVOCloseDevice(a6)

.nodev			lea	keyb_io(pc),a0
			jsr	delete_io

			movem.l	(sp)+,a5-a6
			rts

keyb_msgport	ds.b	MP_SIZE
keyb_io		ds.b	IOSTD_SIZE
keyb_device	dc.b	"keyboard.device",0
matrix		ds.b	16




create_io	; a0 = io_std, a1 = msg_port
		movem.l	a4-a6,-(sp)
		move.l	a0,a4
		move.l	a1,a5

		move.l	4.w,a6
		moveq	#-1,d0
		jsr	_LVOAllocSignal(a6)

		move.b	#1,MP_FLAGS(a5)	; signal task
		move.b	d0,MP_SIGBIT(a5)

		clr.l	d0
		jsr 	_LVOFindTask(a6)
		move.l	d0,MP_SIGTASK(a5)

		lea	MP_MSGLIST(a5),a0
		jsr	init_list

		; init ioreq
		move.l	a5,MN_REPLYPORT(a4)
		move.l	#IOSTD_SIZE,MN_LENGTH(a4)
		clr.l	IO_DEVICE(a4)
		clr.l	IO_UNIT(a4)
		clr.b	IO_FLAGS(a4)
		
		movem.l	(sp)+,a4-a6
		rts


delete_io	; a0 = io_std
		movem.l	a6,-(sp)
		
		move.l	4.w,a6
		move.l	MN_REPLYPORT(a0),a1
		clr.l	d0
		move.b	MP_SIGBIT(a1),d0
		jsr 	_LVOFreeSignal(a6)
		
		movem.l	(sp)+,a6
		rts

init_list	; a0 = list
		lea	LH_TAIL(a0),a1
		move.l	a1,LH_HEAD(a0)
		clr.l	LH_TAIL(a0)
		move.l	a0,LH_TAILPRED(a0)
		rts


