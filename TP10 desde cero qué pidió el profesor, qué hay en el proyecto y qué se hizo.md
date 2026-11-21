# TP10 desde cero: qué pidió el profesor, qué hay en el proyecto y qué se hizo

## Antes de empezar: quién hizo qué

**El código VHDL y los programas .asm los hizo el grupo, no yo.** Están en el repositorio de Francisco (github.com/festradax07/TDA-P10). El historial de cambios (los commits) muestra que el procesador se subió primero tal como lo dio la cátedra y que después se agregaron las instrucciones de pila y los programas de prueba. Si en el oral te preguntan quién escribió tal parte, la respuesta honesta es «el grupo»: no digas que lo copiaste de una IA, porque no es lo que pasó. (mas bueno el Claudio <3)

Lo que hice yo:

- Leí el manual, la consigna, el informe y el código, y los comparé entre sí.
- Simulé el procesador original y el del grupo con otro simulador (GHDL) para comprobar cada tiempo y cada valor del informe. Coinciden.
- Corregí y completé partes del informe (citas, aclaraciones, la tabla 3, la bibliografía, títulos de figuras).
- Escribí una prueba nueva, prueba\_popfp.asm, y el tutorial de verificación en Active-HDL.
- **No modifiqué ningún archivo .vhd.** Todo el código que se explica en este documento es del grupo.

Cómo leer este documento: está en orden. Las secciones 1 a 5 explican los conceptos que hacen falta para entender el resto, sin suponer que sabés nada. Las secciones 6 a 8 cuentan qué hay en el proyecto y qué se cambió. Las secciones 9 a 11 recorren las consignas. Al final hay correcciones al resumen de tu compañero y preguntas probables del oral.

## 1. La historia: qué es esto y qué pide el profesor

**En una frase: la cátedra les dio una computadora simulada que tiene funciones a medio hacer, y el TP10 consiste en terminar una de esas funciones, probarla y explicarla.**

### Qué es el TDA 1819

El TDA 1819 es una computadora que no existe físicamente: está escrita como código en un lenguaje llamado VHDL y se «enciende» dentro de un programa simulador (Active-HDL). La diseñó Facundo Scorza para esta misma materia: TDA viene de Taller De Arquitectura y 1819 de los años en que se hizo (2018–2019). El manual (manual-TDA-1819-vs26b.pdf) es su documentación oficial.

Para qué existe: en materias anteriores usaron simuladores como el MSX88 y el WinMIPS64, donde solo se escriben programas y se mira qué pasa. El TDA 1819 va un paso más allá: como está escrito en VHDL, se puede abrir y modificar el procesador mismo. El autor lo dejó incompleto a propósito: el manual marca con un asterisco (\*) las partes «sin implementar», para que los alumnos las agreguen.

De dónde sale su diseño (manual, sección 3.1):

- La memoria se armó copiando la idea del MSX88 (secciones fijas de datos, instrucciones, pila).
- La forma de programarlo copia al WinMIPS64: las mismas directivas (.data, .code) y nombres de instrucciones parecidos (lw, dadd, daddi).
- Es casi RISC (instrucciones simples, una por ciclo, un cauce de 5 etapas), pero conserva cosas de los procesadores CISC como el MSX88: el registro de banderas FLAGS y un grupo de instrucciones especiales para la pila.

### Qué pide el TP10 (Practica10-Taller2026.pdf)

1. **Consigna 1:** se sortea entre los grupos una de cuatro funcionalidades pendientes y hay que programarla en VHDL dentro del procesador. Las opciones eran: ej1, implementar las instrucciones de pila que faltan (tabla 38 del manual); ej2, manejar la pila con un registro común en vez de SP, como en el MIPS64; ej3, que los saltos se resuelvan en la etapa Decode en vez de Execute; ej4, agregar adelantamiento de datos (forwarding).
2. **Consigna 2:** escribir al menos dos programas en Assembly que usen lo nuevo y permitan compararlo con el procesador original.
3. **Consigna 3:** simular esos programas y (a) medir los tiempos con el cauce habilitado y deshabilitado, separando ensamblado de ejecución; (b) describir el ciclo de cada instrucción y demostrar, con lo que se ve en la simulación, que los programas usan de verdad lo nuevo.
4. **Consigna 4 (la entrega):** (a) el informe; (b) los .vhd modificados, con su nombre y su ruta dentro del proyecto; (c) los .asm nuevos y su ruta; (d) una presentación con diapositivas basada en el informe, para la defensa oral.

**Al Grupo 4 le tocó ej1: las instrucciones de pila.** La entrega es el viernes 27 de noviembre de 2026 hasta las 11:59:59 por la mensajería de IDEAS, y ese mismo día es la exposición oral.

### Qué quiere ver el profesor, en pocas palabras

- Que el procesador modificado acepte y ejecute las 10 instrucciones nuevas sin romper lo que ya andaba.
- Pruebas concretas: capturas del simulador donde se vea el puntero de pila moverse, los datos guardados en la pila y los registros recuperando sus valores.
- Una comparación con el procesador original: que el original no las reconoce, y cuánto se gana en cantidad de instrucciones y en tiempo.
- Que cada integrante pueda explicar qué se hizo y por qué. La evaluación del oral es individual.

## 2. Conceptos básicos desde cero

### VHDL en cinco ideas

VHDL es un lenguaje para **describir circuitos**, no para hacer programas comunes. Con lo siguiente alcanza para leer el código del TP:

| Palabra de VHDL | Qué es, en criollo | Ejemplo en el TDA 1819 |
| --- | --- | --- |
| entity | Una caja negra con cables de entrada y salida | `entity registros` |
| architecture | Lo que pasa adentro de esa caja | `REGISTROS_ARCHITECTURE` |
| signal | Un cable (o un grupo de cables) que guarda un valor | `SIGNAL SP: std_logic_vector(15 downto 0)` = 16 cables |
| process | Un bloque de código que se despierta cuando pasa algo y ejecuta sus líneas en orden | `ALU_Write: PROCESS` escribe FLAGS cuando la ALU avisa |
| package | Un archivo con constantes y tipos que comparten todos los demás | `const_memoria.vhd` define dónde empieza la pila |

Dos detalles que aparecen todo el tiempo:

- `std_logic` es un bit que, además de 0 y 1, puede valer U (sin inicializar, nadie le dio valor todavía), Z (alta impedancia: el cable está desconectado) o X (conflicto: dos partes escriben valores distintos a la vez). Por eso en las capturas aparecen U, Z y ?.
- `WAIT FOR 1 ns` hace que el proceso espere 1 nanosegundo de tiempo simulado. El TDA 1819 usa muchas esperas así para ordenar los pasos dentro de un ciclo de reloj.

### El simulador

Active-HDL compila el VHDL (lo traduce y revisa errores) y después lo simula: hace avanzar el tiempo y calcula el valor de cada cable. Tiene dos ventanas que importan:

- **Consola:** muestra los mensajes que el código imprime, por ejemplo «El programa ha sido ensamblado exitosamente» junto al tiempo en que pasó.
- **Waveform (forma de onda):** un gráfico con el tiempo de izquierda a derecha y una fila por señal. Cada vez que una señal cambia de valor, aparece un cruce. Es la «prueba» que pide el profesor.

### La computadora, en cuatro piezas

- **Memoria:** una fila enorme de cajitas de 1 byte (8 bits) cada una, numeradas desde 0. El número de una cajita es su dirección. El TDA 1819 tiene 64 KB, pero el proyecto usa de 0000h a 7FFFh.
- **CPU (procesador):** lee instrucciones de la memoria y las ejecuta una por una.
- **Registros:** cajitas dentro de la CPU, mucho más rápidas que la memoria, donde se hacen las cuentas (sección 3).
- **ALU y FPU:** las dos calculadoras de la CPU. La ALU (Unidad Aritmético-Lógica) hace cuentas con enteros; la FPU (Unidad de Punto Flotante) hace cuentas con números con coma.

### Instrucciones, Assembly y ensamblador

Una instrucción es una orden elemental: «sumá r2 y r3 y guardá en r5» se escribe `dadd r5, r2, r3`. Un programa en Assembly (.asm) es una lista de instrucciones en texto. La CPU no entiende texto: el **ensamblador** traduce cada línea a bytes y los guarda en la memoria antes de que la CPU arranque. En el TDA 1819 el ensamblador también está escrito en VHDL (ensamblador.vhd) y corre al principio de la simulación; ese es el «tiempo de ensamblaje».

Cómo queda guardada una instrucción (tabla 41 del manual): el primer byte es la **cabecera**, que dice cuántos bytes ocupa la instrucción; el segundo es el **código de operación**, que dice cuál es; y después vienen los operandos. Ejemplo: `pushw r1` ocupa 3 bytes: 03 (tamaño), 01100100 (el código de pushw en la tabla 39) y 01 (el número del registro r1 en la tabla 40). `pushfl` ocupa 2 bytes, porque no lleva operando.

El programa tiene dos partes: `.data`, donde se declaran las variables y sus valores iniciales (`LEGAJO: .word 33771`), y `.code`, donde van las instrucciones.

### Números: hexadecimal, tamaños y little endian

- **Hexadecimal:** base 16, con dígitos 0–9 y A–F. Se marca con una h al final: 7FFFh = 32767. Cada dígito hexadecimal son 4 bits, así que un byte son dos dígitos (07, EB, FF).
- **Tamaños:** byte = 8 bits; half-word = 16 bits = 2 bytes; word = 32 bits = 4 bytes. Las letras b, h y w de las instrucciones (lb, lh, lw, pushb, pushh, pushw) dicen el tamaño.
- **Little endian:** cuando un número ocupa varios bytes, el byte menos significativo va en la dirección más baja. El legajo 33771 = 000083EBh se guarda como EB 83 00 00. Por eso en las capturas los números se leen «al revés».
- **Por qué el legajo va en un word:** con 16 bits y signo, el máximo es 32767; 33771 es más grande, así que necesita 32 bits. Eso es justamente lo que hace útil a pushw.

## 3. Los registros del TDA 1819

Un registro es una cajita de memoria dentro de la CPU. El TDA 1819 tiene dos familias (tabla 35 y tabla 40 del manual): de **uso general**, donde el programa guarda lo que quiera, y de **uso particular**, que tienen un trabajo fijo. Los nombres vienen del inglés y de los procesadores en los que se inspira (MIPS64 y el Intel 8088 del MSX88).

| Registro | Nombre en inglés | Tamaño | Qué hace | En el TP10 |
| --- | --- | --- | --- | --- |
| r0 a r15 | register | 32 bits | Guardan enteros. r0 se usa como el número 0 fijo: `lw r1, LEGAJO(r0)` significa «dirección LEGAJO + 0» | pushb, pushw, popb y popw apilan y desapilan estos |
| f0 a f15 | floating point | 32 bits | Guardan números con coma (formato IEEE 754) | pila\_esp carga 7.0 en f1 y 1.0 en f2 |
| IR | Instruction Register | 8 bits | Guarda el código de operación de la instrucción que se está ejecutando | No se toca |
| IP | Instruction Pointer | 16 bits | Dice la dirección de la próxima instrucción; un salto cambia su valor | bfpt lo cambia cuando salta |
| FLAGS | flags (banderas) | 8 bits | Cada bit es una «banderita» que la ALU levanta según el resultado de la última cuenta | pushfl y popfl lo apilan y desapilan |
| FPFLAGS | floating point flags | 8 bits | Las mismas banderas, pero de la FPU | pushfp y popfp |
| BP | Base Pointer | 32 bits | Pensado para marcar la base de la pila; el manual lo marca como sin implementar | No se toca |
| SP | Stack Pointer | 32 bits según el manual; el código usa 16 | Señala el tope de la pila | Todas las instrucciones nuevas lo mueven |
| RA | Return Address | 32 bits | Pensado para guardar a dónde volver al terminar una subrutina (call y ret todavía no están implementadas) | pushra y popra |

Cada registro tiene además un número de identificación (tabla 40): r0–r15 son 0–15, f0–f15 son 16–31, IR = 32, IP = 33, FLAGS = 34, FPFLAGS = 35, BP = 36, SP = 37, RA = 38. En el código aparecen como constantes: ID\_FLAGS, ID\_FPFLAGS, ID\_SP, ID\_RA. Cuando decode.vhd quiere leer un registro, le pasa ese número al banco de registros.

### Las banderas, bit por bit (tabla 36 del manual)

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Bandera | F | I | Z | S | O | C | A | P |
| Significado | Punto flotante: resultado de la última comparación de la FPU | Interrupciones habilitadas | Cero: el resultado dio 0 | Signo: el resultado es negativo | Overflow: desbordamiento | Carry: acarreo | Acarreo auxiliar | Paridad |

Lo que hay que saber para el TP:

- **Z (bit 5)** es la que se usa para comprobar pushfl y popfl: `dsub r2, r2, r2` da 0 y la pone en 1.
- **F (bit 7)** solo la usa FPFLAGS: `ltf` (menor que) y `eqf` (igual a) la ponen en 1 si la comparación es verdadera. `bfpt` (branch if floating point true) salta si F = 1.
- La ALU nunca escribe F ni I en FLAGS. Como el registro arranca en Z (desconectado), esos dos bits quedan en Z para siempre y por eso FLAGS se ve como ZZ000001 en binario o ?1 en hexadecimal.

## 4. La memoria, la pila y el SP

### El mapa de memoria

La memoria está dividida en secciones fijas, y cada tipo de instrucción solo puede tocar la suya: un lw solo accede a datos, un push solo a la pila. Si una instrucción intenta salirse de su sección, el procesador frena la simulación con un error (por ejemplo, «la dirección seleccionada no pertenece a la memoria de pila» si se desapila con la pila vacía). Los límites salen del paquete const\_memoria.vhd:

| Sección | Desde | Hasta | Qué guarda | Nombre en el waveform |
| --- | --- | --- | --- | --- |
| Reservada | 0000h | 0FFFh | Uso del sistema; el programa no la toca | — |
| Datos | 1000h (4096) | 1FFFh | Las variables de .data (LEGAJO, PROD, RES…) | Data\_Memory |
| Instrucciones | 2000h | 2FFFh | Las instrucciones de .code, ya traducidas | Inst\_Memory |
| Subrutinas | 3000h | 6FFFh | Pensada para subrutinas; sin implementar | Subr\_Memory |
| Pila | 7000h | 7FFFh (32767) | Lo que se apila con push | Stack\_Memory |

Ojo: la tabla 42.1 del manual da otros límites (por ejemplo, la pila entre 6400h y 7FFFh). El código real usa los de la tabla de arriba, que coinciden con los rangos de la tabla 41. El informe lo aclara en la sección 1.1.

### La pila, como una pila de platos

La pila guarda datos de forma temporal: lo último que se pone es lo primero que se saca (en inglés, LIFO: last in, first out). Sirve para «hacer lugar»: se guarda el valor de un registro, se usa el registro para otra cosa y después se recupera el valor original.

SP es el dedo que señala el plato de arriba. En el TDA 1819 arranca en 8000h, una dirección justo afuera de la pila, porque la pila está vacía, y crece hacia abajo:

- **push de n bytes:** primero SP = SP − n, después se escribe el dato en la dirección SP.
- **pop de n bytes:** primero se leen n bytes desde la dirección SP, después SP = SP + n.
- Un pop no borra el dato: solo mueve SP. Por eso al final de pila\_con los bytes siguen en Stack\_Memory.

### Ejemplo completo con pila\_con.asm

| Paso | SP después | Qué queda en la pila |
| --- | --- | --- |
| Inicio | 8000h | vacía |
| pushw r1 (r1 = 000083EBh, 4 bytes) | 7FFCh | 7FFC–7FFF = EB 83 00 00 |
| pushb r2 (r2 = 7, 1 byte) | 7FFBh | 7FFB = 07 |
| pushfl (FLAGS, 1 byte) | 7FFAh | 7FFA = ?1 |
| popfl (saca 1 byte y lo pone en FLAGS) | 7FFBh | sigue todo igual |
| popb r2 (saca 1 byte y lo pone en r2) | 7FFCh | sigue todo igual |
| popw r1 (saca 4 bytes y los pone en r1) | 8000h | sigue todo igual |

Los pops van en orden inverso a los pushes. Si se hiciera popw primero, leería 4 bytes desde 7FFAh y mezclaría FLAGS, el 7 y parte del legajo.

### Las 12 instrucciones de pila (tablas 38 y 39 del manual)

| Instrucción | Qué hace | Bytes que mueve | Código de operación | Estado antes del TP |
| --- | --- | --- | --- | --- |
| pushb rf / popb rd | Apila los 8 bits bajos de rf / desapila 1 byte en rd | 1 | 01100000 / 01100001 | Faltaba |
| pushh rf / poph rd | Apila los 16 bits bajos / desapila 2 bytes | 2 | 01100010 / 01100011 | Ya andaba |
| pushw rf / popw rd | Apila los 32 bits / desapila 4 bytes | 4 | 01100100 / 01100101 | Faltaba |
| pushfl / popfl | Apila FLAGS / desapila en FLAGS | 1 | 01100110 / 01100111 | Faltaba |
| pushfp / popfp | Apila FPFLAGS / desapila en FPFLAGS | 1 | 01101000 / 01101001 | Faltaba |
| pushra / popra | Apila RA / desapila en RA | 4 | 01101010 / 01101011 | Faltaba |

rf significa «registro fuente» (de donde sale el dato) y rd, «registro destino» (adonde llega).

## 5. El cauce de 5 etapas y los atascos

### Las 5 etapas

Cada instrucción pasa por cinco etapas, una por ciclo de reloj. El reloj del TDA 1819 es de 10 MHz, así que un ciclo dura 100 ns.

| Etapa | Nombre en inglés | Qué hace | Archivo |
| --- | --- | --- | --- |
| IF | Instruction Fetch (búsqueda) | Lee la instrucción de la memoria de instrucciones, en la dirección que dice IP | fetch.vhd |
| ID | Instruction Decode (decodificación) | Mira el código de operación, lee los registros que hacen falta y prepara las órdenes para las etapas siguientes | decode.vhd |
| EX | Execute (ejecución) | La ALU o la FPU hacen la cuenta y escriben las banderas | execute.vhd, execute\_alu.vhd, execute\_fpu.vhd |
| MA | Memory Access (acceso a memoria) | Lee o escribe la memoria de datos o la pila | memory\_access.vhd |
| WB | Writeback (escritura en registro) | Guarda el resultado en el registro destino | writeback.vhd |

En el TDA 1819, lo más importante de las instrucciones de pila pasa en ID: ahí se lee SP, se calcula la dirección nueva y se actualiza SP. EX no hace nada para ellas, MA escribe o lee la pila y WB, en los pop, guarda el dato leído.

### Cauce habilitado y deshabilitado

- **Deshabilitado (`Pipelining := false`):** una instrucción recorre las 5 etapas y recién después entra la siguiente. Cada instrucción tarda unos 5 ciclos.
- **Habilitado (`Pipelining := true`):** mientras una instrucción está en ID, la siguiente ya está en IF, como una línea de montaje. Idealmente termina una instrucción por ciclo.

| Ciclo | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| pushw r1 | IF | ID | EX | MA | WB |  |  |
| pushb r2 |  | IF | ID | EX | MA | WB |  |
| pushfl |  |  | IF | ID | EX | MA | WB |

Por eso pila\_con tarda 7543 ns sin cauce y 2443 ns con cauce: unas 3 veces menos (el «speedup»).

### Los atascos (stalls)

Cuando varias instrucciones están a la vez en el cauce, una puede necesitar algo que otra todavía no terminó. La CPU detecta el problema y frena a la segunda (la «atasca») hasta que se resuelva. El detector está en raw\_waw\_detector.vhd (atascos por datos) y str\_detector.vhd (atascos estructurales, cuando dos instrucciones quieren usar la misma pieza a la vez).

- **RAW (Read After Write, lectura después de escritura):** una instrucción quiere leer un registro que otra anterior todavía no escribió. Ejemplo del TP: `popra` escribe RA en WB, y `pushra`, justo después, quiere leer RA en ID. Sin atasco, pushra apilaría el RA viejo (00000000). Con el atasco espera, y por eso en la Figura 9 pasan 302 ns entre popra y pushra.
- **WAW (Write After Write, escritura después de escritura):** dos instrucciones escriben el mismo registro y la segunda podría terminar antes que la primera, así que el valor final sería el viejo. Ejemplo del TP: `popfl` escribe FLAGS en WB (etapa 5), pero `dsub`, justo después, escribe FLAGS en EX (etapa 3), un ciclo antes. Sin atasco, al final quedaría el FLAGS de popfl en vez del de dsub.
- **Cómo los detecta el procesador:** lleva un contador de escrituras pendientes por registro (por ejemplo, R1\_WrPending). Cuando una instrucción que va a escribir un registro pasa por ID, el contador sube; cuando llega a WB y escribe, baja. Si otra instrucción quiere leer ese registro mientras el contador es mayor que 0, se prende la señal StallRAW y la instrucción queda frenada en ID.
- **Atasco por salto:** cuando aparece un salto condicional como bfpt, la instrucción siguiente queda frenada en ID hasta que la ALU decide en EX si se salta o no. Si se salta, esa instrucción se cancela (manual, Figura 76).

## 6. Qué mandó el profesor

El profesor mandó tres cosas:

- **El enunciado:** Practica10-Taller2026.pdf (la consigna del TP10).
- **El manual:** manual-TDA-1819-vs26b.pdf, de Facundo Scorza. Las partes que importan para ej1 son la tabla 35 (características generales), la 36 (banderas), la 38 (repertorio de instrucciones, con las de pila marcadas con \* como sin implementar), la 39 (códigos de operación), la 40 (números de los registros), la 41 (formato de cada instrucción) y la 42.1 (mapa de memoria).
- **El proyecto TDA\_1819:** la carpeta de Active-HDL con todo el procesador en VHDL. Es lo que está en el primer commit del repo («initial commit»). Lo comparé con el archivo TDA\_orginal.zip del proyecto de Claude: los .vhd son idénticos, salvo espacios en blanco; ese zip es tu copia del original, donde copiaste los tres .asm del grupo para sacar las Figuras 1 a 4.

### Qué hay dentro de la carpeta TDA\_1819

| Carpeta | Qué contiene |
| --- | --- |
| TDA\_1819.wsw, TDA\_1819.aws | El «workspace»: el archivo que se abre con File > Open Workspace |
| TDA\_1819/compile, compile.cfg, compilation.order, … | Archivos que genera Active-HDL al compilar; no se tocan |
| TDA\_1819/src/Packages/ | 14 paquetes: constantes y tipos que usa todo el procesador |
| TDA\_1819/src/Usuario/ | usuario.vhd y la carpeta PC con todas las piezas de la computadora |
| TDA\_1819/src/Assembler/ | Los programas .asm de ejemplo; el ensamblador busca los programas acá |
| TDA\_1819/src/\*.asdb, \*.awc | Archivos de formas de onda guardadas |

### Cómo se arma la computadora por dentro

Cada archivo .vhd es una pieza, y las piezas grandes contienen a las chicas. Arriba de todo está usuario.vhd, que es el «banco de pruebas»: no es parte de la computadora sino lo que la enciende y le dice qué programa correr.

&#91;embedded content: cómo se arma el TDA 1819 por dentro · qué archivo es cada pieza\]

Los 14 paquetes de src/Packages no son piezas sino «diccionarios» que todas usan. Los que importan para el TP son: repert\_cpu.vhd (códigos de operación de cada instrucción), const\_memoria.vhd (dónde empieza cada sección de memoria), const\_registros.vhd (números de los registros, como ID\_FLAGS), const\_buses.vhd (órdenes como WRITE\_STACK\_MEM), const\_cpu.vhd (códigos internos de las etapas, como EX\_ADD) y los dos del ensamblador, que sí se modificaron: const\_ensamblador.vhd y tipos\_ensamblador.vhd.

## 7. Qué archivos se modificaron y cuáles quedaron igual

Se comparó archivo por archivo el commit inicial del repo (el original de la cátedra) contra la versión actual. **Se modificaron 8 archivos .vhd y se agregaron 5 programas .asm; los otros 30 archivos .vhd quedaron exactamente igual.**

### Archivos modificados

| Archivo | Ruta dentro de TDA\_1819/src | Qué se cambió, en una línea | Consigna |
| --- | --- | --- | --- |
| const\_ensamblador.vhd | Packages/ | La lista de instrucciones de pila con registro pasó de 2 a 6, y se creó una lista nueva con las 6 sin operandos | 1 |
| tipos\_ensamblador.vhd | Packages/ | Nuevos tipos para esa lista, con nombres de 6 letras | 1 |
| ensamblador.vhd | Usuario/PC/1. Ensamblador/ | Nueva función checkInstPe(), que reconoce y traduce las 6 instrucciones sin operandos | 1 |
| decode.vhd | Usuario/PC/2. CPU/2. Etapas/2. Decode/ | Un caso nuevo por cada una de las 10 instrucciones, y un control al final para las instrucciones de la ALU después de un popfl | 1 |
| registros.vhd | Usuario/PC/2. CPU/7. Registros/ | La etapa WB ahora puede escribir FLAGS y FPFLAGS | 1 |
| raw\_waw\_detector.vhd | Usuario/PC/2. CPU/4. Atascos/2. Datos/ | Contadores de escrituras pendientes para FLAGS, FPFLAGS y RA | 1 |
| fetch.vhd | Usuario/PC/2. CPU/2. Etapas/1. Fetch/ | Corrección de un error del original: la instrucción que sigue a un doble atasco RAW se perdía | 1 (apareció al probar) |
| usuario.vhd | Usuario/ | Solo el valor por defecto de ProgName: de nop\_0.asm a pila\_con.asm | 2 y 3 (para correr los programas) |

### Programas agregados en src/Assembler/

| Programa | Para qué | Consigna |
| --- | --- | --- |
| pila\_con.asm | Usa pushw, pushb, pushfl y sus pop | 2 y 3 |
| pila\_sin.asm | Hace lo mismo con pushh y poph, para comparar con el original | 2 y 3 |
| pila\_esp.asm | Prueba pushfp/popfp, pushra/popra y pushfl con popb | 2 y 3 |
| prueba\_popfl.asm | Prueba auxiliar del atasco después de popfl | 1 (verificación) |
| prueba\_raw.asm | Prueba auxiliar del arreglo de fetch.vhd | 1 (verificación) |
| prueba\_popfp.asm | Prueba auxiliar de una comparación de la FPU después de popfp; la escribí yo y falta subirla al repo | 1 (verificación) |

### Otros cambios del repo que no son código

- La carpeta «1. Máquina de Estados» se renombró a «1. Maquina de Estados», sin tilde, porque la tilde se rompía al comprimir y descomprimir y el proyecto no compilaba. El archivo de adentro (states\_machine.vhd) no cambió.
- Se agregó un README.md con instrucciones para correr todo.
- Los programas .asm que ya traía la carpeta (ascii.asm, waw1.asm, prog\_prueba.asm, etc.) quedaron igual.

### Archivos que quedaron exactamente igual

- **Packages (12 de 14):** const\_ascii, const\_buses, const\_cpu, const\_flags, const\_memoria, const\_registros, const\_reloj, func\_ensamblador, repert\_cpu, tipos\_ascii, tipos\_cpu, tipos\_memoria. En repert\_cpu.vhd ya estaban los códigos de operación de las 12 instrucciones de pila, por eso no hubo que tocarlo.
- **Piezas de la computadora:** pc.vhd, cpu.vhd, buses\_admin.vhd, memoria.vhd, ui.vhd, states\_machine.vhd, registros\_fp.vhd, etapas.vhd, execute.vhd, execute\_alu.vhd, execute\_fpu.vhd, memory\_access.vhd, writeback.vhd, pipeline\_registros.vhd, atascos.vhd, str\_detector.vhd, cpu\_admin.vhd, reloj.vhd.

Por qué no hizo falta tocar memory\_access.vhd ni writeback.vhd: ya estaban hechas de forma general. memory\_access lee o escribe la cantidad de bytes que le indica decode (1, 2 o 4) en la sección que le indica (datos o pila), y writeback guarda el dato en el registro cuyo número le pasa decode. Por eso decode es el archivo con más cambios: es el que les da esas órdenes.

## 8. Cada cambio explicado paso a paso

Para que una instrucción nueva funcione hacen falta dos cosas: que el ensamblador sepa traducirla (A) y que la CPU sepa ejecutarla (B a D). E es un arreglo aparte.

### A. Ensamblador: que reconozca las palabras nuevas

**const\_ensamblador.vhd** es el diccionario del ensamblador. Las instrucciones están en grupos, y cada grupo tiene una cantidad, una lista de nombres, una de códigos y una de tamaños en bytes.

Antes:

```vhdl
CONSTANT CANT_INSTMP: INTEGER := 2;
CONSTANT INSTMP_NAMES: ... := ("pushh", "poph ");
CONSTANT INSTMP_SIZES: ... := (3, 3);
```

Después:

```vhdl
CONSTANT CANT_INSTMP: INTEGER := 6;
CONSTANT INSTMP_NAMES: ... := ("pushb", "popb ", "pushh", "poph ", "pushw", "popw ");
CONSTANT INSTMP_SIZES: ... := (3, 3, 3, 3, 3, 3);
-- grupo nuevo, sin operandos
CONSTANT CANT_INSTPE: INTEGER := 6;
CONSTANT INSTPE_NAMES: ... := ("pushfl", "popfl ", "pushfp", "popfp ", "pushra", "popra ");
CONSTANT INSTPE_SIZES: ... := (2, 2, 2, 2, 2, 2);
```

MP significa «manejo de pila»; PE es el nombre que eligió el grupo para «pila especiales». Los nombres llevan espacios al final para que todos tengan el mismo largo ("poph " tiene 5 caracteres, igual que "pushh"). Los tamaños son 3 bytes (cabecera, código y registro) o 2 bytes (cabecera y código).

**tipos\_ensamblador.vhd** define el «molde» de esas listas. El molde viejo era `STRING(1 to 5)`, cinco letras, y "pushfl" tiene seis. Por eso se creó `instpe_name_array`, de `STRING(1 to 6)`.

**ensamblador.vhd** lee el .asm línea por línea y prueba cada grupo hasta encontrar a cuál pertenece la línea. Se agregó la función `checkInstPe()`, copiada de `checkInstCt()` (la que reconoce nop y halt, que tampoco llevan operandos). Lo que hace:

1. Compara letra por letra la línea con cada nombre de la lista INSTPE.
2. Si coincide, revisa que la letra siguiente no sea otra letra. Sin esto, "popflx" se aceptaría como popfl.
3. Escribe 2 bytes en la memoria de instrucciones: primero la cabecera (el número 2) y después el código de operación.

En `checkCode()`, que es la función que recorre el programa, se agregó un bloque que llama a checkInstPe() si la línea no coincidió con ningún grupo anterior.

### B. Decode: qué hace la CPU con cada instrucción

decode.vhd tiene un `CASE` enorme: un caso por cada código de operación. Se agregaron 10 casos, todos copiados del modelo de PUSHH y POPH. Así queda PUSHW, comentado:

```vhdl
WHEN PUSHW =>
  IDtoMA.control  <= WRITE_STACK_MEM;   -- orden para MA: escribir en la pila
  IDtoMA.datasize <= 4;                 -- 4 bytes
  -- 1) leer el registro fuente (su número viene en la instrucción)
  IdRegID <= rf;  EnableRegID <= '1';
  IDtoMA.data.decode(31 downto 0) <= DataRegOutID(31 downto 0);
  if (StallRAW = '0') then             -- si no hay que esperar a nadie
    -- 2) leer SP y restarle 4
    IdRegID <= ID_SP;  addrAux := SP - 4;
    IDtoMA.address <= addrAux;          -- 3) MA escribirá en esa dirección
    -- 4) guardar el SP nuevo
    DataRegInID <= addrAux;  EnableRegIDSP <= '1';
  end if;
```

(Simplificado: el código real tiene `WAIT FOR 1 ns` entre cada paso y conversiones de tipo.)

Y POPW:

```vhdl
WHEN POPW =>
  IDtoMA.control  <= READ_STACK_MEM;    -- orden para MA: leer la pila
  IDtoMA.datasize <= 4;
  IDtoWB.mode     <= rd + 1;            -- orden para WB: guardar en rd
  IdRegID <= ID_SP;                     -- leer SP
  IDtoMA.address <= SP;                 -- MA lee desde la dirección actual
  DataRegInID <= SP + 4;  EnableRegIDSP <= '1';   -- y SP sube 4
```

El `+ 1` en el destino de WB es porque el valor 0 significa «no escribir nada»; el original usa la misma convención.

Las diferencias entre los 10 casos son solo tres: cuántos bytes (1 o 4), qué registro se lee o escribe (rf o rd, o ID\_FLAGS, ID\_FPFLAGS, ID\_RA) y dos detalles especiales:

- **PUSHFL y PUSHFP** esperan 2 ns y 6 ns antes de leer las banderas. Si la instrucción anterior es una cuenta, la ALU o la FPU escriben las banderas en el mismo instante en que decode las lee, y sin la espera se apilaba el valor viejo. El informe lo menciona como limitación porque depende de los tiempos de la simulación.
- **POPFP** lee FPFLAGS aunque no lo use. Es un truco para que el detector de atascos lo frene si una comparación de la FPU (que tarda 4 ciclos) todavía no terminó de escribir FPFLAGS.

Además, después del CASE se agregó un control: si la instrucción es de la ALU (sus códigos internos van de EX\_ADD a EX\_DSR), decode «lee» FLAGS. Así, si hay un popfl en camino, el detector la frena (problema WAW de la sección 5).

### C. Registros: que WB pueda escribir FLAGS y FPFLAGS

En VHDL, si dos procesos distintos escriben la misma señal, el resultado es X (conflicto). FLAGS ya lo escribía el proceso ALU\_Write; si el proceso Writeback lo escribiera directamente, habría dos «dueños». La solución fue que Writeback deje el valor en una señal intermedia y avise, y que ALU\_Write siga siendo el único que escribe:

```vhdl
ALU_Write: PROCESS BEGIN
  WAIT UNTIL (rising_edge(EnableRegEXALUWr) or rising_edge(EnableFlagsWB));
  if (EnableRegEXALUWr = '1') then
    FLAGS <= DataRegInEXALU(7 downto 0);  -- lo escribe la ALU (como antes)
  else
    FLAGS <= FlagsWB;                     -- lo pide WB (popfl)
  end if;
END PROCESS;
```

Lo mismo se hizo con FPFLAGS en FPU\_Write. RA no necesitó cambios: el Writeback original ya sabía escribirlo.

### D. Detector de atascos: contadores para FLAGS, FPFLAGS y RA

raw\_waw\_detector.vhd ya tenía un contador por registro común (R1\_WrPending, etc.) y uno para las escrituras de la FPU en FPFLAGS. Se agregaron tres: FLAGS\_WrPending, FPFLAGSWB\_WrPending y RA\_WrPending. Cada uno se usa en tres lugares:

1. Cuando un popfl, popfp o popra pasa por ID, su contador sube 1.
2. Cuando llega a WB y escribe, baja 1, y si alguien estaba frenado esperando ese registro, lo libera.
3. Cuando una instrucción lee FLAGS, FPFLAGS o RA en ID (pushfl, pushfp, bfpt, pushra, o la lectura extra de las instrucciones de la ALU), si el contador es mayor que 0 se prende StallRAW y queda frenada.

También se corrigió un detalle del original: la escritura de FPFLAGS en WB descontaba el contador de la FPU, que no le corresponde. Ahora cada uno descuenta el suyo.

### E. Fetch: el error del doble atasco

Cuando decode se frena, fetch tiene que esperar para no buscar la instrucción siguiente antes de tiempo. El original esperaba un solo atasco:

```vhdl
if (StallRAW = '1') then
  WAIT UNTIL falling_edge(StallRAW);   -- espera a que termine el atasco
  WAIT UNTIL rising_edge(EnableIF);
  -- agregado por el grupo:
  while (StallRAW = '1') loop          -- si apareció otro atasco, seguir esperando
    WAIT UNTIL falling_edge(StallRAW);
    WAIT UNTIL rising_edge(EnableIF);
  end loop;
```

Con `dsub r5, r2, r3` justo después de cargar r2 y r3, decode se frena dos veces: primero esperando r2 y después r3. El original solo esperaba la primera vez y la instrucción siguiente se perdía. Se nota en prueba\_raw.asm: en el original R9 nunca se escribe.

## 9. Consigna 2: los programas, línea por línea

La consigna pide al menos dos programas que usen lo nuevo y permitan compararlo con el original. La idea del grupo fue hacer el mismo trabajo de dos maneras (pila\_con con las instrucciones nuevas y pila\_sin sin ellas) y uno más para lo que el original directamente no puede hacer (pila\_esp). Los datos salen del legajo de Rocío, 03377/1: el número 33771 y sus dígitos mayor (7) y menor (1).

### pila\_con.asm (15 instrucciones)

| Línea | Qué hace |
| --- | --- |
| `LEGAJO: .word 33771` | Variable de 4 bytes en 1000h |
| `MAYOR: .byte 7` / `MENOR: .byte 1` | Variables de 1 byte en 1004h y 1005h |
| `PROD: .word 0` / `COPIA: .word 0` | Lugares para el producto (1006h) y la copia del legajo (100Ah) |
| `lb r2, MAYOR(r0)` | r2 = 7 (lb = load byte) |
| `lb r3, MENOR(r0)` | r3 = 1 |
| `lw r1, LEGAJO(r0)` | r1 = 33771 (lw = load word) |
| `dsub r5, r2, r3` | r5 = 7 − 1 = 6. Da distinto de cero, así que Z = 0 en FLAGS |
| `pushw r1` | Apila los 4 bytes del legajo. SP: 8000h → 7FFCh |
| `pushb r2` | Apila el 7 en 1 byte. SP → 7FFBh |
| `pushfl` | Apila FLAGS (con Z = 0). SP → 7FFAh |
| `dmul r1, r1, r2` | r1 = 33771 × 7 = 236397: se «ensucia» r1 a propósito |
| `sw r1, PROD(r0)` | Guarda el producto en memoria |
| `dsub r2, r2, r2` | r2 = 0: se ensucia r2 y Z pasa a 1 |
| `popfl` | Recupera FLAGS: Z vuelve a 0. SP → 7FFBh |
| `popb r2` | Recupera el 7 en r2. SP → 7FFCh |
| `popw r1` | Recupera 33771 en r1. SP → 8000h |
| `sw r1, COPIA(r0)` | Guarda r1 en COPIA: si es 33771, la pila funcionó |
| `halt` | Termina |

La lógica de la prueba: se guarda algo, se destruye y se recupera. Si al final COPIA vale 33771, r2 vale 7 y Z vale 0, las tres instrucciones nuevas funcionaron.

### pila\_sin.asm (20 instrucciones)

Hace lo mismo con solo pushh y poph, que son las que tenía el original. Las diferencias:

- El legajo no entra en 16 bits, así que se apila en dos mitades: `pushh r1` apila la mitad baja; para la mitad alta se carga `daddi r8, r0, 2` y `lh r7, LEGAJO(r8)` (lee 2 bytes desde LEGAJO + 2) y después `pushh r7`.
- El 7 se apila con pushh y ocupa 2 bytes en vez de 1.
- Para reconstruir el legajo hacen falta `poph r7`, `poph r1`, `sh r1, COPIA(r0)`, `sh r7, COPIA(r8)` y `lw r1, COPIA(r0)`.
- FLAGS no se puede apilar, así que al final se repite `dsub r5, r2, r3` para recalcular las banderas.

Para qué sirve: corre en el original y en el modificado, así que demuestra que no se rompió nada (mismos tiempos y mismos resultados en los dos) y mide cuánto se gana con las instrucciones nuevas (5 instrucciones y entre 21 % y 25 % de tiempo).

### pila\_esp.asm

| Bloque | Líneas | Qué demuestra |
| --- | --- | --- |
| FPFLAGS | `lf f1, NUM1` (7.0), `lf f2, NUM2` (1.0), `ltf f2, f1` (¿1.0 < 7.0? sí: F = 1), 4 nop, `pushfp`, `eqf f1, f2` (¿7.0 = 1.0? no: F = 0), 4 nop, `popfp` (F vuelve a 1) | popfp restituyó FPFLAGS |
| El salto | `bfpt SIGUE` (salta si F = 1), `daddi r5, r0, 1`, `jmp FIN`, `SIGUE: daddi r5, r0, 7`, `FIN: sw r5, RES` | Si popfp funcionó, salta y RES = 7; si no, RES = 1 |
| RA | `lw r1, DIRRET` (2030h), `pushw r1`, `popra` (RA = 2030h), `pushra`, `popw r2` (r2 = 2030h), `sw r2, COPIARA` | popra escribe RA y pushra lo lee |
| FLAGS a un registro | `pushfl`, `popb r6`, `sb r6, BANDERAS` | El byte de FLAGS se puede llevar a un registro común y a memoria |

Los 4 nop no tienen que ver con las instrucciones nuevas: el TDA 1819 original, con el cauce deshabilitado, pierde la escritura de la instrucción que viene justo después de una de punto flotante. Lo comprobé: sin los nop y sin cauce, RES queda en 0. 2030h (8240 en decimal) cae dentro de la sección de instrucciones (2000h–2FFFh), que es donde estaría una dirección de retorno real.

## 10. Consigna 3: qué quiere ver el profesor, dónde y por qué

La consigna 3 pide **pruebas**, no explicaciones: que se vea en el simulador que los programas usan de verdad lo nuevo. Cada pedido tiene su lugar en Active-HDL y en el informe.

| Qué pide | Dónde se ve | Qué tiene que aparecer | En el informe |
| --- | --- | --- | --- |
| 3.a Tiempo de ensamblaje | Consola, primer mensaje | «ha sido ensamblado exitosamente» con su tiempo (157, 221 o 253 ns) | Tabla 1 |
| 3.a Tiempo de ejecución, con y sin cauce | Consola, segundo mensaje, con Pipelining en true y en false | «ha sido ejecutado exitosamente» con su tiempo; ejecución = fin − ensamblado | Tabla 1 y sección 3.1 |
| 3.b Ciclo de cada instrucción | Se razona con el manual y el código de decode.vhd | Para cada instrucción, qué se lee o escribe en IF, ID, EX, MA y WB (memoria, ALU/FPU, registros) | Sección 3.2, Tablas 2 y 3 |
| 3.b Que se use la pila | Waveform: SP y Stack\_Memory | SP baja con cada push y sube con cada pop; los bytes aparecen en 7FFAh–7FFFh | Tabla 5, Figuras 6, 7 y 9 |
| 3.b Que los datos vuelvan bien | Waveform: R1, R2, FLAGS, FPFLAGS, RA, Data\_Memory | Los registros recuperan su valor y COPIA, RES y COPIARA quedan con el valor esperado | Tablas 4 y 6, Figuras 5, 7, 8, 10, 11 y 12 |
| 2 Contraste con el original | Consola del procesador original | pila\_con y pila\_esp dan error al ensamblar; pila\_sin corre igual | Sección 2.3, Figuras 1 a 4 |

### Por qué se separa el ensamblado de la ejecución

El ensamblador corre antes que la CPU y tarda según la cantidad de líneas del programa, no según el cauce. Si no se resta, la comparación entre programas se ensucia con un tiempo que no tiene nada que ver con el procesador. Por eso pila\_con y pila\_sin se comparan con el tiempo de ejecución (2443 ns contra 3079 ns con cauce), no con el total.

### Por qué el bit Z y el bit F

Para demostrar que pushfl y popfl funcionan hace falta una bandera que cambie de valor entre el push y el pop. Z es la más fácil de controlar: `dsub r2, r2, r2` siempre da cero y la pone en 1, así que si después de popfl vuelve a 0, el valor salió de la pila. Con FPFLAGS pasa lo mismo con F: ltf la pone en 1, eqf en 0, y bfpt muestra cuál quedó.

### Dónde mirar paso a paso

El [Tutorial de verificación en Active-HDL](https://claude.ai/artifact/RsZyzJ4Po5TsftJttoN3NV) explica cómo armar el waveform y tiene, para pila\_con y pila\_esp, una tabla con cada cambio de señal: el tiempo exacto, el valor nuevo y la instrucción que lo causa.

## 11. Consigna 4: qué se entrega y qué falta

Todo se manda por la mensajería de IDEAS antes del viernes 27 de noviembre de 2026 a las 11:59:59.

| Inciso | Qué es | Estado |
| --- | --- | --- |
| 4.a | El informe (Google Doc del grupo) | Listo, salvo dos cosas: rehacer la Figura 11 y completar el legajo de Martín |
| 4.b | Los .vhd modificados, con nombre y ruta | Los 8 archivos están en el repo; la tabla con las rutas está en el Apéndice del informe. No hace falta mandar el proyecto entero |
| 4.c | Los .asm nuevos y su ruta | Están en el repo, salvo prueba\_popfp.asm, que hay que subir a src/Assembler/ |
| 4.d | Presentación para el oral | La hace un compañero a partir del informe |

- [x] Rehacer la captura de la Figura 11 (pasos en el tutorial).
- [ ] Completar el legajo de Martín en la portada.
- [x] Subir prueba\_popfp.asm al repo.
- [ ] Armar el archivo de entrega: el informe en PDF, los 8 .vhd y los 6 .asm.

## 12. Correcciones y agregados al resumen de tu compañero

El resumen de tu compañero está bien en lo esencial. Estos son los puntos para ajustar o agregar:

| Lo que dice | Lo correcto o lo que falta |
| --- | --- |
| «Tocaron 5 partes del procesador, repartidas en 7 archivos» | Son 8 archivos: también cambió usuario.vhd, aunque solo el nombre del programa por defecto |
| «Cambiaron un if por un while» en fetch.vhd | El if original sigue; se agregó un while adentro, para seguir esperando si aparece un segundo atasco. El efecto es el mismo que describe |
| «pila\_con es \~21 % más rápido» | Más preciso: tarda un 21 % menos (2443 ns contra 3079 ns). Decir «más rápido» con ese número puede llevar a una repregunta |
| «INSTPE (Instrucciones de Pila Especiales)» | El nombre lo eligió el grupo; no sale del manual. Está bien explicarlo así, pero no presentarlo como un término oficial |
| Parte D: popfp se frena si hay una cuenta de la FPU en camino | Correcto. Falta la otra mitad: al revés (popfp y después una cuenta de la FPU) no hace falta frenar, porque la FPU tarda 4 ciclos y escribe después que popfp. Se comprobó con prueba\_popfp.asm |
| Parte D, no lo menciona | También se corrigió que, en el original, la escritura de FPFLAGS en WB descontaba el contador de la FPU |
| «pila\_sin demuestra que en el nuevo sigue dando exactamente igual» | Correcto para pila\_sin. Pero no es cierto para todos los programas viejos: el arreglo de fetch.vhd cambia los que tienen dos atascos RAW seguidos. Por ejemplo, prog\_prueba.asm termina a los 4700 ns en el original y a los 5100 ns en el modificado, con los mismos resultados, porque el original se saltea una instrucción |
| No menciona prueba\_popfp.asm | Es la tercera prueba auxiliar (falta subirla al repo) |
| No menciona el inciso 4.d | La consigna también pide la presentación con diapositivas |
| La pila va de 7000h a 7FFFh | Correcto según el código. Conviene saber que la tabla 42.1 del manual dice otra cosa (6400h–7FFFh), por si el profesor lo pregunta |

Todo lo demás (el glosario, los registros, los atascos, las esperas de 2 ns y 6 ns, los nop de pila\_esp y el resumen de 4 frases) está bien y lo podés usar tal cual.

## 13. Preguntas probables del oral

**¿Qué les tocó y qué hicieron?** Ej1: implementar las 10 instrucciones de pila que faltaban en la tabla 38. Se actualizó el ensamblador para que las reconozca, decode para que las ejecute, el banco de registros para que WB pueda escribir FLAGS y FPFLAGS, y el detector de atascos para que no se pisen los datos con el cauce habilitado.

**¿Por qué no tuvieron que agregar códigos de operación?** Porque ya estaban en repert\_cpu.vhd, de 01100000 (pushb) a 01101011 (popra). Faltaba que el ensamblador y la CPU los usaran.

**¿Por qué push resta y después escribe?** Porque la pila crece hacia direcciones menores y SP arranca en 8000h, afuera de la pila. Primero hay que hacer lugar (SP − n) y después escribir. El pop hace lo inverso: lee y después suma. Es el mismo criterio que ya usaban pushh y poph.

**¿En qué etapa se actualiza SP?** En ID (decode). Por eso, si un pop viene justo después de un push, no hay atasco por SP: el SP nuevo ya está escrito cuando lo lee el pop. En la Figura 9, SP queda en 7FFCh solo 98 ns.

**¿Por qué tardan 302 ns entre popra y pushra?** Porque pushra necesita leer RA en ID, y popra recién lo escribe en WB, tres etapas después. El detector de atascos frena a pushra hasta que RA está actualizado. Es un atasco RAW.

**¿Qué es el problema WAW de popfl?** popfl escribe FLAGS en WB (etapa 5), pero una instrucción de la ALU que venga justo después lo escribe en EX (etapa 3), antes. Sin control, al final quedaría el valor de popfl, que es el viejo. Por eso se frena a la instrucción de la ALU hasta que popfl termine. Se ve en prueba\_popfl.asm.

**¿Por qué tuvieron que tocar registros.vhd?** Porque en VHDL dos procesos no pueden escribir la misma señal: daría X. FLAGS lo escribía solo la ALU. Se agregó una señal intermedia para que WB le pida al mismo proceso de la ALU que escriba el valor desapilado.

**¿Qué son los 2 ns y 6 ns de pushfl y pushfp?** Una espera antes de leer las banderas, porque si la instrucción anterior es una cuenta, la ALU o la FPU las escriben en el mismo instante en que decode las lee. Funciona, pero depende de los tiempos de la simulación; por eso figura en Limitaciones.

**¿Por qué pila\_esp tiene nop?** Por un error del procesador original: sin cauce, la instrucción que sigue a una de la FPU pierde su escritura. Se comprobó con un programa sin instrucciones de pila. Sin los nop, RES queda en 0.

**¿Qué arreglaron en fetch.vhd y por qué?** Si una instrucción se frenaba dos veces seguidas (por ejemplo dsub r5, r2, r3 esperando a r2 y después a r3), fetch solo esperaba la primera vez y la instrucción siguiente se perdía. Se agregó un while para seguir esperando. Apareció al probar: en prueba\_raw.asm, el original nunca escribe R9.

**¿Cómo saben que el original no las reconoce?** Se corrieron pila\_con y pila\_esp en una copia del procesador sin modificar: el ensamblador se detiene a los 59 ns en la línea 12 (pushw r1) y a los 71 ns en la línea 16 (pushfp).

**¿Cuánto se gana?** pila\_con tarda 2443 ns con cauce y 7543 ns sin cauce, contra 3079 y 10079 de pila\_sin: entre 21 % y 25 % menos, porque usa 15 instrucciones en vez de 20.

**¿Por qué FLAGS aparece como ?1 o ZZ000001?** Porque la ALU nunca escribe los bits F e I de FLAGS y el registro arranca desconectado (Z). En hexadecimal, un dígito con algún bit Z se muestra como ?. Por eso la verificación se hace con el bit Z, en binario.

**¿Por qué el legajo es un word?** Porque 33771 es más grande que 32767, el máximo de 16 bits con signo. Con pushh habría que partirlo en dos, que es justamente lo que hace pila\_sin.

**Si te preguntan algo que no sabés:** no inventes. Decí qué parte sí sabés y dónde se ve (la consola, el waveform o la sección del informe), y que lo podés comprobar en la simulación.
