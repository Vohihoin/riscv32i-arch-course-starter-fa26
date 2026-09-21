## Author: Vahe Ohihoin
##
## You may implement the following with any of the instructions in the RV32I instruction set
## and described in the reference sheet. Do not use any of the mul[h][s][u] instructions which
## are *not* described in the reference sheet. Remember to respect the calling convention - if
## you choose to use any of the callee saved registers s[0-11], remember to save them to the
## stack before reusing them (note, you should not need to do this but are free to do so).
##
## [Description]
## Multiplies two 32-bit *unsigned* numbers and provides a 32-bit *unsigned* result
## consisting of the lower 32 bits of the product.
##
## [Arguments]
## a0 = multiplicand
## a1 = multiplier
##
## [Returns]
## a0 = 32-bit product

## Notes to self: x0 - x15 (caller saved, can use these without restriction)
## x16 - x31 (callee saved, have to save these before using)
    .text
    .globl umul
umul:
    add t5, zero, a0         # save the multiplicand before zero-ing a0 as our accumulator register
    add a0, zero, zero       # zero a0
loop:
    beq a1, zero, done;      # if our multiplier is 0 then, we don't need to accumulate anything
    andi t4, a1, 1           # else we check what bit-0 of multiplier is
    beq t4, zero, skip_accum # if 0, we don't need to accumulate and so we skip that
    add a0, a0, t5           # else we accum into a0 whatever our multiplicand is
skip_accum:
    slli t5, t5, 1           # we shift our multiplicand left, so that we're adding the right multiplied value each cycle
    srli a1, a1, 1           # we also logically shift our multiplier right, so that bit 0 is the appropriate postion we want to add in 
    jal zero, loop
done:
    jalr zero, 0(ra)
