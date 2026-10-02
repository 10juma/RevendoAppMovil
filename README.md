# Revendo (app móvil)

App en Flutter para Revendo — SaaS multi-tenant para negocios que revenden/producen
productos de limpieza y hogar. Consume `Revendo.Api` (repo `Revendo.Web`, proyecto
`Revendo.Api`), nunca llama directo a la base de datos.

- **Repartidor**: solo ve y avanza sus propias entregas (`/api/entregas`), nunca precios/totales.
- **Admin/Vendedor**: Dashboard, Reportes, y CRUD de la mayoría de los módulos del panel
  web (Productos, Almacenes, Existencias, Producción, Proveedores, Compras, Clientes,
  Ventas, Gastos, Listas de precios, Rutas de reparto, Equipo, Mi negocio) — mismos
  permisos por rol que la web. Compras y Ventas son solo alta desde la app (editar una
  existente reconcilia inventario ya movido, eso se queda en la web).
- Compartir ticket de una venta/compra como imagen (vía `share_plus`), pensado para
  mandarlo por WhatsApp.

## Stack

Flutter 3.x / Dart, `http` para consumir la Api, `shared_preferences` para la sesión,
`share_plus` + `path_provider` para compartir tickets, `intl` para moneda/fechas.

## Correr en local

```bash
flutter pub get
flutter run
```

`lib/services/api_client.dart` apunta a `https://revendoapi.globalappsuite.com.mx` fijo
(no hay variante de ambiente todavía) — para probar contra un backend local hay que
cambiar `baseUrl` ahí a mano.

## Identidad de la app

- **Bundle ID / Application ID**: `com.globalappsuite.revendo` (Android e iOS).
- **Ícono y splash**: generados desde `assets/images/logo_1024x1024.jpeg` con
  `flutter_launcher_icons` y `flutter_native_splash` — si el logo cambia, hay que
  volver a correr `dart run flutter_launcher_icons` y `dart run flutter_native_splash:create`.

## Firma de release (Android)

`android/upload-keystore.jks` + `android/key.properties` — **ninguno de los dos se sube
a git** (ver `android/.gitignore`). Sin `key.properties`, el build de `release` cae de
vuelta a la llave de debug automáticamente (para que `flutter run --release` siga
funcionando en una máquina nueva sin el keystore).

El keystore y sus contraseñas están respaldados fuera de este repo — si se pierden, no
se puede volver a actualizar la app en Play Store con la misma identidad.

```bash
flutter build appbundle --release   # para Play Console
flutter build apk --release         # para probar/instalar directo
```

## iOS

El Xcode usado para compilar ya no soporta deployment target menor a 15.0 — el
`Podfile` fija `platform :ios, '15.0'` y fuerza ese mínimo en todos los pods vía
`post_install` (algunos traían 9.0–13.0 declarado y eso rompía el build). La firma real
(certificado de distribución + perfil de aprovisionamiento) se hace desde Xcode con la
cuenta de Apple Developer — no es parte de este repo.

```bash
flutter build ios --release --no-codesign   # para verificar que compila, sin firmar
```

## Estado

Apps subidas a **Google Play Console** y **App Store Connect** el 1 de octubre de 2026,
en espera de revisión/aprobación. CRUD completo de los módulos de Admin/Vendedor, ícono
y splash con el logo real, y firma de release propia (ya no la de debug).
