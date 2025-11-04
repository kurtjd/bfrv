# Linux syscalls
.equ EXIT, 93
.equ OPEN, 56
.equ CLOSE, 57
.equ READ, 63
.equ WRITE, 64
.equ STDIN, 0
.equ STDOUT, 1

# Some values for Linux constants
.equ AT_FDCWD, -100
.equ O_RDONLY, 0

# Max brainfuck RAM and ROM we support
.equ RAMSZ, 4096
.equ ROMSZ, 4096

# Store the RAM and ROM statically in memory
.data
ram: .zero RAMSZ
rom: .zero ROMSZ

.text
.globl _start
# Linux calls _start for us when we are loaded
_start:
    # Open file from command line for reading
    li a7, OPEN 
    li a0, AT_FDCWD
    ld a1, 16(sp) # Aka argv[1]
    li a2, O_RDONLY
    ecall
    # FD is now in a0... but copy to temp for closing
    mv t0, a0

    # Read file into ROM
    li a7, READ
    la a1, rom
    li a2, ROMSZ
    ecall
    # Num bytes read now in a0... but copy to temp for later
    mv t1, a0

    # Close file
    li a7, CLOSE
    mv a0, t0

    # Program counter
    la s2, rom

    # Program end
    add s3, s2, t1

    # RAM pointer
    la s4, ram

# Main brainfuck interpretation loop, until we hit EOF
interpret:
    # Load instruction
    lb t0, 0(s2)

    # Jump to instruction handler
    li t1, '>'
    beq t0, t1, inc_ptr
    li t1, '<'
    beq t0, t1, dec_ptr
    li t1, '+'
    beq t0, t1, inc_byte
    li t1, '-'
    beq t0, t1, dec_byte
    li t1, '.'
    beq t0, t1, out_byte
    li t1, ','
    beq t0, t1, in_byte
    li t1, '['
    beq t0, t1, branch_start
    li t1, ']'
    beq t0, t1, branch_end

    # If not an instruction, ignore it (treat like comment)
    j continue

inc_ptr:
    addi s4, s4, 1
    j continue

dec_ptr:
    addi s4, s4, -1
    j continue

inc_byte:
    lb t0, 0(s4)
    addi t0, t0, 1
    sb t0, 0(s4)
    j continue

dec_byte:
    lb t0, 0(s4)
    addi t0, t0, -1
    sb t0, 0(s4)
    j continue

out_byte:
    # Setup syscall to print the ascii character in the current cell
    li a7, WRITE
    li a0, STDOUT
    mv a1, s4
    li a2, 1
    ecall
    j continue

in_byte:
    # Setup syscall to read character from stdin into current cell
    li a7, READ
    li a0, STDIN
    mv a1, s4
    li a2, 1
    ecall
    j continue

branch_start:
    # If current cell is zero, jump to end of branch
    lb t0, 0(s4)
    beqz t0, branch_jump_end
    # Otherwise continue as if nop
    j continue
# Need to walk until we find the matching branch end
# This accounts for nested branches, so need to keep track
branch_jump_end:
    li t1, 1
    li t2, '['
    li t3, ']'
branch_jump_end_loop:
    # If our count is zero, we've found the matching branch end and resume interpreting
    beqz t1, continue
    # Otherwise keep checking
    addi s2, s2, 1
    lb t0, 0(s2)
    # If instruction is [ or ], inc or dec count respectively
    beq t0, t2, branch_jump_end_inc
    beq t0, t3, branch_jump_end_dec
    # Otherwise continue checking next instruction
    j branch_jump_end_loop
branch_jump_end_inc:
    addi t1, t1, 1
    j branch_jump_end_loop
branch_jump_end_dec:
    addi t1, t1, -1
    j branch_jump_end_loop

branch_end:
    # If current cell is non-zero, jump to start of branch
    lb t0, 0(s4)
    bnez t0, branch_jump_start
    # Otherwise continue as if nop
    j continue
# Need to walk until we find the matching branch start
# This accounts for nested branches, so need to keep track
branch_jump_start:
    li t1, 1
    li t2, ']'
    li t3, '['
branch_jump_start_loop:
    # If our count is zero, we've found the matching branch start and resume interpreting
    beqz t1, continue
    # Otherwise keep checking
    addi s2, s2, -1
    lb t0, 0(s2)
    # If instruction is ] or [, inc or dec count respectively
    beq t0, t2, branch_jump_start_inc
    beq t0, t3, branch_jump_start_dec
    # Otherwise continue checking next instruction
    j branch_jump_start_loop
branch_jump_start_inc:
    addi t1, t1, 1
    j branch_jump_start_loop
branch_jump_start_dec:
    addi t1, t1, -1
    j branch_jump_start_loop

continue:
    # Increment PC
    addi s2, s2, 1
    # Check if program done
    bge s2, s3, exit
    j interpret

exit:
    # Setup syscall to exit properly
    li a7, EXIT
    li a0, 0
    ecall
