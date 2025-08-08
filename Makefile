# gladiator/Makefile
# Use one shell per recipe so heredocs work
.ONESHELL:
# Requires cc65 toolchain installed: ca65, ld65
# Build: make
# Clean: make clean

NAME = gladiator

CC65 ?= ca65
LD65 ?= ld65

SRC = src/main.s
BUILD = build
PRG = $(BUILD)/$(NAME).prg
NES = $(BUILD)/$(NAME).nes
OBJ = $(BUILD)/main.o
CFG = nrom128.cfg
HDR = $(BUILD)/header.bin

all: $(NES)

$(OBJ): $(SRC)
	@mkdir -p $(BUILD)
	$(CC65) $(SRC) -o $(OBJ)

$(PRG): $(OBJ) $(CFG)
	$(LD65) -C $(CFG) $(OBJ) -o $(PRG)

$(HDR):
	@mkdir -p $(BUILD)
	python3 - <<-'PY'
	hdr = bytearray(b'NES\x1A')
	hdr += bytes([1, 0, 0, 0]) + bytes(8)  # 1 PRG bank, 0 CHR, mapper 0
	open('$(HDR)','wb').write(hdr)
	PY

$(NES): $(PRG) $(HDR)
	cat $(HDR) $(PRG) > $(NES)
	@echo "Built $(NES)"

clean:
	rm -rf $(BUILD)

.PHONY: all clean
