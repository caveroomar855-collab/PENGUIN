# Logo Placeholder

Para agregar el logo de Penguin Ternos:

1. Crea una carpeta `assets` en la raíz de `flutter_app`:
   ```
   flutter_app/assets/
   ```

2. Coloca tu logo en formato PNG con el nombre `logo.png`

3. También puedes crear una subcarpeta `images` para otras imágenes:
   ```
   flutter_app/assets/images/
   ```

4. El logo se mostrará en el splash screen automáticamente

## Recomendaciones para el logo:

- Formato: PNG con transparencia
- Tamaño recomendado: 512x512 px
- Peso: Menos de 500 KB
- Fondo transparente para mejor visualización

## Alternativa temporal:

Actualmente el splash screen usa un ícono de Flutter. Puedes personalizarlo
editando el archivo: `lib/screens/splash_screen.dart`

Busca esta línea (alrededor de la línea 60):
```dart
const Icon(
  Icons.checkroom,  // Cambia este ícono
  size: 80,
  color: Colors.lightBlue,
)
```

Puedes cambiar `Icons.checkroom` por otro ícono de Material Icons:
- `Icons.business_center`
- `Icons.store`
- `Icons.style`
- etc.

O reemplazar todo el Container por un Image.asset cuando tengas tu logo:
```dart
Image.asset(
  'assets/logo.png',
  width: 150,
  height: 150,
)
```
