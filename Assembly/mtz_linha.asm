.data

mtz: .word 0:16
num_linhas: .word 4
num_colunas: .word 4

.text
.globl main

main:

    la $t0,num_linhas   # t0 = num_linhas
    lw $t0,0($t0) 
    la $t1,num_colunas  # t1 = num_colunas
    lw $t1,0($t1)
    li $t2,0            # t2 = i = 0
    li $t3,0            # t3 = j = 0
    la $t4,mtz          # t4 = &mtz
    addu $t5,$t4,0       # t5 = iterator = &mtz[0]
    j for_i

# for(int i = 0; i < num_linhas; i++) {

inc_i:
    addu $t2,$t2,1       # i++
for_i:
    bge $t2,$t0,fim     # i >= num_linhas, j fim
    li $t3,0            # j = 0
    jal for_j           # recursivo for_j()
    j inc_i             # goto inc_i
    
# }
# for(int j = 0; j < num_colunas; j++) {

for_j:
    lw  $t6,0($t5)      # t6 = *t5
    addu $t6,$t2,$t3     # t6 = i + j
    sw  $t6,0($t5)      # *t5 = $t6
    addu $t5,$t5,4       # t5++
    addu $t3,$t3,1       # j++
    blt $t3,$t1,for_j   # j < num_colunas
    jr $ra              # return;

# }

fim:
    li $v0,10
    syscall            # fim do programa
