# Back‑end (.NET 8 / C#  +  MySQL)

## 1. Objetivo
Servir como _core_ de dominio, IA y API:
- Gestionar atletas, objetivos, planes, métricas y gamificación.
- Generar planes personalizados mediante LLM (OpenAI fine‑tune).
- Enforcer de políticas de suscripción y seguridad.
- Exponer REST + gRPC para la app y webhooks de dispositivos.

## 2. Arquitectura (C4 Contenedor)
[API Gateway] → gRPC/REST → [Training Service (.NET)] [Training Service] → MySQL [Training Service] ↔ RabbitMQ ↔ [AI Worker] [Auth Service] emisión JWT

shell
Copiar
Editar

### Principales proyectos (.sln)
src/ ├─ ApiGateway/ (YARP) ├─ TrainingService/ │ ├─ Application/ (CQRS MediatR) │ ├─ Domain/ (DDD agregados) │ ├─ Infrastructure/ (EF Core, Repos, MySQL) │ └─ WebApi/ (Controllers, Filters) ├─ AuthService/ (Identity, JWT, RBAC) ├─ AiWorker/ (BackgroundService, OpenAI client) └─ Contracts/ (gRPC & REST DTOs)

markdown
Copiar
Editar

## 3. Dominios y Servicios
- **Aggregates**: Athlete, TrainingPlan, Subscription, Challenge.
- **Domain Services**:  
  - `PlanGenerationService` (construye prompt + persiste resultado).  
  - `ViabilityEvaluator` (Current vs Target Level).  
  - `PlanAdjustmentService` (ventana 7 d).  
  - `WorkoutUnlockPolicy` (24 h + Buffer).  
  - `SubscriptionGuard` (atributos `[Authorize(Tier="Pro")]`).
- **Eventos de dominio → Outbox** para proyecciones y gamificación.

## 4. Capas
| Capa | Patrón | Librerías |
|------|--------|-----------|
| **Presentation** | Minimal API + Swagger | `Swashbuckle` |
| **Application** | CQRS + MediatR | `MediatR`, `FluentValidation` |
| **Domain** | DDD | — |
| **Infrastructure** | EF Core 8, MySQL 8 | `Pomelo.EntityFrameworkCore.MySql` |
| **Integration** | RabbitMQ, Webhooks | `MassTransit`, `Hangfire` worker |

## 5. Seguridad
- JWT RS256, refresh tokens rotativos.
- OWASP Top 10 mitigaciones; `RateLimitMiddleware`.
- TDE en MySQL; Keys → AWS KMS / Azure Key Vault.

## 6. Requerimientos No Funcionales
| Métrica | Valor |
|---------|-------|
| Latencia p95 | ≤ 200 ms |
| SLA | 99.5 % |
| RPM pico | 30 k |
| Observabilidad | OpenTelemetry → Jaeger · Prometheus · Grafana |

## 7. IA Pipeline
1. **Trigger**: `PlanGenerationRequested` event.  
2. **AiWorker** construye prompt (json) y llama OpenAI.  
3. Respuesta validada contra `PlanSchema` (JsonSchema).  
4. Plan persiste (`TrainingPlan`, `TrainingWeeks`, `Workouts`).  
5. Devuelve evento `PlanGenerated`.

## 8. Base de Datos (MySQL 8)
- Tablas: `Athletes`, `Profiles`, `Surveys`, `Goals`, `TrainingPlans`, `Weeks`, `Workouts`, `Metrics`, `Achievements`, `Subscriptions`, `DeviceLinks`, `DomainEvents`.
- Migraciones **Flyway** en pipeline CI (`pre-deploy`).

## 9. Endpoints REST (extracto)
| Método | URL | Tier | Descripción |
|--------|-----|------|-------------|
| `POST` | `/athletes` | Free | Alta de atleta |
| `POST` | `/survey` | Free | Respuestas onboarding |
| `GET` | `/plan/today` | Free | Entreno del día |
| `POST` | `/workout/{id}/complete` | Free | Completar entreno |
| `POST` | `/plan/regenerate` | Pro | Nueva versión de plan |
| `POST` | `/subscription/upgrade` | Free | Cambio de tier |

## 10. CI/CD & Ops
- **GitHub Actions**: test → build → scan (Sonar) → docker → Helm upgrade.  
- **Kubernetes**: HPA, PodDisruptionBudget.  
- **Blue‑Green** deploy con flag `X-Canary`.  
- **Secrets** gestionados vía Vault.  
- **Chaos testing** con Litmus.

## 11. Pruebas
- Unit (xUnit) 80 % coverage.  
- Integration (Testcontainers MySQL).  
- Contract (Pact + Dredd).  
- Load (k6‑cloud).  
- Resilience (Polly fault‑injection in staging).

## 12. Roadmap Backend
| Versión | Características | Meta |
|---------|-----------------|------|
| **1.0** | Aggregates, Plan IA, Free tier | Q4‑2025 |
| **1.1** | Pagos, Pro tier, Garmin sync | Q1‑2026 |
| **1.2** | Elite tier, Live alerts, Coach chat | Q2‑2026 |
Cada documento es autosuficiente para sus respectivos equipos.
Mantén la sincronía vía contratos / DTOs compartidos en Contracts/.