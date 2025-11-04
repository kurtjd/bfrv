bfrv
----
A brainfuck intepreter written in RISC-V (rv64i) assembly targeting Linux.

Build
-----
`make`

Run (easy)
----------
`make run` (runs life.bl)

Run (manual)
------------
`qemu-riscv64 bfrv <bf-file>`

Help
----
Make sure you have qemu-riscv64 and a riscv64 linux cross compiler installed,
then modify the Makefile if they have different names on your system. Unless
you're 1337 and running RISC-V natively, but then you know what to do.

Hack the planet!