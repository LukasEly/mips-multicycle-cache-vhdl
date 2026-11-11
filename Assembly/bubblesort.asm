.text
.globl main

main:	la $t1, vet		#pega o endere�o da primeira pos de vet
	la $t2, n		#endere�o do valor de n
	lw $t2, 0($t2)		#coloca o valor de n em $t2
	jal ordenaVetor
	li $v0, 10
	syscall

################################################################################################
#### BUBBLESORT ----------=== RECEBE UM VETOR ($T1)	->	RECEBE O TAMANHO DO VETOR ($T2)
################################################################################################
	
ordenaVetor:
	
	xor $t3, $t3, $t3
	xor $t9, $t9, $t9	#endereco de vet[i]
	xor $t8, $t8, $t8	#endereco de vet[j]
	xor $t0, $t0, $t0	#valor de vet[i]
	la $t9, 0($t1)		#pega o endereco de vet[i]
	xor $t6, $t6, $t6	#valor de vet[j]
	xor $t5, $t5, $t5	#garante que o j começa com 0
	xor $t4, $t4, $t4	#inicializa i
	j primeiroLoop		#entra no primeiro loop

primeiroLoop:
	
	xor $t8, $t8, $t8		#inicializa t8	
	beq $t4, $t2, retornaJal	#testa se i < n
	addu $t8, $t9, 4			#endereço de t8 = endereço de t9 + 4
	lw $t0, 0($t9)			# t0 recebe o valor de vet[i]
	addu $t5, $t4, 1 		#inicializa o j; j = i+1
	lw $t6, 0($t8)			# t6 recebe o valor de vet[j]
	
	j segundoLoop	

segundoLoop:
	
	beq $t5, $t2, incrementaPrimeiro	#se j == n volta pro primeiro loop
	bgt $t0, $t6, ordena			#do contrario confere se vet[i] > vet[j]; caso sim, então ordena
	j incrementaSegundo			#senão incrementa
	
ordena:
	xor $s0, $s0, $s0
	addu $s0, $t0, $0	#aux = vet[i]
	addu $t0, $t6, $0	#vet[i] = vet[j]
	addu $t6, $s0, $0	#vet[j] = aux
	sw $t0, 0($t9)		#guarda na memoria o valor de vet[i]
	sw $t6, 0($t8)		#guarda na memoria o valor de vet[j]
	j incrementaSegundo
		
incrementaPrimeiro:
	
	addu $t4, $t4, 1		#incrementa o i
	addu $t9, $t9, 4		#incrementa o endereco de memoria de vet[i]
	j primeiroLoop
	
incrementaSegundo:
	
	addu $t5, $t5, 1		#incrementa o j
	addu $t8, $t8, 4		#incrementa o endere�o de memoria de vet[j]
	lw $t6, 0($t8)		#pega o valor de vet[j]
	j segundoLoop	
	
retornaJal:	jr $ra

.data
n: .word 14
vet: .word 7 20 8 5 1 8 4 2 5 5 14 12 3 8
