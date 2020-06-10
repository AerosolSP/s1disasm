; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4F - Cannon
; ---------------------------------------------------------------------------

Obj4F:
		moveq	#$00,d0					; clear d0
		move.b	$24(a0),d0				; load routine counter
		move.w	Obj4F_Index(pc,d0.w),d0			; load correct relative address
		jmp	Obj4F_Index(pc,d0.w)			; jump to address

Obj4F_Index:	dc.w	Obj4F_Setup-Obj4F_Index			; 00 - Setup routine
		dc.w	Obj4F_Idle-Obj4F_Index			; 02 - Idle and waiting for Sonic
		dc.w	Obj4F_Touched-Obj4F_Index		; 04 - Sonic has touched the cannon
		dc.w	Obj4F_Align-Obj4F_Index			; 06 - Aligning Sonic towards centre of object
		dc.w	Obj4F_Charge-Obj4F_Index		; 08 - Charging cannon
		dc.w	Obj4F_Delay-Obj4F_Index			; 0A - Delaying to let Sonic shoot away before setting touch/collision again

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4F - 00 - Setup routine
; ---------------------------------------------------------------------------

Obj4F_Setup:
		ori.l	#$00140000|($F4C0/$20),(a0)		; set display mode and pattern index address
		move.l	#Map_Obj4F,$04(a0)			; set mappings list address
		move.b	#$20,$16(a0)				; set draw height (only if bit 4 is set in object byte $01)
		move.w	#$0120,$18(a0)				; set priority and draw width
		move.w	$08(a0),$3C(a0)				; store X and Y spawn positions
		move.w	$0C(a0),$3E(a0)				; ''

Obj4F_Reset:
		move.b	#$02,$24(a0)				; advance to next routine (for next frame)
		move.b	#$40|$0F,$20(a0)			; set touch/collision response

; ---------------------------------------------------------------------------
; Object 4F - 02 - Idle
; ---------------------------------------------------------------------------

Obj4F_Idle:
		moveq	#$FFFFFF80,d2				; prepare subtraction/and value
		move.w	$3C(a0),d0				; load object's original X spawn position
		and.w	d2,d0					; wrap to nearest object load block
		move.w	($FFFFF700).w,d1			; load screen's X position
		add.w	d2,d1					; move left a load block (include block to left of screen)
		and.w	d2,d1					; wrap to nearest object load block
		sub.w	d1,d0					; subtract from object's X spawn position
		cmpi.w	#$0300-$80,d0				; is the object still within the load area? (-$80 to +$2FF relative to screen)
		bhi.w	DeleteObject				; if not, branch to delete the object (it's gone out of range)
		bra.w	DisplaySprite				; save object to priority list for display

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4F - 04 - Sonic touched the cannon
; ---------------------------------------------------------------------------

Obj4F_Touched:
		sf.b	$20(a0)					; clear touch/collision response
		move.b	#$81,($FFFFF7C8).w			; force lock Sonic (no physics, control, gravity etc)
		lea	($FFFFD000).w,a1			; load Sonic's object RAM slot
		move.b	#$02,$1C(a1)				; set Sonic's animation to rolling
		moveq	#$00,d0					; clear d0
		move.l	d0,$10(a1)				; clear Sonic's X and Y speed
		move.w	d0,$14(a1)				; clear Sonic's ground speed
		move.b	$22(a0),d0				; load object's status
		andi.b	#%00000001,d0				; get only the mirror (left/right facing) status
		ori.b	#%00000110,d0				; set Sonic's "in-air" and "roll" status bits
		move.b	d0,$22(a1)				; set Sonic's direction/status correctly
		sf.b	$3C(a1)					; clear "height cap" flag (prevent release jump buttons effect)
		move.b	#$02,$24(a1)				; ensure Sonic is in normal control mode
		addq.b	#$02,$24(a0)				; advance to next routine (for next frame)

; ---------------------------------------------------------------------------
; Object 4F - 06 - aligning Sonic towards centre of cannon
; ---------------------------------------------------------------------------

Obj4F_Align:
		lea	($FFFFD000).w,a1			; load Sonic's object RAM slot
		move.w	$08(a1),d1				; load Sonic's X and Y positions
		move.w	$0C(a1),d2				; ''
		sub.w	$08(a0),d1				; subtract cannon's X and Y to get the distance
		sub.w	$0C(a0),d2				; ''
		move.w	d1,d0					; check if Sonic is at object on X and Y already
		or.w	d2,d0					; ''
		beq.s	Obj4F_AlignFinish			; if so, branch
		jsr	CalcAngle				; get the angle Sonic is from the cannon (00 - FF inside d0)
		jsr	CalcSine				; get the sine/cosine (X and Y) using the angle in d0
		ext.l	d1					; sign extend to long-word
		ext.l	d0					; ''
		asl.l	#$08,d1					; multiply X and Y to x10000
		asl.l	#$08,d0					; ''
		sub.l	d1,$08(a1)				; move Sonic towards the object on X
		sub.l	d0,$0C(a1)				; move Sonic towards the object on Y
		bra.w	Obj4F_Idle				; continue for deletion check and display

Obj4F_AlignFinish:
		addq.b	#$02,$24(a0)				; advance to next routine (for next frame)
		move.b	#$10,$3B(a0)				; set charge timer
		moveq	#$FFFFFFBB,d0				; play charge/lock SFX
		jsr	PlaySound_Special			; ''

; ---------------------------------------------------------------------------
; Object 4F - 08 - charging and firing the cannon
; ---------------------------------------------------------------------------

Obj4F_Charge:
		addq.w	#$01,$0C(a0)				; move cannon down
		subq.w	#$01,$08(a0)				; move cannon left
		btst.b	#$00,$22(a0)				; is object facing right?
		beq.s	Obj4F_ChargeRight			; if so, branch
		addq.w	#$01+1,$08(a0)				; move cannon right instead

Obj4F_ChargeRight:
		subq.b	#$01,$3B(a0)				; minus 1 from charge timer
		bcc.w	Obj4F_Idle				; if not finished, branch
		move.w	$3C(a0),$08(a0)				; restore cannon's X position
		move.w	$3E(a0),$0C(a0)				; restore cannon's Y position
		move.l	#$0C00F400,($FFFFD010).w		; set Sonic's X and Y speeds (up and right)
		btst.b	#$00,$22(a0)				; is the cannon facing right?
		beq.s	Obj4F_ReleaseRight			; if so, branch
		neg.w	($FFFFD010).w				; reverse Sonic's X speed

Obj4F_ReleaseRight:
		sf.b	($FFFFF7C8).w				; release Sonic
		move.b	#$60,$3B(a0)				; set delay time before allowing cannon to activate again
		addq.b	#$02,$24(a0)				; increase routine counter
		moveq	#$FFFFFFBC,d0				; play release SFX
		jsr	PlaySound_Special			; ''

; ---------------------------------------------------------------------------
; Object 4F - 0A - delaying to give Sonic time to shoot away from object
; ---------------------------------------------------------------------------

Obj4F_Delay:
		subq.b	#$01,$3B(a0)				; minus 1 from delay timer
		bcc.w	Obj4F_Idle				; if not finished, branch
		bra.w	Obj4F_Reset				; branch to reset routine counter and collision/touch

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4F - Mappings
; ---------------------------------------------------------------------------

Map_Obj4F:	dc.w	Map4F_Frame00-Map_Obj4F

Map4F_Frame00:	dc.b	$08					; Number of sprite peices
		dc.b	$E0,$01,$00,$00,$E0			; Top left blue sphere (left side)
		dc.b	$E0,$01,$08,$00,$E8			; '' (right side)
		dc.b	$E0,$01,$00,$00,$10			; Top right red sphere (left side)
		dc.b	$E0,$01,$08,$00,$18			; '' (right side)
		dc.b	$10,$01,$00,$00,$E0			; Bottom left red sphere (left side)
		dc.b	$10,$01,$08,$00,$E8			; '' (right side)
		dc.b	$10,$01,$00,$00,$10			; Bottom right blue sphere (left side)
		dc.b	$10,$01,$08,$00,$18			; '' (right side)
		even

; ===========================================================================
