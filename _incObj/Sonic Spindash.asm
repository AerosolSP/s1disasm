; ---------------------------------------------------------------------------
; Subroutine to check for starting to charge a spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; Sonic_Spindash:
Sonic_Spindash:
	tst.b	spindash_flag(a0)
	bne.s	Sonic_UpdateSpindash
	cmpi.b	#id_Duck,obAnim(a0)
	bne.s	return_1AC8C
	move.b	(v_jpadpress2).w,d0
	andi.b	#btnABC,d0
	beq.w	return_1AC8C
	move.b	#id_Spindash,obAnim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound_Special).l
	addq.l	#4,sp
	move.b	#1,spindash_flag(a0)
	move.w	#0,spindash_counter(a0)
	cmpi.b	#$C,v_air(a0)	; if he's drowning, branch to not make dust (v_air might be wrong)
	bcs.s loc_1AC84
	;move.b	#2,(Sonic_Dust+obAnim).w
  move.b #0,($FFFFD11C).w

loc_1AC84:
	bsr.w	Sonic_LevelBound
	bsr.w	Sonic_AnglePos

return_1AC8C:
	rts
; End of subroutine Sonic_Spindash


; ---------------------------------------------------------------------------
; Subrouting to update an already-charging spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AC8E:
Sonic_UpdateSpindash:
  move.b	#id_Spindash,obAnim(a0)
	move.b	(v_jpadhold2).w,d0
	btst	#1,d0
	bne.w	Sonic_ChargingSpindash

	; unleash the charged spindash and start rolling quickly:
	move.b	#$E,y_radius(a0)
	move.b	#7,x_radius(a0)
	move.b	#id_Roll,obAnim(a0)
	addq.w	#5,y_pos(a0)	; add the difference between Sonic's rolling and standing heights
	move.b	#0,spindash_flag(a0)
	moveq	#0,d0
	move.b	spindash_counter(a0),d0
	add.w	d0,d0
	move.w	Dash_Speeds(pc,d0.w),obInertia(a0)
;	tst.b	(Super_Sonic_flag).w
;	beq.s	+
;	move.w	Dash_SpeedsSuper(pc,d0.w),obInertia(a0)
;+
	move.w	obInertia(a0),d0
	subi.w	#$800,d0
	add.w	d0,d0
	andi.w	#$1F00,d0
	neg.w	d0
	addi.w	#$2000,d0
	move.w	d0,(Horiz_scroll_delay_val).w
	btst	#0,status(a0)
	beq.s loc_1ACF4
	neg.w	obInertia(a0)

loc_1ACF4:
	bset	#2,status(a0)
	;move.b	#0,(Sonic_Dust+obAnim).w
  move.b #0,($FFFFD11C).w
	move.w	#SndID_SpindashRelease,d0	; spindash zoom sound
	jsr	(PlaySound_Special).l
	bra.s	Obj01_Spindash_ResetScr
; ===========================================================================
; word_1AD0C:
Dash_Speeds:
	dc.w  $800	; 0
	dc.w  $880	; 1
	dc.w  $900	; 2
	dc.w  $980	; 3
	dc.w  $A00	; 4
	dc.w  $A80	; 5
	dc.w  $B00	; 6
	dc.w  $B80	; 7
	dc.w  $C00	; 8
; word_1AD1E:
Dash_SpeedsSuper:
	dc.w  $B00	; 0
	dc.w  $B80	; 1
	dc.w  $C00	; 2
	dc.w  $C80	; 3
	dc.w  $D00	; 4
	dc.w  $D80	; 5
	dc.w  $E00	; 6
	dc.w  $E80	; 7
	dc.w  $F00	; 8
; ===========================================================================
; loc_1AD30:
Sonic_ChargingSpindash:			; If still charging the dash...
	tst.w	spindash_counter(a0)
	beq.s loc_1AD48
	move.w	spindash_counter(a0),d0
	lsr.w	#5,d0
	sub.w	d0,spindash_counter(a0)
	bcc.s	loc_1AD48
	move.w	#0,spindash_counter(a0)

loc_1AD48:
	move.b	(v_jpadpress2).w,d0
	andi.b	#btnABC,d0
	beq.w	Obj01_Spindash_ResetScr
	move.w	#$1F00,obAnim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound_Special).l
	addi.w	#$200,spindash_counter(a0)
	cmpi.w	#$800,spindash_counter(a0)
	blo.s	Obj01_Spindash_ResetScr
	move.w	#$800,spindash_counter(a0)

; loc_1AD78:
Obj01_Spindash_ResetScr:
	addq.l	#4,sp
	cmpi.w	#(224/2)-16,(Camera_Y_pos_bias).w
	beq.s	loc_1AD8C
	bcc.s loc_1AD88
	addq.w	#4,(Camera_Y_pos_bias).w

loc_1AD88:
  subq.w	#2,(Camera_Y_pos_bias).w

loc_1AD8C:
	bsr.w	Sonic_LevelBound
	bsr.w	Sonic_AnglePos
  move.w #$60,(v_lookshift).w
	rts
; End of subroutine Sonic_UpdateSpindash
