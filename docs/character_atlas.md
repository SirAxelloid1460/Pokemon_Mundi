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

## Layout de frames (analizado)
- **Frame = 32×36 px** (ancho 32 confirmado: 96/3, 224/7, 192/6, 160/5; 32/1).
- **idle**: 1 fila. Partes móviles = 3 frames (96 px), estáticas (chest/hair) = 1 frame (32 px).
- **walk/run**: las partes **móviles** son una **rejilla** de N columnas × **3 filas** (alto 108 = 3×36);
  las **estáticas** (chest/hair) son N columnas × 1 fila (alto 36).
  - walk: down/up = 224 px (7 col) · sideways = 192 px (6 col)
  - run:  down/up = 192 px (6 col) · sideways = 160 px (5 col)

## Implementación
- `Scripts/Util/CharacterCompositor.gd` (`class_name CharacterCompositor`): descubre las capas de la
  carpeta, las apila en orden z y crea un `AnimatedSprite2D` por capa (frames cortados de la tira).
  `set_pose(anim, facing)` con facing ∈ {down, up, left, right} (left = sideways + flip).
- `Scenes/debug/CharacterPreview.tscn` (F6): previsualiza · ←/→ animación · ↑/↓ orientación.

## Pendiente / por confirmar con el autor de los assets
1. **Las 3 filas de walk/run** (partes móviles): ¿son 3 frames extra que se leen row-major
   (→ walk = 21 frames y las estáticas 7, que desincronizan), o cada **columna** es el frame y las
   filas son otra cosa (capas/variación vertical)? `CharacterCompositor.USE_ALL_ROWS` lo alterna.
2. **Orden z definitivo** y, en `sideways`, **z por lado** (brazo/pierna lejano —upper— detrás del
   torso y el cercano —lower— delante). Hoy el orden es plano por parte.
3. **Anclaje vertical** de partes con distinto alto al componer.
4. **Recolor** de piel y pelo (vía `palette_swap.gdshader`) y **variantes de ropa** (hat/shirt/pants/
   shoes/gloves del `PlayerCreationPanel`): aún no — el atlas actual son sólo las capas base.
5. Migrar `Player.gd` y `PlayerCreationPanel.gd` para usar el compositor en lugar de `PJ_movement.png`.
