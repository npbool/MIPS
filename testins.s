main:
addiu $9, $0, 1
addu $9, $9, $9
li $8, 1
subu $10, $9, $8
mul $10 $10 $9
jal hello
mul $9 $10 $9
hello:
subu $10 $10 $8
beq $8 $9 hello
bgtz $10 hello
bgez $10 hello
bne $10 $10 hello
li $11 1
sll $11 $11 1
srl $11 $11 1
sllv $11 $11 $11
srlv $11 $11 $8