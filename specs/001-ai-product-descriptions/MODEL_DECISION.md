# Model Selection: GPT-4o-mini

**Date**: 2025-11-24  
**Decision**: Use GPT-4o-mini for AI-generated product descriptions

## Rationale

### Cost-Effectiveness
- **GPT-4o-mini**: ~$0.15/1M input tokens, ~$0.60/1M output tokens
- **GPT-4o**: ~$2.50-5/1M input tokens (10x more expensive)
- **Estimated cost for 100 products**: ~$0.02 with GPT-4o-mini

### Performance
- Fast response times (<2 seconds)
- Sufficient quality for creative product descriptions
- Supports prompt caching for additional cost savings

### Availability
- Widely available across Azure regions
- Stable and production-ready
- Good rate limits for standard tier

## Use Case Fit

Product descriptions are:
- Short (2-3 sentences, ~200 tokens)
- Creative but straightforward
- Don't require advanced reasoning
- Generated once and cached

GPT-4o-mini is perfect for this use case - no need for premium models.

## Deployment Configuration

```bash
MODEL_NAME="gpt-4o-mini"
MODEL_VERSION="2024-07-18"
DEPLOYMENT_NAME="gpt-4o-mini"
```

## Alternative Considered

- **GPT-4o**: Rejected due to 10x higher cost with minimal quality improvement for this use case
- **GPT-3.5-turbo**: Older model, GPT-4o-mini offers better quality at similar price
