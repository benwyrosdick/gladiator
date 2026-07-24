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

; APU
APU_PULSE1_VOL   = $4000
APU_PULSE1_SWEEP = $4001
APU_PULSE1_LO    = $4002
APU_PULSE1_HI    = $4003
APU_NOISE_VOL    = $400C
APU_NOISE_LO     = $400E
APU_NOISE_HI     = $400F
APU_STATUS       = $4015
APU_FRAME        = $4017

; SFX ids (0 = none)
SFX_NONE     = 0
SFX_JUMP     = 1
SFX_PICKUP   = 2
SFX_DROP     = 3
SFX_WIN      = 4
SFX_TIMEOUT  = 5
SFX_HIT      = 6            ; package lands on ground / platform

; Game states
STATE_TITLE    = 0
STATE_PLAY     = 1
STATE_WIN      = 2
STATE_PAUSE    = 3
STATE_TIMEOUT  = 4          ; pan to exit + truck pulls away
STATE_FAIL     = 5          ; TIME UP static screen

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

; Tile indices are derived from CHR labels after tiles_end (see RODATA).

PLAYER_W     = 16
PLAYER_H     = 16
; Vertical motion in 1/16 px (same units as vel_x) for smooth gravity arc
; Hold-A peak ≈ 43 px over ~18 frames; release A clamps rise for short hop
GRAVITY      = $04          ; +0.25 px/f²
JUMP_V       = $B8          ; -72 → -4.5 px/f takeoff (empty-handed)
JUMP_V_CARRY = $C0          ; -64 → -4.0 px/f while holding package (lower peak)
JUMP_CUT     = $E8          ; -24 → -1.5 px/f max rise after releasing A
MAX_FALL     = $60          ; 6.0 px/f terminal
; Horizontal motion (Mario-style accel / friction), units = 1/16 pixel
; Peak speeds ≈ walk 2px/f, run 4px/f
WALK_MAX     = 24
RUN_MAX      = 42
ACCEL        = 3              ; speed up when holding a direction
FRICTION     = 2              ; slow down when no input
SKID         = 5              ; brake faster when reversing
CAMERA_OFF   = 96
LEVEL_W_PX_L = $00          ; level width 512 = $0200
LEVEL_W_PX_H = $02
MAX_SCROLL_L = $00          ; 512-256 = 256
MAX_SCROLL_H = $01
GROUND_TOP_Y = 176          ; pixel Y of ground surface (row 22)
; nametable rows: ground top at row 22 (22*8=176)
; Truck wheels on row 21 (attr top) + ground on row 22 (attr bottom) → no pal bleed

; Expanded warehouse: interior world X [WH_LEFT, WH_EXIT_L), door, truck outside
WH_LEFT       = 16          ; left wall solid x < 16 (cols 0-1)
; Exit doorway world X 400-416 ($0190-$01A0); open for y >= WH_DOOR_TOP
WH_EXIT_L_L   = $90         ; 400 = 256+144
WH_EXIT_L_H   = $01
WH_EXIT_R_L   = $A0         ; 416 = 256+160 — truck starts here
WH_EXIT_R_H   = $01
WH_DOOR_TOP   = 144         ; open doorway for y >= 144 (tile rows 18+)
WH_CEILING    = 40          ; bottom of ceiling (row 5 → y 40)

; Climbable shelves inside warehouse (~24px steps)
SHELF_MID_Y   = 128         ; row 16
SHELF_HIGH_Y  = 104         ; row 13 — package spawn
SHELF_MID_L   = 104
SHELF_MID_R   = 152
SHELF_HIGH_L  = 24
SHELF_HIGH_R  = 72

; Interior bridges deeper in warehouse (still before exit at 400)
PLAT1_Y       = 144         ; world x 184-248
PLAT1_L       = 184
PLAT1_R       = 248
PLAT2_Y       = 152         ; world x 320-384 (hi=1)
PLAT2_L_LO    = 64          ; 320-256
PLAT2_R_LO    = 128         ; 384-256

PKG_W         = 12
PKG_H         = 12
PKG_WORLD_X_L = 56          ; on high shelf
PKG_WORLD_X_H = 0
PKG_WORLD_Y   = SHELF_HIGH_Y - PKG_H
PKG_THROW     = $04          ; extra horizontal toss on drop (0.25 px/f)
PKG_TOSS_UP   = $D0          ; -48 (1/16 px) upward when holding Up on release

; Truck just outside door: NT1 cols 20-27 → world X 416-480 (door ends 416)
TRUCK_LEFT_L  = $A0         ; 256+160=416
TRUCK_LEFT_H  = $01
TRUCK_RIGHT_L = $E0         ; 256+224=480
TRUCK_RIGHT_H = $01
TRUCK_TOP_Y   = 144         ; pixel Y of truck top row (tile row 18)
TRUCK_W_TILES = 8
TRUCK_H_TILES = 4

; Forklift enemies (16×16 sprites, warehouse floor patrol)
NUM_FORKLIFTS   = 2
FORKLIFT_W      = 16
FORKLIFT_H      = 16
FORKLIFT_Y      = GROUND_TOP_Y - FORKLIFT_H   ; sit on ground
FORKLIFT_SPD    = 1         ; px/frame
FORKLIFT_MIN_X  = 24        ; just inside left wall
FORKLIFT_MAX_L  = $80       ; 384 = 256+128; stop before exit door
FORKLIFT_MAX_H  = $01
FORKLIFT_KNOCK  = 36        ; package shoved this far past forklift
FORKLIFT_COOL   = 40        ; frames between knocks
FORKLIFT_TURN_D = 32        ; px between random turn rolls
; Spawn: FL0 mid-warehouse facing right; FL1 deeper facing left
FL0_START_L     = 120
FL0_START_H     = 0
FL1_START_L     = $40       ; 320 = 256+64
FL1_START_H     = $01

; Level timer (NTSC)
TIMER_SEC_INIT = 25
FRAMES_PER_SEC = 60
PAN_SPEED      = 4          ; scroll px/frame during timeout pan
TRUCK_DRIVE_SPD = 2         ; truck pull-away px/frame
TRUCK_DRIVE_MAX = 160       ; then fail screen

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
player_x_sub:      .res 1   ; subpixel 0-15 (1/16 px)
player_y:          .res 1
player_y_sub:      .res 1   ; subpixel 0-15 (1/16 px)
screen_x:          .res 1
vel_x:             .res 1   ; signed, 1/16 px per frame
vel_y:             .res 1   ; signed, 1/16 px per frame
on_ground:         .res 1
drop_ignore_y:     .res 1   ; platform top Y to fall through ($FF = none)
anim_frame:        .res 1
facing:            .res 1   ; 0=right, 1=left (flip)
has_package:       .res 1
package_x_lo:      .res 1   ; world X of free package (when not held)
package_x_hi:      .res 1
package_x_sub:     .res 1   ; subpixel 0-15
package_y:         .res 1
package_y_sub:     .res 1   ; subpixel 0-15
package_vel_x:     .res 1   ; signed, 1/16 px per frame
package_vel_y:     .res 1   ; signed, 1/16 px per frame
package_on_ground: .res 1
timer_sec:         .res 1   ; remaining seconds
timer_frames:      .res 1   ; frames until next second
truck_drive:       .res 1   ; px truck has driven past parking (timeout)
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
sfx_queue:         .res 1   ; pending SFX id (0 = none)
sfx_timer:         .res 1   ; frames left in current step
sfx_pos:           .res 1   ; byte index into current SFX sequence
sfx_ptr_lo:        .res 1
sfx_ptr_hi:        .res 1
forklift_x_lo:     .res NUM_FORKLIFTS
forklift_x_hi:     .res NUM_FORKLIFTS
forklift_dir:      .res NUM_FORKLIFTS   ; 0=right, 1=left
forklift_cool:     .res NUM_FORKLIFTS   ; knock cooldown
forklift_dist:     .res NUM_FORKLIFTS   ; px toward next random turn roll
rng:               .res 1   ; 8-bit LFSR seed (must be non-zero)

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
; sky (empty)
sky_tile:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; player (original gladiator art)
player_s_0_idle:
	.byte $07,$08,$10,$20,$20,$17,$0F,$0F,$00,$07,$0F,$1F,$1F,$09,$05,$05  ; 0
player_s_1_idle:
	.byte $E0,$10,$08,$08,$88,$E8,$F0,$F0,$00,$E0,$F0,$F0,$F0,$10,$A0,$A0  ; 1
player_s_2_idle:
	.byte $1B,$39,$4C,$4C,$3C,$0E,$17,$21,$0F,$1F,$3B,$33,$07,$07,$0E,$1E  ; 2
player_s_3_idle:
	.byte $D8,$9C,$32,$32,$3C,$70,$D0,$08,$F0,$F8,$DC,$CC,$E0,$E0,$E0,$F0  ; 3
player_s_2_walk:
	.byte $1F,$39,$4C,$4C,$3E,$17,$21,$1F,$0B,$1F,$3B,$33,$05,$0E,$1E,$00  ; 4
player_s_3_walk:
	.byte $F8,$9C,$32,$32,$7C,$D0,$08,$F0,$D0,$F8,$DC,$CC,$A0,$60,$F0,$00  ; 5

; NES CHR: 8 bytes plane0 (rows 0-7) then 8 bytes plane1.
; Same bits in both planes → palette index 3 (bright).

ground_top_tile:
	.byte $FF,$FF,$FF,$55,$AA,$55,$AA,$55,$00,$00,$FF,$AA,$55,$AA,$55,$AA  ; 0
	
ground_fill_tile:
	.byte $AA,$55,$AA,$55,$AA,$55,$AA,$55,$55,$AA,$55,$AA,$55,$AA,$55,$AA  ; 0

brick_tile:
	.byte $00,$DF,$DF,$DF,$00,$FB,$FB,$FB,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 0

; platform — full 8x8 solid ledge (white top, blue body; always visible on black sky)
platform_tile:
	.byte $FF,$FF,$EE,$DD,$BB,$77,$EE,$DD,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF  ; 0

; package 12x12 (TL/TR/BL/BR). 0=clear 1=white label 2=cardboard 3=outline
; Label is 4x6 at (2,2) inside the box
package_tiles:
	.byte $FF,$80,$BC,$BC,$BC,$BC,$BC,$80,$FF,$FF,$C3,$DB,$C3,$DB,$C3,$FF  ; 0
	.byte $F0,$10,$10,$10,$10,$10,$10,$10,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0  ; 1

	.byte $80,$80,$80,$FF,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$00  ; 2
	.byte $10,$10,$10,$F0,$00,$00,$00,$00,$F0,$F0,$F0,$F0,$00,$00,$00,$00  ; 3

; title flat shipping box 6x4 — front view
; 0=black outline/icons  1=light panel+label  2=cardboard  3=red tape/border
title_package_tiles:
	.byte $03,$04,$08,$10,$20,$40,$FF,$80,$00,$03,$07,$0F,$1F,$3F,$00,$7F  ; 0
	.byte $FF,$00,$00,$00,$00,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF  ; 1
	.byte $FF,$01,$03,$07,$0F,$1F,$FF,$3F,$00,$FF,$FF,$FF,$FF,$FF,$3F,$FF  ; 2
	.byte $FF,$F8,$F0,$E0,$C0,$80,$FF,$00,$FC,$FF,$FF,$FF,$FF,$FF,$00,$FF  ; 3
	.byte $FF,$00,$00,$00,$00,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF  ; 4
	.byte $FE,$03,$05,$09,$11,$21,$C1,$41,$00,$FC,$FA,$F6,$EE,$DE,$3E,$BE  ; 5

	.byte $80,$80,$80,$80,$80,$80,$80,$80,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F  ; 6
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 7
	.byte $3F,$3F,$15,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 8
	.byte $00,$00,$1F,$1F,$1F,$1F,$1F,$1F,$FF,$FF,$E0,$E0,$E7,$E7,$E0,$E7  ; 9
	.byte $00,$00,$FC,$FC,$FC,$FC,$FC,$FC,$FF,$FF,$03,$03,$C3,$C3,$03,$F3  ; 10
	.byte $41,$41,$41,$41,$41,$41,$41,$41,$BE,$BE,$BE,$BE,$BE,$BE,$BE,$BE  ; 11

	.byte $80,$80,$80,$80,$80,$80,$BF,$A0,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F  ; 12
	.byte $00,$00,$00,$00,$00,$00,$EF,$28,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 13
	.byte $00,$00,$00,$00,$00,$00,$F0,$10,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 14
	.byte $1F,$1F,$1F,$1F,$1F,$1F,$1F,$00,$E0,$E0,$E5,$E5,$E7,$E0,$E0,$FF  ; 15
	.byte $FC,$FC,$FC,$FC,$FC,$FC,$FC,$00,$03,$03,$73,$F3,$53,$03,$03,$FF  ; 16
	.byte $41,$41,$41,$41,$41,$41,$41,$41,$BE,$BE,$BE,$BE,$BE,$BE,$BE,$BE  ; 17

	.byte $A2,$A7,$AF,$A2,$A2,$BF,$80,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$00  ; 18
	.byte $2B,$2A,$A9,$2B,$28,$EF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 19
	.byte $D0,$50,$90,$D0,$10,$F0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 20
	.byte $00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 21
	.byte $00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 22
	.byte $41,$41,$42,$44,$48,$50,$60,$C0,$BE,$BE,$BC,$B8,$B0,$A0,$80,$00  ; 23

; delivery truck 8x4 — yellow/red van, facing right
; 0=empty (sky)  1=yellow body  2=red cab/lines  3=dark outline+tires (visible on black)
delivery_truck_tiles:
	.byte $00,$00,$00,$00,$7F,$80,$80,$8F,$00,$00,$00,$00,$00,$7F,$7F,$7F  ; 0
	.byte $00,$00,$00,$00,$FF,$00,$00,$FC,$00,$00,$00,$00,$00,$FF,$FF,$FF  ; 1
	.byte $00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF  ; 2
	.byte $00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF  ; 3
	.byte $00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF  ; 4
	.byte $00,$00,$00,$00,$FC,$02,$02,$02,$00,$00,$00,$00,$00,$FC,$FC,$FC  ; 5
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 6
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 7

	.byte $9F,$80,$8F,$9F,$80,$8F,$9F,$80,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F  ; 8
	.byte $FE,$00,$FF,$FF,$00,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 9
	.byte $00,$00,$E0,$F0,$00,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 10
	.byte $00,$00,$00,$00,$00,$00,$80,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 11
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 12
	.byte $02,$02,$02,$03,$02,$02,$02,$02,$FC,$FC,$FC,$FC,$FD,$FD,$FD,$FD  ; 13
	.byte $00,$00,$00,$FF,$00,$00,$7F,$40,$00,$00,$00,$00,$FF,$FF,$80,$80  ; 14
	.byte $00,$00,$00,$00,$80,$40,$20,$90,$00,$00,$00,$00,$00,$80,$C0,$60  ; 15

	.byte $8F,$9F,$80,$80,$80,$80,$80,$80,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F  ; 16
	.byte $FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 17
	.byte $FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 18
	.byte $FE,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 19
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 20
	.byte $02,$02,$02,$02,$02,$02,$02,$02,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD  ; 21
	.byte $40,$40,$40,$7F,$00,$60,$00,$00,$80,$80,$80,$80,$FF,$9F,$FF,$FF  ; 22
	.byte $48,$24,$22,$E2,$02,$02,$02,$07,$30,$18,$1C,$1C,$FC,$FC,$FC,$F8  ; 23

	.byte $80,$80,$83,$FE,$7C,$04,$06,$03,$7F,$7F,$7F,$07,$07,$07,$07,$03  ; 24
	.byte $00,$00,$C3,$7E,$3C,$24,$66,$C3,$FF,$FF,$FF,$E7,$E7,$E7,$E7,$C3  ; 25
	.byte $00,$00,$C0,$7F,$3F,$20,$60,$C0,$FF,$FF,$FF,$E0,$E0,$E0,$E0,$C0  ; 26
	.byte $00,$00,$00,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00  ; 27
	.byte $00,$00,$00,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00  ; 28
	.byte $02,$02,$02,$FE,$FF,$00,$00,$00,$FD,$FD,$FD,$01,$00,$00,$00,$00  ; 29
	.byte $00,$00,$07,$0C,$F8,$08,$0C,$07,$FF,$FF,$FF,$FF,$0F,$0F,$0F,$07  ; 30
	.byte $07,$07,$87,$C1,$7F,$40,$C0,$80,$FA,$FA,$F8,$FE,$C0,$C0,$C0,$80  ; 31

forklift_tiles:
	.byte $00,$00,$3E,$41,$41,$60,$62,$66,$00,$00,$3E,$41,$41,$60,$62,$66  ; 0
	.byte $00,$10,$10,$10,$10,$90,$90,$50,$00,$10,$10,$10,$10,$90,$90,$50  ; 1

	.byte $F1,$FE,$FF,$FF,$7F,$9F,$9F,$60,$91,$AE,$A3,$80,$E0,$F1,$FF,$60  ; 2
	.byte $50,$D0,$F0,$F0,$D0,$3F,$30,$DF,$50,$D0,$F0,$10,$F0,$FF,$F0,$DF  ; 3

; font: space, A-Z, !
font_space:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 
	.byte $38,$44,$44,$7C,$44,$44,$44,$00,$38,$44,$44,$7C,$44,$44,$44,$00  ; A
	.byte $78,$44,$44,$78,$44,$44,$78,$00,$78,$44,$44,$78,$44,$44,$78,$00  ; B
	.byte $38,$44,$40,$40,$40,$44,$38,$00,$38,$44,$40,$40,$40,$44,$38,$00  ; C
	.byte $70,$48,$44,$44,$44,$48,$70,$00,$70,$48,$44,$44,$44,$48,$70,$00  ; D
	.byte $7C,$40,$40,$78,$40,$40,$7C,$00,$7C,$40,$40,$78,$40,$40,$7C,$00  ; E
	.byte $7C,$40,$40,$78,$40,$40,$40,$00,$7C,$40,$40,$78,$40,$40,$40,$00  ; F
	.byte $38,$44,$40,$5C,$44,$44,$38,$00,$38,$44,$40,$5C,$44,$44,$38,$00  ; G
	.byte $44,$44,$44,$7C,$44,$44,$44,$00,$44,$44,$44,$7C,$44,$44,$44,$00  ; H
	.byte $7C,$10,$10,$10,$10,$10,$7C,$00,$7C,$10,$10,$10,$10,$10,$7C,$00  ; I
	.byte $3E,$08,$08,$08,$08,$48,$30,$00,$3E,$08,$08,$08,$08,$48,$30,$00  ; J
	.byte $44,$48,$50,$60,$50,$48,$44,$00,$44,$48,$50,$60,$50,$48,$44,$00  ; K
	.byte $40,$40,$40,$40,$40,$40,$7C,$00,$40,$40,$40,$40,$40,$40,$7C,$00  ; L
	.byte $44,$6C,$54,$44,$44,$44,$44,$00,$44,$6C,$54,$44,$44,$44,$44,$00  ; M
	.byte $44,$44,$64,$54,$4C,$44,$44,$00,$44,$44,$64,$54,$4C,$44,$44,$00  ; N
	.byte $38,$44,$44,$44,$44,$44,$38,$00,$38,$44,$44,$44,$44,$44,$38,$00  ; O
	.byte $78,$44,$44,$78,$40,$40,$40,$00,$78,$44,$44,$78,$40,$40,$40,$00  ; P
	.byte $38,$44,$44,$44,$54,$48,$34,$00,$38,$44,$44,$44,$54,$48,$34,$00  ; Q
	.byte $78,$44,$44,$78,$50,$48,$44,$00,$78,$44,$44,$78,$50,$48,$44,$00  ; R
	.byte $38,$44,$40,$38,$04,$44,$38,$00,$38,$44,$40,$38,$04,$44,$38,$00  ; S
	.byte $7C,$10,$10,$10,$10,$10,$10,$00,$7C,$10,$10,$10,$10,$10,$10,$00  ; T
	.byte $44,$44,$44,$44,$44,$44,$38,$00,$44,$44,$44,$44,$44,$44,$38,$00  ; U
	.byte $44,$44,$44,$44,$44,$28,$10,$00,$44,$44,$44,$44,$44,$28,$10,$00  ; V
	.byte $44,$44,$44,$44,$54,$6C,$44,$00,$44,$44,$44,$44,$54,$6C,$44,$00  ; W
	.byte $44,$44,$28,$10,$28,$44,$44,$00,$44,$44,$28,$10,$28,$44,$44,$00  ; X
	.byte $44,$44,$28,$10,$10,$10,$10,$00,$44,$44,$28,$10,$10,$10,$10,$00  ; Y
	.byte $7C,$04,$08,$10,$20,$40,$7C,$00,$7C,$04,$08,$10,$20,$40,$7C,$00  ; Z
	.byte $10,$10,$10,$10,$10,$00,$10,$00,$10,$10,$10,$10,$10,$00,$10,$00  ; !

; digits 0-9 for timer HUD
font_digits:
	.byte $3C,$66,$6E,$76,$66,$66,$3C,$00,$3C,$66,$6E,$76,$66,$66,$3C,$00 ; 0
	.byte $18,$38,$18,$18,$18,$18,$7E,$00,$18,$38,$18,$18,$18,$18,$7E,$00 ; 1
	.byte $3C,$66,$06,$0C,$18,$30,$7E,$00,$3C,$66,$06,$0C,$18,$30,$7E,$00 ; 2
	.byte $3C,$66,$06,$1C,$06,$66,$3C,$00,$3C,$66,$06,$1C,$06,$66,$3C,$00 ; 3
	.byte $0C,$1C,$3C,$6C,$7E,$0C,$0C,$00,$0C,$1C,$3C,$6C,$7E,$0C,$0C,$00 ; 4
	.byte $7E,$60,$7C,$06,$06,$66,$3C,$00,$7E,$60,$7C,$06,$06,$66,$3C,$00 ; 5
	.byte $3C,$60,$7C,$66,$66,$66,$3C,$00,$3C,$60,$7C,$66,$66,$66,$3C,$00 ; 6
	.byte $7E,$06,$0C,$18,$30,$30,$30,$00,$7E,$06,$0C,$18,$30,$30,$30,$00 ; 7
	.byte $3C,$66,$66,$3C,$66,$66,$3C,$00,$3C,$66,$66,$3C,$66,$66,$3C,$00 ; 8
	.byte $3C,$66,$66,$3E,$06,$0C,$38,$00,$3C,$66,$66,$3E,$06,$0C,$38,$00 ; 9
tiles_end:

; Tile indices from CHR labels (16 bytes per tile). Insert/reorder tiles freely;
; these stay correct as long as the labels mark the first tile of each set.
T_SKY              = (sky_tile - tiles) / 16
T_PLAYER_S_0_IDLE  = (player_s_0_idle - tiles) / 16
T_PLAYER_S_1_IDLE  = (player_s_1_idle - tiles) / 16
T_PLAYER_S_2_IDLE  = (player_s_2_idle - tiles) / 16
T_PLAYER_S_3_IDLE  = (player_s_3_idle - tiles) / 16
T_PLAYER_S_2_WALK  = (player_s_2_walk - tiles) / 16
T_PLAYER_S_3_WALK  = (player_s_3_walk - tiles) / 16
T_GROUND_TOP       = (ground_top_tile - tiles) / 16
T_GROUND_FILL      = (ground_fill_tile - tiles) / 16
T_BRICK            = (brick_tile - tiles) / 16
T_PLATFORM         = (platform_tile - tiles) / 16
T_PACKAGE          = (package_tiles - tiles) / 16
T_PACKAGE_TR       = T_PACKAGE + 1
T_PACKAGE_BL       = T_PACKAGE + 2
T_PACKAGE_BR       = T_PACKAGE + 3
T_TITLE_PACKAGE    = (title_package_tiles - tiles) / 16
T_DELIVERY_TRUCK   = (delivery_truck_tiles - tiles) / 16
T_FORKLIFT         = (forklift_tiles - tiles) / 16
T_FONT             = (font_space - tiles) / 16
T_DIGIT0           = (font_digits - tiles) / 16
; font relative: 0=space, 1=A … 26=Z, 27=!

; Metasprite tile aliases (player_s_* labels)
PLAYER_IDLE_0 = T_PLAYER_S_0_IDLE
PLAYER_IDLE_1 = T_PLAYER_S_1_IDLE
PLAYER_IDLE_2 = T_PLAYER_S_2_IDLE
PLAYER_IDLE_3 = T_PLAYER_S_3_IDLE
PLAYER_WALK_2 = T_PLAYER_S_2_WALK
PLAYER_WALK_3 = T_PLAYER_S_3_WALK

; Metasprites: Y, X, tile, attr … END_METASPRITE
; First field is Y-offset; $80 is reserved as list terminator (not a valid Y-off here).
END_METASPRITE = $80

player_idle_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000000
	.byte 0, 8, PLAYER_IDLE_1, %00000000
	.byte 8, 0, PLAYER_IDLE_2, %00000000
	.byte 8, 8, PLAYER_IDLE_3, %00000000
	.byte END_METASPRITE

player_walk1_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000000
	.byte 0, 8, PLAYER_IDLE_1, %00000000
	.byte 8, 0, PLAYER_IDLE_2, %00000000
	.byte 8, 8, PLAYER_WALK_3, %00000000
	.byte END_METASPRITE

player_walk2_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000000
	.byte 0, 8, PLAYER_IDLE_1, %00000000
	.byte 8, 0, PLAYER_WALK_2, %00000000
	.byte 8, 8, PLAYER_IDLE_3, %00000000
	.byte END_METASPRITE

player_idle_flip:
	.byte 0, 8, PLAYER_IDLE_0, %01000000
	.byte 0, 0, PLAYER_IDLE_1, %01000000
	.byte 8, 8, PLAYER_IDLE_2, %01000000
	.byte 8, 0, PLAYER_IDLE_3, %01000000
	.byte END_METASPRITE

player_walk1_flip:
	.byte 0, 8, PLAYER_IDLE_0, %01000000
	.byte 0, 0, PLAYER_IDLE_1, %01000000
	.byte 8, 8, PLAYER_IDLE_2, %01000000
	.byte 8, 0, PLAYER_WALK_3, %01000000
	.byte END_METASPRITE

player_walk2_flip:
	.byte 0, 8, PLAYER_IDLE_0, %01000000
	.byte 0, 0, PLAYER_IDLE_1, %01000000
	.byte 8, 8, PLAYER_WALK_2, %01000000
	.byte 8, 0, PLAYER_IDLE_3, %01000000
	.byte END_METASPRITE

; Forklift 2×2 (tiles 0–3), sprite palette 2. Facing right.
forklift_metasprite:
	.byte 0, 0, T_FORKLIFT+0, %00000010
	.byte 0, 8, T_FORKLIFT+1, %00000010
	.byte 8, 0, T_FORKLIFT+2, %00000010
	.byte 8, 8, T_FORKLIFT+3, %00000010
	.byte END_METASPRITE

forklift_metasprite_flip:
	.byte 0, 8, T_FORKLIFT+0, %01000010
	.byte 0, 0, T_FORKLIFT+1, %01000010
	.byte 8, 8, T_FORKLIFT+2, %01000010
	.byte 8, 0, T_FORKLIFT+3, %01000010
	.byte END_METASPRITE

; Palettes
bg_palette:
	.byte $0F, $21, $11, $30   ; sky / white text
	.byte $0F, $37, $27, $16   ; package: light card, body, red tape
	.byte $0F, $00, $10, $20   ; asphalt gray
	.byte $0F, $28, $16, $07   ; truck: yellow, red, dark brown (not color0 — visible on black)

spr_palette:
	.byte $0F, $27, $17, $30   ; player
	.byte $0F, $30, $27, $16   ; package: white label, cardboard, red outline
	.byte $0F, $38, $2D, $1D   ; forklift
	.byte $0F, $28, $16, $07   ; spare / truck match

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
str_fail:
	; T I M E   U P !
	.byte 20,9,13,5, 0, 21,16, 27, $FF
str_acme:
	; A C M E
	.byte 1,3,13,5, $FF
; Sprite tile indices for PAUSED overlay (absolute CHR)
pause_tiles:
	.byte T_FONT+16, T_FONT+1, T_FONT+21, T_FONT+19, T_FONT+5, T_FONT+4
PAUSE_LEN = 6
PAUSE_X0  = 104             ; (256 - 6*8) / 2
PAUSE_Y   = 112

; SFX sequences, then $FF
; type 0 = pulse1: vol ($4000), sweep ($4001), period_lo, $4003, duration
; type 1 = noise:  vol ($400C), period ($400E), $400F, duration
; Sweep $4001: EPPP NSSS — E=enable, PPP=rate, N=negate (1≈pitch up), SSS=shift
; $FF = end (silence channels)
sfx_table:
	.word 0                 ; SFX_NONE
	.word sfx_jump
	.word sfx_pickup
	.word sfx_drop
	.word sfx_win
	.word sfx_timeout
	.word sfx_hit

; Smooth rising boing via hardware sweep (continuous glide, not stepped notes)
sfx_jump:
	.byte 0, $98, $9B, $78, $0D, 12
	.byte $FF

sfx_pickup:
	.byte 0, $98, $8B, $0C, $09, 4
	.byte $FF

; Release / throw (still in air)
sfx_drop:
	.byte 0, $98, $83, $0C, $09, 4
	.byte $FF

; Package impact on ground or platform
sfx_hit:
	.byte 1, $3C, $0C, $08, 3   ; noise thump
	.byte $FF

sfx_win:
	.byte 0, $9C, $00, $AB, $09, 12
	.byte 0, $9C, $00, $AB, $09, 12
	.byte 0, $98, $00, $7C, $09, 12
	.byte 0, $9C, $00, $52, $09, 12
	.byte 0, $9C, $00, $AB, $09, 12
	.byte 0, $9C, $00, $52, $09, 12
	.byte 0, $9C, $00, $7C, $09, 24
	.byte $FF

sfx_timeout:
	.byte 1, $3C, $0A, $18, 26
	.byte 1, $38, $0C, $18, 28
	.byte 0, $96, $00, $F0, $28, 10
	.byte 0, $92, $00, $F8, $28, 12
	.byte $FF

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
	jsr init_apu

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
	cmp #STATE_PAUSE
	beq @pause
	cmp #STATE_WIN
	beq @win
	cmp #STATE_TIMEOUT
	beq @timeout
	cmp #STATE_FAIL
	beq @fail
	jmp @sfx

@title:
	jsr update_title
	jmp @sfx
@play:
	jsr update_play
	jmp @sfx
@pause:
	jsr update_pause
	jmp @sfx
@win:
	jsr update_win
	jmp @sfx
@timeout:
	jsr update_timeout
	jmp @sfx
@fail:
	jsr update_fail
@sfx:
	jsr update_sfx
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

	jsr draw_title_box_sprites

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
	jsr draw_title_box_sprites
	; Start edge?
	lda pad1_edge
	and #BTN_START
	beq @done
	jsr enter_play
@done:
	rts

; Title box as sprites so it can sit on a 4px (not 8px) Y offset.
; Tile row 9 + 4px → Y=76; cols 13-18 → X=104. Spr pal 1 = package colors.
; Color 0 is transparent → black sky shows through as outline.
TITLE_BOX_Y = 9 * 8 + 4
TITLE_BOX_X = 13 * 8

draw_title_box_sprites:
	jsr hide_all_sprites
	ldx #0                  ; OAM byte index
	ldy #0                  ; tile index 0..23
	lda #TITLE_BOX_Y
	sta temp2               ; row pixel Y
@row:
	lda #TITLE_BOX_X
	sta temp3               ; col pixel X
	lda #6
	sta temp                ; columns left in this row
@col:
	lda temp2
	sta oam_shadow, x
	tya
	clc
	adc #T_TITLE_PACKAGE
	sta oam_shadow+1, x
	lda #%00000001          ; sprite palette 1
	sta oam_shadow+2, x
	lda temp3
	sta oam_shadow+3, x
	txa
	clc
	adc #4
	tax
	iny
	lda temp3
	clc
	adc #8
	sta temp3
	dec temp
	bne @col
	lda temp2
	clc
	adc #8
	sta temp2
	cpy #24
	bcc @row
	stx oam_idx
	rts

draw_title_screen:
	; Text only — box is sprite-drawn (pixel Y for +4px offset)

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

	; Attributes all palette 0 (black sky + white text from pal 0)
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
	sta vel_x
	sta vel_y
	sta player_x_sub
	sta player_y_sub
	sta anim_frame
	sta facing
	sta player_x_hi
	lda #$FF
	sta drop_ignore_y
	lda #40
	sta player_x_lo
	lda #GROUND_TOP_Y - PLAYER_H
	sta player_y
	lda #PKG_WORLD_X_L
	sta package_x_lo
	lda #PKG_WORLD_X_H
	sta package_x_hi
	lda #PKG_WORLD_Y
	sta package_y
	lda #0
	sta package_x_sub
	sta package_y_sub
	sta package_vel_x
	sta package_vel_y
	sta truck_drive
	lda #1
	sta package_on_ground
	sta on_ground
	lda #TIMER_SEC_INIT
	sta timer_sec
	lda #FRAMES_PER_SEC
	sta timer_frames
	; Forklift 0: mid-warehouse, facing right
	lda #FL0_START_L
	sta forklift_x_lo+0
	lda #FL0_START_H
	sta forklift_x_hi+0
	lda #0
	sta forklift_dir+0
	sta forklift_cool+0
	sta forklift_dist+0
	; Forklift 1: deeper warehouse, facing left
	lda #FL1_START_L
	sta forklift_x_lo+1
	lda #FL1_START_H
	sta forklift_x_hi+1
	lda #1
	sta forklift_dir+1
	lda #0
	sta forklift_cool+1
	sta forklift_dist+1
	; Keep RNG non-zero (RAM clear leaves it 0 on first play)
	lda rng
	bne @rng_ok
	lda #$A5
	sta rng
@rng_ok:
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
	; Start → pause (edge so we don't immediately unpause)
	lda pad1_edge
	and #BTN_START
	beq @run
	lda #STATE_PAUSE
	sta game_state
	jsr draw_play_sprites
	jsr draw_timer_hud
	jsr draw_pause_label
	rts

@run:
	lda player_x_lo
	sta old_x_lo
	lda player_x_hi
	sta old_x_hi
	lda player_y
	sta old_y

	jsr apply_horizontal
	jsr collide_walls          ; warehouse brick solids
	jsr clear_drop_ignore_if_past
	jsr probe_support          ; clear on_ground if walked off ledge
	jsr apply_jump
	jsr apply_gravity
	jsr collide_vertical
	jsr update_camera
	jsr update_package_carry    ; B held = carry (Mario shell style)
	jsr update_free_package
	jsr update_forklifts
	jsr update_timer           ; may switch to STATE_TIMEOUT
	lda game_state
	cmp #STATE_PLAY
	bne @done                 ; timed out this frame
	jsr check_truck
	jsr draw_play_sprites
	jsr draw_timer_hud
@done:
	rts

; Frozen play scene; Start again resumes
update_pause:
	lda pad1_edge
	and #BTN_START
	beq @frozen
	lda #STATE_PLAY
	sta game_state
	jsr draw_play_sprites
	jsr draw_timer_hud
	rts
@frozen:
	jsr draw_play_sprites
	jsr draw_timer_hud
	jsr draw_pause_label
	rts

; "PAUSED" as centered sprites (font CHR works in OAM)
draw_pause_label:
	ldx oam_idx
	ldy #0
	lda #PAUSE_X0
	sta temp
@loop:
	lda #PAUSE_Y
	sta oam_shadow, x
	lda pause_tiles, y
	sta oam_shadow+1, x
	lda #%00000000          ; sprite pal 0 (white highlight)
	sta oam_shadow+2, x
	lda temp
	sta oam_shadow+3, x
	clc
	adc #8
	sta temp
	txa
	clc
	adc #4
	tax
	iny
	cpy #PAUSE_LEN
	bne @loop
	stx oam_idx
	rts

; Once feet are clearly below the dropped platform, allow that Y again
clear_drop_ignore_if_past:
	lda drop_ignore_y
	cmp #$FF
	beq @done
	lda player_y
	clc
	adc #PLAYER_H
	sec
	sbc drop_ignore_y        ; feet - ignored top
	bcc @done                 ; still above (shouldn't happen)
	cmp #10                   ; past platform thickness
	bcc @done
	lda #$FF
	sta drop_ignore_y
@done:
	rts

; Set on_ground if feet rest on ground or a platform (no movement)
probe_support:
	lda #0
	sta on_ground
	lda player_y
	clc
	adc #PLAYER_H
	sta check_y
	cmp #GROUND_TOP_Y
	bne @plats
	lda #1
	sta on_ground
	lda #$FF
	sta drop_ignore_y
	rts
@plats:
	lda player_x_lo
	sta check_x_lo
	lda player_x_hi
	sta check_x_hi
	lda #PLAYER_W
	sta temp3
	jsr feet_on_any_platform
	bcc @done
	; standing on platform at check_y — ignore if drop-through that top
	lda check_y
	cmp drop_ignore_y
	beq @done
	lda #1
	sta on_ground
@done:
	rts

; feet_on_any_platform: check_y = feet, check_x_* = left, temp3 = width
; C=1 if standing on a shelf/platform (feet at exact top)
; Note: multiple platforms can share the same Y — always try all that match.
feet_on_any_platform:
	lda check_y
	cmp #SHELF_HIGH_Y
	bne @mid
	jsr x_overlap_shelf_high
	bcs @yes
@mid:
	lda check_y
	cmp #SHELF_MID_Y
	bne @plat1
	jsr x_overlap_shelf_mid
	bcs @yes
@plat1:
	lda check_y
	cmp #PLAT1_Y
	bne @plat2
	jsr plat1_x_overlap
	bcs @yes
@plat2:
	lda check_y
	cmp #PLAT2_Y
	bne @no
	jsr plat2_x_overlap
	bcs @yes
@no:
	clc
	rts
@yes:
	sec
	rts

; X overlap helpers: check_x / temp3 width vs [x0,x1)
; shelf high [SHELF_HIGH_L, SHELF_HIGH_R)
x_overlap_shelf_high:
	lda check_x_hi
	bne @no
	lda check_x_lo
	cmp #SHELF_HIGH_R
	bcs @no
	clc
	adc temp3
	cmp #SHELF_HIGH_L + 1
	bcc @no
	sec
	rts
@no:
	clc
	rts

; shelf mid [SHELF_MID_L, SHELF_MID_R)
x_overlap_shelf_mid:
	lda check_x_hi
	bne @no
	lda check_x_lo
	cmp #SHELF_MID_R
	bcs @no
	clc
	adc temp3
	cmp #SHELF_MID_L + 1
	bcc @no
	sec
	rts
@no:
	clc
	rts

; Interior bridge 1 [PLAT1_L, PLAT1_R) y=PLAT1_Y
plat1_x_overlap:
	lda check_x_hi
	bne @no
	lda check_x_lo
	cmp #PLAT1_R
	bcs @no
	clc
	adc temp3
	cmp #PLAT1_L + 1
	bcc @no
	sec
	rts
@no:
	clc
	rts

; Interior bridge 2 world [320,384) hi=1 lo [PLAT2_L_LO, PLAT2_R_LO)
plat2_x_overlap:
	lda check_x_hi
	cmp #1
	bne @no
	lda check_x_lo
	cmp #PLAT2_R_LO
	bcs @no
	clc
	adc temp3
	cmp #PLAT2_L_LO + 1
	bcc @no
	sec
	rts
@no:
	clc
	rts

; Warehouse walls + ceiling. Exit doorway at world [400,416) open for y >= WH_DOOR_TOP.
collide_walls:
	; --- left wall: x < WH_LEFT (hi=0 only) ---
	lda player_x_hi
	bne @exit
	lda player_x_lo
	cmp #WH_LEFT
	bcs @exit
	lda #WH_LEFT
	sta player_x_lo
	lda #0
	sta player_x_sub
	lda vel_x
	bpl @exit
	lda #0
	sta vel_x

@exit:
	; --- exit pillar solid above door: body vs [400,416) and player_y < WH_DOOR_TOP ---
	lda player_x_hi
	cmp #WH_EXIT_L_H
	bne @ceil
	lda player_x_lo
	cmp #WH_EXIT_R_L
	bcs @ceil
	clc
	adc #PLAYER_W
	cmp #WH_EXIT_L_L + 1
	bcc @ceil
	lda player_y
	cmp #WH_DOOR_TOP
	bcs @ceil                 ; in doorway opening
	; push left of exit (stay inside warehouse)
	lda #WH_EXIT_L_L - PLAYER_W
	sta player_x_lo
	lda #WH_EXIT_L_H
	sta player_x_hi
	lda #0
	sta player_x_sub
	sta vel_x

@ceil:
	; ceiling while inside warehouse (world x < WH_EXIT_L)
	lda player_x_hi
	cmp #WH_EXIT_L_H
	bcc @ceil_do
	bne @done
	lda player_x_lo
	cmp #WH_EXIT_L_L
	bcs @done
@ceil_do:
	lda player_y
	cmp #WH_CEILING
	bcs @done
	lda #WH_CEILING
	sta player_y
	lda #0
	sta player_y_sub
	lda vel_y
	bpl @done
	lda #0
	sta vel_y
@done:
	rts

; Mario-style run: accelerate / skid / friction, then integrate subpixels.
; vel_x = signed speed in 1/16 px per frame; player_x_sub = 0..15 fraction.
apply_horizontal:
	lda #WALK_MAX
	sta temp                  ; max |vel|
	lda pad1
	and #BTN_B
	beq @gotmax
	lda #RUN_MAX
	sta temp
@gotmax:

	lda pad1
	and #BTN_RIGHT
	bne @right
	lda pad1
	and #BTN_LEFT
	bne @left
	jmp @friction

@right:
	lda #0
	sta facing
	lda vel_x
	bmi @skid_r
	clc
	adc #ACCEL
	bmi @rmax                 ; overflow → clamp
	cmp temp
	bcc @rset
	beq @rset
@rmax:
	lda temp
@rset:
	sta vel_x
	jmp @integrate
@skid_r:
	clc
	adc #SKID
	sta vel_x
	jmp @integrate

@left:
	lda #1
	sta facing
	lda vel_x
	beq @acc_l
	bpl @skid_l
@acc_l:
	lda vel_x
	sec
	sbc #ACCEL
	sta vel_x
	lda temp
	eor #$FF
	clc
	adc #1
	sta temp2                 ; -max
	lda vel_x
	cmp temp2
	bcs @integrate
	lda temp2
	sta vel_x
	jmp @integrate
@skid_l:
	lda vel_x
	sec
	sbc #SKID
	sta vel_x
	jmp @integrate

@friction:
	lda vel_x
	beq @integrate
	bpl @fpos
	clc
	adc #FRICTION
	bmi @fset
	lda #0
	jmp @fset
@fpos:
	sec
	sbc #FRICTION
	bpl @fset
	lda #0
@fset:
	sta vel_x

@integrate:
	; signed 16-bit: (hi:lo) = player_x_sub + vel_x  (subpixel)
	lda player_x_sub
	clc
	adc vel_x
	sta temp                  ; lo
	lda vel_x
	bmi @signneg
	lda #0
	jmp @addhi
@signneg:
	lda #$FF
@addhi:
	adc #0
	sta temp2                 ; hi (sign-extended carry)

	; while (hi:lo) >= 16: lo-=16, x++
@norm_ge:
	lda temp2
	bmi @norm_lt              ; negative → need +16 path
	bne @do_sub16             ; hi>0 ⇒ definitely >= 16
	lda temp
	cmp #16
	bcc @norm_done
@do_sub16:
	lda temp
	sec
	sbc #16
	sta temp
	lda temp2
	sbc #0
	sta temp2
	inc player_x_lo
	bne @norm_ge
	inc player_x_hi
	jmp @norm_ge

	; while (hi:lo) < 0: lo+=16, x--
@norm_lt:
	lda temp
	clc
	adc #16
	sta temp
	lda temp2
	adc #0
	sta temp2
	lda player_x_lo
	sec
	sbc #1
	sta player_x_lo
	lda player_x_hi
	sbc #0
	sta player_x_hi
	jmp @norm_ge

@norm_done:
	lda temp
	sta player_x_sub

	; clamp world X to [8, 496]
	lda player_x_hi
	bmi @hitmin               ; went past 0
	bne @chi
	lda player_x_lo
	cmp #8
	bcs @done
@hitmin:
	lda #0
	sta player_x_hi
	lda #8
	sta player_x_lo
	lda #0
	sta player_x_sub
	sta vel_x
	rts
@chi:
	cmp #2
	bcs @hitmax
	lda player_x_lo
	cmp #241
	bcc @done
@hitmax:
	lda #1
	sta player_x_hi
	lda #240
	sta player_x_lo
	lda #0
	sta player_x_sub
	sta vel_x
@done:
	rts

apply_jump:
	lda pad1_edge
	and #BTN_A
	beq @done
	lda on_ground
	beq @done
	; Hold Down+A on a platform → drop through only that platform
	lda pad1
	and #BTN_DOWN
	beq @normal_jump
	lda player_y
	clc
	adc #PLAYER_H
	cmp #GROUND_TOP_Y
	beq @normal_jump          ; on floor: normal jump
	; remember this platform top; other platforms still solid
	sta drop_ignore_y
	lda #0
	sta on_ground
	sta player_y_sub
	lda #GRAVITY * 4          ; small downward nudge
	sta vel_y
	inc player_y              ; leave platform top
	rts
@normal_jump:
	lda has_package
	bne @carry
	lda #JUMP_V
	jmp @setv
@carry:
	lda #JUMP_V_CARRY         ; heavier while holding box
@setv:
	sta vel_y
	lda #0
	sta on_ground
	sta player_y_sub
	lda #SFX_JUMP
	jsr play_sfx
@done:
	rts

apply_gravity:
	lda on_ground
	beq @air
	lda vel_y
	bmi @air                  ; still rising through platform edge
	lda #0
	sta vel_y
	sta player_y_sub
	rts
@air:
	; Variable jump: release A while rising → soft-cap upward speed (not zero)
	lda vel_y
	bpl @grav                 ; falling / apex
	lda pad1
	and #BTN_A
	bne @grav                 ; holding A → full arc
	lda vel_y
	cmp #JUMP_CUT             ; both negative: unsigned < ⇒ more upward
	bcs @grav
	lda #JUMP_CUT
	sta vel_y
@grav:
	lda vel_y
	clc
	adc #GRAVITY
	sta vel_y
	bmi @integrate            ; still rising, skip fall cap
	cmp #MAX_FALL + 1
	bcc @integrate
	lda #MAX_FALL
	sta vel_y
@integrate:
	; player_y_sub + vel_y → subpixel, carry whole pixels into player_y
	lda player_y_sub
	clc
	adc vel_y
	sta temp
	lda vel_y
	bmi @signneg
	lda #0
	jmp @addhi
@signneg:
	lda #$FF
@addhi:
	adc #0
	sta temp2                 ; hi (sign-extended)

@norm_ge:
	lda temp2
	bmi @norm_lt
	bne @do_sub16
	lda temp
	cmp #16
	bcc @norm_done
@do_sub16:
	lda temp
	sec
	sbc #16
	sta temp
	lda temp2
	sbc #0
	sta temp2
	inc player_y
	jmp @norm_ge

@norm_lt:
	lda temp
	clc
	adc #16
	sta temp
	lda temp2
	adc #0
	sta temp2
	dec player_y
	jmp @norm_ge

@norm_done:
	lda temp
	sta player_y_sub
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
	sta player_y_sub
	lda #1
	sta on_ground
	rts

@plats:
	lda player_x_lo
	sta check_x_lo
	lda player_x_hi
	sta check_x_hi
	lda #PLAYER_W
	sta temp3
	; try each surface: feet in [top, top+8); skip only drop_ignore_y
	jsr try_land_shelf_high
	bcc @1
	jsr accept_platform_land
	bcs @snap
@1:
	jsr try_land_shelf_mid
	bcc @2
	jsr accept_platform_land
	bcs @snap
@2:
	jsr try_land_plat1
	bcc @3
	jsr accept_platform_land
	bcs @snap
@3:
	jsr try_land_plat2
	bcc @done
	jsr accept_platform_land
	bcc @done
@snap:
	; A = platform top Y
	sec
	sbc #PLAYER_H
	sta player_y
	lda #0
	sta vel_y
	sta player_y_sub
	lda #1
	sta on_ground
@done:
	rts

; A = candidate top_y from try_land_*. C=1 accept, C=0 skip (drop-through that shelf)
accept_platform_land:
	cmp drop_ignore_y
	beq @skip
	; landed elsewhere — clear drop-through
	ldx #$FF
	stx drop_ignore_y
	sec
	rts
@skip:
	clc
	rts

; try_land_*: C=1 and A=top_y if feet landing on that surface
try_land_shelf_high:
	lda check_y
	cmp #SHELF_HIGH_Y
	bcc @no
	cmp #SHELF_HIGH_Y + 8
	bcs @no
	jsr x_overlap_shelf_high
	bcc @no
	lda #SHELF_HIGH_Y
	sec
	rts
@no:
	clc
	rts

try_land_shelf_mid:
	lda check_y
	cmp #SHELF_MID_Y
	bcc @no
	cmp #SHELF_MID_Y + 8
	bcs @no
	jsr x_overlap_shelf_mid
	bcc @no
	lda #SHELF_MID_Y
	sec
	rts
@no:
	clc
	rts

try_land_plat1:
	lda check_y
	cmp #PLAT1_Y
	bcc @no
	cmp #PLAT1_Y + 8
	bcs @no
	jsr plat1_x_overlap
	bcc @no
	lda #PLAT1_Y
	sec
	rts
@no:
	clc
	rts

try_land_plat2:
	lda check_y
	cmp #PLAT2_Y
	bcc @no
	cmp #PLAT2_Y + 8
	bcs @no
	jsr plat2_x_overlap
	bcc @no
	lda #PLAT2_Y
	sec
	rts
@no:
	clc
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

; B held while overlapping package → pick up; release B → drop (Mario shell style)
update_package_carry:
	lda has_package
	bne @holding
	; --- not holding: pick up if B down and overlapping ---
	lda pad1
	and #BTN_B
	beq @done
	jsr try_pickup_package
	rts
@holding:
	; --- holding: drop when B released ---
	lda pad1
	and #BTN_B
	bne @done
	jmp drop_package
@done:
	rts

; C not used; sets has_package if AABB overlap with free package
try_pickup_package:
	; Y overlap
	lda player_y
	clc
	adc #PLAYER_H
	cmp package_y
	bcc @no
	lda package_y
	clc
	adc #PKG_H
	sta temp
	lda player_y
	cmp temp
	bcs @no
	; X: player_x < package_x + PKG_W
	lda package_x_lo
	clc
	adc #PKG_W
	sta temp
	lda package_x_hi
	adc #0
	sta temp_hi
	lda player_x_hi
	cmp temp_hi
	bcc @chk_r
	bne @no
	lda player_x_lo
	cmp temp
	bcs @no
@chk_r:
	; player_x + PLAYER_W > package_x
	lda player_x_lo
	clc
	adc #PLAYER_W
	sta temp
	lda player_x_hi
	adc #0
	sta temp_hi
	lda temp_hi
	cmp package_x_hi
	bcc @no
	bne @yes
	lda temp
	cmp package_x_lo
	bcc @no
	beq @no
@yes:
	lda #1
	sta has_package
	lda #SFX_PICKUP
	jsr play_sfx
@no:
	rts

; Release package beside player with inherited velocity
; Hold Up on release → also pitch upward (plus forward from facing/run)
drop_package:
	lda player_y
	clc
	adc #(PLAYER_H - PKG_H)
	sta package_y
	lda #0
	sta package_x_sub
	sta package_y_sub
	sta package_on_ground
	; inherit downward velocity only (don't keep player's jump vel by default)
	lda vel_y
	bpl @inhy
	lda #0
@inhy:
	sta package_vel_y
	; Up held → toss into the air
	lda pad1
	and #BTN_UP
	beq @no_up
	lda #PKG_TOSS_UP
	sta package_vel_y
	; spawn a bit higher so it clears the player's head/shelf
	lda package_y
	sec
	sbc #8
	bcs @yok
	lda #0
@yok:
	sta package_y
@no_up:
	lda vel_x
	sta package_vel_x
	lda facing
	bne @drop_l
	lda package_vel_x
	clc
	adc #PKG_THROW
	sta package_vel_x
	lda player_x_lo
	clc
	adc #PLAYER_W
	sta package_x_lo
	lda player_x_hi
	adc #0
	sta package_x_hi
	jmp @clear
@drop_l:
	lda package_vel_x
	sec
	sbc #PKG_THROW
	sta package_vel_x
	lda player_x_lo
	sec
	sbc #PKG_W
	sta package_x_lo
	lda player_x_hi
	sbc #0
	sta package_x_hi
	bpl @clear
	lda #0
	sta package_x_lo
	sta package_x_hi
@clear:
	lda #0
	sta has_package
	lda #SFX_DROP
	jsr play_sfx
	rts

; Free package: horizontal coast/throw + gravity + land
update_free_package:
	lda has_package
	beq @run
	rts
@run:
	; Ground friction on X (air keeps full throw speed)
	lda package_on_ground
	beq @x_move
	lda package_vel_x
	beq @x_move
	bpl @xfric_pos
	clc
	adc #FRICTION
	bmi @xfric_set
	lda #0
	jmp @xfric_set
@xfric_pos:
	sec
	sbc #FRICTION
	bpl @xfric_set
	lda #0
@xfric_set:
	sta package_vel_x
@x_move:
	jsr package_integrate_x
	jsr package_collide_walls

	; Vertical: rest on ground unless falling / walked off
	lda package_on_ground
	beq @air
	jsr package_probe_support
	lda package_on_ground
	beq @air
	lda package_vel_y
	bmi @air
	lda #0
	sta package_vel_y
	sta package_y_sub
	rts
@air:
	lda package_vel_y
	clc
	adc #GRAVITY
	sta package_vel_y
	bmi @y_int
	cmp #MAX_FALL + 1
	bcc @y_int
	lda #MAX_FALL
	sta package_vel_y
@y_int:
	jsr package_integrate_y

	; Land only when moving down / resting
	lda package_vel_y
	bpl @land
	rts
@land:
	lda package_y
	clc
	adc #PKG_H
	sta check_y

	cmp #GROUND_TOP_Y
	bcc @plats
	lda #GROUND_TOP_Y - PKG_H
	sta package_y
	jmp package_landed

@plats:
	lda package_x_lo
	sta check_x_lo
	lda package_x_hi
	sta check_x_hi
	lda #PKG_W
	sta temp3
	jsr try_land_shelf_high
	bcs @snap
	jsr try_land_shelf_mid
	bcs @snap
	jsr try_land_plat1
	bcs @snap
	jsr try_land_plat2
	bcs @snap
	rts
@snap:
	sec
	sbc #PKG_H
	sta package_y
	jmp package_landed

package_landed:
	lda #0
	sta package_vel_y
	sta package_y_sub
	lda #1
	sta package_on_ground
	lda #SFX_HIT
	jsr play_sfx
	rts

; Package vs warehouse walls/ceiling (same rules as player)
package_collide_walls:
	; left wall
	lda package_x_hi
	bne @exit
	lda package_x_lo
	cmp #WH_LEFT
	bcs @exit
	lda #WH_LEFT
	sta package_x_lo
	lda #0
	sta package_x_sub
	lda package_vel_x
	bpl @exit
	lda #0
	sta package_vel_x
@exit:
	; exit pillar solid above door
	lda package_x_hi
	cmp #WH_EXIT_L_H
	bne @ceil
	lda package_x_lo
	cmp #WH_EXIT_R_L
	bcs @ceil
	clc
	adc #PKG_W
	cmp #WH_EXIT_L_L + 1
	bcc @ceil
	lda package_y
	cmp #WH_DOOR_TOP
	bcs @ceil
	lda #WH_EXIT_L_L
	sec
	sbc #PKG_W
	sta package_x_lo
	lda #WH_EXIT_L_H
	sta package_x_hi
	lda #0
	sta package_x_sub
	sta package_vel_x
@ceil:
	lda package_x_hi
	cmp #WH_EXIT_L_H
	bcc @ceil_do
	bne @done
	lda package_x_lo
	cmp #WH_EXIT_L_L
	bcs @done
@ceil_do:
	lda package_y
	cmp #WH_CEILING
	bcs @done
	lda #WH_CEILING
	sta package_y
	lda #0
	sta package_y_sub
	lda package_vel_y
	bpl @done
	lda #0
	sta package_vel_y
@done:
	rts

; Clear package_on_ground if feet no longer on a surface
package_probe_support:
	lda package_y
	clc
	adc #PKG_H
	sta check_y
	cmp #GROUND_TOP_Y
	bne @plats
	rts
@plats:
	lda package_x_lo
	sta check_x_lo
	lda package_x_hi
	sta check_x_hi
	lda #PKG_W
	sta temp3
	jsr feet_on_any_platform
	bcs @ok
	lda #0
	sta package_on_ground
@ok:
	rts

; Integrate package_x_sub += package_vel_x (1/16 px), update package_x_*
package_integrate_x:
	lda package_x_sub
	clc
	adc package_vel_x
	sta temp
	lda package_vel_x
	bmi @sxn
	lda #0
	jmp @sxh
@sxn:
	lda #$FF
@sxh:
	adc #0
	sta temp2
@xge:
	lda temp2
	bmi @xlt
	bne @xsub16
	lda temp
	cmp #16
	bcc @xdone
@xsub16:
	lda temp
	sec
	sbc #16
	sta temp
	lda temp2
	sbc #0
	sta temp2
	inc package_x_lo
	bne @xge
	inc package_x_hi
	jmp @xge
@xlt:
	lda temp
	clc
	adc #16
	sta temp
	lda temp2
	adc #0
	sta temp2
	lda package_x_lo
	sec
	sbc #1
	sta package_x_lo
	lda package_x_hi
	sbc #0
	sta package_x_hi
	jmp @xge
@xdone:
	lda temp
	sta package_x_sub
	; clamp world X to [0, 500]
	lda package_x_hi
	bmi @xmin
	bne @xhi
	rts
@xmin:
	lda #0
	sta package_x_hi
	sta package_x_lo
	sta package_x_sub
	sta package_vel_x
	rts
@xhi:
	cmp #2
	bcc @xok
	lda #1
	sta package_x_hi
	lda #244                 ; 500-256
	sta package_x_lo
	lda #0
	sta package_x_sub
	sta package_vel_x
@xok:
	rts

; Integrate package_y_sub += package_vel_y
package_integrate_y:
	lda package_y_sub
	clc
	adc package_vel_y
	sta temp
	lda package_vel_y
	bmi @syn
	lda #0
	jmp @syh
@syn:
	lda #$FF
@syh:
	adc #0
	sta temp2
@yge:
	lda temp2
	bmi @ylt
	bne @ysub16
	lda temp
	cmp #16
	bcc @ydone
@ysub16:
	lda temp
	sec
	sbc #16
	sta temp
	lda temp2
	sbc #0
	sta temp2
	inc package_y
	jmp @yge
@ylt:
	lda temp
	clc
	adc #16
	sta temp
	lda temp2
	adc #0
	sta temp2
	dec package_y
	jmp @yge
@ydone:
	lda temp
	sta package_y_sub
	rts

check_truck:
	; Win: carrying, on ground, overlapping truck just outside warehouse exit
	lda has_package
	beq @done
	lda on_ground
	beq @done
	lda player_x_hi
	cmp #TRUCK_LEFT_H
	bne @done
	lda player_x_lo
	cmp #TRUCK_LEFT_L - PLAYER_W   ; reach truck left (416)
	bcc @done
	cmp #TRUCK_RIGHT_L               ; past truck right (480)
	bcs @done
	lda #SFX_WIN
	jsr play_sfx
	jsr enter_win
@done:
	rts

; -------------------------
; Level timer (20s)
; -------------------------
update_timer:
	lda timer_sec
	beq @to
	dec timer_frames
	bne @done
	lda #FRAMES_PER_SEC
	sta timer_frames
	dec timer_sec
	bne @done
@to:
	lda #SFX_TIMEOUT
	jsr play_sfx
	jmp enter_timeout
@done:
	rts

; A=0..99 → A=tens, temp=ones. Preserves X (critical: callers hold oam_idx in X).
div10:
	ldy #0                  ; tens counter in Y — do not touch X
@loop:
	cmp #10
	bcc @done
	sec
	sbc #10
	iny
	jmp @loop
@done:
	sta temp                ; ones
	tya                     ; tens
	rts

digit_to_tile:
	clc
	adc #T_DIGIT0
	rts

draw_timer_hud:
	ldx oam_idx
	lda timer_sec
	jsr div10               ; must preserve X = oam_idx
	sta temp2               ; tens
	; tens digit
	lda #16
	sta oam_shadow, x
	lda temp2
	jsr digit_to_tile
	sta oam_shadow+1, x
	lda #%00000000
	sta oam_shadow+2, x
	lda #216
	sta oam_shadow+3, x
	; ones
	lda #16
	sta oam_shadow+4, x
	lda temp
	jsr digit_to_tile
	sta oam_shadow+5, x
	lda #%00000000
	sta oam_shadow+6, x
	lda #224
	sta oam_shadow+7, x
	txa
	clc
	adc #8
	sta oam_idx
	rts

; -------------------------
; Timeout: pan to exit, truck pulls away, then fail
; -------------------------
enter_timeout:
	lda #STATE_TIMEOUT
	sta game_state
	lda #0
	sta truck_drive
	sta timer_sec
	; Erase parked BG truck so sprite truck can leave
	jsr wait_nmi_safe
	lda #$00
	sta PPUMASK
	jsr erase_truck_bg
	jsr wait_vblank
	lda #%10000000
	sta ppuctrl_nt
	sta PPUCTRL
	lda scroll_lo
	sta PPUSCROLL
	lda #$00
	sta PPUSCROLL
	lda #%00011110
	sta PPUMASK
	rts

erase_truck_bg:
	; Clear NT1 cols 20-27, rows 18-21 to sky (same cells draw_truck wrote)
	bit PPUSTATUS
	ldx #0                  ; row index 0..3
@row:
	txa
	sta temp
	; addr lo = (18+row)*32+20 = $54 + row*$20
	lda #$54
	sta temp2
	ldy temp
	beq @addr
@add:
	lda temp2
	clc
	adc #$20
	sta temp2
	dey
	bne @add
@addr:
	lda #$26
	sta PPUADDR
	lda temp2
	sta PPUADDR
	ldy #8
	lda #T_SKY
@col:
	sta PPUDATA
	dey
	bne @col
	inx
	cpx #4
	bcc @row
	rts

update_timeout:
	; Pan scroll toward max (256) if not there yet
	lda scroll_hi
	cmp #1
	bne @pan
	lda scroll_lo
	beq @drive
@pan:
	lda scroll_lo
	clc
	adc #PAN_SPEED
	sta scroll_lo
	lda scroll_hi
	adc #0
	sta scroll_hi
	; clamp to 256
	cmp #1
	bcc @setnt
	lda #0
	sta scroll_lo
	lda #1
	sta scroll_hi
	jmp @setnt
@drive:
	lda truck_drive
	clc
	adc #TRUCK_DRIVE_SPD
	sta truck_drive
	cmp #TRUCK_DRIVE_MAX
	bcc @setnt
	jmp enter_fail
@setnt:
	lda #%10000000
	ldx scroll_hi
	beq @pp
	ora #$01
@pp:
	sta ppuctrl_nt

	jsr hide_all_sprites
	lda #0
	sta oam_idx
	jsr draw_departing_truck
	jsr draw_timer_hud
	rts

; Sprite truck at world X = TRUCK_LEFT + truck_drive (8×4 tiles, pal 3)
; Columns that would wrap past X=255 are skipped (no wrap to left edge).
draw_departing_truck:
	; world_lo/hi
	lda #TRUCK_LEFT_L
	clc
	adc truck_drive
	sta temp3               ; world lo
	lda #TRUCK_LEFT_H
	adc #0
	sta temp_hi             ; world hi
	; screen x = world - scroll (16-bit)
	lda temp3
	sec
	sbc scroll_lo
	sta temp                ; base screen X lo
	lda temp_hi
	sbc scroll_hi
	sta temp_hi             ; base screen X hi (0 = on/near screen, $FF = off left, ≥1 = off right)
	bmi @done               ; entirely off left
	bne @done               ; base past right edge
	; draw 4 rows × 8 tiles; skip any col whose X would wrap (C=1 on adc)
	ldx oam_idx
	lda #0
	sta temp2               ; tile index within truck (0..31)
	lda #TRUCK_TOP_Y
	sta check_y             ; current row Y
@row:
	lda #0
	sta temp3               ; col 0..7
@col:
	; X = base + col*8 — if carry set, sprite would wrap to left; hide it
	lda temp3
	asl a
	asl a
	asl a
	clc
	adc temp
	bcs @skip               ; past right edge of screen
	sta oam_shadow+3, x
	; Y
	lda check_y
	sta oam_shadow, x
	; tile
	lda temp2
	clc
	adc #T_DELIVERY_TRUCK
	sta oam_shadow+1, x
	; attr pal 3
	lda #%00000011
	sta oam_shadow+2, x
	txa
	clc
	adc #4
	tax
@skip:
	inc temp2
	inc temp3
	lda temp3
	cmp #TRUCK_W_TILES
	bcc @col
	lda check_y
	clc
	adc #8
	sta check_y
	lda temp2
	cmp #TRUCK_W_TILES * TRUCK_H_TILES
	bcc @row
	stx oam_idx
@done:
	rts

; -------------------------
; Fail screen (after truck leaves)
; -------------------------
enter_fail:
	lda #STATE_FAIL
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

	lda #$21
	sta str_nt_hi
	lda #$8B
	sta str_nt_lo
	lda #<str_fail
	sta ptr_lo
	lda #>str_fail
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

update_fail:
	jsr hide_all_sprites
	lda pad1_edge
	and #BTN_START
	beq @done
	jsr enter_title
@done:
	rts

draw_play_sprites:
	jsr hide_all_sprites
	lda #0
	sta oam_idx

	; Held package first → lower OAM index = drawn in front of player
	lda has_package
	beq @pick_player
	jsr draw_held_package

@pick_player:
	; choose metasprite (walk if any horizontal velocity)
	lda facing
	bne @face_l
	lda vel_x
	beq @idle_r
@walk_r:
	jsr advance_walk_anim
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
@idle_r:
	lda #<player_idle_metasprite
	sta metasprite_ptr_lo
	lda #>player_idle_metasprite
	sta metasprite_ptr_hi
	jmp @draw_p
@face_l:
	lda vel_x
	beq @idle_l
@walk_l:
	jsr advance_walk_anim
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
	jmp @draw_p
@idle_l:
	lda #<player_idle_flip
	sta metasprite_ptr_lo
	lda #>player_idle_flip
	sta metasprite_ptr_hi
@draw_p:
	lda player_y
	sta temp2
	lda screen_x
	sta temp
	jsr draw_metasprite

	; World package only while not carrying
	lda has_package
	bne @fork
	jsr draw_world_package
@fork:
	jsr draw_forklifts
	rts

; Advance walk cycle; 2x when holding B (run). Frozen while paused.
advance_walk_anim:
	lda game_state
	cmp #STATE_PAUSE
	beq @done
	inc anim_frame
	lda pad1
	and #BTN_B
	beq @done
	inc anim_frame
@done:
	rts

; 12x12 package: 4 sprites (TL/TR/BL/BR tiles). Transparent padding in TR/BL/BR.
; temp = screen X of top-left, temp2 = screen Y of top-left
draw_package_sprites:
	ldx oam_idx
	; TL
	lda temp2
	sta oam_shadow, x
	lda #T_PACKAGE
	sta oam_shadow+1, x
	lda #%00000001          ; palette 1
	sta oam_shadow+2, x
	lda temp
	sta oam_shadow+3, x
	; TR
	lda temp2
	sta oam_shadow+4, x
	lda #T_PACKAGE_TR
	sta oam_shadow+5, x
	lda #%00000001
	sta oam_shadow+6, x
	lda temp
	clc
	adc #8
	sta oam_shadow+7, x
	; BL
	lda temp2
	clc
	adc #8
	sta oam_shadow+8, x
	lda #T_PACKAGE_BL
	sta oam_shadow+9, x
	lda #%00000001
	sta oam_shadow+10, x
	lda temp
	sta oam_shadow+11, x
	; BR
	lda temp2
	clc
	adc #8
	sta oam_shadow+12, x
	lda #T_PACKAGE_BR
	sta oam_shadow+13, x
	lda #%00000001
	sta oam_shadow+14, x
	lda temp
	clc
	adc #8
	sta oam_shadow+15, x
	txa
	clc
	adc #16
	sta oam_idx
	rts

draw_held_package:
	; Carry mid-body (chest/arms), slightly forward by facing
	; Player 16px tall; 12x12 box at +2 sits in torso, drawn first so it is in front
	lda player_y
	clc
	adc #2
	sta temp2
	lda facing
	bne @face_l
	lda screen_x
	clc
	adc #7                  ; in front when facing right
	jmp @xset
@face_l:
	lda screen_x
	sec
	sbc #3                  ; in front when facing left
	bcs @xset
	lda #0
@xset:
	sta temp
	jmp draw_package_sprites

draw_world_package:
	; screen x = package world X - scroll (visible when result in 0..255)
	lda package_x_lo
	sec
	sbc scroll_lo
	sta temp
	lda package_x_hi
	sbc scroll_hi
	bne @offscreen
	lda package_y
	sta temp2
	jmp draw_package_sprites
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

	; Attributes both NT to palette 0 first, then truck (palette 3)
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

	; Draw truck last so its palette-3 attributes are not wiped
	jsr draw_truck
	rts

; A = nametable hi ($20 or $24)
fill_ground_nt:
	sta temp_hi
	; row 22: ground top — addr = nt + 22*32 = nt + $2C0
	lda temp_hi
	clc
	adc #2
	sta PPUADDR             ; $22 or $26
	lda #$C0
	sta PPUADDR
	ldx #32
	lda #T_GROUND_TOP
@top:
	sta PPUDATA
	dex
	bne @top
	; rows 23-29: fill (7 rows)
	ldy #7
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

; Set PPUADDR to NT0 row X, col 0. X in register X.
pp_row_nt0:
	stx temp
	lda #0
	sta temp_hi
	ldy #5
@sh:
	asl temp
	rol temp_hi
	dey
	bne @sh
	lda temp_hi
	clc
	adc #$20
	sta PPUADDR
	lda temp
	sta PPUADDR
	rts

draw_warehouse:
	; Expanded warehouse: ceiling across NT0 + NT1 cols 0-17 (to exit at world 400),
	; left wall, exit pillar NT1 cols 18-19, interior shelves. Truck drawn outside door.
	bit PPUSTATUS

	; Ceiling row 5 full NT0
	lda #$20
	sta PPUADDR
	lda #$A0
	sta PPUADDR
	ldx #32
	lda #T_BRICK
@c0:
	sta PPUDATA
	dex
	bne @c0
	; Ceiling row 5 NT1 cols 0-17 (world 256-400)
	lda #$24
	sta PPUADDR
	lda #$A0
	sta PPUADDR
	ldx #18
	lda #T_BRICK
@c1:
	sta PPUDATA
	dex
	bne @c1

	; ACME signboard on roof (rows 2-4, cols 4-9)
	lda #$20
	sta PPUADDR
	lda #$44
	sta PPUADDR
	ldx #6
	lda #T_BRICK
@sign_top:
	sta PPUDATA
	dex
	bne @sign_top
	lda #$20
	sta PPUADDR
	lda #$64
	sta PPUADDR
	lda #T_BRICK
	sta PPUDATA
	lda #T_FONT + 1
	sta PPUDATA
	lda #T_FONT + 3
	sta PPUDATA
	lda #T_FONT + 13
	sta PPUDATA
	lda #T_FONT + 5
	sta PPUDATA
	lda #T_BRICK
	sta PPUDATA
	lda #$20
	sta PPUADDR
	lda #$84
	sta PPUADDR
	ldx #6
	lda #T_BRICK
@sign_bot:
	sta PPUDATA
	dex
	bne @sign_bot

	; Left wall cols 0-1, rows 6-21
	ldx #6
@left:
	jsr pp_row_nt0
	lda #T_BRICK
	sta PPUDATA
	sta PPUDATA
	inx
	cpx #22
	bcc @left

	; Exit pillar NT1 cols 18-19 (world 400-416), rows 6-17; door open rows 18-21
	ldx #6
@exit_w:
	txa
	sta temp
	lda #0
	sta temp_hi
	ldy #5
@es:
	asl temp
	rol temp_hi
	dey
	bne @es
	lda temp
	clc
	adc #18
	sta temp
	lda temp_hi
	adc #$24
	sta PPUADDR
	lda temp
	sta PPUADDR
	lda #T_BRICK
	sta PPUDATA
	sta PPUDATA
	inx
	cpx #18
	bcc @exit_w

	; Shelves — cols from SHELF_* ; tile count covers full [L,R) even if not 8-aligned:
	;   col = L/8 , count = (R-1)/8 - L/8 + 1
	; High shelf row 13 (y=SHELF_HIGH_Y)
	lda #$21
	sta PPUADDR
	lda #($A0 + SHELF_HIGH_L / 8)   ; 13*32 + col
	sta PPUADDR
	ldx #((SHELF_HIGH_R - 1) / 8 - SHELF_HIGH_L / 8 + 1)
	lda #T_PLATFORM
@sh:
	sta PPUDATA
	dex
	bne @sh

	; Mid shelf row 16 (y=SHELF_MID_Y) — NT0 only (x < 256)
	lda #$22
	sta PPUADDR
	lda #(SHELF_MID_L / 8)          ; 16*32 + col → hi $22, lo = col
	sta PPUADDR
	ldx #((SHELF_MID_R - 1) / 8 - SHELF_MID_L / 8 + 1)
	lda #T_PLATFORM
@sm:
	sta PPUDATA
	dex
	bne @sm
	rts

draw_platform_tiles:
	; Interior bridges deeper in warehouse (before exit)
	bit PPUSTATUS

	; PLAT1: world [PLAT1_L, PLAT1_R), row 18 (y=PLAT1_Y), NT0
	lda #$22
	sta PPUADDR
	lda #($40 + PLAT1_L / 8)        ; 18*32 + col
	sta PPUADDR
	ldx #((PLAT1_R - 1) / 8 - PLAT1_L / 8 + 1)
	lda #T_PLATFORM
@p1:
	sta PPUDATA
	dex
	bne @p1

	; PLAT2: world 320-384, NT1 cols 8-15, row 19 (y=152)
	lda #$26
	sta PPUADDR
	lda #$68                ; 19*32+8
	sta PPUADDR
	ldx #8
	lda #T_PLATFORM
@p2:
	sta PPUDATA
	dex
	bne @p2
	rts

draw_truck:
	; 8x4 truck just outside exit door. NT1 cols 20-27 → world 416-480.
	; Door ends at col 19 (x 416); truck begins col 20.
	; Wheels = attr row5 top (pal3); ground = attr row5 bottom (pal0).
	; $2400 + 18*32 + 20 = $2654
	bit PPUSTATUS
	ldx #0
	; row 18
	lda #$26
	sta PPUADDR
	lda #$54
	sta PPUADDR
@r0:
	txa
	clc
	adc #T_DELIVERY_TRUCK
	sta PPUDATA
	inx
	cpx #8
	bne @r0
	; row 19
	lda #$26
	sta PPUADDR
	lda #$74
	sta PPUADDR
@r1:
	txa
	clc
	adc #T_DELIVERY_TRUCK
	sta PPUDATA
	inx
	cpx #16
	bne @r1
	; row 20
	lda #$26
	sta PPUADDR
	lda #$94
	sta PPUADDR
@r2:
	txa
	clc
	adc #T_DELIVERY_TRUCK
	sta PPUDATA
	inx
	cpx #24
	bne @r2
	; row 21 — wheels sit on ground line
	lda #$26
	sta PPUADDR
	lda #$B4
	sta PPUADDR
@r3:
	txa
	clc
	adc #T_DELIVERY_TRUCK
	sta PPUDATA
	inx
	cpx #32
	bne @r3

	; Palette 3 for truck body (rows 16-19 = attr row 4; 16-17 are sky/color0)
	lda #$27
	sta PPUADDR
	lda #$E5
	sta PPUADDR
	lda #$FF
	sta PPUDATA
	sta PPUDATA
	; Wheels rows 20-21 = top of attr row 5; ground 22-23 = bottom pal0
	lda #$27
	sta PPUADDR
	lda #$ED
	sta PPUADDR
	lda #$0F                ; top L/R = pal 3, bottom L/R = pal 0
	sta PPUDATA
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

; Metasprite at temp2 = pixel Y, temp = screen X
draw_metasprite:
	ldy #0
	ldx oam_idx
@loop:
	lda (metasprite_ptr_lo), y
	cmp #END_METASPRITE
	beq @done
	clc
	adc temp2
	sta oam_shadow, x
	iny
	lda (metasprite_ptr_lo), y
	clc
	adc temp
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

; -------------------------
; Forklift enemies (X = index 0..NUM_FORKLIFTS-1)
; -------------------------
update_forklifts:
	ldx #0
@loop:
	jsr update_one_forklift
	inx
	cpx #NUM_FORKLIFTS
	bcc @loop
	rts

; X = forklift index (preserved)
update_one_forklift:
	; cooldown tick
	lda forklift_cool, x
	beq @move
	dec forklift_cool, x
@move:
	lda forklift_dir, x
	bne @go_left
	; move right
	lda forklift_x_lo, x
	clc
	adc #FORKLIFT_SPD
	sta forklift_x_lo, x
	lda forklift_x_hi, x
	adc #0
	sta forklift_x_hi, x
	; hit max?
	cmp #FORKLIFT_MAX_H
	bcc @maybe_rand
	lda forklift_x_lo, x
	cmp #FORKLIFT_MAX_L
	bcc @maybe_rand
	lda #FORKLIFT_MAX_L
	sta forklift_x_lo, x
	lda #FORKLIFT_MAX_H
	sta forklift_x_hi, x
	lda #1
	sta forklift_dir, x
	lda #0
	sta forklift_dist, x
	jmp @collide
@go_left:
	lda forklift_x_lo, x
	sec
	sbc #FORKLIFT_SPD
	sta forklift_x_lo, x
	lda forklift_x_hi, x
	sbc #0
	sta forklift_x_hi, x
	; hit min? (hi must be 0 and lo < MIN)
	bne @maybe_rand
	lda forklift_x_lo, x
	cmp #FORKLIFT_MIN_X
	bcs @maybe_rand
	lda #FORKLIFT_MIN_X
	sta forklift_x_lo, x
	lda #0
	sta forklift_x_hi, x
	sta forklift_dir, x
	sta forklift_dist, x
	jmp @collide
@maybe_rand:
	; every FORKLIFT_TURN_D px: 25% chance to reverse
	lda forklift_dist, x
	clc
	adc #FORKLIFT_SPD
	sta forklift_dist, x
	cmp #FORKLIFT_TURN_D
	bcc @collide
	lda #0
	sta forklift_dist, x
	jsr rand8
	and #$03                ; 0..3 → 25% when zero
	bne @collide
	lda forklift_dir, x
	eor #1
	sta forklift_dir, x
@collide:
	; skip if cooldown
	lda forklift_cool, x
	bne @done
	jsr forklift_hit_player
@done:
	rts

; 8-bit Galois LFSR; returns next value in A (and rng). Preserves X.
rand8:
	lda rng
	beq @reseed             ; never stay stuck at 0
	asl
	bcc @store
	eor #$1D
@store:
	sta rng
	rts
@reseed:
	lda #$A5
	bne @store              ; always branch

; AABB player vs forklift X; if overlap and carrying, knock package away
; X = forklift index (preserved)
forklift_hit_player:
	; Y: player feet below forklift top, player top above forklift bottom
	; forklift Y is fixed FORKLIFT_Y
	lda player_y
	clc
	adc #PLAYER_H
	cmp #FORKLIFT_Y
	bcc @no                 ; player entirely above forklift
	lda #FORKLIFT_Y
	clc
	adc #FORKLIFT_H
	sta temp
	lda player_y
	cmp temp
	bcs @no                 ; player entirely below forklift
	; X: player_x < forklift_x + W
	lda forklift_x_lo, x
	clc
	adc #FORKLIFT_W
	sta temp
	lda forklift_x_hi, x
	adc #0
	sta temp_hi
	lda player_x_hi
	cmp temp_hi
	bcc @chk_r
	bne @no
	lda player_x_lo
	cmp temp
	bcs @no
@chk_r:
	; player_x + PLAYER_W > forklift_x
	lda player_x_lo
	clc
	adc #PLAYER_W
	sta temp
	lda player_x_hi
	adc #0
	sta temp_hi
	lda temp_hi
	cmp forklift_x_hi, x
	bcc @no
	bne @hit
	lda temp
	cmp forklift_x_lo, x
	bcc @no
	beq @no
@hit:
	; only knock if player has the package
	lda has_package
	beq @no
	jsr forklift_knock_package
	lda #FORKLIFT_COOL
	sta forklift_cool, x
@no:
	rts

; Drop package 24px away from forklift X (on the player's side)
; X = forklift index (preserved)
forklift_knock_package:
	lda #0
	sta has_package
	sta package_x_sub
	sta package_y_sub
	; package on floor
	lda #GROUND_TOP_Y - PKG_H
	sta package_y
	lda #1
	sta package_on_ground
	lda #0
	sta package_vel_y
	; which side is the player relative to forklift?
	; if player_x >= forklift_x → knock right: forklift_x + W + KNOCK
	; else knock left: forklift_x - KNOCK - PKG_W
	lda player_x_hi
	cmp forklift_x_hi, x
	bcc @knock_l
	bne @knock_r
	lda player_x_lo
	cmp forklift_x_lo, x
	bcc @knock_l
@knock_r:
	; package_x = forklift_x + FORKLIFT_W + FORKLIFT_KNOCK
	lda forklift_x_lo, x
	clc
	adc #FORKLIFT_W
	sta temp
	lda forklift_x_hi, x
	adc #0
	sta temp_hi
	lda temp
	clc
	adc #FORKLIFT_KNOCK
	sta package_x_lo
	lda temp_hi
	adc #0
	sta package_x_hi
	lda #$20                ; small right toss (1/16 px units)
	sta package_vel_x
	jmp @sfx
@knock_l:
	; package_x = forklift_x - FORKLIFT_KNOCK - PKG_W
	lda forklift_x_lo, x
	sec
	sbc #FORKLIFT_KNOCK
	sta temp
	lda forklift_x_hi, x
	sbc #0
	sta temp_hi
	lda temp
	sec
	sbc #PKG_W
	sta package_x_lo
	lda temp_hi
	sbc #0
	sta package_x_hi
	bpl @l_vel
	lda #0
	sta package_x_lo
	sta package_x_hi
@l_vel:
	lda #$E0                ; small left toss
	sta package_vel_x
@sfx:
	lda #0
	sta package_on_ground   ; allow brief slide before settling
	lda #SFX_HIT
	jsr play_sfx
	rts

draw_forklifts:
	ldx #0
@loop:
	jsr draw_one_forklift
	inx
	cpx #NUM_FORKLIFTS
	bcc @loop
	rts

; X = forklift index (preserved)
draw_one_forklift:
	; screen x = forklift world - scroll
	lda forklift_x_lo, x
	sec
	sbc scroll_lo
	sta temp
	lda forklift_x_hi, x
	sbc scroll_hi
	bne @off                ; left of camera or ≥256 px right
	; NES sprite X is 8-bit and wraps: hide if any tile would cross 256
	lda temp
	cmp #256 - FORKLIFT_W   ; 240
	bcs @off
	lda #FORKLIFT_Y
	sta temp2
	lda forklift_dir, x
	bne @flip
	lda #<forklift_metasprite
	sta metasprite_ptr_lo
	lda #>forklift_metasprite
	sta metasprite_ptr_hi
	jmp @draw
@flip:
	lda #<forklift_metasprite_flip
	sta metasprite_ptr_lo
	lda #>forklift_metasprite_flip
	sta metasprite_ptr_hi
@draw:
	txa
	pha                     ; draw_metasprite uses X for OAM
	jsr draw_metasprite
	pla
	tax
@off:
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

; -------------------------
; Sound (pulse1 + noise SFX)
; -------------------------
init_apu:
	lda #$40
	sta APU_FRAME             ; 4-step sequence, disable frame IRQ
	lda #0
	sta APU_STATUS            ; silence all
	; zero pulse/noise regs
	sta APU_PULSE1_VOL
	sta APU_PULSE1_SWEEP
	sta APU_PULSE1_LO
	sta APU_PULSE1_HI
	sta APU_NOISE_VOL
	sta APU_NOISE_LO
	sta APU_NOISE_HI
	lda #%00001001            ; enable pulse1 + noise
	sta APU_STATUS
	lda #0
	sta sfx_queue
	sta sfx_timer
	sta sfx_pos
	rts

; A = SFX_* id — queues (interrupts current on next update_sfx)
play_sfx:
	sta sfx_queue
	rts

update_sfx:
	lda sfx_queue
	beq @tick
	; start new sequence
	asl a
	tax
	lda sfx_table, x
	sta sfx_ptr_lo
	lda sfx_table+1, x
	sta sfx_ptr_hi
	lda #0
	sta sfx_queue
	sta sfx_pos
	sta sfx_timer
	jsr sfx_load_step
	rts
@tick:
	lda sfx_timer
	beq @done
	dec sfx_timer
	bne @done
	jsr sfx_load_step
@done:
	rts

; Load next step from (sfx_ptr) at sfx_pos. $FF ends and silences.
sfx_load_step:
	lda sfx_ptr_hi
	ora sfx_ptr_lo
	beq @silence              ; no active sequence
	ldy sfx_pos
	lda (sfx_ptr_lo), y
	cmp #$FF
	beq @silence
	cmp #0
	bne @noise
	; pulse1: vol, sweep, period_lo, $4003, duration
	iny
	lda (sfx_ptr_lo), y
	sta APU_PULSE1_VOL
	iny
	lda (sfx_ptr_lo), y
	sta APU_PULSE1_SWEEP
	iny
	lda (sfx_ptr_lo), y
	sta APU_PULSE1_LO
	iny
	lda (sfx_ptr_lo), y
	sta APU_PULSE1_HI
	iny
	lda (sfx_ptr_lo), y
	sta sfx_timer
	iny
	sty sfx_pos
	rts
@noise:
	iny
	lda (sfx_ptr_lo), y
	sta APU_NOISE_VOL
	iny
	lda (sfx_ptr_lo), y
	sta APU_NOISE_LO
	iny
	lda (sfx_ptr_lo), y
	sta APU_NOISE_HI
	iny
	lda (sfx_ptr_lo), y
	sta sfx_timer
	iny
	sty sfx_pos
	rts
@silence:
	lda #$30                  ; const vol 0
	sta APU_PULSE1_VOL
	sta APU_NOISE_VOL
	lda #0
	sta APU_PULSE1_SWEEP      ; stop any pitch glide
	sta sfx_timer
	sta sfx_ptr_lo
	sta sfx_ptr_hi
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
