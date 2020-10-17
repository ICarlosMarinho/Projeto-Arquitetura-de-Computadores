.data
bufferSize: .word 512			#Tamanho dos buffers de entrada e sa�da

inputFile: .asciiz "entrada.txt"	#Nome do arquivo de entrada
inputBuffer: .space 512			#Buffer onde as strings de entrada ser�o armazenadas

outputFile: .asciiz "saida.txt"		#Nome do arquivo de sa�da
outputBuffer: .space 512		#Buffer onde as strings de sa�da ser�o armazenadas

#A id�ia desse c�digo � usar a pilha para inverter as palavras da seguinte forma:
#Todas as palavras s�o copiadas do arquivo de entrada para o inputBuffer.
#Uma palavra que est� no inputBuffer � copiada para a pilha, caractere a caractere, depois 
#ela � copiada da pilha para o outputBuffer, j� invertida, por conta da caracter�stica
#Last In First Out da pilha (fazemos isso para cada palavra de forma individual). 
#Por fim, as palavras invertidas s�o armazenadas no arquivo de sa�da.

.text
main:
jal openFileForRead	#Executa o procedimento que abre o arquivo de entrada para leitura e armazena o valor $pc + 4 em $ra.
			#Nesta linha a seguinte sequ�ncia de procedimentos foram executados:
			#openFileForRead -> readFile -> closeFile.
			
la $s0, inputBuffer	#Carrega o endere�o inicial do inputBuffer em $s0.
la $s1, outputBuffer	#Carrega o endere�o inicial do outputBuffer em $s1.
move $s3, $sp		#Copia o endere�o inicial da pilha para $s3 (iremos manipular esse valor para percorrer a pilha).

reverseWords:
jal copyToStack			#Executa o procedimento que copia uma palavra do buffer de entrada para a pilha, caractere a caractere.
beq, $s4, 1, endReverseWords	#$s4 armazena o valor 1 quando um caractere possui o c�digo (em base decimal) 
				#ascii entre [48, 57] que representam os caracteres [0, 9]. Portanto, caso $v0 armazene 1, o loop se encerra
				#E essa palava que cont�m o caractere entre [0, 9] n�o � copiada para o buffer de sa�da, bem como as posteriores.
				
jal copyFromStack		#Executa o procedimento que copia uma da palavra da pilha para o buffer de sa�da.
beq $s5, 1, endReverseWords	#$s5 armazena o valor 1 quando o �ltimo caractere carregado do inputBuffer pussui o c�digo ascii igual a 0
				#(null), indicando o final do arquivo. Portanto, caso $s5 armazena 1, o loop se encerra logo ap�s copiar a
				#�ltima palavra da pilha para o buffer de sa�da.	

				#(Se espera que valor armazenado no endere�o atual seja 13, que representa a tecla Enter). Descartamos esse valor.
j reverseWords			#Executa mais uma itera��o.
endReverseWords:

jal openFileForWrite		#Executa o procedimento que abre o arquivo de sa�da para escrita (ou cria um novo se n�o existir)
				#Nesta linha a seguinte sequ�ncia de procedimentos foram executados:
				#openFileForWrite -> writeFile -> closeFile.
				
j endMain			#Vai para o procedimento que carrega em $t1 o valor 1, caso exista um caractere num�rico em alguma palavra
				#e finaliza o programa.

### Procedimentos ###

openFileForRead:
li $v0, 13		#Carrega o valor 13 (c�digo para abrir o arquivo na syscall) em $v0.
la $a0, inputFile	#Carrega o endere�o inicial de inputFile em $a0.
li $a1, 0		#Carrega o valor 0 (pois vamos abrir o arquivo para leitura) em $a1.
li $a2, 0		#Carrega o valor 0 em $a2, pois, n�o setaremos nenhuma flag.
syscall			#Executa a chamada de sistema para abrir o arquivo.
move $t0, $v0		#Move o [descritor] do arquivo que est� em $v0 para $t0.
j readFile

readFile:
li $v0, 14		#Carrega o valor 14 (c�digo para ler o arquivo na syscall) em $v0
move $a0, $t0		#Move o [descritor] do arquivo que est� em $t0 para $a0
la $a1, inputBuffer	#Carrega em $a1 o endere�o inicial do buffer onde a string ser� armazenada
lw $a2, bufferSize	#Carrega em $a2 o tamanho do buffer
syscall			#Executa a chamada de sistema para ler o arquivo
j closeFile

closeFile:
li $v0, 16		#Carrega o valor 16 (c�digo para fechar o arquivo na syscall) em $v0
move $a0, $t0		#Move o [descritor] do arquivo que est� em $t0 para $a0
syscall			#Executa a chamada de sistema para fechar o arquivo
jr $ra			#Retorna para main.

copyToStack:
lb $t2, ($s0)			#Carrega em $t2 o caractere contido no endere�o ($s0) do inputBuffer
beq $t2, 13, exitCopyToStack	#Termina o procedimento se o c�digo ascii do caractere for igual a
				#13 (Enter), indicando o fim de uma palavra.
				
seq $s5, $t2, 0			#Carrega o valor 1 em $s5 se o valor em $s2 for 0 (null), indicando o fim de uma palavra ou/e do arquivo.			
beq $s5, 1, exitCopyToStack	#Termina o procedimento se o c�digo ascii do caractere for igual a 0.	
sgt $t0, $t2, 47		#Carrega o valor 1 em $t0 se o c�digo ascii em $s2 for maior que 47.
slti $t1, $t2, 58		#Carrega o valor 1 em $t1 se o c�digo ascii em $s2 for menor que 58.
and $s4, $t1, $t0		#Carrega em $s4 o resultado de $t0 and $t1. 
beq $s4, 1, exitCopyToStack	#Se $s4 for 1, o caractere est� no intervalo [48, 57], logo � num�rico. Portanto, o programa ser� finalizado.
sb $t2, ($s3)			#Carrega em $s3 (endere�o atual na pilha) o caractere que est� em $t2.
addi $s3, $s3, -1		#Decrementa o endere�o em $s3 (para acessar o pr�ximo endere�o livre na pilha).
addi $s0, $s0, 1		#Incrementa o endere�o em $s0 (para acessar o pr�ximo caractere do inputBuffer).
j copyToStack			#Executa mais uma itera��o.
exitCopyToStack:
addi $s0, $s0, 1		#Incrementa o endere�o em $s0 (para acessar o pr�ximo caractere do inputBuffer).
addi $s3, $s3, 1		#Incrementa o valor de $s3 em 1, pois o valor que est� nesse endere�o � nulo.
				#Portanto descartamos esse valor.
jr $ra				#Volta para main.

copyFromStack:
bgt $s3, $sp, exitCopyfromStack	#Se o valor contido em $s3 for mairor que 0x7fffeffc, indica que ja passamos pelo primeiro
				#endere�o da pilha. Portanto, o procedimento deve terminar.		 
lb $t2, ($s3)			#Carrega em $t2 o caractere contido no endere�o ($s3) da pilha.
sb $t2, ($s1)			#Carrega em $s1 (endere�o atual no outputBuffer) o caractere que est� em $s2.
addi $s1, $s1, 1		#Incrementa o endere�o em $s1 (para acessar o pr�ximo caractere do outputBuffer).
addi $s3, $s3, 1		#incrementa o endere�o em $s3 (para acessar o pr�ximo endere�o v�lido na pilha).
j copyFromStack			#Executa mais uma itera��o.
exitCopyfromStack:
li $t0, 13			#Carrega o c�digo ascii 13 (Enter) em $t0.
sb $t0, ($s1)			#Carrega o valor contido em $t0 no outputBuffer
				#(Para que a pr�xima palavra fique na linha seguinte do arquivo).
addi $s1, $s1, 1		#Incrementa o endere�o do buffer de sa�da carregado em $s1, para obtermos o pr�ximo endere�o livre no outputBuffer.
jr $ra				#Volta para main.

openFileForWrite:
li $v0, 13		#Carrega o valor 13 (c�digo para abrir o arquivo na syscall) em $v0.
la $a0, outputFile	#Carrega o endere�o inicial de outputFile em $a0.
li $a1, 1		#Carrega o valor 1 (pois vamos abrir o arquivo para escrita) em $a1.
li $a2, 0		#Carrega o valor 0 em $a2, pois, n�o setaremos nenhuma flag.
syscall			#Executa a chamada de sistema para escrever o arquivo.
move $t0, $v0
j writeFile

writeFile:
li $v0, 15		#Carrega o valor 15 (c�digo para escrever o arquivo na syscall) em $v0.
move $a0, $t0		#Move o [descritor] do arquivo que est� em $v0 para $t0.
la $a1, outputBuffer	#Carrega em $a1 o endere�o inicial do buffer onde est�o as palavras invertidas.
lw $a2, bufferSize	#Carrega em $a2 o tamanho do buffer.
syscall			#Executa a chamada de sistema para escrever o arquivo.
j closeFile

endMain:
seq $t1, $s4, 1	#Carrega em $t1 o valor 1 se $v0 for igual a 1.
li $v0, 10	#Carrega o valor 10 (c�digo para encerrar o programa na syscall) em $v0.
syscall		#Executa a chamada de sistema para encerrar o programa.
