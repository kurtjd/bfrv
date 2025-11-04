TOOLCHAIN   = riscv64-unknown-linux-gnu
CC      	= $(TOOLCHAIN)-gcc
CC_FLAGS 	= -nostdlib -g
BIN			= bfrv
QEMU    	= qemu-riscv64
DEBUGGER 	= $(TOOLCHAIN)-gdb

all: $(BIN)

$(BIN): $(BIN).s
	$(CC) $(CC_FLAGS) -o $@ $<

clean:
	rm -f *.o $(BIN)

run: $(BIN)
	$(QEMU) $(BIN) "life.bl"

debug: $(BIN)
	$(QEMU) -g 1234 $(BIN) "life.bf"

gdb: $(BIN)
	$(DEBUGGER) $(BIN)

