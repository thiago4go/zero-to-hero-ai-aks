# Feature Specification: Baseline Deployment (Module 0)

**Feature Branch**: `000-baseline-deployment`  
**Created**: 2025-11-17  
**Status**: Draft  
**Input**: User description: "Deploy dapr-store baseline to AKS with PostgreSQL migration and monitoring stack"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy Baseline Application (Priority: P1)

A lab participant deploys the complete dapr-store application to AKS with all microservices running and accessible via the API gateway.

**Why this priority**: Foundation for all AI enhancements. Must be working before any AI features can be added.

**Independent Test**: Access the store frontend via the NGINX gateway external IP, browse products, add items to cart, submit an order, and verify order status changes from OrderReceived to OrderProcessing.

**Acceptance Scenarios**:

1. **Given** AKS cluster is provisioned, **When** Helm chart is deployed, **Then** all pods (products, users, cart, orders, frontend, gateway) are running and healthy
2. **Given** application is deployed, **When** user accesses gateway external IP, **Then** store frontend loads and displays product catalog
3. **Given** user is on product page, **When** user adds product to cart and submits order, **Then** order is created and status progresses through OrderReceived → OrderProcessing → OrderComplete

---

### User Story 2 - Migrate Products to PostgreSQL (Priority: P1)

The products service uses Azure Database for PostgreSQL instead of SQLite to enable horizontal scaling.

**Why this priority**: Critical scalability requirement per Constitution Principle VI (NON-NEGOTIABLE). SQLite breaks horizontal scaling.

**Independent Test**: Scale products service to 3 replicas and verify all replicas serve consistent product data from shared PostgreSQL database.

**Acceptance Scenarios**:

1. **Given** PostgreSQL Flexible Server is provisioned, **When** products service starts, **Then** it connects to PostgreSQL using Dapr state store and loads products from products.csv
2. **Given** products are in PostgreSQL, **When** products service is scaled to 3 replicas, **Then** all replicas return identical product data
3. **Given** PostgreSQL connection fails, **When** products service starts, **Then** it logs error and fails health check (no silent failures)

---

### User Story 3 - Deploy Monitoring Stack (Priority: P2)

Operations team has Prometheus and Grafana deployed to monitor application health and prepare for AI metrics in later modules.

**Why this priority**: Required for Module 1+ AI observability. Better to set up baseline monitoring now than retrofit later.

**Independent Test**: Access Grafana dashboard and verify metrics are being collected from all dapr-store services (request rates, latency, error rates).

**Acceptance Scenarios**:

1. **Given** kube-prometheus-stack is deployed, **When** services expose /metrics endpoints, **Then** Prometheus scrapes metrics from all pods
2. **Given** Prometheus is collecting metrics, **When** user accesses Grafana, **Then** pre-configured dashboards show service health (CPU, memory, request rate, latency)
3. **Given** monitoring is running, **When** user simulates service failure, **Then** Grafana alerts fire and metrics reflect the failure

---

### User Story 4 - Lab Cost Management (Priority: P1)

Lab participant can stop and start all Azure resources to control costs when not actively using the lab.

**Why this priority**: Critical for lab environment per Constitution v1.3.0. Prevents unexpected Azure bills.

**Independent Test**: Run lab-stop.sh script, verify AKS and PostgreSQL are stopped, wait 1 hour, verify no compute costs accrued. Run lab-start.sh and verify application is accessible again.

**Acceptance Scenarios**:

1. **Given** lab is running, **When** user runs lab-stop.sh, **Then** AKS cluster and PostgreSQL server are stopped within 5 minutes
2. **Given** resources are stopped, **When** user runs lab-start.sh, **Then** AKS cluster and PostgreSQL server start and application is accessible within 10 minutes
3. **Given** budget alert is configured, **When** costs exceed $50 threshold, **Then** user receives email notification
4. **Given** lab is complete, **When** user runs lab-cleanup.sh, **Then** all resources tagged with lab=ai-aks are deleted

---

### Edge Cases

- What happens when PostgreSQL connection pool is exhausted?
- How does the system handle AKS node failures during deployment?
- What happens if Helm deployment fails mid-way (partial deployment)?
- How does products service behave if products.csv is missing or malformed?
- What happens when Dapr sidecar fails to inject into pods?
- How does monitoring handle pod restarts and metric continuity?

## Requirements *(mandatory)*

### Functional Requirements

**Infrastructure**:
- **FR-001**: System MUST provision AKS cluster with Dapr extension enabled
- **FR-002**: System MUST provision Azure Database for PostgreSQL Flexible Server with encryption enabled
- **FR-003**: System MUST configure Dapr state store component to use PostgreSQL
- **FR-004**: System MUST deploy kube-prometheus-stack via Helm for monitoring
- **FR-005**: System MUST tag all Azure resources with lab=ai-aks for cost tracking

**Application Deployment**:
- **FR-006**: System MUST deploy all dapr-store services (products, users, cart, orders, frontend, gateway) via Helm
- **FR-007**: Products service MUST load product data from products.csv into PostgreSQL on first startup
- **FR-008**: Products service MUST use Dapr PostgreSQL state store (NOT SQLite)
- **FR-009**: All services MUST have Dapr sidecar injected with correct app-id annotations
- **FR-010**: NGINX gateway MUST be exposed via LoadBalancer with external IP

**Monitoring**:
- **FR-011**: All services MUST expose Prometheus /metrics endpoint
- **FR-012**: Prometheus MUST scrape metrics from all dapr-store pods via ServiceMonitor CRDs
- **FR-013**: Grafana MUST have pre-configured dashboards for service health
- **FR-014**: System MUST configure Dapr metrics collection via ServiceMonitor

**Cost Management**:
- **FR-015**: System MUST provide lab-start.sh script to start AKS and PostgreSQL
- **FR-016**: System MUST provide lab-stop.sh script to stop AKS and PostgreSQL
- **FR-017**: System MUST provide lab-cleanup.sh script to delete all lab resources
- **FR-018**: System MUST configure Azure budget alerts at $50, $100, $150 thresholds
- **FR-019**: AKS cluster MUST support stop/start operations (not classic load balancer)

### Assumptions

- Azure subscription with sufficient quota for AKS (4 vCPUs minimum)
- Azure CLI installed and authenticated
- kubectl and Helm installed locally
- Dapr CLI installed for local testing
- User has Owner or Contributor role on subscription
- Region supports Azure Database for PostgreSQL Flexible Server
- Region supports AKS stop/start feature (most regions do)

### Key Entities

- **AKS Cluster**: Kubernetes cluster with Dapr extension, 2-3 worker nodes (Standard_D2s_v3)
- **PostgreSQL Flexible Server**: Burstable B1ms tier, 32GB storage, 7-day backup retention
- **Dapr State Store Component**: PostgreSQL state store configuration for products service
- **Prometheus**: Metrics collection and storage (15-day retention)
- **Grafana**: Visualization and dashboards (admin credentials in Kubernetes secret)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Complete baseline deployment (AKS + PostgreSQL + monitoring) completes in under 30 minutes
- **SC-002**: All dapr-store services reach Running state within 5 minutes of Helm deployment
- **SC-003**: Products service successfully scales to 3 replicas with consistent data across all replicas
- **SC-004**: Store frontend is accessible via external IP and users can complete full order flow (browse → cart → order)
- **SC-005**: Prometheus collects metrics from all services with <1% data loss
- **SC-006**: Grafana dashboards display real-time metrics within 30 seconds of service activity
- **SC-007**: lab-stop.sh stops all resources within 5 minutes
- **SC-008**: lab-start.sh restarts all resources and application is accessible within 10 minutes
- **SC-009**: Stopped resources incur zero compute costs (verified via Azure Cost Management)
- **SC-010**: Module 0 total cost is under $10 for 3-hour lab session with proper stop/start
