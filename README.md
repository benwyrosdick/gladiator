# Gladiator (NROM-128, CHR-RAM)

This is a tiny, modern starter for homebrew NES development that will run in common emulators (Mesen, FCEUX, Nestopia UE). It:
- Targets **Mapper 0 (NROM-128)** with **1 x 16KB PRG** and **CHR-RAM** (0 CHR banks).

## Requirements
- **cc65** toolchain installed and on PATH (`ca65`, `ld65`).
  - macOS: `brew install cc65`
  - Linux: your package manager or build from source

## Build
```sh
make
```
This produces `build/gladiator.nes`. Load that ROM in your emulator of choice.

## Notes
- The iNES header declares 1 PRG bank and 0 CHR banks (CHR-RAM). Most emulators handle this fine.
- For banked projects, switch to NROM-256 or mappers like MMC1/MMC3 later.
