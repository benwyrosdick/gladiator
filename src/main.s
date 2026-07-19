; Gladiator — NROM-128, CHR-RAM
; Build: make  →  build/gladiator.nes

	.setcpu "6502"
	.feature c_comments

; -------------------------
; NES PPU/APU registers
; -------------------------
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUADDR   = $2006
PPUDATA   = $2007

; Tile indices (order of data in the tiles: blob)
BG_TILE_IDX   = $00
PLAYER_IDLE_0 = $01
PLAYER_IDLE_1 = $02
PLAYER_IDLE_2 = $03
PLAYER_IDLE_3 = $04
PLAYER_WALK_2 = $05
PLAYER_WALK_3 = $06
WALL_TILE     = $07
FLOOR_TILE    = $08
PILLAR_TILE   = $09

; Player is 16×16; screen is 256×240
PLAYER_W      = 16
PLAYER_H      = 16
SCREEN_MAX_X  = 256 - PLAYER_W   ; 240
SCREEN_MAX_Y  = 240 - PLAYER_H   ; 224
MAP_W         = 32
MAP_H         = 16               ; rows in arena_map

; -------------------------
; Zero page
; -------------------------
	.segment "ZEROPAGE"
temp:              .res 1
temp_hi:           .res 1
frame_flag:        .res 1   ; set to 1 each NMI (new frame)
pad1:              .res 1   ; controller 1 state
sprite_x:          .res 1
sprite_y:          .res 1
old_x:             .res 1   ; position before move (collision)
old_y:             .res 1
check_x:           .res 1   ; pixel sample for tile test
check_y:           .res 1
anim_frame:        .res 1   ; walking animation counter
metasprite_ptr_lo: .res 1
metasprite_ptr_hi: .res 1

; -------------------------
; Work RAM (OAM shadow at $0200 for $4014 DMA)
; -------------------------
	.segment "BSS"
oam_shadow: .res 256        ; must be first BSS so address is $0200

; -------------------------
; Read-only data
; -------------------------
	.segment "RODATA"

; CHR tiles uploaded to CHR-RAM at $0000 (16 bytes each: 8 plane0 + 8 plane1)
tiles:
bg_tile:
	.byte %11111111, %11111111
	.byte %11111011, %11111111
	.byte %11111111, %11111111
	.byte %11111111, %11111111
	.byte %00000000, %00000000
	.byte %00000100, %00000000
	.byte %00000000, %00000000
	.byte %00000000, %00000000

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

wall_tile:
	.byte %11111111, %11111111
	.byte %10000001, %11111111
	.byte %10111101, %11111111
	.byte %10111101, %11111111
	.byte %10111101, %11111111
	.byte %10111101, %11111111
	.byte %10000001, %11111111
	.byte %11111111, %11111111

floor_tile:
	.byte %10101010, %01010101
	.byte %01010101, %10101010
	.byte %10101010, %01010101
	.byte %01010101, %10101010
	.byte %10101010, %01010101
	.byte %01010101, %10101010
	.byte %10101010, %01010101
	.byte %01010101, %10101010

pillar_tile:
	.byte %11111111, %11111111
	.byte %10000001, %11111111
	.byte %10111101, %11111111
	.byte %10100101, %11111111
	.byte %10100101, %11111111
	.byte %10111101, %11111111
	.byte %10000001, %11111111
	.byte %11111111, %11111111
tiles_end:

; Metasprites: Y-off, X-off, tile, attr  …  $80 terminator
player_idle_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000001
	.byte 0, 8, PLAYER_IDLE_1, %00000001
	.byte 8, 0, PLAYER_IDLE_2, %00000001
	.byte 8, 8, PLAYER_IDLE_3, %00000001
	.byte $80

player_walk1_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000001
	.byte 0, 8, PLAYER_IDLE_1, %00000001
	.byte 8, 0, PLAYER_IDLE_2, %00000001
	.byte 8, 8, PLAYER_WALK_3, %00000001
	.byte $80

player_walk2_metasprite:
	.byte 0, 0, PLAYER_IDLE_0, %00000001
	.byte 0, 8, PLAYER_IDLE_1, %00000001
	.byte 8, 0, PLAYER_WALK_2, %00000001
	.byte 8, 8, PLAYER_IDLE_3, %00000001
	.byte $80

; NES palette indices ($0F = black)
bg_palette:
	.byte $0F, $27, $16, $30   ; warm roman tones
	.byte $0F, $0F, $10, $20
	.byte $0F, $06, $16, $26
	.byte $0F, $09, $19, $29

spr_palette:
	.byte $0F, $27, $17, $30
	.byte $0F, $0F, $16, $37
	.byte $0F, $06, $16, $26
	.byte $0F, $09, $19, $29

; Arena nametable (32×30 tiles). WALL / FLOOR / PILLAR.
arena_map:
	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE
	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE
	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE
	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,PILLAR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,PILLAR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,PILLAR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,PILLAR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,PILLAR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,PILLAR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE
	.byte FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,FLOOR_TILE,WALL_TILE

	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE
	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE
	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE
	.byte WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE,WALL_TILE

; -------------------------
; Code
; -------------------------
	.segment "CODE"

reset:
	sei
	cld
	ldx #$FF
	txs

	; Disable NMI and rendering
	lda #$00
	sta PPUCTRL
	sta PPUMASK

	; Wait for vblank twice (PPU warm-up)
	jsr wait_vblank
	jsr wait_vblank

	; Background palettes at $3F00
	lda #$3F
	sta PPUADDR
	lda #$00
	sta PPUADDR

	ldx #$00
load_bg_pal:
	lda bg_palette, x
	sta PPUDATA
	inx
	cpx #$10
	bne load_bg_pal

	; Sprite palettes at $3F10
	lda #$3F
	sta PPUADDR
	lda #$10
	sta PPUADDR

	ldx #$00
load_spr_pal:
	lda spr_palette, x
	sta PPUDATA
	inx
	cpx #$10
	bne load_spr_pal

	; Upload tiles into CHR-RAM at $0000
	lda #$00
	sta PPUADDR
	sta PPUADDR

	ldx #$00
load_tiles:
	lda tiles, x
	sta PPUDATA
	inx
	cpx #(tiles_end - tiles)
	bne load_tiles

	; Nametable at $2000: full arena_map (16×32 = 512), pad rest with floor
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	ldx #$00
load_map_loop:
	lda arena_map, x
	sta PPUDATA
	inx
	bne load_map_loop           ; first 256 bytes

load_map_loop2:
	lda arena_map+256, x
	sta PPUDATA
	inx
	bne load_map_loop2          ; second 256 → 512 total

	lda #FLOOR_TILE
	ldx #$00
fill_remaining:
	sta PPUDATA
	inx
	bne fill_remaining          ; +256 → 768

	ldx #192                    ; +192 → 960 (30×32)
fill_remaining2:
	sta PPUDATA
	dex
	bne fill_remaining2

	; Attribute table → palette 0
	lda #$23
	sta PPUADDR
	lda #$C0
	sta PPUADDR
	ldx #$00
fill_attr:
	lda #$00
	sta PPUDATA
	inx
	cpx #$40
	bne fill_attr

	; Hide all sprites (Y = $FF)
	ldx #$00
	lda #$FF
hide_all_sprites:
	sta oam_shadow, x
	inx
	inx
	inx
	inx
	bne hide_all_sprites

	; Player start position
	lda #120
	sta sprite_x
	lda #100
	sta sprite_y
	lda #$00
	sta anim_frame

	; Enable NMI; show BG + sprites
	lda #%10000000
	sta PPUCTRL
	lda #%00011110
	sta PPUMASK

; Main loop: wait for NMI, poll pad, update sprite
main_loop:
wait_frame:
	lda frame_flag
	beq wait_frame
	lda #$00
	sta frame_flag

	jsr read_controller1

	; Save position for collision rollback
	lda sprite_x
	sta old_x
	lda sprite_y
	sta old_y

	; --- X axis: move, clamp to screen, revert if solid ---
	lda pad1
	and #$80                    ; Right
	beq no_right
	lda sprite_x
	cmp #SCREEN_MAX_X
	bcs no_right
	inc sprite_x
no_right:
	lda pad1
	and #$40                    ; Left
	beq no_left
	lda sprite_x
	beq no_left                 ; already at left edge
	dec sprite_x
no_left:
	jsr player_hits_solid
	bcc x_ok
	lda old_x
	sta sprite_x
x_ok:

	; --- Y axis: move, clamp to screen, revert if solid ---
	lda pad1
	and #$20                    ; Down
	beq no_down
	lda sprite_y
	cmp #SCREEN_MAX_Y
	bcs no_down
	inc sprite_y
no_down:
	lda pad1
	and #$10                    ; Up
	beq no_up
	lda sprite_y
	beq no_up                   ; already at top edge
	dec sprite_y
no_up:
	jsr player_hits_solid
	bcc y_ok
	lda old_y
	sta sprite_y
y_ok:

	; Walking animation only if we actually moved
	lda sprite_x
	cmp old_x
	bne is_moving
	lda sprite_y
	cmp old_y
	beq still

is_moving:
	inc anim_frame
	lda anim_frame
	lsr                         ; ÷8 for slower anim
	lsr
	lsr
	and #$01
	beq use_walk1

	lda #<player_walk2_metasprite
	sta metasprite_ptr_lo
	lda #>player_walk2_metasprite
	sta metasprite_ptr_hi
	jmp draw_player

use_walk1:
	lda #<player_walk1_metasprite
	sta metasprite_ptr_lo
	lda #>player_walk1_metasprite
	sta metasprite_ptr_hi
	jmp draw_player

still:
	lda #<player_idle_metasprite
	sta metasprite_ptr_lo
	lda #>player_idle_metasprite
	sta metasprite_ptr_hi
	lda #$00
	sta anim_frame

draw_player:
	jsr draw_metasprite
	jmp main_loop

wait_vblank:
	bit PPUSTATUS
	bpl wait_vblank
	rts

nmi:
	; OAM DMA during vblank
	lda #$00
	sta OAMADDR
	lda #$02
	sta $4014                   ; DMA from $0200
	lda #$01
	sta frame_flag
	rti

irq:
	rti

; -------------------------
; Subroutines
; -------------------------

; player_hits_solid: C=1 if any corner of the 16×16 box is on a solid tile
player_hits_solid:
	; top-left
	lda sprite_x
	sta check_x
	lda sprite_y
	sta check_y
	jsr is_solid_at
	bcs @solid

	; top-right (x + 15)
	lda sprite_x
	clc
	adc #PLAYER_W - 1
	sta check_x
	jsr is_solid_at
	bcs @solid

	; bottom-left (y + 15)
	lda sprite_x
	sta check_x
	lda sprite_y
	clc
	adc #PLAYER_H - 1
	sta check_y
	jsr is_solid_at
	bcs @solid

	; bottom-right
	lda sprite_x
	clc
	adc #PLAYER_W - 1
	sta check_x
	jsr is_solid_at
	bcs @solid

	clc
	rts
@solid:
	sec
	rts

; is_solid_at: sample check_x/check_y against arena_map
; C=1 solid (wall, pillar, or outside map)
is_solid_at:
	; tile_y = check_y / 8
	lda check_y
	lsr
	lsr
	lsr
	cmp #MAP_H
	bcs @solid                  ; below arena map → solid

	; index = tile_y * 32  (16-bit in temp_hi:temp)
	sta temp
	lda #0
	sta temp_hi
	ldx #5                      ; << 5
@shift:
	asl temp
	rol temp_hi
	dex
	bne @shift

	; index += tile_x (check_x / 8)
	lda check_x
	lsr
	lsr
	lsr
	clc
	adc temp
	sta temp
	lda temp_hi
	adc #0
	sta temp_hi

	; load tile: arena_map[index]
	ldy temp
	lda temp_hi
	bne @hi_page
	lda arena_map, y
	jmp @got
@hi_page:
	lda arena_map+256, y
@got:
	cmp #WALL_TILE
	beq @solid
	cmp #PILLAR_TILE
	beq @solid
	clc
	rts
@solid:
	sec
	rts

; Draw metasprite at sprite_x, sprite_y.
; metasprite_ptr_lo/hi → data (Y-off, X-off, tile, attr)*  $80
draw_metasprite:
	ldy #$00                    ; index into metasprite data
	ldx #$00                    ; index into OAM shadow
metasprite_loop:
	lda (metasprite_ptr_lo), y
	cmp #$80
	beq metasprite_done

	clc
	adc sprite_y
	sta oam_shadow, x           ; Y
	iny

	lda (metasprite_ptr_lo), y
	clc
	adc sprite_x
	sta oam_shadow+3, x         ; X
	iny

	lda (metasprite_ptr_lo), y
	sta oam_shadow+1, x         ; tile
	iny

	lda (metasprite_ptr_lo), y
	sta oam_shadow+2, x         ; attributes
	iny

	txa
	clc
	adc #$04
	tax
	jmp metasprite_loop

metasprite_done:
	rts

; Read controller 1 into pad1.
; After 8 ROL bits: bit0=A … bit7=Right
read_controller1:
	lda #$01
	sta $4016
	lda #$00
	sta $4016

	lda #$00
	sta pad1
	ldx #$08
rc1_loop:
	lda $4016
	and #$01
	cmp #$01                    ; C = pressed
	rol pad1
	dex
	bne rc1_loop
	rts

	.segment "VECTORS"
	.addr nmi, reset, irq
