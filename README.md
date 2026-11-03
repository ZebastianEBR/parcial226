# Parcial 2 - Programación III (Elixir)

Problemas resueltos: **2** (planificación de tareas con dependencias) y **4**
(paréntesis balanceados con profundidad máxima).

## Preparación

1. Copiar el módulo `Util2` en la raíz del proyecto como `util2.ex` (es el módulo
   de utilidades de la clase; el programa lo usa para mostrar mensajes y pedir datos).
2. Tener Elixir instalado. No se usa `mix`: todo son scripts `.exs`.

## Ejecución (desde la carpeta raíz del proyecto)

```
elixir principal.exs
```

`principal.exs` carga los módulos mediante `cargar.exs`. El programa pregunta
(con `Util2.ingresar`) la carpeta de datos y la de salida (Enter = `datos` y
`salida`) y muestra un menú: problema 2, problema 4 o ambos.

Carpetas de prueba incluidas:

| Carpeta            | Propósito                                             |
|--------------------|-------------------------------------------------------|
| `datos/`           | caso válido (los ejemplos del enunciado)              |
| `datos_invalidos/` | errores de formato, duplicados, ciclos, cadenas malas |
| `datos_limite/`    | proyecto vacío, n=1, cadenas mínimas                  |

Ejemplo con el caso inválido: en el menú escribir `datos_invalidos` y `salida_inv`.

## Pruebas automáticas

```
elixir pruebas.exs
```

## Archivos de salida (carpeta `salida/`)

Problema 2: `validacion_tareas.txt`, `planes.csv`, `resumen_tareas.txt`, `mejor_plan.svg`.

Problema 4: `parentesis_n<N>_p<P>.txt`, `primera_n18_p18.txt`,
`verificacion_parentesis.txt`, `secuencia_parentesis.csv`.

## Estructura

- `principal.exs`: punto de entrada. `cargar.exs`: carga los módulos en orden. `pruebas.exs`: pruebas.
- `lib/parcial2.ex`: menú principal.
- `lib/parcial2/archivos.ex`: lectura en flujo (`File.stream!`), comentarios, salida.
- `lib/parcial2/structs.ex`: `%Tarea{}` y `%Plan{}`.
- `lib/parcial2/tareas.ex`: lectura, recursión de planes, resumen.
- `lib/parcial2/tareas/validacion.ex`: validación recursiva (sin `Enum`/`Stream`).
- `lib/parcial2/tareas/svg.ex`: Gantt escrito por fragmentos.
- `lib/parcial2/parentesis.ex`: generador perezoso, validación recursiva, Stream infinito.

## Notas para la sustentación

- **Evaluación perezosa (n=18, p=18):** `generar/2` devuelve un Stream de
  `Stream.concat` + `Stream.flat_map`; cada rama solo se expande cuando el
  consumidor la pide. `Enum.take(stream, 1)` recorre un único camino de
  profundidad 36 y se detiene. Hay 477 638 700 soluciones (Catalan 18) y no se generan.
- **Por qué no se calcula n=9:** `Stream.transform` calcula `{n, total}` y marca
  que el umbral se alcanzó; al llegar el siguiente n devuelve `:halt` *antes* de
  llamar a `contar/2`. n=8 es el primero con total >= 1000 (1430).
- **Ciclos sin rotaciones:** cada ciclo se busca solo desde su primer nodo en la
  lista, exigiendo que los demás nodos vengan después.
- **Recursión de planes:** en cada nivel se prueban, en orden alfabético, las
  tareas pendientes con dependencias ya terminadas; el plan se escribe al llegar
  a la lista vacía de pendientes.
