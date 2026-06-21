# Personaje principal por capas (atlas)

El personaje deja de construirse desde un spritesheet pre-hecho (`MainCharacter/PJ_movement.png`)
y pasa a **componerse por capas** (paper-doll) desde `Assets/Sprites/MainCharacter/atlas/`.

## Estructura de los assets
```
atlas/{anim}/{dir}/{parte}[/lado]/1.png
  anim  = idle | walk | run
  dir   = down | up | sideways      (left/right = sideways con flip horizontal)
  parte = head, hair, chest, arms, hands, legs, feet
  lado  = left/right (down,up) · upper/lower (sideways) · sin lado (chest, hair, head)
```

## Layout de frames (confirmado)
- **Frame = 32×36 px** (ancho 32 confirmado: 96/3, 224/7, 192/6, 160/5; 32/1).
- **COLUMNAS = frames de animación · FILAS = variantes** (todas las partes comparten el nº de
  columnas dentro de un grupo, así que nunca desincronizan; cada parte usa una fila/variante).
  - idle: 3 col (3 frames). walk: 7 col (down/up) · 6 col (sideways). run: 6 col · 5 col.
  - Partes móviles traen 3 filas (variantes); chest/hair traen 1.
- `CharacterCompositor.variant` / `set_variant()` elige la fila; `CharacterPreview` la cicla con Enter.

## Implementación
- `Scripts/Util/CharacterCompositor.gd` (`class_name CharacterCompositor`): descubre las capas de la
  carpeta, las apila en orden z y crea un `AnimatedSprite2D` por capa (frames cortados de la tira).
  `set_pose(anim, facing)` con facing ∈ {down, up, left, right} (left = sideways + flip).
- `Scenes/debug/CharacterPreview.tscn` (F6): previsualiza · ←/→ animación · ↑/↓ orientación.

## Pendiente / por confirmar con el autor de los assets
1. **Qué representa cada variante (fila)** y cómo se mapea a la personalización
   (skin_tone / hair_color / ropa). Hoy `variant` es global; quizá deba ser por parte.
2. **Orden z definitivo** y, en `sideways`, **z por lado** (brazo/pierna lejano —upper— detrás del
   torso y el cercano —lower— delante). Hoy el orden es plano por parte.
3. **Anclaje vertical** de partes con distinto alto al componer.
4. **Recolor** de piel y pelo (vía `palette_swap.gdshader`) y **variantes de ropa** (hat/shirt/pants/
   shoes/gloves del `PlayerCreationPanel`): aún no — el atlas actual son sólo las capas base.
5. Migrar `Player.gd` y `PlayerCreationPanel.gd` para usar el compositor en lugar de `PJ_movement.png`.
