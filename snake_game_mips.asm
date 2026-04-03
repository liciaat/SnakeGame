.data 
	#Endereços de Base
	.eqv DISPLAY_BASE 0x10008000 #endereço onde começa o bitmap display
	.eqv KEYBOARD_CTRL 0xFFFF0000 #controlador teclado 
	.eqv KEYBOARD_DATA 0xFFFF0004 #onde o valor da tecla é guardado
	
	#posições inciais da cobra(x, y)
	x_pos_cur: .word 4
	y_pos_cur: .word 4
	x_pos_next: .word 4
	y_pos_next: .word 4
	
	#comida e jogo 
	x_food: .word 10
	y_food: .word 10
	delay_time: .word 150
	score: .word 0
	max_score: .word 5
	
	#cores
	color_snake: .word 0x0000FF00  # Verde
	color_food: .word 0x00FF0000  # Vermelho
	color_back: .word 0x00000000  # Preto
	
	# Direção inicial (1: cima, 2: baixo, 3: esquerda, 4: direita)
    	direcao: .word 4  # Começa indo para a direita

.text
main:
	#carregando as variáveis do data para os registradores 
	lw $s0, x_pos_cur
	lw $s1, y_pos_cur
	lw $s4, x_food
	lw $s5, y_food
	lw $s6, delay_time
	lw $s7, score
	lw $t5, max_score
	
	# desenhar a cobra 
	move $a0, $s0 # x
	move $a1, $s1 # y
	lw $a2, color_snake # cor cobra
	jal draw_pixel # desenha cobra
	
	# desenhar comida 
	move $a0, $s4 # x
	move $a1, $s5 # y
	lw $a2, color_food # cor comida
	jal draw_pixel # desenha comida
	
	
loop_principal: 
	# delay
	li $v0, 32 # syscall sleep
	move $a0, $s6 # $s6 é o delay (150)
	syscall
	
	# apaga pos antiga 
	move $a0, $s0 # x atual
	move $a1, $s1 # y atual
	lw $a2, color_back
	jal draw_pixel
	
	#teclado
	jal check_keyboard
	
	#mov
	lw $t9, direcao
	li $t4, 1
	beq $t9, $t4, mov_cima
	li $t4, 2
	beq $t9, $t4, mov_baixo
	li $t4, 3
	beq $t9, $t4, mov_esq
	li $t4, 4
	beq $t9, $t4, mov_direita
	j atualizar_pos
	
mov_cima: 
	addi $s1, $s1, -1
	j atualizar_pos
mov_baixo: 
	addi $s1, $s1, 1
	j atualizar_pos
mov_esq: 
	addi $s0, $s0, -1
	j atualizar_pos
mov_direita: 
	addi $s0, $s0, 1
	j atualizar_pos

atualizar_pos:
	#bordas
	andi $s0, $s0, 15 # se x=16, vira 0. x= -1, vira 15
	andi $s1, $s1, 15 # se y=16, vira 0. y=-1, vira 15
	
	#comeu?
	bne $s0, $s4, desenhar_cobra # x dif, não comeu
	bne $s1, $s5, desenhar_cobra # y dif, não comeu
	
	# comeu
	addi $s7, $s7, 1 # score++
	beq $s7, $t5, fim
	# gerar x aleatório 
	li $v0, 42
	li $a1, 16
	syscall
	move $s4, $a0
	# gerar y aleatório 
	li $v0, 42
	li $a1, 16
	syscall
	move $s5, $a0
	
	# desenha nova comida
	move $a0, $s4
	move $a1, $s5
	lw $a2, color_food
	jal draw_pixel

desenhar_cobra:
	move $a0, $s0
	move $a1, $s1
	lw $a2, color_snake
	jal draw_pixel
	j loop_principal

draw_pixel: 
	# salvar na pilha
	addi $sp, $sp, -4 #reserva 4 bytes na pilha
	sw $ra, 0($sp) # salva o end de retorno 
	
	# (y*16+x)*4
	sll $t8, $a1, 4 # t8 = y*16
	add $t8, $t8, $a0 # t8 = (y*16) + x
	sll $t8, $t8, 2 # t8 = t8 * 4
	la $t9, DISPLAY_BASE # carrega o endereço base 
	add $t9, $t9, $t8 # soma o deslocamento
	sw $a2, 0($t9) # escreve a cor na memor do display (pinta o pixel)
	
	# restaura pilha
	lw $ra, 0($sp) # recupera o end de retorno
	addi $sp, $sp, 4 # devolve o esp para a pilha
	jr $ra # volta ao loop_principal

check_keyboard:
	# salvar na pilha
	addi $sp, $sp, -4 # reserva 4 bytes na pilha
	sw $ra, 0($sp) # salva o end de retorno 
	
	#ler teclado
	la $t0, KEYBOARD_CTRL 
	lw $t1, 0($t0) 
	andi $t1, $t1, 1 #verifica o bit de pronto(1- le a tecla | 0 - ignora)
	beq $t1, $zero, end_check_kbd # = 0 ent sai 
	lw $t2, KEYBOARD_DATA # le o ascii
	#compara(w=119 | s=115 | a=97 | d=100)
	li $t3, 119
	beq $t2, $t3, set_cima
	li $t3, 115
	beq $t2, $t3, set_baixo
	li $t3, 97
	beq $t2, $t3, set_esq
	li $t3, 100
	beq $t2, $t3, set_dir
	j end_check_kbd
set_cima:  
	li $t8, 1
	sw $t8, direcao
	j end_check_kbd
set_baixo: 
	li $t8, 2
	sw $t8, direcao
	j end_check_kbd
set_esq:   
	li $t8, 3
	sw $t8, direcao
	j end_check_kbd
set_dir: 
	li $t8, 4
	sw $t8, direcao
	j end_check_kbd
end_check_kbd:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

fim:
	li $v0, 10 #syscall para encerrar
	syscall
	
