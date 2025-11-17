# API Contracts: AI-Generated Product Descriptions

**Feature**: 001-ai-product-descriptions  
**Date**: 2025-11-16  
**Phase**: 1 - Design & Contracts

## Overview

This feature **does not introduce new API endpoints**. It enhances the existing products service API by enriching product descriptions returned from existing endpoints.

## Affected Endpoints

### GET /get/{id}

**Existing Endpoint**: Fetch single product by ID

**Enhancement**: If product has placeholder description, return AI-generated description instead.

**Request**: No changes
```http
GET /get/prd1 HTTP/1.1
Host: products-service:9002
```

**Response**: Enhanced with AI-generated description
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

**Behavior Changes**:
- **Before**: Returns placeholder description ("...")
- **After**: Returns AI-generated description (if placeholder detected)
- **Fallback**: Returns original description on AI service failure
- **Performance**: May add 0-3 seconds latency on cache miss (first request)

---

### GET /catalog

**Existing Endpoint**: Fetch all products

**Enhancement**: Products with placeholder descriptions include AI-generated descriptions.

**Request**: No changes
```http
GET /catalog HTTP/1.1
Host: products-service:9002
```

**Response**: Array of products with enhanced descriptions
```json
[
  {
    "id": "prd1",
    "name": "Wireless Bluetooth Headphones",
    "description": "Experience premium sound quality...",
    "price": 79.99,
    "category": "Electronics",
    "image": "/photo/headphones.jpg",
    "onOffer": false
  },
  {
    "id": "prd2",
    "name": "Smart Watch",
    "description": "Existing detailed description (not AI-generated)",
    "price": 199.99,
    "category": "Electronics",
    "image": "/photo/watch.jpg",
    "onOffer": true
  }
]
```

**Behavior Changes**:
- **Before**: Returns placeholder descriptions for some products
- **After**: Returns AI-generated descriptions for products with placeholders
- **Performance**: May add latency on first load (parallel AI generation for multiple products)

---

### GET /search/{query}

**Existing Endpoint**: Search products by name/description

**Enhancement**: Search results include AI-generated descriptions.

**Request**: No changes
```http
GET /search/headphones HTTP/1.1
Host: products-service:9002
```

**Response**: Search results with enhanced descriptions
```json
[
  {
    "id": "prd1",
    "name": "Wireless Bluetooth Headphones",
    "description": "Experience premium sound quality...",
    "price": 79.99,
    "category": "Electronics",
    "image": "/photo/headphones.jpg",
    "onOffer": false
  }
]
```

**Behavior Changes**:
- **Before**: Search matches on placeholder descriptions
- **After**: Search matches on AI-generated descriptions (richer content)
- **Note**: Search still uses SQLite LIKE query (AI descriptions not indexed)

---

## Internal Interfaces

### Azure OpenAI API

**Endpoint**: `https://{resource-name}.openai.azure.com/openai/deployments/{deployment-name}/chat/completions?api-version=2024-02-01`

**Authentication**: Azure Managed Identity (DefaultAzureCredential)

**Request**:
```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are an e-commerce product description writer. Write compelling, accurate, professional descriptions that highlight key features and benefits. Keep descriptions to 2-3 sentences."
    },
    {
      "role": "user",
      "content": "Write a product description for: Wireless Bluetooth Headphones\nCategory: Electronics\nPrice: $79.99"
    }
  ],
  "max_tokens": 100,
  "temperature": 0.7
}
```

**Response**:
```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1700000000,
  "model": "gpt-4",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Experience premium sound quality with these wireless Bluetooth headphones featuring active noise cancellation and 30-hour battery life. Perfect for commuters and music enthusiasts seeking comfort and crystal-clear audio."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 65,
    "completion_tokens": 45,
    "total_tokens": 110
  }
}
```

**Error Handling**:
- **429 Rate Limit**: Return original description, log error
- **500 Server Error**: Return original description, log error
- **Timeout (>5s)**: Return original description, increment timeout metric

---

### Dapr State Store API

**Component**: `statestore` (Redis)

**Save Cache Entry**:
```http
POST http://localhost:3500/v1.0/state/statestore HTTP/1.1
Content-Type: application/json

[
  {
    "key": "ai-description:prd1",
    "value": {
      "product_id": "prd1",
      "description": "Experience premium sound quality...",
      "generated_at": "2025-11-16T11:44:00Z",
      "model": "gpt-4",
      "tokens_used": 45
    },
    "metadata": {
      "ttlInSeconds": "86400"
    }
  }
]
```

**Get Cache Entry**:
```http
GET http://localhost:3500/v1.0/state/statestore/ai-description:prd1 HTTP/1.1
```

**Response** (cache hit):
```json
{
  "product_id": "prd1",
  "description": "Experience premium sound quality...",
  "generated_at": "2025-11-16T11:44:00Z",
  "model": "gpt-4",
  "tokens_used": 45
}
```

**Response** (cache miss): `204 No Content`

---

## Backward Compatibility

✅ **Fully backward compatible** - No breaking changes to existing API contracts.

**Frontend Impact**:
- No code changes required
- Product descriptions automatically enhanced
- Existing error handling sufficient (graceful degradation)

**Service-to-Service Impact**:
- Cart service calls products service via Dapr service invocation (no changes)
- Frontend calls products service via API gateway (no changes)

---

## Performance Characteristics

| Scenario | Latency | Notes |
|----------|---------|-------|
| Cache hit | +5-10ms | Dapr state store lookup |
| Cache miss (AI generation) | +500-2000ms | Azure OpenAI API call |
| AI service timeout | +5000ms | Timeout threshold, returns original description |
| AI service unavailable | +10-50ms | Fast fail, returns original description |

**Optimization**: 80%+ cache hit rate after initial generation reduces average latency to ~10ms overhead.
