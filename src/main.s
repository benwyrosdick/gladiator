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
STATE_PAUSE = 3

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

; Warehouse geometry (NT0 / world X 0-127)
WH_LEFT       = 16          ; left wall solid x < 16 (cols 0-1)
WH_RIGHT_L    = 96          ; right wall cols 12-13 → x 96-112
WH_RIGHT_R    = 112
WH_DOOR_TOP   = 144         ; open doorway for y >= 144 (tile rows 18+)
WH_CEILING    = 40          ; bottom of ceiling (row 5 → y 40)

; Climbable shelves (platform tops), ~24px steps (within jump height)
; X ranges leave gaps from walls so you can drop off a side
SHELF_LOW_Y   = 152         ; row 19, x 24-64 (cols 3-7)
SHELF_MID_Y   = 128         ; row 16, x 48-88 (cols 6-10)
SHELF_HIGH_Y  = 104         ; row 13, x 32-72 (cols 4-8) — package here
SHELF_LOW_L   = 24
SHELF_LOW_R   = 64
SHELF_MID_L   = 48
SHELF_MID_R   = 88
SHELF_HIGH_L  = 32
SHELF_HIGH_R  = 72

; Outdoor platforms
PLAT1_Y       = 144         ; row 18, world x 160-224
PLAT2_Y       = 152         ; row 19, world x 320-384

PKG_W         = 12
PKG_H         = 12
PKG_WORLD_X_L = 44          ; on high shelf center
PKG_WORLD_X_H = 0
PKG_WORLD_Y   = SHELF_HIGH_Y - PKG_H   ; 84
PKG_THROW     = $04          ; extra horizontal toss on drop (0.25 px/f)
PKG_TOSS_UP   = $D0          ; -48 (1/16 px) ≈ -3 px/f upward when holding Up on release

; Truck BG tiles: NT1 cols 22-27 → world X 432-480 (hi=$01)
TRUCK_LEFT_L  = $B0         ; 256+176=432
TRUCK_LEFT_H  = $01
TRUCK_RIGHT_L = $E0         ; 256+224=480
TRUCK_RIGHT_H = $01

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
; sky (empty)
sky_tile:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; player (original gladiator art)
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

ground_top_tile:
	.byte $FF,$FF,$AA,$55,$AA,$55,$FF,$FF,$00,$FF,$55,$AA,$55,$AA,$FF,$FF
ground_fill_tile:
	.byte $AA,$55,$AA,$55,$AA,$55,$AA,$55,$55,$AA,$55,$AA,$55,$AA,$55,$AA
brick_tile:
	.byte $FF,$81,$BD,$BD,$FF,$DB,$DB,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; platform — full 8x8 solid ledge (white top, blue body; always visible on black sky)
platform_tile:
	.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
; package 12x12 (TL/TR/BL/BR). 0=clear 1=white label 2=cardboard 3=outline
; Label is 4x6 at (2,2) inside the box
package_tiles:
	.byte $FF,$80,$BC,$BC,$BC,$BC,$BC,$BC,$FF,$FF,$C3,$C3,$C3,$C3,$C3,$C3  ; TL
	.byte $F0,$10,$10,$10,$10,$10,$10,$10,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0  ; TR
	.byte $80,$80,$80,$FF,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$00  ; BL
	.byte $10,$10,$10,$F0,$00,$00,$00,$00,$F0,$F0,$F0,$F0,$00,$00,$00,$00  ; BR
; title flat shipping box 6x3 — front view
; 0=black outline/icons  1=light panel+label  2=cardboard  3=red tape/border
title_package_tiles:
	.byte $03,$04,$08,$10,$20,$40,$FF,$80,$00,$03,$07,$0F,$1F,$3F,$00,$7F  ; 0
	.byte $FF,$00,$00,$00,$00,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF  ; 1
	.byte $FF,$01,$03,$07,$0F,$1F,$FF,$3F,$00,$FF,$FF,$FF,$FF,$FF,$3F,$FF  ; 2
	.byte $FF,$F8,$F0,$E0,$C0,$80,$FF,$00,$FC,$FF,$FF,$FF,$FF,$FF,$00,$FF  ; 3
	.byte $FF,$00,$00,$00,$00,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF  ; 4
	.byte $FE,$03,$05,$09,$11,$21,$C1,$41,$00,$FC,$FA,$F6,$EE,$DE,$3E,$BE  ; 5
	.byte $80,$80,$80,$80,$80,$80,$BF,$A0,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F  ; 6
	.byte $00,$00,$00,$00,$00,$00,$EF,$28,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 7
	.byte $3F,$3F,$15,$00,$00,$00,$F0,$10,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 8
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 9
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; 10
	.byte $41,$41,$41,$41,$41,$41,$41,$41,$BE,$BE,$BE,$BE,$BE,$BE,$BE,$BE  ; 11
	.byte $A2,$A7,$AF,$A2,$A2,$BF,$80,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$00  ; 12
	.byte $2B,$2A,$A9,$2B,$28,$EF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 13
	.byte $D0,$50,$90,$D0,$10,$F0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 14
	.byte $00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 15
	.byte $00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; 16
	.byte $41,$41,$42,$44,$48,$50,$60,$C0,$BE,$BE,$BC,$B8,$B0,$A0,$80,$00  ; 17
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

; font: space, A-Z, !
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
T_FONT             = (font_space - tiles) / 16
; font relative: 0=space, 1=A … 26=Z, 27=!

; Metasprite tile aliases (player_s_* labels)
PLAYER_IDLE_0 = T_PLAYER_S_0_IDLE
PLAYER_IDLE_1 = T_PLAYER_S_1_IDLE
PLAYER_IDLE_2 = T_PLAYER_S_2_IDLE
PLAYER_IDLE_3 = T_PLAYER_S_3_IDLE
PLAYER_WALK_2 = T_PLAYER_S_2_WALK
PLAYER_WALK_3 = T_PLAYER_S_3_WALK

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
	.byte $0F, $21, $11, $30   ; sky / white text
	.byte $0F, $37, $27, $16   ; package: light card, body, red tape
	.byte $0F, $00, $10, $20   ; asphalt gray
	.byte $0F, $28, $16, $07   ; truck: yellow, red, dark brown (not color0 — visible on black)

spr_palette:
	.byte $0F, $27, $17, $30   ; player
	.byte $0F, $30, $27, $16   ; package: white label, cardboard, red outline
	.byte $0F, $00, $10, $20
	.byte $0F, $28, $16, $07   ; truck

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
str_acme:
	; A C M E
	.byte 1,3,13,5, $FF
; Sprite tile indices for PAUSED overlay (absolute CHR)
pause_tiles:
	.byte T_FONT+16, T_FONT+1, T_FONT+21, T_FONT+19, T_FONT+5, T_FONT+4
PAUSE_LEN = 6
PAUSE_X0  = 104             ; (256 - 6*8) / 2
PAUSE_Y   = 112

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
	cmp #STATE_PAUSE
	beq @pause
	cmp #STATE_WIN
	beq @win
	jmp main_loop

@title:
	jsr update_title
	jmp main_loop
@play:
	jsr update_play
	jmp main_loop
@pause:
	jsr update_pause
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
	; Flat shipping box 6x3 tiles, rows 9-11, cols 13-18 (centered)
	; $2000 + 9*32 + 13 = $212D
	lda #$21
	sta PPUADDR
	lda #$2D
	sta PPUADDR
	ldx #0
@row0:
	txa
	clc
	adc #T_TITLE_PACKAGE
	sta PPUDATA
	inx
	cpx #6
	bne @row0

	lda #$21
	sta PPUADDR
	lda #$4D                ; row 10, col 13
	sta PPUADDR
@row1:
	txa
	clc
	adc #T_TITLE_PACKAGE
	sta PPUDATA
	inx
	cpx #12
	bne @row1

	lda #$21
	sta PPUADDR
	lda #$6D                ; row 11, col 13
	sta PPUADDR
@row2:
	txa
	clc
	adc #T_TITLE_PACKAGE
	sta PPUDATA
	inx
	cpx #18
	bne @row2

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

	; Attributes: box uses palette 1 (light / card / red)
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
	; rows 8-11, cols 12-19 → attr $D3,$D4  (and $D5 for col 20 edge)
	lda #$23
	sta PPUADDR
	lda #$D3
	sta PPUADDR
	lda #$55
	sta PPUDATA
	sta PPUDATA
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
	lda #1
	sta package_on_ground
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
	; Start → pause (edge so we don't immediately unpause)
	lda pad1_edge
	and #BTN_START
	beq @run
	lda #STATE_PAUSE
	sta game_state
	jsr draw_play_sprites
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
	jsr check_truck
	jsr draw_play_sprites
	rts

; Frozen play scene; Start again resumes
update_pause:
	lda pad1_edge
	and #BTN_START
	beq @frozen
	lda #STATE_PLAY
	sta game_state
	jsr draw_play_sprites
	rts
@frozen:
	jsr draw_play_sprites
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
	bne @low
	jsr x_overlap_shelf_mid
	bcs @yes
@low:
	lda check_y
	cmp #SHELF_LOW_Y
	bne @out1
	jsr x_overlap_shelf_low
	bcs @yes
@out1:
	lda check_y
	cmp #PLAT1_Y
	bne @out2
	jsr plat1_x_overlap
	bcs @yes
@out2:
	; outdoor plat 2 may share Y with SHELF_LOW — always test
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

; shelf low [SHELF_LOW_L, SHELF_LOW_R)
x_overlap_shelf_low:
	lda check_x_hi
	bne @no
	lda check_x_lo
	cmp #SHELF_LOW_R
	bcs @no
	clc
	adc temp3
	cmp #SHELF_LOW_L + 1
	bcc @no
	sec
	rts
@no:
	clc
	rts

; outdoor platform 1 [160,224) y=PLAT1_Y
plat1_x_overlap:
	lda check_x_hi
	bne @no
	lda check_x_lo
	cmp #224
	bcs @no
	clc
	adc temp3
	cmp #161
	bcc @no
	sec
	rts
@no:
	clc
	rts

; outdoor platform 2 [320,384) y=PLAT2_Y
plat2_x_overlap:
	lda check_x_hi
	cmp #1
	bne @no
	lda check_x_lo
	cmp #128
	bcs @no
	clc
	adc temp3
	cmp #65
	bcc @no
	sec
	rts
@no:
	clc
	rts

; Warehouse walls + ceiling. Call after horizontal move.
collide_walls:
	; --- left wall: x < WH_LEFT ---
	lda player_x_hi
	bne @right
	lda player_x_lo
	cmp #WH_LEFT
	bcs @right
	lda #WH_LEFT
	sta player_x_lo
	lda #0
	sta player_x_sub
	lda vel_x
	bpl @right
	lda #0
	sta vel_x

@right:
	; --- right wall solid when body overlaps [WH_RIGHT_L, WH_RIGHT_R) x [0, WH_DOOR_TOP) ---
	lda player_x_hi
	bne @ceil
	; player right > wall left && player left < wall right
	lda player_x_lo
	cmp #WH_RIGHT_R
	bcs @ceil
	clc
	adc #PLAYER_W
	cmp #WH_RIGHT_L + 1
	bcc @ceil
	; Y: any part of player above door top (player_y < WH_DOOR_TOP)
	lda player_y
	cmp #WH_DOOR_TOP
	bcs @ceil                 ; fully in doorway height
	; push out based on old position
	lda old_x_lo
	cmp #WH_RIGHT_L
	bcc @push_l
	; from right or inside → push to right of wall
	lda #WH_RIGHT_R
	sta player_x_lo
	jmp @stop_x
@push_l:
	lda #WH_RIGHT_L - PLAYER_W
	sta player_x_lo
@stop_x:
	lda #0
	sta player_x_sub
	sta vel_x

@ceil:
	; ceiling inside warehouse (x < WH_RIGHT_R): keep head below WH_CEILING
	lda player_x_hi
	bne @done
	lda player_x_lo
	cmp #WH_RIGHT_R
	bcs @done
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
	jsr try_land_shelf_low
	bcc @3
	jsr accept_platform_land
	bcs @snap
@3:
	jsr try_land_plat1
	bcc @4
	jsr accept_platform_land
	bcs @snap
@4:
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

try_land_shelf_low:
	lda check_y
	cmp #SHELF_LOW_Y
	bcc @no
	cmp #SHELF_LOW_Y + 8
	bcs @no
	jsr x_overlap_shelf_low
	bcc @no
	lda #SHELF_LOW_Y
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
	jsr try_land_shelf_low
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
	rts

; Package vs warehouse walls/ceiling (same rules as player)
package_collide_walls:
	; left wall
	lda package_x_hi
	bne @right
	lda package_x_lo
	cmp #WH_LEFT
	bcs @right
	lda #WH_LEFT
	sta package_x_lo
	lda #0
	sta package_x_sub
	lda package_vel_x
	bpl @right
	lda #0
	sta package_vel_x
@right:
	; right wall solid above door
	lda package_x_hi
	bne @ceil
	lda package_x_lo
	cmp #WH_RIGHT_R
	bcs @ceil
	clc
	adc #PKG_W
	cmp #WH_RIGHT_L + 1
	bcc @ceil
	lda package_y
	cmp #WH_DOOR_TOP
	bcs @ceil
	; push out: if package center-ish left of wall, push left
	lda package_x_lo
	cmp #WH_RIGHT_L
	bcc @push_l
	lda #WH_RIGHT_R
	sta package_x_lo
	jmp @stop_x
@push_l:
	lda #WH_RIGHT_L
	sec
	sbc #PKG_W
	sta package_x_lo
@stop_x:
	lda #0
	sta package_x_sub
	sta package_vel_x
@ceil:
	lda package_x_hi
	bne @done
	lda package_x_lo
	cmp #WH_RIGHT_R
	bcs @done
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
	; Win only when carrying package, on the ground, and overlapping truck X
	; (jumping over the truck does not count)
	lda has_package
	beq @done
	lda on_ground
	beq @done
	lda player_x_hi
	cmp #TRUCK_LEFT_H
	bne @done
	lda player_x_lo
	cmp #TRUCK_LEFT_L - PLAYER_W   ; 416: player right edge at truck left
	bcc @done
	cmp #TRUCK_RIGHT_L               ; 480: past truck right edge
	bcs @done
	jsr enter_win
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
	jsr draw_metasprite

	; World package only while not carrying
	lda has_package
	bne @done
	jsr draw_world_package
@done:
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
	; Tall warehouse cols 0-13, ceiling row 5, walls rows 6-21
	; Right wall cols 12-13 with doorway rows 18-21 open
	bit PPUSTATUS

	; Ceiling row 5, cols 0-13: $2000+5*32 = $20A0
	lda #$20
	sta PPUADDR
	lda #$A0
	sta PPUADDR
	ldx #14
	lda #T_BRICK
@ceil:
	sta PPUDATA
	dex
	bne @ceil

	; ACME signboard on roof (rows 2-4, cols 4-9)
	; top border
	lda #$20
	sta PPUADDR
	lda #$44                ; row 2 col 4
	sta PPUADDR
	ldx #6
	lda #T_BRICK
@sign_top:
	sta PPUDATA
	dex
	bne @sign_top
	; middle: | A C M E |
	lda #$20
	sta PPUADDR
	lda #$64                ; row 3 col 4
	sta PPUADDR
	lda #T_BRICK
	sta PPUDATA
	lda #T_FONT + 1         ; A
	sta PPUDATA
	lda #T_FONT + 3         ; C
	sta PPUDATA
	lda #T_FONT + 13        ; M
	sta PPUDATA
	lda #T_FONT + 5         ; E
	sta PPUDATA
	lda #T_BRICK
	sta PPUDATA
	; bottom border (rests on ceiling)
	lda #$20
	sta PPUADDR
	lda #$84                ; row 4 col 4
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

	; Right wall cols 12-13, rows 6-17 only (door below)
	ldx #6
@right:
	txa
	pha
	jsr pp_row_nt0
	; advance to col 12: write 12 skies then 2 bricks — or set addr
	pla
	sta temp
	lda #0
	sta temp_hi
	ldy #5
@rs:
	asl temp
	rol temp_hi
	dey
	bne @rs
	lda temp
	clc
	adc #12
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
	cpx #18
	bcc @right

	; Door lintel row 17; opening rows 18-21 empty (sky) down to ground.

	; Shelves with side gaps so you can drop off (match collision X ranges)
	; High shelf row 13 (y=104), cols 4-8 (x 32-72)
	lda #$21
	sta PPUADDR
	lda #$A4                ; 13*32+4 = $1A4 → $21A4
	sta PPUADDR
	ldx #5
	lda #T_PLATFORM
@sh:
	sta PPUDATA
	dex
	bne @sh

	; Mid shelf row 16 (y=128), cols 6-10 (x 48-88)
	lda #$22
	sta PPUADDR
	lda #$06                ; 16*32+6 = $206 → $2206
	sta PPUADDR
	ldx #5
	lda #T_PLATFORM
@sm:
	sta PPUDATA
	dex
	bne @sm

	; Low shelf row 19 (y=152), cols 3-7 (x 24-64)
	lda #$22
	sta PPUADDR
	lda #$63                ; 19*32+3 = $263 → $2263
	sta PPUADDR
	ldx #5
	lda #T_PLATFORM
@sl:
	sta PPUDATA
	dex
	bne @sl
	rts

draw_platform_tiles:
	; Outdoor platforms only (warehouse shelves drawn in draw_warehouse)
	bit PPUSTATUS

	; Platform 1: world px 160-224 (cols 20-27), top at y=144 → tile row 18
	lda #$22
	sta PPUADDR
	lda #$54                ; 18*32+20 = $254
	sta PPUADDR
	ldx #8
	lda #T_PLATFORM
@p1:
	sta PPUDATA
	dex
	bne @p1

	; Platform 2: world px 320-384 (NT1 cols 8-15), top at y=152 → tile row 19
	bit PPUSTATUS
	lda #$26
	sta PPUADDR
	lda #$68                ; 19*32+8 = $268
	sta PPUADDR
	ldx #8
	lda #T_PLATFORM
@p2:
	sta PPUDATA
	dex
	bne @p2
	rts

draw_truck:
	; 8x4 truck, rows 18-21 (bottom y=175 ≈ ground y=176). NT1 cols 20-27.
	; Wheels = attr row5 top (pal3); ground = attr row5 bottom (pal0) — no bleed.
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
