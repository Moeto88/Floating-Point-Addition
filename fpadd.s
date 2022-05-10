  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb
  
  .global   fp_add

@ fp_add subroutine
@ Add two IEEE-754 floating point numbers
@
@ Paramaters:
@   R0: a - first number
@   R1: b - second number
@
@ Return:
@   R0: result - a+b 

@ myResult:
@ 00111111100000000000000000000000
@ expectedResult
@ 00111111100000000000000000000000

@ binaryNum1
@ 0 01111111 00000000000000000000000
@          1 00000000000000000000000

fp_add:
  PUSH    {R4-R11,LR}            @ add any registers R4...R12 that you use

  MOV     R4, R0          @ copyOfNum1 = a
  MOV     R5, R1          @ copyOfNum2 = b
  MOV     R11, #0         @ classifier = 0

  BL      fp_exp          @ fp_exp()
  MOV     R6, R0          @ expOfNum1 = result

  MOV     R0, R5          @ IEEE-754 = copyOfNum2
  BL      fp_exp          @ fp_exp()

  MOV     R7, R0          @ expOfNum2 = result

  MOV     R0, R4          @ IEEE-754 = copyOfNum1
  BL      fp_frac         @ fp_frac()
  MOV     R8, R0          @ frcOfNum1 = result

  MOV     R0, R5          @ IEEE-754  = copyOfNum2
  BL      fp_frac         @ fp_frac()

  MOV     R9, R0          @ frcOfNum2 = result
  
  CMP     R6, R7          @ if(expOfNum1 == expOfNum2)
  BNE     elseIf          @ {
  ADD     R0, R8, R9      @  fraction = frcOfNum1 + frcOfNum2
  MOV     R1, R6          @  exponent = expOfNum1
  BL      fp_enc          @  fp_enc()
  B       endAll          @ }

elseIf:
  CMP     R6, R7          @ else if(expOfNum1 < expOfNum2)
  BGT     else            @ {
  CMP     R4, #0          @  if(copyOfNum1 >= 0)
  BLT     negForSub2      @  {
endNegForSub2:
  SUB     R10, R7, R6     @   count = expOfNum2 - expOfNum1
whileForNorm: 
  CMP     R10, #0         @   while(count > 0)
  BLE     endWhileNorm    @   {
  MOV     R8, R8, LSR #1  @    shift to the right by 1bit
  SUB     R10, R10, #1    @    count--
  B       whileForNorm    @   }
endWhileNorm:
  CMP     R11, #1         @   if(classifier != 1)
  BEQ     subVer2         @   {
  ADD     R0, R8, R9      @    fraction = frcOfNum1 + frcOfNum2
  MOV     R1, R7          @    exponent = expOfNum2
  BL      fp_enc          @    fp_enc()          
  B       endAll          @   }
subVer2:                  @   else {
  SUB     R0, R9, R8      @    fraction = frcOfNum2 - frcOfNum1
  MOV     R1, R7          @    exponent = expOfNum2
  BL      fp_enc          @    fp_enc()
  B       endAll          @   }

negForSub2:               @  else {
  NEG     R8, R8          @   frcOfNum1 = -frcOfNum1
  MOV     R11, #1         @   classifier = 1
  B       endNegForSub2   @  }

else:                     @ else {
  CMP     R5, #0          @ if(copyOfNum2 >= 0)
  BLT     negForSub       @  {
endNegForSub:
  SUB     R10, R6, R7     @   count = expOfNum1 - expOfNum2
whileForNorm2:            @
  CMP     R10, #0         @   while(count > 0)
  BLE     endWhileNorm2   @   {
  MOV     R9, R9, LSR #1  @    shift to the right by 1bit
  SUB     R10, R10, #1    @    count--
  B       whileForNorm2   @   }
endWhileNorm2:
  CMP     R11, #1         @   if(classifier != 1)
  BEQ     subVer          @   {
  ADD     R0, R8, R9      @    fraction = frcOfNum1 + frcOfNum2
  MOV     R1, R6          @    exponent = expOfNum1
  BL      fp_enc          @    fp_enc()        
  B       endAll          @   }
subVer:                   @   else {
  SUB     R0, R8, R9      @    fraction = frcOfNum1 - frcOfNum2
  MOV     R1, R6          @    exponent = expOfNum1
  BL      fp_enc          @    fp_enc()
  B       endAll          @   }

negForSub:                @  else {
NEG     R9, R9            @   frcOfNum2 = -frcOfNum2
MOV     R11, #1           @   classifier = 1
B       endNegForSub      @  }

endAll:

  POP     {R4-R11,PC}                      @ add any registers R4...R12 that you use

fp_exp:
  PUSH    {R4-R7,LR}                      @ add any registers R4...R12 that you use

  MOV     R4, R0            @ tmp = IEEE-754
  LDR     R5, =23           @ cons1 = 23
  LDR     R6, =127          @ cons2 = 23
While:
  CMP     R5, #0            @ while(cons1 > 0)
  BLE     endWhile          @ {
  MOV     R4, R4, LSR #1    @  shift to the right by 1bit
  SUB     R5, R5, #1        @  cons1--
  B       While             @ }
endWhile: 
  CMP     R0, #0            @ if(IEEE-754 >= 0)
  BLT     ifNegative        @ {
bias:   
  SUB     R4, R4, 127       @  tmp =  tmp - 127
  MOV     R0, R4            @  result = tmp
  B       endBias           @ }

ifNegative:                 @ else {
  LDR     R7, =0b11111111111111111111111011111111 @ mask = 0b11111111111111111111111011111111
  AND     R4, R4, R7        @        clear 8bit
  B       bias              @      }

endBias:

  POP     {R4-R7,PC}                      @ add any registers R4...R12 that you use



fp_frac:
  PUSH    {R4-R9,LR}                      @ add any registers R4...R12 that you use

  MOV     R4, R0               @ tmp1 = IEEE-754
  MOV     R9, R0               @ tmp2 = IEEE-754
  CMP     R9, #0               @ if(tmp2 >= 0)
  BLT     ifNegative2          @ {
start:
  LDR     R5, =8               @  cons1 = 8
  MOV     R6, R5               @  copyOfCons1 = 8
While2:
  CMP     R5, #0               @  while(cons1 > 0)
  BLE     endWhile2            @  {
  MOV     R4, R4, LSL #1       @   shift to the left by 1bit 
  SUB     R5, R5, #1           @   cons1--
  B       While2               @  }
endWhile2:  
While3:
  CMP     R6, #0               @  while(copyOfCons1 > 0)
  BLE     endWhile3            @  {
  MOV     R4, R4, LSR #1       @   shift to the right by 1bit
  SUB     R6, R6, #1           @   copyOfCons1--  
  B       While3               @  }
endWhile3:
  LDR     R7, =0b00000000100000000000000000000000  @ mask = 0b00000000100000000000000000000000
  ORR     R4, R4, R7           @  set bit24
  MOV     R0, R4               @  result = tmp1
  CMP     R9, #0               @  if(tmp2 < 0)
  BGE     finish               @  {
  NEG     R0, R0               @   result = -result
  B       finish               @  }

ifNegative2:
  LDR     R8, =0b01111111111111111111111111111111  @ mask = 0b01111111111111111111111111111111
  AND     R4, R4, R8           @ clear 31bit
  B       start                @ }

finish:

  POP     {R4-R9,PC}                      @ add any registers R4...R12 that you use



fp_enc:
  PUSH    {R4-R11,LR}                      @ add any registers R4...R12 that you use
  LDR     R11, =0b111111111111111111111111 @ cons1(for normalisation) = 0b111111111111111111111111
  MOV     R5, R1             @ exp = exponent
  MOV     R4, R0             @ frc1 = fraction
  MOV     R9, R0             @ frc2 = fraction

  CMP     R4, #0             @ if(frc1 < 0)
  BGE     loop               @ {
  NEG     R4, R4             @  frc1 = -frc1
loop:                        @ }
  CMP     R4, R11            @ if(frc > cons1)
  BLE     start2             @ {
  MOV     R4, R4, LSR #1     @  shift to the right by 1bit
  ADD     R5, R5, #1         @  exp++
  B       loop               @ }

start2:
  LDR     R6, =0b11111111011111111111111111111111 @ mask = 0b11111111011111111111111111111111
  AND     R4, R4, R6         @ clear 23bit

  LDR     R7, =127           @ cons2 = 127
  ADD     R5, R5, R7         @ exp = exp + cons2

  LDR     R8, =23            @ cons3 = 23
While4:
  CMP     R8, #0             @ while(cons3 > 0)
  BLE     endWhile4          @ {
  MOV     R5, R5, LSL #1     @  shift to the left by 1bit
  SUB     R8, R8, #1         @  cons3--
  B       While4             @ }
endWhile4:
  ADD     R0, R4, R5         @ result = frc1 + exp
  CMP     R9, #0             @ if(frc2 < 0)
  BGE     finish2            @ {
  LDR     R10, =0b10000000000000000000000000000000 @ mask = 0b10000000000000000000000000000000
  ORR     R0, R0, R10        @  set bit31

finish2:                     @ }
  POP     {R4-R11,PC}                      @ add any registers R4...R12 that you use



@
@ Copy your fp_frac, fp_exp, fp_enc subroutines from Assignment #6 here
@   and call them from fp_add above.
@


.end