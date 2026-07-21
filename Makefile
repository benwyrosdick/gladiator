# VESYL Shipper NES — requires cc65 (ca65, ld65) and python3
# make / make clean / make install / make run

NAME  = vesyl_shipper
CC65 ?= ca65
LD65 ?= ld65

SRC   = src/main.s
BUILD = build
OBJ   = $(BUILD)/main.o
PRG   = $(BUILD)/$(NAME).prg
NES   = $(BUILD)/$(NAME).nes
CFG   = nrom128.cfg
HDR   = $(BUILD)/header.bin

# RetroArch: rgui_browser_directory is ~/Games/roms (see retroarch.cfg)
RA_ROMS ?= $(HOME)/Games/roms
RA_NES  = $(RA_ROMS)/nes
RA_CORE ?= nestopia_libretro

all: $(NES) install

$(OBJ): $(SRC)
	mkdir -p $(BUILD)
	$(CC65) $(SRC) -o $(OBJ)

$(PRG): $(OBJ) $(CFG)
	$(LD65) -C $(CFG) $(OBJ) -o $(PRG)

# iNES: 1 PRG, 0 CHR (CHR-RAM), mapper 0, vertical mirroring (horizontal scroll)
$(HDR):
	mkdir -p $(BUILD)
	python3 -c "open('$(HDR)','wb').write(b'NES\x1a'+bytes([1,0,1,0])+bytes(8))"

$(NES): $(PRG) $(HDR)
	cat $(HDR) $(PRG) > $(NES)
	@echo "Built $(NES)"

# Symlink into RetroArch content dir so Load Content → nes/ always sees latest build
install: $(NES)
	mkdir -p $(RA_NES)
	ln -sfr $(NES) $(RA_NES)/$(NAME).nes
	@echo "Available in RetroArch: $(RA_NES)/$(NAME).nes"

# Build and launch with Nestopia (override: make run RA_CORE=mesen_libretro)
run: $(NES)
	retroarch -L $(RA_CORE) $(NES)

clean:
	rm -rf $(BUILD)
	rm -f $(RA_NES)/$(NAME).nes

.PHONY: all install run clean
