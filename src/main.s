; gladiator/src/main.s
; Minimal NES starter (NROM-128 / mapper 0, CHR-RAM) using ca65/ld65.
; Puts a single sprite on screen.
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

PLAYER_TILE1 = $01
PLAYER_TILE2 = $02

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
	.byte %11111111, %11111111
	.byte %11111111, %11111111
	.byte %11111111, %11111111
	.byte %00000000, %00000000
	.byte %00000000, %00000000
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
tiles_end:

; Background palette (4 colors) + 3 more sub-palettes (unused)
; Values are NES palette indices. $0F is black.
bg_palette:
  .byte $30, $27, $16, $30   ; warm roman tones (universal background set to white)
	.byte $0F, $00, $10, $20   ; BG palette 1
	.byte $0F, $06, $16, $26   ; BG palette 2
	.byte $0F, $09, $19, $29   ; BG palette 3

; Sprite palette (same idea)
spr_palette:
	.byte $0F, $27, $17, $30   ; SPR palette 0
	.byte $0F, $00, $10, $20   ; SPR palette 1
	.byte $0F, $06, $16, $26   ; SPR palette 2
	.byte $0F, $09, $19, $29   ; SPR palette 3

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

	; Fill nametable with background tile
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	ldx #$1E              ; 30 rows
fill_nt_row:
	ldy #$20              ; 32 columns
fill_nt_col:
	lda #$00              ; bg_tile index
	sta PPUDATA
	dey
	bne fill_nt_col
	dex
	bne fill_nt_row

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
	inc anim_frame
	lda anim_frame
	and #$01
	beq use_walk1
	lda #PLAYER_TILE2
	bne set_tile
use_walk1:
	lda #PLAYER_TILE1
set_tile:
	sta oam_shadow+1
	jmp store_pos
still:
	lda #PLAYER_TILE1
	sta oam_shadow+1
	lda #$00
	sta anim_frame
store_pos:
	lda sprite_y
	sta oam_shadow+0
	lda sprite_x
	sta oam_shadow+3

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
