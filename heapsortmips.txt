.data 
	# Declaramos el arreglo y su longitud y guardamos en memoria
	vector: .word 15, 3, 18, 5, 20, 2, 8
	len: .word 7
	
	# Guardamos en la memoria datos necesarios para imprimir
	space: .asciiz ", "
	newline: .asciiz "\n"


# ------- Memoria de instrucciones ------- #
.text
	
main: 
	la $a0, vector # -- $a0 = Dirección base del vector en memoria -- #
	lw $a1, len 	 # -- $a1 = Longitud del arreglo
	
	jal printarray
	
	jal heapsort
	
	jal printarray
	
	# Salir del programa
	addi $v0, $zero, 10
	syscall	

heapsort:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $a1, 4($sp)
	jal create_minheap
	jal extract
end_heapsort:
	lw $ra, 0($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

extract:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $s1, $a1, -1
	
	ciclo_extract:
		lw $s2, 0($a0) # Cargo el primer elemento del arreglo en $s2
		sll $s3, $s1, 2	# En $t1 cargo i*4
		add $s3, $s3, $a0 # $t1 = dirección de array[i]
		lw $s4, 0($s3)	# $t2 = array[i]
		
		sw $s4, 0($a0) # array[0] = array[i]
		sw $s2, 0($s3)
		
		addi $a1, $s1, 0
		addi $a2, $zero, 0
		
		jal heapify
		addi $s1, $s1, -1
		beq $s1, $zero, end_extract
		j ciclo_extract
	
end_extract:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
create_minheap:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	srl $a2, $a1, 1
	addi $a2, $a2, -1
	
	ciclo:
		la $a0, vector 	# -- $a0 = Dirección base del vector en memoria -- #
		lw $a1, len 	# -- $a1 = Longitud del arreglo
		jal heapify	 	
		ble $a2, $zero, end_createminheap
		addi $a2, $a2, -1
		j ciclo
	
end_createminheap:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

printarray:
	 add $t0, $a0, $zero # Guardamos la dirección base del vector en $t0
	 add $t1, $a1, $zero # Guardamos la longitud del arreglo en $t1

printloop:
	# Si el registro $t1 = 0 entonces termina el loop de impresión
	beq $t1, $zero, end_printloop
	# Cargamos el valor del arreglo que vamos a imprimir
	lw $t2, 0($t0)
	# Asignación de 1 a $v0 para el syscall (Imprimir entero)
	li $v0, 1
	# a $a0 le llevamos $t2 que es el número a imprimir
	add $a0, $t2, $zero
	syscall
	
	# Sumamos 4 a $t0 para que tome la dirección del vector un elemento después
	addi $t0, $t0, 4
	# Restamos 1 a $t1 para controlar cuando imprimimos todos los números del arreglo
	addi $t1, $t1, -1
	
	# Si llegamos a 0 en $t1 que no imprima una coma
	beq $t1, $zero, end_printloop 
	
	# Impresión de una coma y espacio
	# Cargamos 4 en $v0 para indicarle al syscall que debe imprimir un arreglo
	li $v0, 4
	# Le llevamos a $a0 el registro que previamente definimos con la coma y el espacio
	la $a0, space
	syscall
	
	# Volvemos a printloop en el caso de que no hayamos terminado aún
	j printloop
	
end_printloop:
	# Imprimimos una nueva línea después de imprimir todo el vector
	li $v0, 4
	la $a0, newline
	syscall
	
	jr $ra
	
heapify:
	
	
	addi $sp, $sp, -8		# Se reserva un espacio para el otro i (recursivo)
	sw $ra, 0($sp)
	sw $a2, 4($sp)
	
	add $t0, $a0, $zero 	# Cargamos la dirección del vector en $t0
	add $t1, $a1, $zero 	# Cargamos la longitud del arreglo en $t1
	add $t2, $a2, $zero 	# Cargamos el parámetro i de heapify
	
	add $t3, $t2, $zero 	# $t3 = min -- $t3 == i
	
	sll $t4, $t2, 1 		# $t4 = i*2
	addi $t4, $t4, 1		# $t4 = i*2+1 ($t4 = índice izquierdo)
	
	sll $t5, $t2, 1		# $t5 = i*2
	addi $t5, $t5, 2		# $t5 = i*2+1 ($t5 = índice derecho)
	
	# -- Parámetros necesarios para comparaciones -- #
	sll $t6, $t3, 2		# Cálculo de número de bytes en el arreglo para alcanzar array[min]
	add $s0, $t0, $t6		# t6 = dirección de array en la posición min
	lw $t6, 0($s0)		# t6 = arreglo[min]
	
	# -- Comparaciones -- #
	
	# -- Comparación izquierda -- #
	sll $t7, $t4, 2		# $t7 = ind_izq * 4 Nro de bytes para alcanzar array[ind_izq]
	add $t7, $t0, $t7		# $t7 = dirección de array[ind_izq]
	lw $t7, 0($t7)		# $t7 = array[ind_izq]
	
	comp_izq:		
		bge $t4, $t1, end_compizq
		bge $t7, $t6, end_compizq
		
		addi $t3, $t4, 0
	end_compizq:
	
	sll $t6, $t3, 2		# Cálculo de número de bytes en el arreglo para alcanzar array[min]
	add $s0, $t0, $t6		# t6 = dirección de array en la posición min
	lw $t6, 0($s0)		# t6 = arreglo[min]
	
	# -- Comparación Derecha -- #
	sll $t7, $t5, 2		# $t7 = ind_der * 4 Nro de bytes para alcanzar array[ind_der]
	add $t7, $t0, $t7	# $t7 = dirección de array[ind_der]
	lw $t7, 0($t7)		# $t7 = array[ind_der]
	
	comp_der:
		bge $t5, $t1, end_compder
		bge $t7, $t6, end_compder
		
		addi $t3, $t5, 0
	end_compder:
	
	# Intercambio de valores en el arreglo
	beq $t3, $t2, end_heapify	# Salta si min = i
	sll $t8, $t2, 2			# $t8 = i * 4
	add $t8, $t8, $t0			# $t8 = dirección arr[i]
	lw $t9, 0($t8)			# $t8 = arr[i]
	
	sll $t6, $t3, 2			# Cálculo de número de bytes en el arreglo para alcanzar array[min]
	add $s0, $t0, $t6			# s0 = dirección de array en la posición min
	lw $t6, 0($s0)			# t6 = arreglo[min]
	
	sw $t6, 0($t8)			# arr[i] = arr[min]
	sw $t9, 0($s0)	
	
	addi $a2, $t3, 0
	jal heapify
	
	lw $a2, 4($sp)
	
end_heapify:
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra

