# Research: AI-Generated Product Descriptions

**Feature**: 001-ai-product-descriptions  
**Date**: 2025-11-16  
**Phase**: 0 - Outline & Research

## Research Questions

### 1. Azure OpenAI SDK for Go Integration

**Decision**: Use `github.com/Azure/azure-sdk-for-go/sdk/ai/azopenai` v0.4.0+

**Rationale**:
- Official Azure SDK with Managed Identity support
- Native Go implementation (no CGO dependencies)
- Supports chat completions API for GPT-4/GPT-3.5-turbo
- Built-in retry logic and error handling
- Active maintenance by Microsoft

**Alternatives Considered**:
- **OpenAI Go SDK** (sashabaranov/go-openai): Rejected - requires API key, no Managed Identity support
- **Direct HTTP calls**: Rejected - would require manual auth token refresh, retry logic, error handling

**Implementation Pattern**:
```go
import (
    "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
    "github.com/Azure/azure-sdk-for-go/sdk/ai/azopenai"
)

// Use DefaultAzureCredential for Managed Identity
cred, _ := azidentity.NewDefaultAzureCredential(nil)
client, _ := azopenai.NewClient(endpoint, cred, nil)
```

### 2. Caching Strategy for AI Descriptions

**Decision**: Use Dapr state store (Redis) with 24-hour TTL

**Rationale**:
- Dapr state store already configured for products service
- Redis provides fast in-memory lookups (<1ms)
- TTL support prevents stale descriptions
- Consistent with existing architecture (users/cart services use Dapr state)
- Enables cache metrics via Dapr observability

**Alternatives Considered**:
- **In-memory cache (sync.Map)**: Rejected - lost on pod restart, no TTL support, no distributed cache
- **PostgreSQL cache table**: Rejected - slower than Redis, adds DB load
- **Azure Cache for Redis directly**: Rejected - bypasses Dapr, inconsistent with architecture

**Cache Key Pattern**: `ai-description:{product_id}`

**TTL Justification**: 24 hours balances freshness with cost. Products rarely change descriptions daily.

### 3. Placeholder Detection Logic

**Decision**: Multi-criteria detection:
1. Description length < 20 characters
2. Description contains "..." substring
3. Description is empty or whitespace-only

**Rationale**:
- Covers common placeholder patterns in products.csv
- Simple boolean logic (no regex overhead)
- Explicit criteria make testing straightforward

**Alternatives Considered**:
- **Regex pattern matching**: Rejected - overkill for simple checks, performance overhead
- **ML-based detection**: Rejected - unnecessary complexity for Level 1
- **Manual product tagging**: Rejected - requires data migration, not scalable

### 4. Prompt Engineering for Product Descriptions

**Decision**: System + user message pattern with structured prompt

**System Message**:
```
You are an e-commerce product description writer. Write compelling, accurate, 
professional descriptions that highlight key features and benefits. Keep descriptions 
to 2-3 sentences. Use engaging but professional language suitable for online retail.
```

**User Message Template**:
```
Write a product description for: {product_name}
Category: {category}
Price: ${price}
```

**Rationale**:
- System message sets tone and constraints
- User message provides context (name, category, price)
- 2-3 sentence limit controls token usage and cost
- Professional tone aligns with e-commerce standards

**Alternatives Considered**:
- **Single-shot prompt**: Rejected - less control over output format
- **Few-shot examples**: Rejected - increases token usage, not needed for simple task
- **Temperature tuning**: Using default 0.7 for balanced creativity/consistency

### 5. Error Handling and Circuit Breaker

**Decision**: Implement graceful fallback with exponential backoff

**Pattern**:
1. Attempt Azure OpenAI call with 5-second timeout
2. On failure: log error, return original description
3. On rate limit (429): exponential backoff, return original description
4. On timeout: return original description, increment timeout metric

**Rationale**:
- Preserves user experience (no broken pages)
- Meets 99.9% uptime requirement
- Prometheus metrics enable alerting on failures
- Simple implementation (no external circuit breaker library needed)

**Alternatives Considered**:
- **gobreaker library**: Rejected - adds dependency, simple fallback sufficient for Level 1
- **Retry with jitter**: Rejected - 5-second timeout already generous, retries would delay page load
- **Queue failed requests**: Rejected - over-engineering for Level 1, adds complexity

### 6. Prometheus Metrics Design

**Decision**: Four key metrics

**Metrics**:
```go
ai_description_requests_total (counter, labels: status=[success|error|timeout|cached])
ai_description_cache_hits_total (counter)
ai_description_cache_misses_total (counter)
ai_description_latency_seconds (histogram, buckets: 0.1, 0.5, 1, 2, 5)
```

**Rationale**:
- Counters track volume and success rate
- Cache metrics measure cost optimization (target 80%+ hit rate)
- Latency histogram enables SLO monitoring (p95 < 2s)
- Labels enable filtering by outcome

**Alternatives Considered**:
- **Token usage metric**: Deferred to Module 3 (requires Azure Monitor integration)
- **Cost per request**: Deferred to Module 3 (requires pricing API)
- **Description quality score**: Deferred to future (requires user feedback)

## Technology Stack Summary

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Language | Go | 1.23+ | Existing products service |
| Azure SDK | azure-sdk-for-go/sdk/ai/azopenai | 0.4.0+ | Azure OpenAI client |
| Auth | azure-sdk-for-go/sdk/azidentity | 1.5.0+ | Managed Identity |
| Cache | Dapr state store (Redis) | Dapr 1.12+ | Description caching |
| Metrics | prometheus/client_golang | 1.18+ | Observability |
| Testing | testify | 1.8+ | Assertions |

## Implementation Risks

| Risk | Mitigation |
|------|-----------|
| Azure OpenAI rate limits | Cache responses (80%+ hit rate), 5s timeout, graceful fallback |
| Inappropriate AI content | System prompt constraints, manual review of initial outputs |
| Cost overruns | Caching, timeout, Prometheus cost tracking dashboard |
| Managed Identity misconfiguration | Detailed setup docs in quickstart.md, RBAC validation script |
| Cache invalidation on product updates | 24h TTL acceptable (products rarely change), manual cache clear if needed |

## Next Steps

Phase 1 will produce:
- **data-model.md**: Product entity, AI cache entity
- **contracts/**: No new API endpoints (internal enhancement)
- **quickstart.md**: Local dev setup, Azure OpenAI provisioning, Managed Identity configuration
