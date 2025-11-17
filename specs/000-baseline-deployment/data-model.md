# Data Model: Baseline Deployment (Module 0)

**Feature**: 000-baseline-deployment  
**Date**: 2025-11-17  
**Phase**: 1 - Design & Contracts

## PostgreSQL Schema via Dapr State Store

**Note**: Dapr state store abstracts the database schema. Products are stored as key-value pairs where the key is the product ID and the value is the JSON-serialized Product object.

### Product Entity (Stored in PostgreSQL via Dapr)

**Dapr State Key**: `{product_id}` (e.g., "prd1", "prd2")

**Value Structure**:
```json
{
  "id": "prd1",
  "name": "Wireless Bluetooth Headphones",
  "description": "Premium wireless headphones with noise cancellation",
  "price": 79.99,
  "category": "Electronics",
  "image": "/photo/headphones.jpg",
  "onOffer": false
}
```

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | string | Required, unique, format: "prd{N}" | Product identifier |
| name | string | Required, max 200 chars | Product name |
| description | string | Optional, max 1000 chars | Product description |
| price | float64 | Required, > 0 | Product price in USD |
| category | string | Optional, max 50 chars | Product category |
| image | string | Optional, URL format | Product image path |
| onOffer | boolean | Required, default false | Whether product is on sale |

### Dapr State Store Table Structure

Dapr creates the following PostgreSQL table automatically:

```sql
CREATE TABLE state (
    key TEXT NOT NULL PRIMARY KEY,
    value JSONB NOT NULL,
    isbinary BOOLEAN NOT NULL,
    insertdate TIMESTAMP NOT NULL DEFAULT NOW(),
    updatedate TIMESTAMP
);

CREATE INDEX idx_state_updatedate ON state(updatedate);
```

**Example Rows**:
| key | value | isbinary | insertdate | updatedate |
|-----|-------|----------|------------|------------|
| prd1 | {"id":"prd1","name":"Wireless Bluetooth Headphones",...} | false | 2025-11-17 10:00:00 | 2025-11-17 10:00:00 |
| prd2 | {"id":"prd2","name":"Smart Watch",...} | false | 2025-11-17 10:00:01 | 2025-11-17 10:00:01 |
| products-initialized | "true" | false | 2025-11-17 10:00:02 | 2025-11-17 10:00:02 |

### Initialization Marker

**Key**: `products-initialized`  
**Value**: `"true"`  
**Purpose**: Prevents re-loading products.csv on every startup

### Connection String Format

```
host=<server>.postgres.database.azure.com port=5432 user=daprstore password=<password> dbname=daprstore sslmode=require
```

Stored in Kubernetes Secret:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  connectionString: "host=<server>.postgres.database.azure.com port=5432 user=daprstore password=<password> dbname=daprstore sslmode=require"
```

### Migration from SQLite

**No migration needed** - products.csv is the source of truth. On first startup:
1. Products service checks for `products-initialized` key
2. If not found, reads products.csv
3. Saves each product to Dapr state store
4. Sets `products-initialized` to "true"

### Scaling Behavior

With PostgreSQL:
- ✅ Multiple product service replicas share same data
- ✅ Consistent reads across all replicas
- ✅ No data loss on pod restart

With SQLite (old):
- ❌ Each replica has own database file
- ❌ Inconsistent data across replicas
- ❌ Data lost on pod restart

### Performance Characteristics

| Operation | Latency | Notes |
|-----------|---------|-------|
| Get single product | 5-10ms | Dapr state store lookup |
| List all products | 50-100ms | ~100 products, JSONB deserialization |
| Save product | 10-20ms | Dapr state store write |
| Startup initialization | 2-5s | Load ~100 products from CSV |

### Backup and Recovery

- **Automated Backups**: 7-day retention (PostgreSQL Flexible Server)
- **Point-in-Time Restore**: Available for last 7 days
- **Manual Backup**: Export products via Dapr state API if needed
- **Disaster Recovery**: Re-run initialization from products.csv

### Future Enhancements

For production (beyond lab scope):
- Add `description_source` field (manual vs AI-generated)
- Add `description_generated_at` timestamp
- Add indexes on category, price for faster queries
- Implement connection pooling (PgBouncer)
- Add read replicas for high traffic
