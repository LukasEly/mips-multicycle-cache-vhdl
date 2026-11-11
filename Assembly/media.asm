.text
	.globl main
	
main:	la $t1, vet		#pega o endere�o da primeira pos de vet
	la $t2, n		#endere�o do valor de n
	lw $t2, 0($t2)		#coloca o valor de n em $t2

###########################################################################################################################################
############ CALCULO DA MEDIA
###########################################################################################################################################
			
mediaInicio:	la $t7, media	#pega o endere�o de media
	xor $t3, $t3, $t3	#inicializa a vari�vel para alocar o valor de media, j� que o endere�o de media precisa ser salvo
	xor $t4, $t4, $t4	#inicializa o i com 0
	xor $t5, $t5, $t5	#variavel para armazenar o valor de t1[i]
	xor $t6, $t6, $t6	#inicializa a variavel que armazena o endere�o inicial do vet
	addu $t6, $t1, $0	#armazena o endere�o inicial do vet	
	
mediaLoop:			#loop media
	
	beq $t4, $t2, calculaMedia	#confere se o valor de i � igual do que n
	lw $t5, 0($t6)		#carrega em t5 o valor de de vet[t6]
	addu $t3, $t3, $t5	#se n�o ent�o soma o valor atual de m�dia com o vetor na pos do endere�o
	addu $t4, $t4, 1		#incrementa i
	addu $t6, $t6, 4		#incrementa o endere�o de t6
	
	j mediaLoop		#volta para o loop

calculaMedia: 
	
	addu $s1, $t3, $0
	addu $s0, $t2, $0
	
	jal divider
	
	sw $v1, 0($t7)		#guarda o valor de v1
	#recuprerar os valores de $t1 e $t2 dps da divis�o serial
	la $t1, vet
	la $t2, n		#endere�o do valor de n
	lw $t2, 0($t2)		#coloca o valor de n em $t2
	jal ordenaVetor		#entra na ordena��o do vetor
	j end

###########################################################################################################################################
					
										
																				
###############################################################################################
###  Divisão serial  $s1/ $s0 -->   $v0--> resto    $v1 --> divisão
###############################################################################################
divider:  lui   $t0, 0x8000       # mascara para isolar bit mais significativo
          li    $t1, 32           # contador de iterações

          xor   $v0, $v0, $v0     # registrador P($v0)-A($v1) com  0 e o dividendo
          addu   $v1, $s1, $0

dloop:    and   $t2, $v1, $t0     # isola em t2 o bit mais significativo do registador 'A' ($v1)
          sll   $v0, $v0, 1       # desloca o registrado P-A
          sll   $v1, $v1, 1 

          beq   $t2, $0, di1    
          ori   $v0, $v0, 1       # coloca 1 no bit menos significativo do registador 'P'($v0)

di1:      subu   $t2, $v0, $s0     # subtrai 'P'($v0) do divisor ($s0)
          blt   $t2, $0, di2
          addu   $v0, $t2, $0      # se a subtração deu positiva, 'P'($v0) recebe o valor da subtração
          ori   $v1, $v1, 1       # e 'A'($v1) recebe 1 no bit menos significativo

di2:      addi  $t1, $t1, -1      # decrementa o número de iterações 
          bne   $t1, $0, dloop 

          jr    $ra  

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

################################################################################################
			

	
end:
	li $v0, 10
	syscall

##########################################
### DATA
##########################################

.data

n: .word 14
media: .word 0
vezes: .word 0
vet: .word 7 20 8 5 1 8 4 2 5 5 14 12 3 8
