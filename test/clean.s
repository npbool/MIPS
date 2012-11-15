main:
li $2,0x1FD003F8
li $3,0x1FC00000
li $4,0xFE102353
li $5,0x00000003
slt $6,$4,$5

sltu $6,$4,$5

and $6,$2,$4

sll $7,$6,2

sllv $7,$6,$5

srl $7,$6,30

sra $7,$6,30

mult $2,$3
mfhi $6

mflo $6

sw $4,1000($0)
lw $6,1000($0)

lb $6,1003($0)

srl $6,$6,8


