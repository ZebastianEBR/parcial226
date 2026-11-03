# Parcial 2 - Programación III (Elixir)

Dos problemas independientes en un solo repositorio, sin `mix` (todo son scripts `.exs`):

- **Problema 2** - Planificación de tareas con dependencias y diagrama SVG: carpeta `problema2_tareas/`.
- **Problema 4** - Paréntesis balanceados con profundidad máxima y Streams: carpeta `problema4_parentesis/`.

## Preparación

1. Tener Elixir instalado.
2. Dejar el módulo de utilidades de la clase como `Util2.ex` en la **raíz** del repositorio (junto a este README).

## Estructura

```
Util2.ex                      módulo de utilidades de la clase
compartido/archivos.ex        lectura en flujo y escritura de archivos (usado por ambos)
problema2_tareas/
  principal.exs  cargar.exs  pruebas.exs
  lib/   structs.ex  tareas.ex  validacion.ex  svg.ex
  datos/  datos_invalidos/  datos_limite/      (tareas.csv)
  pruebas/tareas_test.exs
problema4_parentesis/
  principal.exs  cargar.exs  pruebas.exs
  lib/   parentesis.ex
  datos/  datos_invalidos/  datos_limite/      (parametros.csv, propuestas.txt)
  pruebas/parentesis_test.exs
```

## Ejecución (siempre desde la raíz del repositorio)

Problema 2:

```
elixir problema2_tareas/principal.exs
```

Problema 4:

```
elixir problema4_parentesis/principal.exs
```

Cada programa pregunta (con `Util2.ingresar`) la carpeta de datos y la de salida. Con Enter usa
`datos` y `salida` dentro de la carpeta del problema. Para otros casos escribir
`datos_invalidos` o `datos_limite` (y, por ejemplo, `salida_inv` como salida).

## Pruebas automáticas

```
elixir problema2_tareas/pruebas.exs
elixir problema4_parentesis/pruebas.exs
```

## Archivos de salida

- Problema 2 (`problema2_tareas/salida/`): `validacion_tareas.txt`, `planes.csv`, `resumen_tareas.txt`, `mejor_plan.svg`.
- Problema 4 (`problema4_parentesis/salida/`): `parentesis_n<N>_p<P>.txt`, `primera_n18_p18.txt`,
  `verificacion_parentesis.txt`, `secuencia_parentesis.csv`.

## Notas para la sustentación

- **Evaluación perezosa (n=18, p=18):** `generar/2` devuelve un Stream de `Stream.concat` +
  `Stream.flat_map`; cada rama solo se expande cuando el consumidor la pide. `Enum.take(stream, 1)`
  recorre un único camino de profundidad 36 y se detiene. Hay 477 638 700 soluciones y no se generan.
- **Por qué no se calcula n=9:** `Stream.transform` calcula `{n, total}` y marca que el umbral se
  alcanzó; al llegar el siguiente n devuelve `:halt` *antes* de llamar a `contar/2`. n=8 es el
  primero con total >= 1000 (1430).
- **Ciclos sin rotaciones:** cada ciclo se busca solo desde su primer nodo en la lista, exigiendo
  que los demás nodos vengan después.
- **Recursión de planes:** en cada nivel se prueban, en orden alfabético, las tareas pendientes con
  dependencias ya terminadas; el plan se escribe al llegar a la lista vacía de pendientes.
