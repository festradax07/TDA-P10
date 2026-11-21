# TP10 - Taller de Arquitectura - Grupo 4

Procesador TDA 1819 con las instrucciones de pila que faltaban (ej1):
pushb/popb, pushw/popw, pushfl/popfl, pushfp/popfp y pushra/popra.

## Como correrlo en Active-HDL

1. Descomprimir el zip y abrir `TDA_1819.wsw` (File > Open Workspace).
2. Design > Compile All. Tiene que terminar sin errores.
3. En `TDA_1819/src/Usuario/usuario.vhd` elegir el programa y el modo del cauce:
   - `ProgName`: `pila_sin.asm`, `pila_con.asm` o `pila_esp.asm`
   - `Pipelining`: `true` (cauce habilitado) o `false` (deshabilitado)
4. Guardar, compilar `usuario.vhd` y correr la simulacion (Simulation > Initialize Simulation y despues `run`).

Si la consola dice "la instruccion declarada no es valida" en una instruccion de pila,
es que quedo compilada una version vieja: hacer Compile All de nuevo.

## Tiempos esperados (consola)

| Programa | Cauce habilitado | Cauce deshabilitado |
|---|---|---|
| pila_sin.asm | ensamblado 221 ns, fin 3300 ns | ensamblado 221 ns, fin 10300 ns |
| pila_con.asm | ensamblado 157 ns, fin 2600 ns | ensamblado 157 ns, fin 7700 ns |
| pila_esp.asm | ensamblado 253 ns, fin 5200 ns | ensamblado 253 ns, fin 14400 ns |

## Archivos modificados

- `src/Packages/const_ensamblador.vhd`
- `src/Packages/tipos_ensamblador.vhd`
- `src/Usuario/PC/1. Ensamblador/ensamblador.vhd`
- `src/Usuario/PC/2. CPU/2. Etapas/1. Fetch/fetch.vhd`
- `src/Usuario/PC/2. CPU/2. Etapas/2. Decode/decode.vhd`
- `src/Usuario/PC/2. CPU/4. Atascos/2. Datos/raw_waw_detector.vhd`
- `src/Usuario/PC/2. CPU/7. Registros/registros.vhd`
- `src/Usuario/usuario.vhd`

Programas: `src/Assembler/pila_sin.asm`, `pila_con.asm`, `pila_esp.asm`
y las pruebas auxiliares `prueba_popfl.asm` y `prueba_raw.asm`.

La carpeta `1. Maquina de Estados` esta sin tilde a proposito: con la tilde el nombre
se rompia al comprimir/descomprimir y el proyecto no compilaba.
