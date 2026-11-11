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
    mulu $t7,$t1,4       # t7 = compensador1 = 0
    li $t8,4            # t8 = compensador2 = 0
    j for_i

# for(int i = 0; i < num_colunas; i++) {

inc_i:
    addu $t2,$t2,1       # i++
    addu $t5,$t4,0       # iterator = &mtz[0]
    addu $t5,$t5,$t8     # iterator += t8
    addu $t8,$t8,4       # t8 = sizeof(int)
for_i:
    bge $t2,$t1,fim     # i >= num_linhas, j fim
    li $t3,0            # j = 0
    jal for_j           # recursivo for_j()
    j inc_i             # goto inc_i
    
# }
# for(int j = 0; j < num_linhas; j++) {

for_j:
    lw  $t6,0($t5)      # t6 = *t5
    addu $t6,$t2,$t3     # t6 = i + j
    sw  $t6,0($t5)      # *t5 = $t6
    addu $t5,$t5,$t7     # t5 += num_colunas
    addu $t3,$t3,1       # j++
    blt $t3,$t0,for_j   # j < num_colunas
    jr $ra              # return;

# }

fim:
    li $v0,10
    syscall            # fim do programa
