# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NES (Nintendo Entertainment System) game written in 6502 assembly using the cc65 toolchain. The game targets the NROM-128 mapper (Mapper 0) with CHR-RAM for graphics.

## Build Commands

```bash
# Build the ROM
make

# Clean and rebuild
make clean && make

# Test after changes - builds the .nes ROM file
make
```

The build process creates `build/gladiator.nes` which can be run in NES emulators (Mesen, FCEUX, Nestopia UE).

## Architecture

### Memory Map
- **Zero Page ($00-$FF)**: Fast-access variables (sprite positions, controller state, animation frame, metasprite pointers)
- **OAM Shadow ($0200-$02FF)**: Sprite buffer for DMA transfer
- **ROM ($C000-$FFFF)**: Program code and data in a single 16KB bank

### File Structure
- `src/main.s`: Main game code containing all game logic, graphics data, and system initialization
- `nrom128.cfg`: Linker configuration defining memory segments
- `Makefile`: Build automation using ca65/ld65

### Graphics System
The game uses CHR-RAM (not CHR-ROM), loading tile data during initialization:
- Tiles are defined as raw bytes in the RODATA segment
- Metasprites use a format: Y-offset, X-offset, tile-index, attributes, with $80 as end marker
- OAM DMA is performed during NMI for sprite rendering

### Current Implementation
- **Player sprite**: 16×16 pixel metasprite composed of 4 tiles
- **Animation states**: idle, walk1, walk2 metasprites
- **Controller handling**: D-pad movement with frame-based updates
- **Palettes**: Roman-themed color scheme

### Key Constants
Tile indices are defined at the top of main.s:
- `BG_TILE_IDX`: Background tile
- `PLAYER_IDLE_0-3`: Idle animation tiles  
- `PLAYER_WALK_2-3`: Walking animation tiles

## Development Notes

### Adding New Features
When modifying graphics:
1. Add tile data in the RODATA segment between `tiles:` and `tiles_end:`
2. Update tile index constants
3. For metasprites, follow the existing format with $80 terminator

### Testing Changes
After any code modifications:
1. Run `make clean && make` to ensure a fresh build
2. Test in an emulator to verify functionality
3. Check for sprite flickering or incorrect tile indices

### Common Tasks
- **Modify player movement speed**: Adjust increment/decrement values in D-pad handling (lines ~290-310)
- **Change animation speed**: Modify the shift count in walking animation logic (currently divides by 8)
- **Add new metasprites**: Define in RODATA after existing metasprite definitions, create index constants

## Reference Documentation

The repository includes `nes_assembly_guide.md` with comprehensive NES programming information including:
- Complete 6502 instruction reference
- PPU register descriptions
- Controller input patterns
- Graphics programming techniques