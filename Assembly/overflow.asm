.data
var1:  .word 1       # Variável 2 começa com 1
var2:  .word 1       # Variável 3 começa com 1



.text
.globl main
main:
    lw  $t0, var1      # Carrega var2 em $t0
    lw  $t1, var2      # Carrega var3 em $t1

loop:
    beq $t1, $zero, teste_zero # Se o resultado em $t4 for não zero, houve overflow

    mulu $t0, $t0, 2  # Multiplica var2 por 2 (dobro) usando a instrução mulu
    mulu $t1, $t1, -2 # Multiplica var3 por -2 (negativo) usando a instrução mulu
    
    j loop            # Loop de novo se não houve overflow
    nop
    
teste_zero:
    beq $t2, $zero, overflow_detected
    j loop
    
overflow_detected:
    # Saia do programa
    li $v0, 10
    syscall
