# Aplicación Móvil de Entrenamiento Personalizado para Corredores Recreativos

*Stack tecnológico*: **Flutter + Dart** (front‑end), **.NET 8 / C#** (back‑end) y **MySQL** (base de datos creada desde cero).

---

## 1. Objetivo Principal
Generar planes de entrenamiento **personalizados** para corredores recreativos, adaptándolos de manera inteligente a sus capacidades, objetivos y desempeño real.

---

## 2. Sistema de Evaluación Inicial
1. **Encuesta de registro**  
   - Preguntas validadas para evitar respuestas redundantes o poco útiles.  
   - Datos recopilados alimentan un modelo de **Inteligencia Artificial (IA)** que genera el plan inicial.
2. **Validación de realismo**  
   - La IA verifica si el objetivo declarado es viable en el tiempo disponible.  
   - Si no lo es, propone metas alternativas (p. ej., reducir distancia o ajustar ritmo).

---

## 3. Tipos de Objetivo del Usuario
| Tipo | Descripción | Sub‑opciones |
|------|-------------|--------------|
| **Carrera específica** | Participar en 5 K, 10 K, medio maratón o maratón | • Completar <br> • Completar en tiempo determinado |
| **Ritmo objetivo** | Alcanzar un ritmo dado en una distancia (ej.: 4 min/km para 10 K) | — |
| **Sin objetivo específico** | Mantenerse activo con un plan general | — |

---

## 4. Análisis de Viabilidad con IA
- La IA compara **TargetLevel** (meta) con **CurrentLevel** (perfil) y genera un *ViabilityReport*.  
- Si el objetivo es inviable, sugiere alternativas (ej.: correr 5 K en vez de maratón) y solicita confirmación del usuario antes de crear el plan.

---

## 5. Seguimiento y Adaptación del Plan
1. **Monitoreo básico** – comprobar si el entrenamiento del día se completó.  
2. **Monitoreo avanzado** – ritmo promedio, FC, distancia, RPE, etc.  
3. **Reconfiguración periódica** (“Elastic Plan”):  
   - Ventana de revisión cada 7 días.  
   - Si `CompletedRatio < 80 %` o `AvgRPE > 8`, reducir carga 10 %.  
   - Si `CompletedRatio > 95 %` y `AvgRPE < 6`, aumentar carga 5 %.

---

## 6. Manejo de Entrenamientos Incompletos
| Estrategia | Descripción | Recomendación |
|------------|-------------|---------------|
| *Recovery Buffer* | Máx. 2 entrenos recuperables sin penalidad | Activar por defecto |
| *Penalty Points* | Penaliza entrenos perdidos fuera del buffer | Aplicar para gamificación |
| *Desbloqueo 24 h* | Solo se muestra el entreno del día; el siguiente se desbloquea al completarlo o al finalizar el día | Combinar con *Recovery Buffer* |

---

## 7. Funcionalidades Adicionales
### 7.1 Gamificación
- Logros (medallas, insignias, trofeos virtuales).  
- Sistema de puntos por consistencia y mejora.  
- Retos diarios, semanales y mensuales con ranking.  
- Competencias opcionales entre usuarios.

### 7.2 Visualización y Retroalimentación
- Gráficos de progreso (rendimiento y salud).  
- Alertas inteligentes en tiempo real durante el entrenamiento.

### 7.3 Educación Personalizada
- Consejos de técnica, recuperación, nutrición e hidratación.  
- Módulos interactivos activados según la fase del plan.

### 7.4 Integración con Dispositivos
- Compatibilidad con Garmin, Apple Watch, Fitbit, bandas cardíacas, etc.  
- Sincronización automática de métricas avanzadas.

### 7.5 Comunidad y Aspectos Sociales
- Feed para compartir logros y participar en grupos.  
- Equipos privados y retos colaborativos.  
- Integración con redes sociales.

---

## 8. Modelo de Suscripción por Niveles (Tiers)
| Plan | Características clave |
|------|-----------------------|
| **Free** | 1 plan activo · 2 regeneraciones/mes · Integración con un solo dispositivo |
| **Pro** | Planes ilimitados · Re‑generaciones ilimitadas · Desbloqueo anticipado 7 días · Multi‑dispositivo · Feedback IA post‑entreno |
| **Elite** | Alertas live (audio/haptic) · Informe semanal PDF · Coach virtual (chat) · Retos privados ilimitados · Detector predictivo de lesiones |

---

## 9. Dominio – Objetos de Negocio
*(Agregados, VO y servicios clave — ver tablas anteriores.)*

---

## 10. Requerimientos No Funcionales (NFR)
| Categoría | Meta |
|-----------|------|
| **Rendimiento** | ≤ 200 ms p95 en `POST /workouts` y `GET /plan/today` |
| **Disponibilidad** | SLA 99.5 % mensual |
| **Escalabilidad** | Soportar 50 k usuarios activos con picos de 500 rps |
| **Seguridad** | JWT + RBAC; OWASP Top 10 mitigado; cifrado TLS 1.3; hashing BCrypt |
| **Privacidad** | Cumplir GDPR/CCPA; consentimiento explícito para datos de salud |
| **Accesibilidad** | WCAG 2.1 AA para la app Flutter |
| **Portabilidad** | Despliegue contenedorizado (Docker + K8s) |
| **Observabilidad** | Logs estructurados, trazas OpenTelemetry, métricas Prometheus |
| **Compatibilidad** | iOS 15+, Android 11+; dispositivos BLE HRM v4+ |

---

## 11. Arquitectura de Alto Nivel (C4)
Context → Contenedores [Mobile App] → HTTPS → [API Gateway] [API Gateway] → gRPC → [Training Service (.NET)] [Training Service] → MySQL [Training Service] → RabbitMQ → [AI Worker] [AI Worker] → OpenAI LLM [Training Service] ↔ Garmin/Fitbit APIs [API Gateway] ↔ Auth Service (JWT)

yaml
Copiar
Editar
*(Diagrama detallado en PlantUML anexo.)*

---

## 12. Flujos de Usuario Clave
| Flujo | Pasos | Endpoints |
|-------|-------|-----------|
| **Onboarding** | Alta → Encuesta → Viabilidad → Plan generado | `POST /athletes`, `POST /survey`, `GET /plan` |
| **Entreno Diario** | Desbloqueo → Mapa Live → Completar/Abandonar | `GET /plan/today`, `POST /workout/{id}/complete` |
| **Regenerar Plan** | Ajustar objetivo → Nueva IA prompt → Plan v +1 | `PATCH /goal`, `POST /plan/regenerate` |
| **Upgrade de Suscripción** | Selección tier → Pago → Activación | `POST /subscription/upgrade` |
| **Integrar Dispositivo** | OAuth → Webhook/sync → Métricas | `POST /device/link`, `POST /device/webhook` |

---

## 13. Observabilidad & Métricas
- **Dashboards**: rendimiento API, tasa de errores, latencia IA, backlog de colas.  
- **Alertas**: p95 latencia > 400 ms; errores 5xx > 1 %.  
- **Trazabilidad**: trace‑ID propagado desde app Flutter → API → micro‑servicios → LLM.

---

## 14. Seguridad & Cumplimiento
- Cifrado AES‑256 en reposo (MySQL TDE).  
- Rotación de claves / tokens cada 90 días.  
- Limpieza de PII tras 3 años de inactividad.  
- Política de cookies y Términos de uso pre‑aprobados por Legal.

---

## 15. Operación & DevOps
| Tema | Estrategia |
|------|------------|
| **CI/CD** | GitHub Actions: build, test, scan, dockerize, deploy → staging/prod |
| **Infra** | Kubernetes (AKS/EKS) · Helm charts · Horizontal Pod Autoscaler |
| **Migraciones** | Flyway/EF Core Migrations en fase `pre-deploy` |
| **Versionado API** | SemVer; breaking changes → `/v{n}` prefix |
| **Rollback** | Blue‑Green deployments con bandera de feature |

---

## 16. Modelo IA – Detalles
| Aspecto | Definición |
|---------|-----------|
| **Dataset** | 200 k planes históricos anonimizados + métricas CRONOA (Garmin, Strava) |
| **Feature Engineering** | Edad, género, VO₂max, CTL, ATL, disponibilidad semanal |
| **Modelo base** | GPT‑4o (OpenAI) fine‑tuned con RLHF |
| **Métricas de calidad** | MAE en tiempo‑objetivo (≤ 2 %), precisión viabilidad (≥ 95 %) |
| **Retraining** | Cada 3 meses o Δ > 10 % en error |

---

## 17. Plan de Pruebas
- **Unitarias** – cobertura ≥ 80 % en servicios de dominio.  
- **Integración** – API + DB + cola; contract testing con Pact.  
- **Performance** – k6: 500 rps durante 30 min.  
- **Resiliencia** – Chaos Mesh: caída de MySQL primario, latencia en API externa.  
- **E2E móviles** – Flutter Driver + Firebase Test Lab.

---

## 18. Roadmap
| Fase | Alcance | Fecha meta |
|------|---------|-----------|
| **MVP 1.0** | Onboarding, plan IA, entreno diario, Free tier | Q4 ‑ 2025 |
| **v 1.1** | Pro tier, pagos, integración Garmin | Q1 ‑ 2026 |
| **v 1.2** | Elite tier, alertas live, coach virtual | Q2 ‑ 2026 |
| **v 2.0** | Predictor de lesiones, retos privados, IA retraining v2 | Q4 ‑ 2026 |

---

## 19. Prompt Guide – Instrucciones para la IA
*(Sección intacta de la versión anterior, ahora con contexto ampliado).*  

> **Copia y pega** este documento como **single‑source of truth**.  
> El equipo técnico debe respetar los NFR, arquitectura y roadmap; la IA debe seguir la Prompt Guide para generar código
