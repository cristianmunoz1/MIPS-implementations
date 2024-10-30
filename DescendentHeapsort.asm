.data
    filename: .asciiz "numeros.txt"     # Nombre del archivo de entrada con los n�meros
    buffer: .space 100                  # Espacio para almacenar temporalmente el contenido del archivo
    vector: .space 100                  # Espacio para almacenar los n�meros convertidos
    space: .asciiz ", "                 # Cadena que representa la coma y espacio
    NewFile: .asciiz "equipo04.txt"     # Nombre del archivo de salida
    new_space: .space 2048              # Espacio para conversi�n de n�meros a texto


# ------- Memoria de instrucciones ------- #
.text
	
main: 
	jal leerarchivo
	jal longitudArreglo
	jal heapsort
	jal guardar_archivo
	jal terminate_execution

# -------------------- FUNCIONES -------------------- #

# Función para guardar el archivo de texto con el arreglo que hay en memoria ----------#

leerarchivo:
# Abrir archivo de entrada
        addi $v0, $zero, 13             # Syscall para abrir archivo
        la $a0, filename                # Direcci�n del nombre del archivo
        addi $a1, $zero, 0              # Modo de lectura (read-only)
        addi $a2, $zero, 0              # Permisos por defecto
        syscall
        add $t0, $zero, $v0             # Guardar el descriptor del archivo en $t0

        # Leer el contenido del archivo
        addi $v0, $zero, 14             # Syscall para leer archivo
        add $a0, $zero, $t0             # Descriptor de archivo en $a0
        la $a1, buffer                  # Direcci�n de almacenamiento del buffer
        addi $a2, $zero, 100            # Tama�o m�ximo de lectura en bytes
        syscall
        add $t1, $zero, $v0             # Almacenar n�mero de bytes le�dos en $t1

        # Cerrar el archivo
        addi $v0, $zero, 16             # Syscall para cerrar archivo
        add $a0, $zero, $t0             # Descriptor de archivo
        syscall

        # Configurar punteros para el parsing de n�meros
        la $t2, buffer                  # Puntero al inicio del buffer
        add $t3, $t2, $t1               # Puntero al final del buffer
        addi $sp, $sp, -4               # Reservar espacio en la pila

parse_loop:
        # Comprobar fin del buffer
        beq $t2, $t3, end_parse         # Si llegamos al final, salir del bucle
        lb $t4, 0($t2)                  # Cargar el siguiente byte en $t4
        beq $t4, 44, store_number       # Si es una coma (','), almacenar n�mero
        beq $t4, 10, end_parse          # Si es salto de l�nea, terminar
        beq $t4, 13, end_parse          # Si es retorno de carro, terminar
        sub $t4, $t4, 48                # Convertir de ASCII a n�mero (0-9)
        mul $t5, $t5, 10                # Multiplicar el n�mero actual por 10
        add $t5, $t5, $t4               # A�adir el d�gito actual
        addi $t2, $t2, 1                # Avanzar al siguiente byte
        j parse_loop

    store_number:
        # Almacenar el n�mero en la pila y preparar para el siguiente
        sw $t5, 0($sp)                  # Guardar n�mero en la pila
        addi $sp, $sp, -4               # Reservar espacio para el siguiente n�mero
        addi $t5, $zero, 0              # Reiniciar $t5 para el pr�ximo n�mero
        addi $t2, $t2, 1                # Avanzar al siguiente byte
        j parse_loop

    end_parse:
        addi $sp, $sp, 4                # Ajustar la pila para iniciar la impresi�n

llenarVector:
        # Llenar el array desde la pila
        lw $t6, 0($sp)                  # Cargar n�mero desde la pila
        beq $t6, 0, end_leer               # Salir si encontramos un cero (fin de pila)
        bne $t7, $zero, indiceInicializado
        add $t7, $zero, 0               # Definir �ndice $t7 = 0
indiceInicializado:
 	sw $t6, vector($t7)             # Guardar el n�mero en vector[i]
        # Imprimir el n�mero actual
        addi $v0, $zero, 1              # Syscall para imprimir entero
        add $a0, $zero, $t6             # N�mero a imprimir
        syscall
        
        # Avanzar en la pila y aumentar el �ndice del vector
        addi $sp, $sp, 4                # Moverse al siguiente n�mero en la pila
        addi $t7, $t7, 4                # Incrementar �ndice
        j llenarVector
end_leer:
	la $a0, vector
	jr $ra

guardar_archivo:
    # Abrir o crear el archivo para escritura
    li $v0, 13               # syscall para abrir/crear archivo
    la $a0, NewFile          # nombre del archivo
    li $a1, 1                # modo de escritura
    li $a2, 0                # permisos por defecto
    syscall
    move $s6, $v0            # guardar el descriptor del archivo
    
    # Verificar si hubo error al abrir el archivo
    bltz $s6, cerrar_archivo          # si es negativo, hubo error
    
    # Inicializar variables
    la $t1, vector           # puntero al vector
    li $t2, 0                # �ndice
    la $s1, new_space        # buffer para conversi�n
    
escribir_bucle:
    lw $t3, ($t1)            # cargar n�mero actual
    beqz $t3, cerrar_archivo  # si es 0, terminamos
    
    # Convertir n�mero a string
    move $t4, $t3            # copiar n�mero para conversi�n
    li $t5, 0                # contador de d�gitos
    li $t6, 10               # divisor
    la $s1, new_space        # reiniciar puntero del buffer
    
    # Si el n�mero es negativo, manejarlo
    bgez $t4, bucle_conversion
    li $t7, 45               # ASCII del signo menos
    sb $t7, ($s1)            # guardar el signo
    addiu $s1, $s1, 1        # avanzar puntero
    neg $t4, $t4             # hacer positivo el n�mero
    
bucle_conversion:
    divu $t4, $t6            # dividir por 10
    mfhi $t7                 # obtener residuo (�ltimo d�gito)
    mflo $t4                 # obtener cociente
    addiu $t7, $t7, 48       # convertir a ASCII
    sb $t7, ($s1)            # guardar d�gito
    addiu $s1, $s1, 1        # avanzar puntero
    addiu $t5, $t5, 1        # incrementar contador
    bnez $t4, bucle_conversion  # si quedan d�gitos, continuar
    
    # Invertir la cadena de caracteres
    la $s1, new_space        # reiniciar puntero
    add $t7, $s1, $zero      # guardar inicio
    add $t8, $s1, $t5        # apuntar al final
    addi $t8, $t8, -1        # ajustar al �ltimo car�cter
    
invertir_bucle:
    bge $t7, $t8, escribir_numero
    lb $t4, ($t7)            # cargar car�cter del inicio
    lb $t6, ($t8)            # cargar car�cter del final
    sb $t6, ($t7)            # intercambiar caracteres
    sb $t4, ($t8)
    addiu $t7, $t7, 1        # avanzar puntero inicio
    addiu $t8, $t8, -1       # retroceder puntero final
    j invertir_bucle
    
escribir_numero:
    # Escribir el n�mero en el archivo
    li $v0, 15               # syscall para escribir
    move $a0, $s6            # descriptor del archivo
    la $a1, new_space        # buffer con el n�mero
    move $a2, $t5            # longitud del n�mero
    syscall
    
    # Avanzar al siguiente n�mero
    addiu $t1, $t1, 4        # siguiente elemento del vector
    addiu $t2, $t2, 1        # incrementar �ndice
    
    # Verificar si hay m�s n�meros para escribir la coma
    lw $t3, ($t1)            # cargar el siguiente n�mero
    bnez $t3, escribir_coma  # si no es cero, escribir la coma
    j escribir_bucle         # si es cero, terminar el bucle

escribir_coma:
    # Escribir el separador (coma y espacio)
    li $v0, 15               # syscall para escribir
    move $a0, $s6            # descriptor del archivo
    la $a1, space            # ", "
    li $a2, 2                # longitud del separador
    syscall
    
    j escribir_bucle         # volver al bucle de escritura
    
cerrar_archivo:
    li $v0, 16               # syscall para cerrar archivo
    move $a0, $s6            # descriptor del archivo
    syscall
    jr $ra
    

#Calcular la longitud del arreglo
longitudArreglo:
	addi $sp, $sp, -8 		# Reservamos espacio en la pila
	sw $ra, 0($sp)			# Guardamos en la pila la posición de retorno
	sw $a0, 4($sp)			# Guardamos en la pila nuestro arreglo
	addi $t1, $zero, 0 		# Definimos el contador
whileElementoMayorCero:
	lw  $t2,0($a0)				# Guardamos en $t2 cada valor del arreglo al recorrerlo
        beq $t2,$zero,endElementoMayorCero	# Si $t2 = 0, entonces termina while
        addi $t1,$t1,1 			        # Sumamos 1 al contador
        addi $a0,$a0,4 		                # aumentamos en 4 el valor del indice de nuestro arreglo
        j   whileElementoMayorCero
endElementoMayorCero:    
        add $v0, $zero,$t1		# Guardamos en $v0 la longitud
        lw  $ra,0($sp)			# cargamos la posición de retorno
        lw  $a0,4($sp)			# Cargamos en $a0 el arreglo  guardado en la pila
        addi $sp,$sp,8			# liberamos la pila
        jr  $ra

	# ---------- Fin función para escribir el arreglo en un archivo de texto ------- #

# Función para terminar la ejecución del programa cuando se llame
terminate_execution:		
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $v0, $zero, 10
	syscall
end_terminate_execution:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# Función que dado un arreglo ingresado y una longitud, ordena el arreglo usando el algoritmo heapsort de manera descendente
heapsort:
	addi $a1, $v0, 0
	addi $sp, $sp, -8		# Reservamos 2 espacios en la pila para guardar la dirección de retorno y el parámetro n
	sw $ra, 0($sp)			# Guardamos la dirección de retorno en la pila
	sw $a1, 4($sp)			# Guardamos el $a1, que representa el tercer parámetro del heapify en la pila
	jal create_minheap		# Llamamos a la función minheap para que ordene el arreglo
	jal extract			# Llamamos a la función extract para que con el minheap creado anteriormente podamos ordenar el arreglo
end_heapsort:
	lw $ra, 0($sp)			# Obtenemos la dirección de retorno anterior
	lw $a1, 4($sp)			# Obtenemos el $a1 anterior
	addi $sp, $sp, 8		# Liberamos los 2 espacios en la pila
	jr $ra				# Retornamos al proceso que llamó heapsort

# Función que dado un arreglo ya ordenado como minheap, extrae cada elemento y lo pone en la posición correspondiente
extract:
	addi $sp, $sp, -4		# Reservamos un espacio en la pila para guardar la dirección de retorno
	sw $ra, 0($sp)			# Guardamos la dirección de retorno en la pila
	addi $s1, $a1, -1		# Obtenemos n - 1 y lo guardamos en $s1
	
	ciclo_extract:
		lw $s2, 0($a0) 		# Cargo el primer elemento del arreglo en $s2
		sll $s3, $s1, 2		# En $s3 cargo i*4
		add $s3, $s3, $a0 	# $s3 = dirección de array[i]
		lw $s4, 0($s3)		# $s3 = array[i]
		
		sw $s4, 0($a0) 		# array[0] = array[i]
		sw $s2, 0($s3)		# array[i] = array[0]
		
		addi $a1, $s1, 0	# $a1 = $s1 = i
		addi $a2, $zero, 0	# Al tercer argumento del heapify le llevamos cero
		
		jal heapify			# Llamamos la función heapify con los nuevos argumentos
		addi $s1, $s1, -1		# Restamos 1 a i
		beq $s1, $zero, end_extract	# Salta si $s1 = i llega a cero 
		j ciclo_extract
end_extract:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# Función que dado cualquier arreglo crea el minheap del mismo para luego implementar el ordenamiento
create_minheap:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	srl $a2, $a1, 1
	addi $a2, $a2, -1
	
	ciclo:
		la $a0, vector 		# -- $a0 = Dirección base del vector en memoria -- #
		#lw $a1, len 		# -- $a1 = Longitud del arreglo
		jal heapify	 	
		ble $a2, $zero, end_createminheap
		addi $a2, $a2, -1
		j ciclo
	
end_createminheap:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

heapify:
	
	
	addi $sp, $sp, -8	# Se reserva un espacio para el otro i (recursivo)
	sw $ra, 0($sp)
	sw $a2, 4($sp)
	
	add $t0, $a0, $zero 	# Cargamos la dirección del vector en $t0
	add $t1, $a1, $zero 	# Cargamos la longitud del arreglo en $t1
	add $t2, $a2, $zero 	# Cargamos el parámetro i de heapify
	
	add $t3, $t2, $zero 	# $t3 = min -- $t3 == i
	
	sll $t4, $t2, 1 	# $t4 = i*2
	addi $t4, $t4, 1	# $t4 = i*2+1 ($t4 = índice izquierdo)
	
	sll $t5, $t2, 1		# $t5 = i*2
	addi $t5, $t5, 2	# $t5 = i*2+1 ($t5 = índice derecho)
	
	# -- Parámetros necesarios para comparaciones -- #
	sll $t6, $t3, 2		# Cálculo de número de bytes en el arreglo para alcanzar array[min]
	add $s0, $t0, $t6	# t6 = dirección de array en la posición min
	lw $t6, 0($s0)		# t6 = arreglo[min]
	
	# -- Comparaciones -- #
	
	# -- Comparación izquierda -- #
	sll $t7, $t4, 2		# $t7 = ind_izq * 4 Nro de bytes para alcanzar array[ind_izq]
	add $t7, $t0, $t7	# $t7 = dirección de array[ind_izq]
	lw $t7, 0($t7)		# $t7 = array[ind_izq]
	
	comp_izq:		
		bge $t4, $t1, end_compizq	# Salta si ind_izq < n
		bge $t7, $t6, end_compizq	# Salta si array[ind_izq] < array[min]
		
		addi $t3, $t4, 0			# min = ind_izq
	end_compizq:
	
	sll $t6, $t3, 2		# Cálculo de número de bytes en el arreglo para alcanzar array[min]
	add $s0, $t0, $t6	# t6 = dirección de array en la posición min
	lw $t6, 0($s0)		# t6 = arreglo[min]
	
	# -- Comparación Derecha -- #
	sll $t7, $t5, 2		# $t7 = ind_der * 4 Nro de bytes para alcanzar array[ind_der]
	add $t7, $t0, $t7	# $t7 = dirección de array[ind_der]
	lw $t7, 0($t7)		# $t7 = array[ind_der]
	
	comp_der:
		bge $t5, $t1, end_compder	# Salta si ind_der < n
		bge $t7, $t6, end_compder	# Salta si array[ind_der] < array[min]
		
		addi $t3, $t5, 0			# min = ind_der
	end_compder:
	
	# Intercambio de valores en el arreglo
	beq $t3, $t2, end_heapify	# Salta si min = i
	sll $t8, $t2, 2			# $t8 = i * 4
	add $t8, $t8, $t0		# $t8 = dirección arr[i]
	lw $t9, 0($t8)			# $t9 = arr[i]
	
	sll $t6, $t3, 2			# Cálculo de número de bytes en el arreglo para alcanzar array[min]
	add $s0, $t0, $t6		# s0 = dirección de array en la posición min
	lw $t6, 0($s0)			# t6 = arreglo[min]
	
	sw $t6, 0($t8)			# arr[i] = arr[min]
	sw $t9, 0($s0)			# arr[min] = arr[i]
	
	addi $a2, $t3, 0		# Cambiamos el parámetro para el siguiente heapify $a2 = min
	jal heapify			# Llamado a heapify con parámetros arr, n, min
	
	lw $a2, 4($sp)			# Obtenemos nuevamente el valor de $a2 luego de cambiarlo para el anterior heapify
	
end_heapify:
	lw $ra, 0($sp)			# Obtenemos nuevamente la dirección de retorno
	addi $sp, $sp, 8		# Liberamos los 2 espacios en la pila obtenidos anteriormente
	jr $ra				# Retornamos al proceso que llamó la función heapify
