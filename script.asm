.data
bufferSize: .word 512			#Tamanho dos buffers de entrada e saída

inputFile: .asciiz "entrada.txt"	#Nome do arquivo de entrada
inputBuffer: .space 512			#Buffer onde as strings de entrada serão armazenadas

outputFile: .asciiz "saida.txt"		#Nome do arquivo de saída
outputBuffer: .space 512		#Buffer onde as strings de saída serão armazenadas

#A idéia desse código é usar a pilha para inverter as palavras da seguinte forma:
#Todas as palavras são copiadas do arquivo de entrada para o inputBuffer.
#Uma palavra que está no inputBuffer é copiada para a pilha, caractere a caractere, depois 
#ela é copiada da pilha para o outputBuffer, já invertida, por conta da característica
#Last In First Out da pilha (fazemos isso para cada palavra de forma individual). 
#Por fim, as palavras invertidas são armazenadas no arquivo de saída.

.text
main:
jal openFileForRead	#Executa o procedimento que abre o arquivo de entrada para leitura e armazena o valor $pc + 4 em $ra.
			#Nesta linha a seguinte sequência de procedimentos foram executados:
			#openFileForRead -> readFile -> closeFile.
			
la $s0, inputBuffer	#Carrega o endereço inicial do inputBuffer em $s0.
la $s1, outputBuffer	#Carrega o endereço inicial do outputBuffer em $s1.
move $s3, $sp		#Copia o endereço inicial da pilha para $s3 (iremos manipular esse valor para percorrer a pilha).

reverseWords:
jal copyToStack			#Executa o procedimento que copia uma palavra do buffer de entrada para a pilha, caractere a caractere.
beq, $s4, 1, endReverseWords	#$s4 armazena o valor 1 quando um caractere possui o código (em base decimal) 
				#ascii entre [48, 57] que representam os caracteres [0, 9]. Portanto, caso $v0 armazene 1, o loop se encerra
				#E essa palava que contém o caractere entre [0, 9] não é copiada para o buffer de saída, bem como as posteriores.
				
jal copyFromStack		#Executa o procedimento que copia uma da palavra da pilha para o buffer de saída.
beq $s5, 1, endReverseWords	#$s5 armazena o valor 1 quando o último caractere carregado do inputBuffer pussui o código ascii igual a 0
				#(null), indicando o final do arquivo. Portanto, caso $s5 armazena 1, o loop se encerra logo após copiar a
				#última palavra da pilha para o buffer de saída.	

				#(Se espera que valor armazenado no endereço atual seja 13, que representa a tecla Enter). Descartamos esse valor.
j reverseWords			#Executa mais uma iteração.
endReverseWords:

jal openFileForWrite		#Executa o procedimento que abre o arquivo de saída para escrita (ou cria um novo se não existir)
				#Nesta linha a seguinte sequência de procedimentos foram executados:
				#openFileForWrite -> writeFile -> closeFile.
				
j endMain			#Vai para o procedimento que carrega em $t1 o valor 1, caso exista um caractere numérico em alguma palavra
				#e finaliza o programa.

### Procedimentos ###

openFileForRead:
li $v0, 13		#Carrega o valor 13 (código para abrir o arquivo na syscall) em $v0.
la $a0, inputFile	#Carrega o endereço inicial de inputFile em $a0.
li $a1, 0		#Carrega o valor 0 (pois vamos abrir o arquivo para leitura) em $a1.
li $a2, 0		#Carrega o valor 0 em $a2, pois, não setaremos nenhuma flag.
syscall			#Executa a chamada de sistema para abrir o arquivo.
move $t0, $v0		#Move o [descritor] do arquivo que está em $v0 para $t0.
j readFile

readFile:
li $v0, 14		#Carrega o valor 14 (código para ler o arquivo na syscall) em $v0
move $a0, $t0		#Move o [descritor] do arquivo que está em $t0 para $a0
la $a1, inputBuffer	#Carrega em $a1 o endereço inicial do buffer onde a string será armazenada
lw $a2, bufferSize	#Carrega em $a2 o tamanho do buffer
syscall			#Executa a chamada de sistema para ler o arquivo
j closeFile

closeFile:
li $v0, 16		#Carrega o valor 16 (código para fechar o arquivo na syscall) em $v0
move $a0, $t0		#Move o [descritor] do arquivo que está em $t0 para $a0
syscall			#Executa a chamada de sistema para fechar o arquivo
jr $ra			#Retorna para main.

copyToStack:
lb $t2, ($s0)			#Carrega em $t2 o caractere contido no endereço ($s0) do inputBuffer
beq $t2, 13, exitCopyToStack	#Termina o procedimento se o código ascii do caractere for igual a
				#13 (Enter), indicando o fim de uma palavra.
				
seq $s5, $t2, 0			#Carrega o valor 1 em $s5 se o valor em $s2 for 0 (null), indicando o fim de uma palavra ou/e do arquivo.			
beq $s5, 1, exitCopyToStack	#Termina o procedimento se o código ascii do caractere for igual a 0.	
sgt $t0, $t2, 47		#Carrega o valor 1 em $t0 se o código ascii em $s2 for maior que 47.
slti $t1, $t2, 58		#Carrega o valor 1 em $t1 se o código ascii em $s2 for menor que 58.
and $s4, $t1, $t0		#Carrega em $s4 o resultado de $t0 and $t1. 
beq $s4, 1, exitCopyToStack	#Se $s4 for 1, o caractere está no intervalo [48, 57], logo é numérico. Portanto, o programa será finalizado.
sb $t2, ($s3)			#Carrega em $s3 (endereço atual na pilha) o caractere que está em $t2.
addi $s3, $s3, -1		#Decrementa o endereço em $s3 (para acessar o próximo endereço livre na pilha).
addi $s0, $s0, 1		#Incrementa o endereço em $s0 (para acessar o próximo caractere do inputBuffer).
j copyToStack			#Executa mais uma iteração.
exitCopyToStack:
addi $s0, $s0, 1		#Incrementa o endereço em $s0 (para acessar o próximo caractere do inputBuffer).
addi $s3, $s3, 1		#Incrementa o valor de $s3 em 1, pois o valor que está nesse endereço é nulo.
				#Portanto descartamos esse valor.
jr $ra				#Volta para main.

copyFromStack:
bgt $s3, $sp, exitCopyfromStack	#Se o valor contido em $s3 for mairor que 0x7fffeffc, indica que ja passamos pelo primeiro
				#endereço da pilha. Portanto, o procedimento deve terminar.		 
lb $t2, ($s3)			#Carrega em $t2 o caractere contido no endereço ($s3) da pilha.
sb $t2, ($s1)			#Carrega em $s1 (endereço atual no outputBuffer) o caractere que está em $s2.
addi $s1, $s1, 1		#Incrementa o endereço em $s1 (para acessar o próximo caractere do outputBuffer).
addi $s3, $s3, 1		#incrementa o endereço em $s3 (para acessar o próximo endereço válido na pilha).
j copyFromStack			#Executa mais uma iteração.
exitCopyfromStack:
li $t0, 13			#Carrega o código ascii 13 (Enter) em $t0.
sb $t0, ($s1)			#Carrega o valor contido em $t0 no outputBuffer
				#(Para que a próxima palavra fique na linha seguinte do arquivo).
addi $s1, $s1, 1		#Incrementa o endereço do buffer de saída carregado em $s1, para obtermos o próximo endereço livre no outputBuffer.
jr $ra				#Volta para main.

openFileForWrite:
li $v0, 13		#Carrega o valor 13 (código para abrir o arquivo na syscall) em $v0.
la $a0, outputFile	#Carrega o endereço inicial de outputFile em $a0.
li $a1, 1		#Carrega o valor 1 (pois vamos abrir o arquivo para escrita) em $a1.
li $a2, 0		#Carrega o valor 0 em $a2, pois, não setaremos nenhuma flag.
syscall			#Executa a chamada de sistema para escrever o arquivo.
move $t0, $v0
j writeFile

writeFile:
li $v0, 15		#Carrega o valor 15 (código para escrever o arquivo na syscall) em $v0.
move $a0, $t0		#Move o [descritor] do arquivo que está em $v0 para $t0.
la $a1, outputBuffer	#Carrega em $a1 o endereço inicial do buffer onde estão as palavras invertidas.
lw $a2, bufferSize	#Carrega em $a2 o tamanho do buffer.
syscall			#Executa a chamada de sistema para escrever o arquivo.
j closeFile

endMain:
seq $t1, $s4, 1	#Carrega em $t1 o valor 1 se $v0 for igual a 1.
li $v0, 10	#Carrega o valor 10 (código para encerrar o programa na syscall) em $v0.
syscall		#Executa a chamada de sistema para encerrar o programa.
