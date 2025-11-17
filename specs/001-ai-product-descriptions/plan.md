# Implementation Plan: AI-Generated Product Descriptions

**Branch**: `001-ai-product-descriptions` | **Date**: 2025-11-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-ai-product-descriptions/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enhance the products service to automatically generate compelling product descriptions using Azure OpenAI when placeholder or minimal descriptions are detected. The feature implements Level 1 of the AI progression framework (Gen AI via API) with Managed Identity authentication, response caching for cost optimization, graceful fallback for reliability, and Prometheus metrics for observability.

**Primary Requirement**: Products with placeholder descriptions (<20 chars or containing "...") display AI-generated 2-3 sentence descriptions within 3 seconds.

**Technical Approach**: Modify existing Go products service to detect placeholder descriptions, call Azure OpenAI API with Managed Identity, cache responses in Redis/memory, implement circuit breaker for fallback, and expose Prometheus metrics.

## Technical Context

**Language/Version**: Go 1.23+  
**Primary Dependencies**: 
- Azure Identity SDK for Go (github.com/Azure/azure-sdk-for-go/sdk/azidentity)
- Azure OpenAI SDK for Go (github.com/Azure/azure-sdk-for-go/sdk/ai/azopenai)
- Dapr Go SDK (github.com/dapr/go-sdk) for state management
- Prometheus client for Go (github.com/prometheus/client_golang)

**Storage**: 
- Redis via Dapr state store (description cache with 24h TTL)
- SQLite (existing product database - to be migrated to PostgreSQL per Module 0)

**Testing**: 
- Go testing package (testing)
- testify for assertions (github.com/stretchr/testify)
- httptest for mocking Azure OpenAI responses

**Target Platform**: Linux containers on Azure Kubernetes Service (AKS)

**Project Type**: Microservice enhancement (existing products service in dapr-store monorepo)

**Performance Goals**: 
- <3 seconds total page load time (including AI generation)
- <2 seconds Azure OpenAI API latency (p95)
- 80%+ cache hit rate after initial generation
- Support 100 concurrent product views

**Constraints**: 
- 5-second timeout for Azure OpenAI calls
- NO API keys in code/config (Managed Identity only)
- Graceful degradation required (99.9% uptime)
- Minimal changes to existing products service code

**Scale/Scope**: 
- ~50-100 products in catalog (from products.csv)
- Expected 1000 daily product views
- Azure OpenAI rate limit: 60 requests/minute (standard tier)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Microservices-First Architecture
- ✅ **PASS**: Enhances existing products microservice (no new service needed for Level 1)
- ✅ **PASS**: Products service already Dapr-enabled with service invocation
- ✅ **PASS**: Existing containerization and health checks maintained

### Principle II: AKS-Native Deployment
- ✅ **PASS**: Products service already has Helm chart in deploy/helm/daprstore
- ✅ **PASS**: Resource limits will be updated for AI workload (CPU/memory)
- ✅ **PASS**: No HPA changes needed (stateless AI calls)

### Principle III: AI Model Integration Standards - Level 1
- ✅ **PASS**: Uses Azure OpenAI API (Level 1 - Gen AI via API)
- ✅ **PASS**: Managed Identity authentication (NO API keys)
- ✅ **PASS**: Response caching implemented (cost optimization)
- ✅ **PASS**: Graceful fallback for service unavailability

### Principle IV: Observability & Monitoring
- ✅ **PASS**: Prometheus /metrics endpoint already exists on products service
- ✅ **PASS**: Custom metrics added: ai_description_requests_total, ai_description_cache_hits, ai_description_latency_seconds
- ✅ **PASS**: Structured logging for Azure OpenAI calls (JSON format)
- ✅ **PASS**: Grafana dashboard update planned (Module 1 requirement)

### Principle V: Incremental AI Enhancement
- ✅ **PASS**: Baseline products service functionality preserved
- ✅ **PASS**: AI generation only for placeholder descriptions (existing descriptions untouched)
- ✅ **PASS**: Graceful degradation ensures 99.9% uptime
- ✅ **PASS**: Feature independently testable (can disable AI generation via config)

### Principle VI: Data Persistence & Scalability
- ⚠️ **DEFERRED**: SQLite migration to PostgreSQL is Module 0 prerequisite
- ✅ **PASS**: AI description cache uses Dapr state store (Redis)
- ✅ **PASS**: No writes to product database (read-only AI enhancement)

### Security Standards
- ✅ **PASS**: Managed Identity for Azure OpenAI (no API keys)
- ✅ **PASS**: No PII in logs or metrics
- ✅ **PASS**: TLS for Azure OpenAI API calls

### Cost Optimization
- ✅ **PASS**: Response caching (80%+ hit rate target)
- ✅ **PASS**: 5-second timeout prevents runaway costs
- ✅ **PASS**: Prometheus metrics for cost tracking

**Overall Status**: ✅ **PASSED** - All gates passed. SQLite→PostgreSQL migration is Module 0 prerequisite (not blocking for this feature).

## Project Structure

### Documentation (this feature)

```text
specs/001-ai-product-descriptions/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - Technology decisions
├── data-model.md        # Phase 1 output - Product & cache entities
├── quickstart.md        # Phase 1 output - Setup guide
├── contracts/           # Phase 1 output - API contracts
│   └── README.md        # No new endpoints (internal enhancement)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

**Structure Decision**: Microservice enhancement - modifying existing products service in dapr-store monorepo.

```text
dapr-store/
├── cmd/
│   └── products/                    # MODIFIED: Existing products service
│       ├── main.go                  # MODIFIED: Add AI client initialization
│       ├── routes.go                # MODIFIED: Enhance /get, /catalog, /search endpoints
│       ├── impl/
│       │   └── impl.go              # MODIFIED: Add AI description generation logic
│       ├── spec/
│       │   └── spec.go              # NO CHANGE: Product interface unchanged
│       └── ai/                      # NEW: AI description generation module
│           ├── client.go            # NEW: Azure OpenAI client with Managed Identity
│           ├── cache.go             # NEW: Dapr state store cache wrapper
│           ├── generator.go         # NEW: Description generation logic
│           ├── metrics.go           # NEW: Prometheus metrics
│           └── client_test.go       # NEW: Unit tests
├── components/
│   └── statestore.yaml              # NO CHANGE: Existing Dapr state store config
├── deploy/
│   └── helm/
│       └── daprstore/
│           ├── templates/
│           │   └── products.yaml    # MODIFIED: Add Managed Identity annotations
│           └── values.yaml          # MODIFIED: Add Azure OpenAI config
└── go.mod                           # MODIFIED: Add Azure SDK dependencies
```

**Key Changes**:
- **New directory**: `cmd/products/ai/` - AI-specific logic isolated from core service
- **Modified files**: `main.go`, `routes.go`, `impl/impl.go` - Minimal changes to integrate AI
- **New tests**: `ai/client_test.go` - Unit tests for AI module
- **Helm updates**: Managed Identity configuration for AKS deployment

**Design Rationale**:
- Isolate AI logic in separate package for testability and maintainability
- Minimal changes to existing products service code (Principle V: Incremental Enhancement)
- No new microservice needed for Level 1 (Principle I: Microservices-First)

## Complexity Tracking

> **No violations** - All constitution checks passed. No complexity justification needed.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
