  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb

  .global Main


  .section  .text

Main:
  STMFD   SP!, {LR}

  LDR     R0, =0x3f000000    @ 0.5
  LDR     R1, =0x3f000000    @ 0.5
  BL      fp_add             @ result should be 1.0 (0x3f800000)

  LDR     R0, =0x3f800000    @ 1.0
  LDR     R1, =0x3f800000    @ 1.0
  BL      fp_add             @ result should be 2.0 (0x40000000)

  LDR     R0, =0x3f000000    @ 0.5
  LDR     R1, =0x3f800000    @ 1.0
  BL      fp_add             @ result should be 1.5 (0x3fc00000)

  LDR     R0, =0x3f800000    @ 1.0
  LDR     R1, =0x3f000000    @ 0.5
  BL      fp_add             @ result should be 1.5 (0x3fc00000)

  LDR     R0, =0x41200000    @ 10
  LDR     R1, =0x3fe00000    @ 1.75
  BL      fp_add             @ result should be 11.75 (0x413c0000)

  LDR     R0, =0xc1200000    @ -10
  LDR     R1, =0x3fe00000    @ 1.75
  BL      fp_add             @ result should be -8.25 (0xc1040000)

  LDR     R0, =0xbfe00000    @ -1.75
  LDR     R1, =0x41200000    @ 10
  BL      fp_add             @ result should be 8.25 (0x41040000)

End_Main:
  LDMFD   SP!, {PC}


.end
