; gladiator/src/main.s
;
; Build (assuming cc65 suite is installed and on PATH):
;   ca65 src/main.s -o build/main.o
;   ld65 -C nrom128.cfg build/main.o -o build/gladiator.prg
;   # Create iNES header: "NES\x1A", 1 PRG bank (16KB), 0 CHR, rest zeros
;   python - <<'PY'
;   import sys
;   hdr = bytearray(b'NES\\x1A')
;   hdr += bytes([1, 0, 0, 0]) + bytes(8)
;   open('build/header.bin','wb').write(hdr)
;   PY
;   cat build/header.bin build/gladiator.prg > build/gladiator.nes
;
; Then load build/gladiator.nes in an emulator (Mesen, FCEUX, etc).

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

; Tile indices (based on order in CHR-RAM)
BG_TILE_IDX = $00
PLAYER_TILE1 = $01
PLAYER_TILE2 = $02
PLAYER_IDLE_0 = $03
PLAYER_IDLE_1 = $04
PLAYER_IDLE_2 = $05
PLAYER_IDLE_3 = $06
PLAYER_WALK_2 = $07
PLAYER_WALK_3 = $08
WALL_TILE = $09
FLOOR_TILE = $0A
PILLAR_TILE = $0B

; -------------------------
; Zero page
; -------------------------
	.segment "ZEROPAGE"
temp:             .res 1
frame_flag:       .res 1   ; set to 1 each NMI to signal a new frame
pad1:             .res 1   ; controller 1 current state
sprite_x:         .res 1
sprite_y:         .res 1
anim_frame:       .res 1   ; walking animation toggle
metasprite_ptr_lo: .res 1   ; pointer to current metasprite data
metasprite_ptr_hi: .res 1

; -------------------------
; Work RAM (OAM shadow at $0200 page for DMA)
; -------------------------
	.segment "BSS"
oam_shadow:        .res 256  ; must start at $0200 for $4014 DMA page = $02

; -------------------------
; Read-only data (sprite tile and palette)
; -------------------------
	.segment "RODATA"

; Tiles: background brick and two human walk frames
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

player_walk1:
	.byte %00110000, %00110000  ; row 0
	.byte %00110000, %00110000  ; row 1
	.byte %01001000, %01001000  ; row 2
	.byte %00000000, %00000000  ; row 3
	.byte %00110000, %00110000  ; row 4
	.byte %00110000, %00110000  ; row 5
	.byte %01111000, %01111000  ; row 6
	.byte %11111100, %11111100  ; row 7

player_walk2:
	.byte %00110000, %00110000  ; row 0
	.byte %00110000, %00110000  ; row 1
	.byte %01111000, %01111000  ; row 2
	.byte %01111000, %01111000  ; row 3
	.byte %00110000, %00110000  ; row 4
	.byte %00110000, %00110000  ; row 5
	.byte %10010000, %10010000  ; row 6
	.byte %01000010, %01000010  ; row 7

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
	

; Background palette (4 colors) + 3 more sub-palettes (unused)
; Values are NES palette indices. $0F is black.
bg_palette:
  .byte $0F, $27, $16, $30   ; warm roman tones (universal background set to white)
	.byte $0F, $0F, $10, $20   ; BG palette 1
	.byte $0F, $06, $16, $26   ; BG palette 2
	.byte $0F, $09, $19, $29   ; BG palette 3

; Sprite palette (same idea)
spr_palette:
	.byte $0F, $27, $17, $30   ; SPR palette 0
	.byte $0F, $0F, $16, $37   ; SPR palette 1
	.byte $0F, $06, $16, $26   ; SPR palette 2
	.byte $0F, $09, $19, $29   ; SPR palette 3

; Background map data (32x30 tiles)
; Arena layout with walls, floor, and pillars
; W = Wall, F = Floor, P = Pillar
arena_map:
	.byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09
	.byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0B,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0B,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0B,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0A,$0A,$0A,$09
	.byte $09,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$09
	.byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09
	.byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09

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

	; Wait for vblank twice (PPUSTATUS bit7)
	jsr wait_vblank
	jsr wait_vblank

	; Load background palettes at $3F00
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

	; Load sprite palettes at $3F10
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

	; Load background map from arena_map
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	ldx #$00              ; map data index
load_map_loop:
	lda arena_map, x
	sta PPUDATA
	inx
	bne load_map_loop     ; first 256 bytes
	
	; Continue loading remaining map data
load_map_loop2:
	lda arena_map+256, x
	sta PPUDATA
	inx
	cpx #$E0              ; 224 more bytes (total 480 = 30 rows * 16 tiles/row * 2)
	bne load_map_loop2
	
	; Fill remaining tiles to complete 30x32 grid
	lda #FLOOR_TILE
	ldx #$E0
fill_remaining:
	sta PPUDATA
	inx
	bne fill_remaining
	
	ldx #$40              ; 64 more tiles
fill_remaining2:
	sta PPUDATA
	dex
	bne fill_remaining2

	; Set attribute table to palette 0
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

        ; Initialize OAM shadow: hide all sprites (Y=$FF at each entry)
	ldx #$00
	lda #$FF
hide_all_sprites:
	sta oam_shadow, x    ; Y
	inx
	inx                  ; skip tile
	inx                  ; skip attr
	inx                  ; skip X (advance 4 bytes per sprite)
	bne hide_all_sprites ; 64 sprites -> wraps at 256

	; Initialize first sprite position and data
	lda #120
	sta sprite_x
	lda #100
	sta sprite_y
	lda #$00
	sta anim_frame
	lda sprite_y
	sta oam_shadow+0     ; Y
	lda #PLAYER_TILE1
	sta oam_shadow+1     ; tile index
	lda #%00000000
	sta oam_shadow+2     ; attributes
	lda sprite_x
	sta oam_shadow+3     ; X

	; Enable NMI and show BG+sprites
	lda #%10000000       ; enable NMI on vblank
	sta PPUCTRL
	lda #%00011110       ; show bg & sprites
	sta PPUMASK

; Main loop: wait for vblank, poll controller, update sprite, NMI does DMA
main_loop:
wait_frame:
	lda frame_flag
	beq wait_frame
	lda #$00
	sta frame_flag

	; Read controller 1
	jsr read_controller1

	; Update sprite position based on D-Pad
	lda pad1
	and #$80              ; Right
	beq no_right
	inc sprite_x
no_right:
	lda pad1
	and #$40              ; Left
	beq no_left
	dec sprite_x
no_left:
	lda pad1
	and #$20              ; Down
	beq no_down
	inc sprite_y
no_down:
	lda pad1
	and #$10              ; Up
	beq no_up
	dec sprite_y
no_up:

	; handle walking animation and write to OAM shadow
	lda pad1
	and #$F0              ; any D-pad pressed?
	beq still
	
	; Walking - use metasprites
	inc anim_frame
	lda anim_frame
	lsr                   ; divide by 8 for slower animation
	lsr
	lsr
	and #$01
	beq use_walk1
	
	; Use walk2 metasprite
	lda #<player_walk2_metasprite
	sta metasprite_ptr_lo
	lda #>player_walk2_metasprite
	sta metasprite_ptr_hi
	jmp draw_player
	
use_walk1:
	; Use walk1 metasprite
	lda #<player_walk1_metasprite
	sta metasprite_ptr_lo
	lda #>player_walk1_metasprite
	sta metasprite_ptr_hi
	jmp draw_player
	
still:
	; Use idle metasprite
	lda #<player_idle_metasprite
	sta metasprite_ptr_lo
	lda #>player_idle_metasprite
	sta metasprite_ptr_hi
	lda #$00
	sta anim_frame
	
draw_player:
	jsr draw_metasprite
continue_main:

	jmp main_loop

wait_vblank:
	; Wait for bit 7 of PPUSTATUS to go 1 (vblank)
	bit PPUSTATUS
	bpl wait_vblank
	rts

nmi:
	; Perform OAM DMA during vblank
	lda #$00
	sta $2003             ; OAMADDR = 0
	lda #$02
	sta $4014             ; start DMA from $0200
	lda #$01
	sta frame_flag        ; signal main loop
	rti

irq:
	rti

; -------------------------
; Vectors
; -------------------------

; -------------------------
; Subroutines
; -------------------------

; draw_metasprite: draws a metasprite at sprite_x, sprite_y
; Input: metasprite_ptr_lo/hi points to metasprite data
draw_metasprite:
	ldy #$00            ; OAM shadow index
	ldx #$00            ; metasprite data index
metasprite_loop:
	lda (metasprite_ptr_lo), y
	cmp #$80            ; check for end marker
	beq metasprite_done
	
	; Y offset
	clc
	adc sprite_y
	sta oam_shadow, x
	iny
	
	; X offset  
	lda (metasprite_ptr_lo), y
	clc
	adc sprite_x
	sta oam_shadow+3, x
	iny
	
	; Tile
	lda (metasprite_ptr_lo), y
	sta oam_shadow+1, x
	iny
	
	; Attributes
	lda (metasprite_ptr_lo), y
	sta oam_shadow+2, x
	iny
	
	; Move to next sprite slot (4 bytes per sprite)
	txa
	clc
	adc #$04
	tax
	
	jmp metasprite_loop
	
metasprite_done:
	rts

; read_controller1: reads 8 bits from $4016 into pad1
; Bit order (bit0..bit7): A, B, Select, Start, Up, Down, Left, Right
read_controller1:
	; strobe controllers
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
	cmp #$01              ; set carry if pressed
	rol pad1
	dex
	bne rc1_loop
	rts

	.segment "VECTORS"
	.addr nmi, reset, irq
