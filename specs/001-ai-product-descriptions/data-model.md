# Data Model: AI-Generated Product Descriptions

**Feature**: 001-ai-product-descriptions  
**Date**: 2025-11-16  
**Phase**: 1 - Design & Contracts

## Entities

### Product (Existing - Enhanced)

**Purpose**: Represents a product in the catalog. Enhanced to support AI-generated descriptions.

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | string | Required, unique, format: "prd{N}" | Product identifier |
| name | string | Required, max 200 chars | Product name |
| description | string | Optional, max 1000 chars | Product description (may be AI-generated) |
| price | float64 | Required, > 0 | Product price in USD |
| category | string | Optional, max 50 chars | Product category |
| image | string | Optional, URL format | Product image URL |
| onOffer | boolean | Required, default false | Whether product is on sale |

**Validation Rules**:
- `id` must match pattern `^prd[0-9]+$`
- `price` must be positive
- `description` is considered placeholder if:
  - Length < 20 characters, OR
  - Contains "..." substring, OR
  - Is empty/whitespace-only

**State Transitions**: None (read-only for this feature)

**Relationships**: None

**Storage**: SQLite (existing) - to be migrated to PostgreSQL in Module 0

**Example**:
```json
{
  "id": "prd1",
  "name": "Wireless Bluetooth Headphones",
  "description": "...",
  "price": 79.99,
  "category": "Electronics",
  "image": "/photo/headphones.jpg",
  "onOffer": false
}
```

**After AI Enhancement**:
```json
{
  "id": "prd1",
  "name": "Wireless Bluetooth Headphones",
  "description": "Experience premium sound quality with these wireless Bluetooth headphones featuring active noise cancellation and 30-hour battery life. Perfect for commuters and music enthusiasts seeking comfort and crystal-clear audio.",
  "price": 79.99,
  "category": "Electronics",
  "image": "/photo/headphones.jpg",
  "onOffer": false
}
```

---

### AI Description Cache (New)

**Purpose**: Caches AI-generated product descriptions to minimize Azure OpenAI API calls and costs.

**Storage**: Dapr state store (Redis)

**Key Pattern**: `ai-description:{product_id}`

**Value Structure**:
```json
{
  "product_id": "prd1",
  "description": "Experience premium sound quality...",
  "generated_at": "2025-11-16T11:44:00Z",
  "model": "gpt-4",
  "tokens_used": 45
}
```

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| product_id | string | Required, matches Product.id | Product this description belongs to |
| description | string | Required, max 1000 chars | AI-generated description |
| generated_at | timestamp | Required, ISO 8601 | When description was generated |
| model | string | Required | Azure OpenAI model used (e.g., "gpt-4") |
| tokens_used | int | Optional, > 0 | Tokens consumed for generation |

**TTL**: 24 hours (86400 seconds)

**Validation Rules**:
- `product_id` must exist in products database
- `description` must not be empty
- `generated_at` must be valid ISO 8601 timestamp

**Cache Invalidation**:
- Automatic: TTL expires after 24 hours
- Manual: Clear cache via Dapr state API if product updated
- On error: Cache entry not created (fallback to original description)

**Dapr State Store Configuration**:
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: password
  - name: actorStateStore
    value: "true"
```

---

## Data Flow

### AI Description Generation Flow

```
1. User requests product detail page
   ↓
2. Products service fetches product from SQLite
   ↓
3. Check if description is placeholder
   ↓ (YES)
4. Check Dapr state store for cached description
   ↓ (MISS)
5. Call Azure OpenAI API with Managed Identity
   ↓
6. Receive AI-generated description
   ↓
7. Store in Dapr state store (24h TTL)
   ↓
8. Return enhanced product to frontend
   ↓
9. User sees AI-generated description
```

### Cache Hit Flow

```
1. User requests product detail page
   ↓
2. Products service fetches product from SQLite
   ↓
3. Check if description is placeholder
   ↓ (YES)
4. Check Dapr state store for cached description
   ↓ (HIT)
5. Return cached description (skip Azure OpenAI call)
   ↓
6. User sees AI-generated description
```

### Error/Fallback Flow

```
1. User requests product detail page
   ↓
2. Products service fetches product from SQLite
   ↓
3. Check if description is placeholder
   ↓ (YES)
4. Check Dapr state store for cached description
   ↓ (MISS)
5. Call Azure OpenAI API with Managed Identity
   ↓ (ERROR/TIMEOUT)
6. Log error, increment error metric
   ↓
7. Return original placeholder description
   ↓
8. User sees original description (graceful degradation)
```

---

## Database Schema Changes

**None required** - This feature is read-only and does not modify the products database. AI-generated descriptions are served dynamically and cached in Redis, not persisted to SQLite/PostgreSQL.

**Future Consideration**: If descriptions should be persisted, add:
- `description_source` field (enum: "manual", "ai_generated")
- `description_generated_at` timestamp
- Migration script to backfill existing products

---

## Cache Metrics

**Target Metrics**:
- Cache hit rate: >80% after initial generation
- Cache size: ~50-100 entries (one per product)
- Memory usage: ~50KB per entry = ~5MB total
- TTL: 24 hours

**Monitoring**:
- Prometheus metrics: `ai_description_cache_hits_total`, `ai_description_cache_misses_total`
- Grafana dashboard: Cache hit rate percentage, cache size over time
