# NES Assembly Programming: Getting Started Guide

## 6502 Processor Instructions

The NES uses a modified 6502 processor. Here are all available instructions grouped by category:

### Load/Store Operations
- **LDA** - Load Accumulator (A = memory)
- **LDX** - Load X Register (X = memory)
- **LDY** - Load Y Register (Y = memory)
- **STA** - Store Accumulator (memory = A)
- **STX** - Store X Register (memory = X)
- **STY** - Store Y Register (memory = Y)

### Transfer Operations
- **TAX** - Transfer A to X (X = A)
- **TAY** - Transfer A to Y (Y = A)
- **TXA** - Transfer X to A (A = X)
- **TYA** - Transfer Y to A (A = Y)
- **TSX** - Transfer Stack Pointer to X (X = SP)
- **TXS** - Transfer X to Stack Pointer (SP = X)

### Stack Operations
- **PHA** - Push Accumulator onto stack
- **PHP** - Push Processor Status onto stack
- **PLA** - Pull Accumulator from stack
- **PLP** - Pull Processor Status from stack

### Arithmetic Operations
- **ADC** - Add with Carry (A = A + memory + C)
- **SBC** - Subtract with Carry (A = A - memory - !C)
- **INC** - Increment Memory (memory = memory + 1)
- **INX** - Increment X Register (X = X + 1)
- **INY** - Increment Y Register (Y = Y + 1)
- **DEC** - Decrement Memory (memory = memory - 1)
- **DEX** - Decrement X Register (X = X - 1)
- **DEY** - Decrement Y Register (Y = Y - 1)

### Logical Operations
- **AND** - Logical AND (A = A & memory)
- **ORA** - Logical OR (A = A | memory)
- **EOR** - Exclusive OR (A = A ^ memory)
- **BIT** - Bit Test (affects N, V, Z flags)

### Shift/Rotate Operations
- **ASL** - Arithmetic Shift Left (C <- [76543210] <- 0)
- **LSR** - Logical Shift Right (0 -> [76543210] -> C)
- **ROL** - Rotate Left through Carry (C <- [76543210] <- C)
- **ROR** - Rotate Right through Carry (C -> [76543210] -> C)

### Compare Operations
- **CMP** - Compare A with memory (A - memory)
- **CPX** - Compare X with memory (X - memory)
- **CPY** - Compare Y with memory (Y - memory)

### Branch Operations (2-byte, signed 8-bit offset)
- **BCC** - Branch if Carry Clear (C = 0)
- **BCS** - Branch if Carry Set (C = 1)
- **BEQ** - Branch if Equal/Zero (Z = 1)
- **BNE** - Branch if Not Equal/Zero (Z = 0)
- **BMI** - Branch if Minus/Negative (N = 1)
- **BPL** - Branch if Plus/Positive (N = 0)
- **BVC** - Branch if Overflow Clear (V = 0)
- **BVS** - Branch if Overflow Set (V = 1)

### Jump/Subroutine Operations
- **JMP** - Jump to address
- **JSR** - Jump to Subroutine (pushes return address)
- **RTS** - Return from Subroutine
- **RTI** - Return from Interrupt

### Flag Operations
- **CLC** - Clear Carry Flag (C = 0)
- **CLD** - Clear Decimal Flag (D = 0)
- **CLI** - Clear Interrupt Disable (I = 0)
- **CLV** - Clear Overflow Flag (V = 0)
- **SEC** - Set Carry Flag (C = 1)
- **SED** - Set Decimal Flag (D = 1)
- **SEI** - Set Interrupt Disable (I = 1)

### Miscellaneous
- **NOP** - No Operation (does nothing)
- **BRK** - Force Break/Interrupt

### Addressing Modes

The 6502 supports multiple addressing modes:

```assembly
; Immediate - Use literal value
LDA #$10         ; A = $10

; Zero Page - Access memory $00-$FF
LDA $10          ; A = value at address $0010

; Zero Page,X - Zero page indexed by X
LDA $10,X        ; A = value at address ($0010 + X)

; Absolute - Full 16-bit address
LDA $1234        ; A = value at address $1234

; Absolute,X - Absolute indexed by X
LDA $1234,X      ; A = value at address ($1234 + X)

; Absolute,Y - Absolute indexed by Y
LDA $1234,Y      ; A = value at address ($1234 + Y)

; Indirect - JMP only
JMP ($1234)      ; Jump to address stored at $1234-$1235

; Indexed Indirect (Zero Page,X)
LDA ($10,X)      ; A = value at address stored in ($10 + X)

; Indirect Indexed (Zero Page),Y
LDA ($10),Y      ; A = value at (address stored in $10) + Y

; Implied - No operand needed
INX              ; Increment X
CLC              ; Clear carry

; Accumulator - Operates on A
ROL A            ; Rotate A left
ASL A            ; Shift A left
```

### Processor Status Flags

The 6502 has 7 status flags in the P register:
- **N** (bit 7) - Negative flag (set if result bit 7 = 1)
- **V** (bit 6) - Overflow flag (signed arithmetic overflow)
- **-** (bit 5) - Unused (always 1)
- **B** (bit 4) - Break flag (set by BRK instruction)
- **D** (bit 3) - Decimal mode (not used on NES)
- **I** (bit 2) - Interrupt disable
- **Z** (bit 1) - Zero flag (set if result = 0)
- **C** (bit 0) - Carry flag

## Memory Layout and Organization

### CPU Memory Map ($0000-$FFFF)

The NES CPU sees a 64KB address space divided into specific regions:

```
$0000-$07FF: Internal RAM (2KB)
$0800-$0FFF: Mirror of $0000-$07FF
$1000-$17FF: Mirror of $0000-$07FF  
$1800-$1FFF: Mirror of $0000-$07FF
$2000-$2007: PPU Registers
$2008-$3FFF: Mirrors of $2000-$2007
$4000-$4017: APU and I/O Registers
$4018-$401F: APU and I/O (usually disabled)
$4020-$5FFF: Cartridge Expansion ROM
$6000-$7FFF: SRAM
$8000-$BFFF: PRG-ROM
$C000-$FFFF: PRG-ROM
```

### Important Memory Regions

**Zero Page ($0000-$00FF):** Fast access memory, ideal for frequently used variables
```assembly
; Example zero page variables
player_x     = $10
player_y     = $11
temp_var     = $12
```

**Stack ($0100-$01FF):** Used for subroutine calls and temporary storage

**General RAM ($0200-$07FF):** Your main working memory
```assembly
; Common usage
$0200-$02FF: Sprite data (OAM buffer)
$0300-$07FF: General variables, buffers, game state
```

### PPU Memory Map ($0000-$3FFF)

The Picture Processing Unit has its own memory space:

```
$0000-$0FFF: Pattern Table 0 (sprites, background tiles)
$1000-$1FFF: Pattern Table 1 (sprites, background tiles)
$2000-$23FF: Nametable 0
$2400-$27FF: Nametable 1
$2800-$2BFF: Nametable 2
$2C00-$2FFF: Nametable 3
$3000-$3EFF: Mirrors of nametables
$3F00-$3F1F: Palette RAM
$3F20-$3FFF: Mirrors of palette RAM
```

## Working with Graphics

### Understanding Palettes

The NES has a master palette of 64 colors but can only display 25 at once:
- 1 background color (shared)
- 12 background colors (4 palettes × 3 colors each)
- 12 sprite colors (4 palettes × 3 colors each)

```assembly
; Loading a palette
load_palette:
    LDA $2002        ; Read PPU status to reset address latch
    LDA #$3F         ; High byte of palette address
    STA $2006        ; PPU address register
    LDA #$00         ; Low byte of palette address  
    STA $2006
    
    LDX #$00
palette_loop:
    LDA palette_data, X
    STA $2007        ; PPU data register
    INX
    CPX #$20         ; 32 palette entries
    BNE palette_loop
    RTS

palette_data:
    ; Background palettes
    .db $0F, $31, $32, $33  ; Palette 0
    .db $0F, $35, $36, $37  ; Palette 1
    .db $0F, $39, $3A, $3B  ; Palette 2
    .db $0F, $3D, $3E, $0F  ; Palette 3
    ; Sprite palettes
    .db $0F, $16, $27, $18  ; Palette 0
    .db $0F, $02, $38, $3C  ; Palette 1
    .db $0F, $1C, $15, $14  ; Palette 2
    .db $0F, $02, $38, $3C  ; Palette 3
```

### Working with Tiles

Tiles are 8×8 pixel graphics stored in pattern tables. Each tile uses 16 bytes:

```assembly
; Example tile data (a simple cross pattern)
cross_tile:
    ; Plane 0 (low bits)
    .db %00011000
    .db %00011000  
    .db %11111111
    .db %11111111
    .db %11111111
    .db %11111111
    .db %00011000
    .db %00011000
    ; Plane 1 (high bits)
    .db %00000000
    .db %00000000
    .db %00000000
    .db %00000000
    .db %00000000
    .db %00000000
    .db %00000000
    .db %00000000
```

### Drawing Background Tiles

```assembly
draw_background:
    LDA $2002        ; Reset PPU address latch
    LDA #$20         ; Nametable 0 high byte
    STA $2006
    LDA #$00         ; Nametable 0 low byte
    STA $2006
    
    LDX #$00
    LDY #$00
bg_loop:
    LDA background_data, X
    STA $2007        ; Write tile to nametable
    INX
    INY
    CPY #$20         ; 32 tiles per row
    BNE bg_loop
    ; Continue for all rows...
    RTS
```

### Working with Sprites

Sprites are managed through OAM (Object Attribute Memory). Each sprite uses 4 bytes:

```assembly
; Sprite structure (4 bytes per sprite):
; Byte 0: Y position
; Byte 1: Tile number
; Byte 2: Attributes (palette, priority, flip)
; Byte 3: X position
```

#### Understanding Sprite Colors and Transparency

Sprites use 2-bit color values (0-3) that index into the selected palette:
- **Color 0:** Always transparent (shows background through)
- **Color 1-3:** Visible colors from the selected sprite palette

```assembly
; Example sprite tile data with transparency
player_sprite:
    ; Plane 0 (low bits) - defines bit 0 of each pixel
    .db %00111100    ; Row 0:  __####__
    .db %01111110    ; Row 1:  _######_
    .db %11011011    ; Row 2:  ##_##_##
    .db %11111111    ; Row 3:  ########
    .db %10111101    ; Row 4:  #_####_#
    .db %10100101    ; Row 5:  #_#__#_#
    .db %10000001    ; Row 6:  #______#
    .db %01111110    ; Row 7:  _######_
    
    ; Plane 1 (high bits) - defines bit 1 of each pixel
    .db %00000000    ; Row 0
    .db %00111100    ; Row 1
    .db %01111110    ; Row 2
    .db %01111110    ; Row 3
    .db %00111100    ; Row 4
    .db %00000000    ; Row 5
    .db %00000000    ; Row 6
    .db %00000000    ; Row 7

; The two planes combine to form 2-bit color values:
; Plane1 Plane0 = Color Index
;   0      0    = 0 (transparent)
;   0      1    = 1 (color 1 from palette)
;   1      0    = 2 (color 2 from palette)
;   1      1    = 3 (color 3 from palette)
```

#### Sprite Attributes and Palettes

The attribute byte (byte 2) controls various sprite properties:

```assembly
; Sprite attribute byte format:
; 76543210
; |||   ||
; |||   ++- Sprite palette (0-3)
; ||+------ Priority (0: in front of background, 1: behind background)
; |+------- Flip sprite horizontally
; +-------- Flip sprite vertically

; Example: Setting sprite attributes
update_sprites:
    ; Player sprite
    LDA player_y
    STA $0200        ; Y position
    LDA #$01         ; Tile number
    STA $0201
    
    ; Set attributes: palette 2, normal priority, no flipping
    LDA #%00000010   ; Binary: vhp000pp (palette 2)
    STA $0202
    
    LDA player_x
    STA $0203        ; X position
    
    ; Enemy sprite with different attributes
    LDA enemy_y
    STA $0204
    LDA #$02         ; Different tile
    STA $0205
    LDA #%01000001   ; Palette 1, flipped horizontally
    STA $0206
    LDA enemy_x
    STA $0207
    
    ; Transfer OAM data to PPU
    LDA #$00
    STA $2003        ; OAM address low
    LDA #$02         ; High byte of OAM buffer ($0200)
    STA $4014        ; DMA transfer
    RTS
```

#### Working with Transparency

Transparency is automatic for color 0 in sprites. Here's how to design sprites with transparent areas:

```assembly
; Creating a coin sprite with transparent background
coin_sprite:
    ; Plane 0 - notice the outer pixels are 0
    .db %00111100    ;   ####
    .db %01000010    ;  #    #
    .db %10000001    ; #      #
    .db %10011001    ; #  ##  #
    .db %10011001    ; #  ##  #
    .db %10000001    ; #      #
    .db %01000010    ;  #    #
    .db %00111100    ;   ####
    
    ; Plane 1 - also 0 for transparent pixels
    .db %00000000    ; All outer pixels remain 00 (transparent)
    .db %00111100    ; Inner pixels get color values
    .db %01111110
    .db %01100110
    .db %01100110
    .db %01111110
    .db %00111100
    .db %00000000

; Metasprite example - combining multiple sprites
draw_large_character:
    ; Top-left quadrant
    LDA char_y
    STA $0200
    LDA #$10         ; Top-left tile
    STA $0201
    LDA #%00000000   ; Palette 0
    STA $0202
    LDA char_x
    STA $0203
    
    ; Top-right quadrant
    LDA char_y
    STA $0204
    LDA #$11         ; Top-right tile
    STA $0205
    LDA #%00000000
    STA $0206
    LDA char_x
    CLC
    ADC #$08         ; 8 pixels to the right
    STA $0207
    
    ; Bottom-left quadrant
    LDA char_y
    CLC
    ADC #$08         ; 8 pixels down
    STA $0208
    LDA #$12         ; Bottom-left tile
    STA $0209
    LDA #%00000000
    STA $020A
    LDA char_x
    STA $020B
    
    ; Bottom-right quadrant
    LDA char_y
    CLC
    ADC #$08
    STA $020C
    LDA #$13         ; Bottom-right tile
    STA $020D
    LDA #%00000000
    STA $020E
    LDA char_x
    CLC
    ADC #$08
    STA $020F
    RTS
```

## Building Background Scenes

### Understanding Nametables

The NES background is composed of 32×30 tiles (256×240 pixels). Each screen is called a nametable, stored in PPU memory:

```
Nametable layout (32×30 tiles):
$2000-$23BF: Tile indices (960 bytes)
$23C0-$23FF: Attribute table (64 bytes)
```

### Creating a Simple Background

```assembly
; Load a full screen background
load_background:
    LDA $2002        ; Reset PPU latch
    LDA #$20         ; High byte of nametable 0
    STA $2006
    LDA #$00         ; Low byte
    STA $2006
    
    ; Load 960 tiles (32×30)
    LDX #$00
    LDY #$00
load_bg_loop:
    LDA background_data, X
    STA $2007
    INX
    BNE load_bg_loop
    INC load_bg_loop+2  ; Increment high byte of source
    INY
    CPY #$04         ; 4 pages = 960 bytes (with some extra)
    BNE load_bg_loop
    RTS

; Example background data
background_data:
    ; Sky row (repeated)
    .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ; ... more rows
```

### Attribute Tables

Attribute tables control which palette each 16×16 pixel area uses. Each byte controls a 32×32 pixel area (2×2 tiles):

```assembly
; Attribute byte layout:
; 76543210
; ||||||||
; ||||||++- Top-left 2×2 block palette
; ||||++--- Top-right 2×2 block palette
; ||++----- Bottom-left 2×2 block palette
; ++------- Bottom-right 2×2 block palette

load_attributes:
    LDA $2002
    LDA #$23         ; Attribute table high byte
    STA $2006
    LDA #$C0         ; Attribute table low byte
    STA $2006
    
    LDX #$00
attr_loop:
    LDA attribute_data, X
    STA $2007
    INX
    CPX #$40         ; 64 attribute bytes
    BNE attr_loop
    RTS

attribute_data:
    ; Each byte controls 4 2×2 tile blocks
    .db %00000000    ; All use palette 0
    .db %01010101    ; All use palette 1
    .db %10101010    ; All use palette 2
    .db %11111111    ; All use palette 3
    ; ... 60 more bytes
```

### Building Complex Scenes

#### Metatile System

For efficient level design, use metatiles (2×2 or larger tile groups):

```assembly
; Define metatiles as 2×2 tile blocks
metatile_grass:
    .db $80,$81      ; Top row tiles
    .db $90,$91      ; Bottom row tiles
    .db %00          ; Palette 0

metatile_brick:
    .db $82,$83
    .db $92,$93
    .db %01          ; Palette 1

metatile_water:
    .db $84,$85
    .db $94,$95
    .db %10          ; Palette 2

; Draw a metatile at specific position
; X = metatile X position (0-15)
; Y = metatile Y position (0-14)
draw_metatile:
    ; Calculate nametable address
    TYA
    ASL A            ; Y * 2
    ASL A            ; Y * 4
    ASL A            ; Y * 8
    ASL A            ; Y * 16
    ASL A            ; Y * 32
    STA temp_lo
    LDA #$20         ; Nametable 0 base
    STA temp_hi
    
    TXA
    ASL A            ; X * 2
    CLC
    ADC temp_lo
    STA temp_lo
    BCC no_carry
    INC temp_hi
no_carry:
    
    ; Set PPU address
    LDA $2002
    LDA temp_hi
    STA $2006
    LDA temp_lo
    STA $2006
    
    ; Draw top row
    LDA metatile_data+0
    STA $2007
    LDA metatile_data+1
    STA $2007
    
    ; Move to next row
    LDA temp_lo
    CLC
    ADC #$20         ; Next row is 32 tiles down
    STA temp_lo
    BCC no_carry2
    INC temp_hi
no_carry2:
    
    LDA $2002
    LDA temp_hi
    STA $2006
    LDA temp_lo
    STA $2006
    
    ; Draw bottom row
    LDA metatile_data+2
    STA $2007
    LDA metatile_data+3
    STA $2007
    RTS
```

#### Compression Techniques

For larger levels, use compression:

```assembly
; RLE (Run-Length Encoding) decompression
decompress_rle:
    LDX #$00
    LDY #$00
decomp_loop:
    LDA compressed_data, X
    CMP #$FF         ; End marker
    BEQ decomp_done
    
    ; Check if RLE marker (high bit set)
    BMI is_rle
    
    ; Single tile
    STA $2007
    INX
    JMP decomp_loop
    
is_rle:
    AND #$7F         ; Clear high bit to get count
    STA temp_count
    INX
    LDA compressed_data, X  ; Get tile to repeat
    LDY temp_count
repeat_loop:
    STA $2007
    DEY
    BNE repeat_loop
    INX
    JMP decomp_loop
    
decomp_done:
    RTS

; Example compressed data
compressed_data:
    .db $00          ; Single sky tile
    .db $80|20, $00  ; Repeat sky 20 times
    .db $01,$02,$03  ; Three different tiles
    .db $80|10, $04  ; Repeat tile $04 10 times
    .db $FF          ; End marker
```

#### Screen Transitions

For smooth screen transitions:

```assembly
; Column-based screen loading for horizontal scrolling
load_new_column:
    ; X = column number (0-31)
    TXA
    STA temp_column
    
    ; Calculate starting nametable address
    LDA scroll_x
    LSR A
    LSR A
    LSR A            ; Divide by 8 to get tile column
    AND #$1F         ; Wrap at 32
    STA temp_addr_lo
    
    LDA #$20         ; Or $24 for second nametable
    STA temp_addr_hi
    
    LDY #$00         ; Row counter
column_loop:
    ; Set PPU address for this row
    LDA $2002
    LDA temp_addr_hi
    STA $2006
    
    TYA
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A            ; Y * 32
    CLC
    ADC temp_column
    STA $2006
    
    ; Load tile for this position
    LDA new_screen_data, Y
    STA $2007
    
    INY
    CPY #30          ; 30 rows
    BNE column_loop
    RTS
```

### Animated Backgrounds

Create animated tiles by swapping CHR data:

```assembly
; Animate water tiles
animate_water:
    INC frame_counter
    LDA frame_counter
    AND #$0F         ; Every 16 frames
    BNE skip_water
    
    ; Swap between water animation frames
    LDA water_frame
    EOR #$01
    STA water_frame
    
    ; Update specific tiles in nametable
    LDA $2002
    LDA #$21         ; Address of water tile
    STA $2006
    LDA #$84
    STA $2006
    
    LDA water_frame
    BNE water_frame2
    LDA #$84         ; Water tile 1
    JMP write_water
water_frame2:
    LDA #$86         ; Water tile 2
write_water:
    STA $2007
    
skip_water:
    RTS
```

### Complete Scene Example

```assembly
; Build a simple platformer scene
build_scene:
    ; Clear nametable first
    JSR clear_nametable
    
    ; Draw sky (rows 0-20)
    LDX #$00
    LDY #$00
sky_loop:
    JSR draw_sky_row
    INY
    CPY #20
    BNE sky_loop
    
    ; Draw ground (rows 21-29)
ground_loop:
    JSR draw_ground_row
    INY
    CPY #30
    BNE ground_loop
    
    ; Add clouds
    LDX #$05         ; X position
    LDY #$03         ; Y position
    JSR draw_cloud
    
    LDX #$14
    LDY #$05
    JSR draw_cloud
    
    ; Add platforms
    LDX #$08
    LDY #$10
    LDA #$06         ; 6 tiles wide
    JSR draw_platform
    
    ; Load attribute table
    JSR load_scene_attributes
    RTS

draw_platform:
    STA platform_width
    ; Calculate nametable address
    TYA
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    STA temp_lo
    TXA
    CLC
    ADC temp_lo
    STA temp_lo
    LDA #$20
    ADC #$00
    STA temp_hi
    
    ; Set PPU address
    LDA $2002
    LDA temp_hi
    STA $2006
    LDA temp_lo
    STA $2006
    
    ; Draw platform tiles
    LDX #$00
platform_loop:
    LDA #$C0         ; Platform tile
    STA $2007
    INX
    CPX platform_width
    BNE platform_loop
    RTS
```

### Tips for Background Design

1. **Plan your tile usage:** You only have 256 tiles available
2. **Reuse tiles creatively:** Flip and rotate tiles for variety
3. **Use metatiles:** Simplifies level design and reduces data
4. **Consider attribute restrictions:** Plan 16×16 areas for palette usage
5. **Optimize for scrolling:** Design seamless transitions between screens
6. **Use compression:** Essential for larger games
7. **Animate sparingly:** Too many animated tiles can be distracting

## Controller Input

### Reading Controllers

```assembly
; Controller button bits:
; Bit 7: A
; Bit 6: B  
; Bit 5: Select
; Bit 4: Start
; Bit 3: Up
; Bit 2: Down
; Bit 1: Left
; Bit 0: Right

read_controller:
    LDA #$01
    STA $4016        ; Strobe controller
    LDA #$00
    STA $4016        ; End strobe
    
    LDX #$08         ; Read 8 buttons
controller_loop:
    LDA $4016        ; Read controller 1
    LSR A            ; Shift right, button state in carry
    ROL buttons      ; Rotate into buttons variable
    DEX
    BNE controller_loop
    RTS

; Check for specific button presses
check_input:
    JSR read_controller
    
    LDA buttons
    AND #%10000000   ; Check A button
    BEQ no_a_press
    ; Handle A button press
    JSR jump_action
    
no_a_press:
    LDA buttons
    AND #%00001000   ; Check Up
    BEQ no_up_press
    ; Handle up press
    DEC player_y
    
no_up_press:
    ; Continue checking other buttons...
    RTS
```

## Battery-Backed Save Data

### Understanding Save RAM

Battery-backed save RAM (SRAM) is typically mapped to $6000-$7FFF (8KB). This memory persists when the console is turned off.

```assembly
; Save game data structure
save_data_start = $6000

; Define save data layout
player_level     = save_data_start + $00
player_health    = save_data_start + $01
player_score_lo  = save_data_start + $02
player_score_hi  = save_data_start + $03
game_flags       = save_data_start + $04
; ... more save data

save_data_end    = save_data_start + $FF
```

### Saving Game State

```assembly
save_game:
    ; Save current game state to SRAM
    LDA current_level
    STA player_level
    
    LDA current_health  
    STA player_health
    
    LDA score_low
    STA player_score_lo
    
    LDA score_high
    STA player_score_hi
    
    LDA flags
    STA game_flags
    
    ; Calculate and store checksum for data integrity
    JSR calculate_checksum
    STA save_data_start + $FE
    RTS
```

### Loading Game State

```assembly
load_game:
    ; Verify save data integrity first
    JSR verify_checksum
    BCC load_failed     ; Branch if checksum invalid
    
    ; Load data from SRAM
    LDA player_level
    STA current_level
    
    LDA player_health
    STA current_health
    
    LDA player_score_lo
    STA score_low
    
    LDA player_score_hi
    STA score_high
    
    LDA game_flags
    STA flags
    
    SEC                 ; Set carry to indicate success
    RTS
    
load_failed:
    ; Initialize default game state
    JSR init_new_game
    CLC                 ; Clear carry to indicate failure
    RTS
```

### Data Integrity with Checksums

```assembly
calculate_checksum:
    LDA #$00
    TAX                 ; X = checksum accumulator
    LDY #$00            ; Y = data index
    
checksum_loop:
    LDA save_data_start, Y
    CLC
    ADC checksum_temp
    STA checksum_temp
    INY
    CPY #$FE            ; Don't include checksum byte itself
    BNE checksum_loop
    
    LDA checksum_temp
    EOR #$FF            ; Invert for simple checksum
    RTS

verify_checksum:
    JSR calculate_checksum
    CMP save_data_start + $FE
    BEQ checksum_valid
    CLC                 ; Clear carry = invalid
    RTS
checksum_valid:
    SEC                 ; Set carry = valid
    RTS
```

## Basic Program Structure

```assembly
.segment "HEADER"
    .byte "NES", $1A    ; iNES header
    .byte $02           ; 2 * 16KB PRG ROM
    .byte $01           ; 1 * 8KB CHR ROM
    .byte $01           ; Mapper 0, vertical mirroring
    .byte $00, $00, $00, $00, $00, $00, $00, $00

.segment "STARTUP"
reset:
    SEI                 ; Disable interrupts
    CLD                 ; Clear decimal mode
    LDX #$FF
    TXS                 ; Initialize stack
    
    ; Wait for PPU to be ready
    BIT $2002
wait_vblank1:
    BIT $2002
    BPL wait_vblank1
    
    ; Initialize RAM
    LDA #$00
    TAX
clear_ram:
    STA $0000, X
    STA $0100, X
    STA $0200, X
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X
    INX
    BNE clear_ram
    
    ; Wait for second vblank
wait_vblank2:
    BIT $2002
    BPL wait_vblank2
    
    ; Initialize PPU
    LDA #%10000000      ; Enable NMI
    STA $2000
    LDA #%00010000      ; Enable sprites
    STA $2001
    
    ; Try to load save data
    JSR load_game
    BCS continue_game   ; Branch if load successful
    JSR init_new_game   ; Initialize new game
    
continue_game:
    JMP main_loop

main_loop:
    JSR read_controller
    JSR update_game_logic
    JSR check_save_trigger
    JMP main_loop

nmi:
    ; Handle screen updates during vblank
    JSR update_sprites
    JSR update_background
    RTI

irq:
    RTI

.segment "VECTORS"
    .word nmi
    .word reset  
    .word irq
```

## Tips for Getting Started

1. **Start Simple:** Begin with basic sprite movement and controller input
2. **Use Emulators:** FCEUX and Mesen have excellent debugging tools
3. **Plan Your Memory:** Organize your RAM usage early
4. **Timing Matters:** Most updates should happen during vblank (NMI)
5. **Test Save Functionality:** Battery-backed saves need thorough testing
6. **Graphics Tools:** Use tools like YY-CHR for creating tile graphics
7. **Assembler Choice:** ca65 (part of cc65) is popular and well-documented

This guide covers the fundamentals, but NES programming has many nuances. Practice with simple projects and gradually add complexity as you become more comfortable with the hardware constraints and assembly programming techniques.