# Penguin Ternos — Sistema de Gestión

Aplicación full-stack para gestionar una tienda de alquiler y venta de ternos. Permite administrar clientes, crear alquileres con garantía y cálculo de mora, registrar ventas, controlar inventario (incluyendo mantenimiento), programar citas y generar reportes en PDF.

Este README recoge cómo ejecutar el proyecto en desarrollo, cómo desplegar el backend en Render y las variables críticas que necesitas configurar.

**Objetivo:** ofrecer una herramienta sencilla y robusta para llevar control de stock, alquileres y ventas, con informes y operaciones atómicas realizadas en la base de datos (RPCs en PostgreSQL/Supabase).
# Penguin Ternos — ¿De qué trata esta aplicación?

Penguin Ternos es una aplicación pensada para ayudar a tiendas de alquiler y venta de ternos a gestionar su operación diaria sin complicaciones técnicas. Permite, de forma sencilla y visual:

- Registrar y buscar clientes.
- Gestionar alquileres (con registro de garantía y cálculo de mora automáticamente).
- Registrar ventas y devoluciones.
- Mantener el inventario actualizado (disponible, alquilado, en mantenimiento).
- Generar reportes en PDF para contabilidad o revisión.

El objetivo es que personal de tienda y administradores puedan llevar el control desde una interfaz clara, evitando papeleo y errores manuales.

## Público objetivo

Dueños, encargados y personal de mostrador de tiendas de alquiler/venta de ternos o empresas similares que necesiten un sistema simple para:

- Controlar stock.
- Registrar operaciones de alquiler y venta.
- Obtener reportes rápidos y exportables.

No se requiere formación técnica para utilizar la aplicación.

## Servicios externos que utiliza

- Supabase (PostgreSQL administrado): guarda los datos (clientes, artículos, alquileres, ventas, configuraciones) y ejecuta funciones en la base para operaciones seguras.
- Render: aloja el servidor que expone la API usada por la app móvil.

Estos servicios hacen que los datos estén disponibles desde distintos dispositivos y que la tienda no tenga que mantener servidores propios.

## Herramientas y lenguajes usados para desarrollar la aplicación

- Interfaz móvil: Flutter (lenguaje Dart).
- Gestión de estado en la app: Provider (patrón/librería de Flutter).
- Backend / API: Node.js con Express.
- Base de datos: PostgreSQL (a través de Supabase).
- Generación de PDFs: paquetes `pdf` / `printing` en Flutter.

## Descripción corta para presentaciones (1-2 líneas)

Penguin Ternos es una solución digital para gestionar alquileres y ventas de ternos: control de clientes, stock, garantías y reportes listos para imprimir.

Si quieres, adapto este texto a un formato aún más breve para usar en una web o folleto (ej. 1 frase publicitaria). 
**Variables de entorno importantes (backend)**


