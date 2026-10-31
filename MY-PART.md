# 🧱 Teammate 1 — Platform & Infrastructure (My Part)

## What I own
| Item | Port | Purpose |
|---|---|---|
| `backend/eureka-server/` | **8761** | Service registry — every other service registers here |
| `backend/api-gateway/` | **8080** | Single entry point: JWT auth filter, routing, CORS, rate limiting |
| `backend/common-lib/` | — | Shared DTOs, `JwtUtil`, exceptions (**shared contract of the whole team**) |
| `start-backend.ps1` / `stop-backend.ps1` | — | Chunk-local orchestrators |
| `SETUP.md`, `RUN-LOCAL.md`, `PHASE0-RUNBOOK.md` | — | Onboarding & infra docs |

## How to run my part
```powershell
cd backend
mvn -q install -DskipTests      # first build (~1-2 min)
cd ..
.\start-backend.ps1             # starts eureka + gateway
.\stop-backend.ps1 -IncludeEureka   # to stop
```
No MongoDB needed for this chunk (infra only).

## ⚠️ Special responsibility
`common-lib`, `eureka-server` and `api-gateway` exist as **copies inside every
teammate's folder** so each one can run standalone. **My folder is the MASTER copy.**
If the shared contract changes (new DTO, new JWT claim, gateway route), I make the
change here and tell the others to re-copy these 3 directories.

## Everyday checks
- Eureka dashboard: http://localhost:8761
- Gateway health: http://localhost:8080/actuator/health
