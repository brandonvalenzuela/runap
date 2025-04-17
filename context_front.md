# Front‑end (Flutter + Dart)

## 1. Objetivo
Crear una app móvil (iOS 15+, Android 11+) que:
- Guíe al usuario en el onboarding y la encuesta inicial.
- Muestre el plan de entrenamiento día a día (desbloqueo 24 h + Recovery Buffer).
- Sincronice métricas de dispositivos (Garmin, Apple Watch, Fitbit, HRM BLE).
- Gamifique la experiencia (logros, puntos, retos).
- Permita gestión de suscripción (Free, Pro, Elite) y pagos in‑app.

## 2. Arquitectura Flutter
| Capa | Librerías / patrones |
|------|----------------------|
| **Presentación** | Material 3 · Responsive · `go_router` · `flutter_hooks` |
| **Estado** | Riverpod 2 (`ProviderScope` global) |
| **Datos** | `dio` (REST) · gRPC optional hooks |
| **Persistencia local** | `hive` (cifrado) para tokens, último plan, cache offline |
| **Background** | `workmanager` para sync métricas & notifs |
| **Inyección dependencias** | `get_it` + Riverpod |

### Carpeta de módulos
lib/ ├─ app.dart ├─ features/ │ ├─ onboarding/ │ ├─ plan/ │ ├─ workout/ │ ├─ gamification/ │ ├─ subscription/ │ └─ settings/ └─ shared/ (theme, widgets, utils, network, models)

markdown
Copiar
Editar

## 3. Flujos Clave de UI
1. **Onboarding & Encuesta**  
   - Ruta: `/onboarding` → `/survey` → `/review-goal`  
   - Llama `POST /athletes`, `POST /survey`, `GET /plan`.
2. **Entreno Diario**  
   - Home (`/plan/today`) muestra tarjeta del entreno.  
   - Al tocar → `/workout/{id}` (mapa + tiempo real).  
   - Botón *Completar* → `POST /workout/{id}/complete`.
3. **Gamificación**  
   - `/profile/achievements`, `/challenges`.  
   - Websocket o polling `GET /events`.
4. **Suscripción**  
   - `/subscription` lista planes.  
   - Usa `in_app_purchase` + `POST /subscription/upgrade`.
5. **Integración Dispositivo**  
   - `/devices` enlaza OAuth (WebView).  
   - Background task procesa webhooks externos.

## 4. Accesibilidad y UX
- WCAG 2.1 AA (contraste, texto dinámico, screen readers).
- Haptic feedback: suave en logros / fuerte al completar entreno.
- Modo oscuro y tema de alto contraste.

## 5. Internacionalización
- Soporta **es‑MX** y **en‑US** con `flutter_localizations` y `intl`.

## 6. Observabilidad Cliente
- `firebase_crashlytics` + `firebase_analytics`.
- Propagar `trace-id` en cabecera `X-Request-ID`.