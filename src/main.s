; VESYL Shipper — NROM-128, CHR-RAM, side-scroller
; Build: make  →  build/vesyl_shipper.nes

	.setcpu "6502"
	.feature c_comments
	.feature underline_in_numbers

; -------------------------
; PPU registers
; -------------------------
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014

; Game states
STATE_TITLE = 0
STATE_PLAY  = 1
STATE_WIN   = 2

; Controller bits after read_controller (ROL serial read):
; bit7=A bit6=B bit5=Select bit4=Start bit3=Up bit2=Down bit1=Left bit0=Right
BTN_A      = $80
BTN_B      = $40
BTN_SELECT = $20
BTN_START  = $10
BTN_UP     = $08
BTN_DOWN   = $04
BTN_LEFT   = $02
BTN_RIGHT  = $01

; Tile indices (order in tiles: blob)
T_SKY         = $00
T_PLAYER0     = $01
T_PLAYER1     = $02
T_PLAYER2     = $03
T_PLAYER3     = $04
T_PLAYER4     = $05
T_PLAYER5     = $06
T_GROUND_TOP  = $07
T_GROUND_FILL = $08
T_BRICK       = $09
T_PLATFORM    = $0A
T_BOX         = $0B
T_BOX_TL      = $0C
T_BOX_TR      = $0D
T_BOX_BL      = $0E
T_BOX_BR      = $0F
T_TRUCK0      = $10
T_TRUCK1      = $11
T_TRUCK2      = $12
T_TRUCK3      = $13
T_TRUCK4      = $14
T_TRUCK5      = $15
T_FONT        = $16
; font: 0=space, 1=A … 26=Z, 27=!

PLAYER_IDLE_0 = T_PLAYER0
PLAYER_IDLE_1 = T_PLAYER1
PLAYER_IDLE_2 = T_PLAYER2
PLAYER_IDLE_3 = T_PLAYER3
PLAYER_WALK_2 = T_PLAYER4
PLAYER_WALK_3 = T_PLAYER5

PLAYER_W     = 16
PLAYER_H     = 16
GRAVITY      = 1
; Full hold peak ≈ 9+8+…+1 = 45 px (~3× old 15 px from JUMP_V=-5)
JUMP_V       = $F7          ; -9 signed (max jump impulse)
MAX_FALL     = 6
MOVE_SPEED   = 2
CAMERA_OFF   = 96
LEVEL_W_PX_L = $00          ; level width 512 = $0200
LEVEL_W_PX_H = $02
MAX_SCROLL_L = $00          ; 512-256 = 256
MAX_SCROLL_H = $01
GROUND_TOP_Y = 168          ; pixel Y of ground surface (row 21)
; nametable rows: ground top at row 21 (21*8=168)

PKG_WORLD_X_L = 48          ; package world X
PKG_WORLD_X_H = 0
PKG_WORLD_Y   = 152         ; on ground (16px tall box sprite uses 8px tile)

TRUCK_ZONE_L  = $80         ; world X low  for drop-off start (~400)
TRUCK_ZONE_H  = $01
TRUCK_ZONE_R_L = $E0        ; end ~480
TRUCK_ZONE_R_H = $01

; -------------------------
; Zero page
; -------------------------
	.segment "ZEROPAGE"
temp:              .res 1
temp2:             .res 1
temp3:             .res 1
temp_hi:           .res 1
ptr_lo:            .res 1
ptr_hi:            .res 1
frame_flag:        .res 1
game_state:        .res 1
pad1:              .res 1
pad1_prev:         .res 1
pad1_edge:         .res 1
scroll_lo:         .res 1
scroll_hi:         .res 1
ppuctrl_nt:        .res 1   ; PPUCTRL with nametable bits
player_x_lo:       .res 1
player_x_hi:       .res 1
player_y:          .res 1
screen_x:          .res 1
vel_y:             .res 1   ; signed
on_ground:         .res 1
anim_frame:        .res 1
facing:            .res 1   ; 0=right, 1=left (flip)
has_package:       .res 1
old_x_lo:          .res 1
old_x_hi:          .res 1
old_y:             .res 1
check_x_lo:        .res 1
check_x_hi:        .res 1
check_y:           .res 1
metasprite_ptr_lo: .res 1
metasprite_ptr_hi: .res 1
oam_idx:           .res 1
str_nt_hi:         .res 1
str_nt_lo:         .res 1

; -------------------------
; BSS — OAM must be at $0200
; -------------------------
	.segment "BSS"
oam_shadow: .res 256

; -------------------------
; RODATA
; -------------------------
	.segment "RODATA"

tiles:
; $00 sky (empty)
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; $01-$06 player (original gladiator art)
player_s_0_idle:
	.byte $07,$08,$10,$20,$20,$17,$0F,$0F,$00,$07,$0F,$1F,$1F,$09,$05,$05
player_s_1_idle:
	.byte $E0,$10,$08,$08,$88,$E8,$F0,$F0,$00,$E0,$F0,$F0,$F0,$10,$A0,$A0
player_s_2_idle:
	.byte $1F,$3F,$4F,$4F,$3F,$0F,$17,$21,$0B,$1C,$3B,$33,$04,$06,$0E,$1E
player_s_3_idle:
	.byte $F8,$FC,$F2,$F2,$FC,$F0,$D0,$08,$D0,$38,$DC,$CC,$20,$60,$E0,$F0
player_s_2_walk:
	.byte $1F,$3F,$4F,$4F,$3F,$17,$21,$1F,$0B,$1C,$3B,$33,$04,$0E,$1E,$00
player_s_3_walk:
	.byte $F8,$FC,$F2,$F2,$FC,$D0,$08,$F0,$D0,$38,$DC,$CC,$20,$60,$F0,$00

; NES CHR: 8 bytes plane0 (rows 0-7) then 8 bytes plane1.
; Same bits in both planes → palette index 3 (bright).

; $07 ground top
	.byte $FF,$FF,$AA,$55,$AA,$55,$FF,$FF,$00,$FF,$55,$AA,$55,$AA,$FF,$FF
; $08 ground fill
	.byte $AA,$55,$AA,$55,$AA,$55,$AA,$55,$55,$AA,$55,$AA,$55,$AA,$55,$AA
; $09 brick
	.byte $FF,$81,$BD,$BD,$FF,$DB,$DB,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; $0A platform — full 8×8 solid ledge (white top, blue body; always visible on black sky)
	.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
; $0B box (sprite)
	.byte $FF,$81,$A5,$81,$BD,$99,$81,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; $0C-$0F title box 2×2 (cardboard package)
	.byte $0F,$10,$20,$20,$27,$20,$10,$0F,$0F,$1F,$3F,$3F,$3F,$3F,$1F,$0F
	.byte $F0,$08,$04,$04,$E4,$04,$08,$F0,$F0,$F8,$FC,$FC,$FC,$FC,$F8,$F0
	.byte $0F,$10,$27,$22,$21,$20,$10,$0F,$0F,$1F,$3F,$3F,$3F,$3F,$1F,$0F
	.byte $F0,$08,$E4,$44,$84,$04,$08,$F0,$F0,$F8,$FC,$FC,$FC,$FC,$F8,$F0
; $10-$15 truck
	.byte $00,$1F,$3F,$3F,$3F,$3F,$3F,$3F,$00,$1F,$3F,$3F,$3F,$3F,$3F,$3F
	.byte $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	.byte $00,$F8,$FC,$FE,$FE,$1E,$1E,$1E,$00,$F8,$FC,$FE,$FE,$1E,$1E,$1E
	.byte $3F,$3F,$18,$3C,$3C,$18,$00,$00,$3F,$3F,$18,$3C,$3C,$18,$00,$00
	.byte $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
	.byte $1E,$1E,$18,$3C,$3C,$18,$00,$00,$1E,$1E,$18,$3C,$3C,$18,$00,$00
; $16+ font: space, A-Z, !
font_space:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $38,$44,$44,$7C,$44,$44,$44,$00,$38,$44,$44,$7C,$44,$44,$44,$00 ; A
	.byte $78,$44,$44,$78,$44,$44,$78,$00,$78,$44,$44,$78,$44,$44,$78,$00 ; B
	.byte $3C,$42,$40,$40,$40,$42,$3C,$00,$3C,$42,$40,$40,$40,$42,$3C,$00 ; C
	.byte $78,$44,$42,$42,$42,$44,$78,$00,$78,$44,$42,$42,$42,$44,$78,$00 ; D
	.byte $7E,$40,$40,$7C,$40,$40,$7E,$00,$7E,$40,$40,$7C,$40,$40,$7E,$00 ; E
	.byte $7E,$40,$40,$7C,$40,$40,$40,$00,$7E,$40,$40,$7C,$40,$40,$40,$00 ; F
	.byte $3C,$42,$40,$4E,$42,$42,$3C,$00,$3C,$42,$40,$4E,$42,$42,$3C,$00 ; G
	.byte $42,$42,$42,$7E,$42,$42,$42,$00,$42,$42,$42,$7E,$42,$42,$42,$00 ; H
	.byte $3C,$08,$08,$08,$08,$08,$3C,$00,$3C,$08,$08,$08,$08,$08,$3C,$00 ; I
	.byte $1E,$04,$04,$04,$04,$44,$38,$00,$1E,$04,$04,$04,$04,$44,$38,$00 ; J
	.byte $42,$44,$48,$50,$48,$44,$42,$00,$42,$44,$48,$50,$48,$44,$42,$00 ; K
	.byte $40,$40,$40,$40,$40,$40,$7E,$00,$40,$40,$40,$40,$40,$40,$7E,$00 ; L
	.byte $42,$66,$5A,$42,$42,$42,$42,$00,$42,$66,$5A,$42,$42,$42,$42,$00 ; M
	.byte $42,$62,$52,$4A,$46,$42,$42,$00,$42,$62,$52,$4A,$46,$42,$42,$00 ; N
	.byte $3C,$42,$42,$42,$42,$42,$3C,$00,$3C,$42,$42,$42,$42,$42,$3C,$00 ; O
	.byte $7C,$42,$42,$7C,$40,$40,$40,$00,$7C,$42,$42,$7C,$40,$40,$40,$00 ; P
	.byte $3C,$42,$42,$42,$4A,$44,$3A,$00,$3C,$42,$42,$42,$4A,$44,$3A,$00 ; Q
	.byte $7C,$42,$42,$7C,$48,$44,$42,$00,$7C,$42,$42,$7C,$48,$44,$42,$00 ; R
	.byte $3C,$42,$40,$3C,$02,$42,$3C,$00,$3C,$42,$40,$3C,$02,$42,$3C,$00 ; S
	.byte $7E,$08,$08,$08,$08,$08,$08,$00,$7E,$08,$08,$08,$08,$08,$08,$00 ; T
	.byte $42,$42,$42,$42,$42,$42,$3C,$00,$42,$42,$42,$42,$42,$42,$3C,$00 ; U
	.byte $42,$42,$42,$42,$42,$24,$18,$00,$42,$42,$42,$42,$42,$24,$18,$00 ; V
	.byte $42,$42,$42,$42,$5A,$66,$42,$00,$42,$42,$42,$42,$5A,$66,$42,$00 ; W
	.byte $42,$42,$24,$18,$24,$42,$42,$00,$42,$42,$24,$18,$24,$42,$42,$00 ; X
	.byte $42,$42,$24,$18,$08,$08,$08,$00,$42,$42,$24,$18,$08,$08,$08,$00 ; Y
	.byte $7E,$02,$04,$08,$10,$20,$7E,$00,$7E,$02,$04,$08,$10,$20,$7E,$00 ; Z
	.byte $08,$08,$08,$08,$08,$00,$08,$00,$08,$08,$08,$08,$08,$00,$08,$00 ; !
tiles_end:

; Metasprites: Y, X, tile, attr … $80
player_idle_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000000
	.byte 0, 8, PLAYER_IDLE_1, %00000000
	.byte 8, 0, PLAYER_IDLE_2, %00000000
	.byte 8, 8, PLAYER_IDLE_3, %00000000
	.byte $80

player_walk1_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000000
	.byte 0, 8, PLAYER_IDLE_1, %00000000
	.byte 8, 0, PLAYER_IDLE_2, %00000000
	.byte 8, 8, PLAYER_WALK_3, %00000000
	.byte $80

player_walk2_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000000
	.byte 0, 8, PLAYER_IDLE_1, %00000000
	.byte 8, 0, PLAYER_WALK_2, %00000000
	.byte 8, 8, PLAYER_IDLE_3, %00000000
	.byte $80

player_idle_flip:
	.byte 0, 8, PLAYER_IDLE_0, %01000000
	.byte 0, 0, PLAYER_IDLE_1, %01000000
	.byte 8, 8, PLAYER_IDLE_2, %01000000
	.byte 8, 0, PLAYER_IDLE_3, %01000000
	.byte $80

player_walk1_flip:
	.byte 0, 8, PLAYER_IDLE_0, %01000000
	.byte 0, 0, PLAYER_IDLE_1, %01000000
	.byte 8, 8, PLAYER_IDLE_2, %01000000
	.byte 8, 0, PLAYER_WALK_3, %01000000
	.byte $80

player_walk2_flip:
	.byte 0, 8, PLAYER_IDLE_0, %01000000
	.byte 0, 0, PLAYER_IDLE_1, %01000000
	.byte 8, 8, PLAYER_WALK_2, %01000000
	.byte 8, 0, PLAYER_IDLE_3, %01000000
	.byte $80

; Palettes
bg_palette:
	.byte $0F, $21, $11, $30   ; sky blue / white text
	.byte $0F, $17, $27, $07   ; cardboard brown
	.byte $0F, $00, $10, $20   ; asphalt gray
	.byte $0F, $02, $12, $22   ; truck blue

spr_palette:
	.byte $0F, $27, $17, $30   ; player
	.byte $0F, $17, $27, $07   ; package brown
	.byte $0F, $00, $10, $20
	.byte $0F, $02, $12, $22

; Strings: tile indices relative to T_FONT (0=space, 1=A…), $FF end
; Helper: letter L means tile (L-'A'+1)
str_title:
	; V E S Y L   S H I P P E R
	.byte 22,5,19,25,12, 0, 19,8,9,16,16,5,18, $FF
str_press:
	; P R E S S   S T A R T
	.byte 16,18,5,19,19, 0, 19,20,1,18,20, $FF
str_win:
	; D E L I V E R E D !
	.byte 4,5,12,9,22,5,18,5,4, 27, $FF

; -------------------------
; CODE
; -------------------------
	.segment "CODE"

reset:
	sei
	cld
	ldx #$FF
	txs
	lda #$00
	sta PPUCTRL
	sta PPUMASK

	jsr wait_vblank
	jsr wait_vblank

	; Clear RAM $0000-$07FF
	lda #$00
	tax
@clr:
	sta $0000, x
	sta $0100, x
	sta $0200, x
	sta $0300, x
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $0700, x
	inx
	bne @clr

	jsr load_palettes
	jsr load_chr

	lda #%10000000
	sta ppuctrl_nt
	sta PPUCTRL
	lda #%00011110
	sta PPUMASK

	jsr enter_title

main_loop:
	lda frame_flag
	beq main_loop
	lda #$00
	sta frame_flag

	jsr read_controller

	lda game_state
	cmp #STATE_TITLE
	beq @title
	cmp #STATE_PLAY
	beq @play
	cmp #STATE_WIN
	beq @win
	jmp main_loop

@title:
	jsr update_title
	jmp main_loop
@play:
	jsr update_play
	jmp main_loop
@win:
	jsr update_win
	jmp main_loop

; -------------------------
; State: Title
; -------------------------
enter_title:
	lda #STATE_TITLE
	sta game_state
	lda #$00
	sta scroll_lo
	sta scroll_hi
	sta has_package
	lda #%10000000
	sta ppuctrl_nt

	jsr wait_nmi_safe
	lda #$00
	sta PPUMASK

	jsr clear_nametables
	jsr draw_title_screen

	jsr hide_all_sprites

	jsr wait_vblank
	lda #%10000000
	sta ppuctrl_nt
	sta PPUCTRL
	lda #$00
	sta PPUSCROLL
	sta PPUSCROLL
	lda #%00011110
	sta PPUMASK
	rts

update_title:
	jsr hide_all_sprites
	; Start edge?
	lda pad1_edge
	and #BTN_START
	beq @done
	jsr enter_play
@done:
	rts

draw_title_screen:
	; 2×2 shipping box, row 10–11, col 15–16
	lda #$21
	sta PPUADDR
	lda #$4F                ; row 10, col 15
	sta PPUADDR
	lda #T_BOX_TL
	sta PPUDATA
	lda #T_BOX_TR
	sta PPUDATA
	lda #$21
	sta PPUADDR
	lda #$6F                ; row 11, col 15
	sta PPUADDR
	lda #T_BOX_BL
	sta PPUDATA
	lda #T_BOX_BR
	sta PPUDATA

	; "VESYL SHIPPER" row 6, col 9
	lda #$20
	sta str_nt_hi
	lda #$C9
	sta str_nt_lo
	lda #<str_title
	sta ptr_lo
	lda #>str_title
	sta ptr_hi
	jsr draw_string

	; "PRESS START" row 16, col 10
	lda #$22
	sta str_nt_hi
	lda #$0A
	sta str_nt_lo
	lda #<str_press
	sta ptr_lo
	lda #>str_press
	sta ptr_hi
	jsr draw_string

	; Attributes: default palette 0; box area uses palette 1 (brown)
	lda #$23
	sta PPUADDR
	lda #$C0
	sta PPUADDR
	ldx #$40
	lda #$00
@attr:
	sta PPUDATA
	dex
	bne @attr
	; attr byte for rows 8-11, cols 8-15 → index (row/4)*8 + (col/4)
	; rows 10-11, cols 15-16 → attr row 2, col 3 → offset 2*8+3 = 19 = $13
	lda #$23
	sta PPUADDR
	lda #$D3
	sta PPUADDR
	lda #%01010000          ; bottom-right 2×2 of this attr cell → pal 1
	sta PPUDATA
	rts

; -------------------------
; State: Play
; -------------------------
enter_play:
	lda #STATE_PLAY
	sta game_state
	lda #$00
	sta scroll_lo
	sta scroll_hi
	sta has_package
	sta vel_y
	sta anim_frame
	sta facing
	sta player_x_hi
	lda #40
	sta player_x_lo
	lda #GROUND_TOP_Y - PLAYER_H
	sta player_y
	lda #1
	sta on_ground
	lda #%10000000
	sta ppuctrl_nt

	jsr wait_nmi_safe
	lda #$00
	sta PPUMASK

	jsr build_level
	jsr hide_all_sprites

	jsr wait_vblank
	lda #%10000000
	sta ppuctrl_nt
	sta PPUCTRL
	lda #$00
	sta PPUSCROLL
	sta PPUSCROLL
	lda #%00011110
	sta PPUMASK
	rts

update_play:
	lda player_x_lo
	sta old_x_lo
	lda player_x_hi
	sta old_x_hi
	lda player_y
	sta old_y

	jsr apply_horizontal
	jsr probe_support          ; clear on_ground if walked off ledge
	jsr apply_jump
	jsr apply_gravity
	jsr collide_vertical
	jsr update_camera
	jsr check_package
	jsr check_truck
	jsr draw_play_sprites
	rts

; Set on_ground if feet rest on ground or a platform (no movement)
probe_support:
	lda #0
	sta on_ground
	lda player_y
	clc
	adc #PLAYER_H
	cmp #GROUND_TOP_Y
	bne @plats
	lda #1
	sta on_ground
	rts
@plats:
	; platform 1 @ y=136, x 160-224 — any horizontal overlap with 16px body
	cmp #136
	bne @p2
	jsr plat1_x_overlap
	bcc @p2
	lda #1
	sta on_ground
	rts
@p2:
	; platform 2 @ y=144, x 320-384
	cmp #144
	bne @done
	jsr plat2_x_overlap
	bcc @done
	lda #1
	sta on_ground
@done:
	rts

; C=1 if player [x, x+16) overlaps platform 1 [160, 224)
; i.e. player_x < 224 AND player_x + 16 > 160
plat1_x_overlap:
	lda player_x_hi
	bne @no                   ; x >= 256, past this platform
	lda player_x_lo
	cmp #224
	bcs @no                   ; left edge at/past platform right
	clc
	adc #PLAYER_W
	cmp #161                  ; right edge > 160
	bcc @no
	sec
	rts
@no:
	clc
	rts

; C=1 if player overlaps platform 2 [320, 384)
; i.e. player_x < 384 AND player_x + 16 > 320
plat2_x_overlap:
	lda player_x_hi
	cmp #1
	bne @no                   ; only in second screen half
	lda player_x_lo
	cmp #128                  ; world x >= 384
	bcs @no
	clc
	adc #PLAYER_W
	cmp #65                   ; world (256+lo+16) > 320 → lo+16 > 64
	bcc @no
	sec
	rts
@no:
	clc
	rts

apply_horizontal:
	lda pad1
	and #BTN_RIGHT
	beq @no_r
	lda #0
	sta facing
	lda player_x_lo
	clc
	adc #MOVE_SPEED
	sta player_x_lo
	lda player_x_hi
	adc #0
	sta player_x_hi
@no_r:
	lda pad1
	and #BTN_LEFT
	beq @no_l
	lda #1
	sta facing
	lda player_x_lo
	sec
	sbc #MOVE_SPEED
	sta player_x_lo
	lda player_x_hi
	sbc #0
	sta player_x_hi
	bcs @no_l
	lda #0
	sta player_x_lo
	sta player_x_hi
@no_l:
	; clamp to [8, 496]
	lda player_x_hi
	bne @hi
	lda player_x_lo
	cmp #8
	bcs @max
	lda #8
	sta player_x_lo
	jmp @max
@hi:
	cmp #2
	bcs @setmax
	; hi == 1: max lo = 496-256 = 240
	lda player_x_lo
	cmp #241
	bcc @max
@setmax:
	lda #240
	sta player_x_lo
	lda #1
	sta player_x_hi
@max:
	rts

apply_jump:
	lda pad1_edge
	and #BTN_A
	beq @done
	lda on_ground
	beq @done
	lda #JUMP_V
	sta vel_y
	lda #0
	sta on_ground
@done:
	rts

apply_gravity:
	lda on_ground
	beq @air
	lda vel_y
	bmi @air                  ; jumping through
	lda #0
	sta vel_y
	rts
@air:
	; Variable jump: release A while rising → cut upward velocity
	lda vel_y
	bpl @grav                 ; not rising
	lda pad1
	and #BTN_A
	bne @grav                 ; still holding A → full arc
	lda #0
	sta vel_y                 ; short hop
@grav:
	lda vel_y
	clc
	adc #GRAVITY
	sta vel_y
	bmi @add
	cmp #MAX_FALL + 1
	bcc @add
	lda #MAX_FALL
	sta vel_y
@add:
	lda player_y
	clc
	adc vel_y
	sta player_y
	rts

; Land on ground / platforms when falling
collide_vertical:
	lda vel_y
	bmi @done                 ; rising
	lda player_y
	clc
	adc #PLAYER_H
	sta check_y

	cmp #GROUND_TOP_Y
	bcc @plats
	lda #GROUND_TOP_Y - PLAYER_H
	sta player_y
	lda #0
	sta vel_y
	lda #1
	sta on_ground
	rts

@plats:
	; Platform 1: any body overlap with [160,224), feet crossing top 136
	jsr plat1_x_overlap
	bcc @p2
	lda check_y
	cmp #136
	bcc @p2
	cmp #144
	bcs @p2
	lda #136 - PLAYER_H
	sta player_y
	lda #0
	sta vel_y
	lda #1
	sta on_ground
	rts

@p2:
	; Platform 2: any body overlap with [320,384), top 144
	jsr plat2_x_overlap
	bcc @done
	lda check_y
	cmp #144
	bcc @done
	cmp #152
	bcs @done
	lda #144 - PLAYER_H
	sta player_y
	lda #0
	sta vel_y
	lda #1
	sta on_ground
@done:
	rts

update_camera:
	; desired = player_x - CAMERA_OFF
	lda player_x_lo
	sec
	sbc #CAMERA_OFF
	sta scroll_lo
	lda player_x_hi
	sbc #0
	sta scroll_hi
	bcs @clamp_hi
	; negative → 0
	lda #0
	sta scroll_lo
	sta scroll_hi
	jmp @nt
@clamp_hi:
	; if scroll > 256, clamp to 256
	lda scroll_hi
	beq @nt
	cmp #1
	bcc @nt
	; hi >= 1
	lda scroll_lo
	; if hi > 1 or (hi==1 and lo>0) beyond max 256
	lda scroll_hi
	cmp #1
	beq @check256
	; hi >= 2
	lda #0
	sta scroll_lo
	lda #1
	sta scroll_hi
	jmp @nt
@check256:
	; hi==1: max scroll is 256 so lo must be 0
	lda #0
	sta scroll_lo
@nt:
	; nametable bit from scroll_hi
	lda #%10000000
	ldx scroll_hi
	beq @set
	ora #$01
@set:
	sta ppuctrl_nt

	; screen_x = player_x - scroll
	lda player_x_lo
	sec
	sbc scroll_lo
	sta screen_x
	lda player_x_hi
	sbc scroll_hi
	; result should be 0-255 in screen_x low; ignore hi
	rts

check_package:
	lda has_package
	bne @done
	; package only in first screen (hi=0)
	lda player_x_hi
	bne @done
	; player_x < pkg+16 && player_x+16 > pkg  (generous box)
	lda player_x_lo
	cmp #PKG_WORLD_X_L + 16
	bcs @done
	clc
	adc #PLAYER_W
	cmp #PKG_WORLD_X_L
	bcc @done
	lda player_y
	clc
	adc #PLAYER_H
	cmp #PKG_WORLD_Y
	bcc @done
	lda player_y
	cmp #PKG_WORLD_Y + 16
	bcs @done
	lda #1
	sta has_package
@done:
	rts

check_truck:
	lda has_package
	beq @done
	; zone: world X 400..480 (hi=1, lo 144..224)
	lda player_x_hi
	cmp #1
	bne @done
	lda player_x_lo
	cmp #144                 ; 256+144=400
	bcc @done
	cmp #224                 ; 256+224=480
	bcs @done
	jsr enter_win
@done:
	rts

draw_play_sprites:
	jsr hide_all_sprites
	lda #0
	sta oam_idx

	; choose metasprite
	lda facing
	bne @face_l
	; moving?
	lda player_x_lo
	cmp old_x_lo
	bne @walk_r
	lda player_x_hi
	cmp old_x_hi
	bne @walk_r
	lda #<player_idle_metasprite
	sta metasprite_ptr_lo
	lda #>player_idle_metasprite
	sta metasprite_ptr_hi
	jmp @draw_p
@walk_r:
	inc anim_frame
	lda anim_frame
	lsr
	lsr
	lsr
	and #1
	beq @w1r
	lda #<player_walk2_metasprite
	sta metasprite_ptr_lo
	lda #>player_walk2_metasprite
	sta metasprite_ptr_hi
	jmp @draw_p
@w1r:
	lda #<player_walk1_metasprite
	sta metasprite_ptr_lo
	lda #>player_walk1_metasprite
	sta metasprite_ptr_hi
	jmp @draw_p
@face_l:
	lda player_x_lo
	cmp old_x_lo
	bne @walk_l
	lda player_x_hi
	cmp old_x_hi
	bne @walk_l
	lda #<player_idle_flip
	sta metasprite_ptr_lo
	lda #>player_idle_flip
	sta metasprite_ptr_hi
	jmp @draw_p
@walk_l:
	inc anim_frame
	lda anim_frame
	lsr
	lsr
	lsr
	and #1
	beq @w1l
	lda #<player_walk2_flip
	sta metasprite_ptr_lo
	lda #>player_walk2_flip
	sta metasprite_ptr_hi
	jmp @draw_p
@w1l:
	lda #<player_walk1_flip
	sta metasprite_ptr_lo
	lda #>player_walk1_flip
	sta metasprite_ptr_hi
@draw_p:
	jsr draw_metasprite

	; package world sprite if not held
	lda has_package
	bne @held
	jsr draw_world_package
	jmp @done
@held:
	; small box on player
	ldx oam_idx
	lda player_y
	clc
	adc #4
	sta oam_shadow, x
	lda #T_BOX
	sta oam_shadow+1, x
	lda #%00000001          ; palette 1
	sta oam_shadow+2, x
	lda screen_x
	clc
	adc #4
	sta oam_shadow+3, x
	txa
	clc
	adc #4
	sta oam_idx
@done:
	rts

draw_world_package:
	; screen x = pkg_x - scroll
	lda #PKG_WORLD_X_L
	sec
	sbc scroll_lo
	sta temp
	lda #PKG_WORLD_X_H
	sbc scroll_hi
	bne @offscreen          ; hi != 0 means off left or far right
	; temp is screen x 0-255
	ldx oam_idx
	lda #PKG_WORLD_Y
	sta oam_shadow, x
	lda #T_BOX
	sta oam_shadow+1, x
	lda #%00000001
	sta oam_shadow+2, x
	lda temp
	sta oam_shadow+3, x
	txa
	clc
	adc #4
	sta oam_idx
@offscreen:
	rts

; -------------------------
; State: Win
; -------------------------
enter_win:
	lda #STATE_WIN
	sta game_state
	lda #$00
	sta scroll_lo
	sta scroll_hi
	lda #%10000000
	sta ppuctrl_nt

	jsr wait_nmi_safe
	lda #$00
	sta PPUMASK

	jsr clear_nametables

	; DELIVERED! row 12 col 10: 12*32+10 = 394 = $018A → $218A
	lda #$21
	sta str_nt_hi
	lda #$8A
	sta str_nt_lo
	lda #<str_win
	sta ptr_lo
	lda #>str_win
	sta ptr_hi
	jsr draw_string

	lda #$22
	sta str_nt_hi
	lda #$0A
	sta str_nt_lo
	lda #<str_press
	sta ptr_lo
	lda #>str_press
	sta ptr_hi
	jsr draw_string

	jsr hide_all_sprites

	jsr wait_vblank
	lda #%10000000
	sta ppuctrl_nt
	sta PPUCTRL
	lda #0
	sta PPUSCROLL
	sta PPUSCROLL
	lda #%00011110
	sta PPUMASK
	rts

update_win:
	jsr hide_all_sprites
	lda pad1_edge
	and #BTN_START
	beq @done
	jsr enter_title
@done:
	rts

; -------------------------
; Level build (both nametables)
; -------------------------
build_level:
	; Fill NT0 and NT1 with sky, then ground, props
	bit PPUSTATUS
	jsr clear_nametables

	; Ground rows 21-29 on both nametables (tile rows)
	lda #$20
	jsr fill_ground_nt
	lda #$24
	jsr fill_ground_nt

	jsr draw_warehouse
	jsr draw_platform_tiles
	jsr draw_truck

	; Attributes both NT
	lda #$23
	sta PPUADDR
	lda #$C0
	sta PPUADDR
	ldx #$40
	lda #$00
@a0:
	sta PPUDATA
	dex
	bne @a0

	lda #$27
	sta PPUADDR
	lda #$C0
	sta PPUADDR
	ldx #$40
	lda #$00
@a1:
	sta PPUDATA
	dex
	bne @a1
	rts

; A = nametable hi ($20 or $24)
fill_ground_nt:
	sta temp_hi
	; row 21: ground top — addr = nt + 21*32 = nt + $2A0
	lda temp_hi
	clc
	adc #2
	sta PPUADDR             ; $22 or $26
	lda #$A0
	sta PPUADDR
	ldx #32
	lda #T_GROUND_TOP
@top:
	sta PPUDATA
	dex
	bne @top
	; rows 22-29: fill (8 rows)
	ldy #8
@row:
	ldx #32
	lda #T_GROUND_FILL
@fill:
	sta PPUDATA
	dex
	bne @fill
	dey
	bne @row
	rts

draw_warehouse:
	; Ceiling row 11, cols 0-9: $2000+11*32 = $2160
	lda #$21
	sta PPUADDR
	lda #$60
	sta PPUADDR
	ldx #10
	lda #T_BRICK
@ceil:
	sta PPUDATA
	dex
	bne @ceil

	; Left wall cols 0-1, rows 12-20
	ldx #12
@left:
	txa
	sta temp
	lda #0
	sta temp_hi
	ldy #5
@ml:
	asl temp
	rol temp_hi
	dey
	bne @ml
	lda temp_hi
	clc
	adc #$20
	sta PPUADDR
	lda temp
	sta PPUADDR
	lda #T_BRICK
	sta PPUDATA
	sta PPUDATA
	inx
	cpx #21
	bcc @left

	; Door post cols 8-9, rows 12-20
	ldx #12
@post:
	txa
	sta temp
	lda #0
	sta temp_hi
	ldy #5
@mp:
	asl temp
	rol temp_hi
	dey
	bne @mp
	lda temp
	clc
	adc #8
	sta temp
	lda temp_hi
	adc #0
	clc
	adc #$20
	sta PPUADDR
	lda temp
	sta PPUADDR
	lda #T_BRICK
	sta PPUDATA
	sta PPUDATA
	inx
	cpx #21
	bcc @post
	rts

draw_platform_tiles:
	; Reset PPU address latch before VRAM writes
	bit PPUSTATUS

	; Platform 1: world px 160-224 (cols 20-27), top at y=136 → tile row 17
	; NT0 addr = $2000 + 17*32 + 20 = $2234
	lda #$22
	sta PPUADDR
	lda #$34
	sta PPUADDR
	ldx #8
	lda #T_PLATFORM
@p1:
	sta PPUDATA
	dex
	bne @p1

	; Platform 2: world px 320-384 (NT1 cols 8-15), top at y=144 → tile row 18
	; NT1 addr = $2400 + 18*32 + 8 = $2648
	bit PPUSTATUS
	lda #$26
	sta PPUADDR
	lda #$48
	sta PPUADDR
	ldx #8
	lda #T_PLATFORM
@p2:
	sta PPUDATA
	dex
	bne @p2
	rts

draw_truck:
	; world cols 56-58 → NT1 col 24-26, rows 19-20 (just above ground)
	; $2400 + 19*32 + 24 = $2400 + $260 + $18 = $2678
	lda #$26
	sta PPUADDR
	lda #$78
	sta PPUADDR
	lda #T_TRUCK0
	sta PPUDATA
	lda #T_TRUCK1
	sta PPUDATA
	lda #T_TRUCK2
	sta PPUDATA
	; row 20: $2400 + 20*32 + 24 = $2400+$280+$18 = $2698
	lda #$26
	sta PPUADDR
	lda #$98
	sta PPUADDR
	lda #T_TRUCK3
	sta PPUDATA
	lda #T_TRUCK4
	sta PPUDATA
	lda #T_TRUCK5
	sta PPUDATA
	rts

; -------------------------
; Drawing helpers
; -------------------------
; draw_string: str_nt_hi/lo, ptr → string of font-relative indices $FF-ended
draw_string:
	lda str_nt_hi
	sta PPUADDR
	lda str_nt_lo
	sta PPUADDR
	ldy #0
@loop:
	lda (ptr_lo), y
	cmp #$FF
	beq @done
	clc
	adc #T_FONT
	sta PPUDATA
	iny
	bne @loop
@done:
	rts

draw_metasprite:
	ldy #0
	ldx oam_idx
@loop:
	lda (metasprite_ptr_lo), y
	cmp #$80
	beq @done
	clc
	adc player_y
	sta oam_shadow, x
	iny
	lda (metasprite_ptr_lo), y
	clc
	adc screen_x
	sta oam_shadow+3, x
	iny
	lda (metasprite_ptr_lo), y
	sta oam_shadow+1, x
	iny
	lda (metasprite_ptr_lo), y
	sta oam_shadow+2, x
	iny
	txa
	clc
	adc #4
	tax
	jmp @loop
@done:
	stx oam_idx
	rts

hide_all_sprites:
	ldx #0
	lda #$FF
@h:
	sta oam_shadow, x
	inx
	inx
	inx
	inx
	bne @h
	lda #0
	sta oam_idx
	rts

clear_nametables:
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	lda #T_SKY
	ldy #8                  ; 8*256 = 2048 (two nametables + attrs roughly)
@outer:
	ldx #0
@inner:
	sta PPUDATA
	inx
	bne @inner
	dey
	bne @outer
	rts

load_palettes:
	lda #$3F
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldx #0
@bg:
	lda bg_palette, x
	sta PPUDATA
	inx
	cpx #$10
	bne @bg
	ldx #0
@sp:
	lda spr_palette, x
	sta PPUDATA
	inx
	cpx #$10
	bne @sp
	rts

load_chr:
	lda #$00
	sta PPUADDR
	sta PPUADDR
	lda #<tiles
	sta ptr_lo
	lda #>tiles
	sta ptr_hi
	lda #<(tiles_end - tiles)
	sta temp
	lda #>(tiles_end - tiles)
	sta temp_hi
@loop:
	lda temp
	ora temp_hi
	beq @done
	ldy #0
	lda (ptr_lo), y
	sta PPUDATA
	inc ptr_lo
	bne @dec
	inc ptr_hi
@dec:
	lda temp
	sec
	sbc #1
	sta temp
	lda temp_hi
	sbc #0
	sta temp_hi
	jmp @loop
@done:
	rts

wait_nmi_safe:
	; disable rendering already expected; wait vblank
	jsr wait_vblank
	rts

wait_vblank:
	bit PPUSTATUS
	bpl wait_vblank
	rts

; Read controller 1. After 8 ROL shifts:
; bit7=A, bit6=B, bit5=Select, bit4=Start, bit3=Up, bit2=Down, bit1=Left, bit0=Right
read_controller:
	lda pad1
	sta pad1_prev
	lda #$01
	sta $4016
	lda #$00
	sta $4016
	lda #$00
	sta pad1
	ldx #8
@loop:
	lda $4016
	and #1
	cmp #1                    ; C = pressed
	rol pad1
	dex
	bne @loop
	; edge = newly pressed this frame
	lda pad1_prev
	eor #$FF
	and pad1
	sta pad1_edge
	rts

nmi:
	pha
	txa
	pha
	tya
	pha

	lda #$00
	sta OAMADDR
	lda #$02
	sta OAMDMA

	; Reset shared PPU latch, then set scroll (Y must stay 0)
	bit PPUSTATUS
	lda ppuctrl_nt
	sta PPUCTRL
	lda scroll_lo
	sta PPUSCROLL
	lda #$00
	sta PPUSCROLL

	lda #1
	sta frame_flag

	pla
	tay
	pla
	tax
	pla
	rti

irq:
	rti

	.segment "VECTORS"
	.addr nmi, reset, irq
