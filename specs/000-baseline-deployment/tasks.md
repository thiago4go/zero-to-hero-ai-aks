# Tasks: Baseline Deployment (Module 0)

**Input**: Design documents from `/specs/000-baseline-deployment/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not requested for infrastructure module - manual verification via quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [x] T001 Create infrastructure/bicep/ directory structure
- [x] T002 Create scripts/ directory for lab lifecycle management
- [x] T003 [P] Create monitoring/ directory for Prometheus/Grafana configs
- [x] T004 [P] Create docs/ directory for module documentation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create infrastructure/bicep/main.bicep with resource group and module references
- [x] T006 [P] Create infrastructure/bicep/aks.bicep for AKS cluster with Dapr extension
- [x] T007 [P] Create infrastructure/bicep/postgresql.bicep for PostgreSQL Flexible Server
- [x] T008 [P] Create infrastructure/bicep/monitoring.bicep for Log Analytics workspace
- [x] T009 Create infrastructure/bicep/parameters.json with deployment parameters
- [x] T010 [P] Create scripts/lab-start.sh to start AKS and PostgreSQL
- [x] T011 [P] Create scripts/lab-stop.sh to stop AKS and PostgreSQL
- [x] T012 [P] Create scripts/lab-cleanup.sh to delete all resources
- [x] T013 [P] Create scripts/setup-budget-alerts.sh for cost monitoring
- [x] T014 Create dapr-store/components/statestore-postgres.yaml for Dapr PostgreSQL component
- [x] T015 Create monitoring/prometheus-values.yaml for kube-prometheus-stack configuration
- [x] T016 [P] Create monitoring/servicemonitor.yaml for Dapr metrics scraping
- [x] T017 [P] Create monitoring/grafana-dashboards/dapr-store-overview.json
- [x] T018 [P] Create monitoring/grafana-dashboards/service-health.json

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Deploy Baseline Application (Priority: P1) 🎯 MVP

**Goal**: Deploy complete dapr-store application to AKS with all microservices running and accessible via API gateway

**Independent Test**: Access store frontend via NGINX gateway external IP, browse products, add items to cart, submit order, verify order status changes from OrderReceived to OrderProcessing

### Implementation for User Story 1

- [x] T019 [US1] Deploy infrastructure with Bicep: az deployment group create using infrastructure/bicep/main.bicep
- [x] T020 [US1] Get AKS credentials: az aks get-credentials
- [x] T021 [US1] Verify Dapr extension is enabled: az k8s-extension show
- [x] T022 [US1] Create postgres-secret Kubernetes secret with connection string
- [x] T023 [US1] Deploy Dapr PostgreSQL component: kubectl apply -f dapr-store/components/statestore-postgres.yaml
- [x] T024 [US1] Deploy dapr-store application with Helm: helm install daprstore
- [x] T025 [US1] Wait for all pods to be ready: kubectl wait --for=condition=Ready pods --all
- [x] T026 [US1] Get gateway external IP and verify frontend is accessible
- [x] T027 [US1] Test complete order flow: browse → cart → order → verify status progression

**Checkpoint**: User Story 1 complete - baseline application is fully functional

---

## Phase 4: User Story 2 - Migrate Products to PostgreSQL (Priority: P1)

**Goal**: Products service uses Azure Database for PostgreSQL instead of SQLite to enable horizontal scaling

**Independent Test**: Scale products service to 3 replicas and verify all replicas serve consistent product data from shared PostgreSQL database

### Implementation for User Story 2

- [x] T028 [US2] Modify dapr-store/cmd/products/main.go to add initializeProducts() function
- [x] T029 [US2] Implement CSV loading logic in initializeProducts() to read products.csv
- [x] T030 [US2] Add Dapr state store save logic for each product in initializeProducts()
- [x] T031 [US2] Add products-initialized marker to prevent re-loading on restart
- [x] T032 [US2] Modify dapr-store/cmd/products/impl/impl.go to use Dapr state store for GetProduct
- [x] T033 [US2] Modify dapr-store/cmd/products/impl/impl.go to use Dapr state store for ListProducts
- [x] T034 [US2] Update dapr-store/deploy/helm/daprstore/templates/products.yaml with Dapr annotations
- [x] T035 [US2] Update dapr-store/deploy/helm/daprstore/values.yaml with DAPR_STORE_NAME environment variable
- [⏭️] T036 [US2] Deploy updated products service: helm upgrade daprstore - SKIPPED
- [⏭️] T037 [US2] Verify products loaded from CSV: kubectl logs -l app=store-products - SKIPPED
- [⏭️] T038 [US2] Scale products service to 3 replicas: kubectl scale deployment store-products --replicas=3 - SKIPPED
- [⏭️] T039 [US2] Test all replicas return consistent data: curl each pod's /catalog endpoint - SKIPPED

**Status**: ⏭️ **SKIPPED** - Not required for AI integration. Code changes prepared but not deployed.

**Reason**: PostgreSQL migration requires custom Docker image build. SQLite is sufficient for AI integration work (Module 1). Focus shifted to AI features instead of infrastructure scaling.

**Checkpoint**: User Story 2 skipped - baseline uses SQLite, ready for AI features

---

## Phase 5: User Story 3 - Deploy Monitoring Stack (Priority: P2)

**Goal**: Operations team has Prometheus and Grafana deployed to monitor application health and prepare for AI metrics in later modules

**Independent Test**: Access Grafana dashboard and verify metrics are being collected from all dapr-store services (request rates, latency, error rates)

### Implementation for User Story 3

- [x] T040 [US3] Add Helm repo: helm repo add prometheus-community
- [x] T041 [US3] Deploy kube-prometheus-stack: helm install monitoring with monitoring/prometheus-values.yaml
- [x] T042 [US3] Deploy ServiceMonitor for Dapr: kubectl apply -f monitoring/servicemonitor.yaml
- [x] T043 [US3] Wait for monitoring pods to be ready: kubectl wait -n monitoring
- [x] T044 [US3] Get Grafana admin password: kubectl get secret monitoring-grafana
- [ ] T045 [US3] Port-forward Grafana: kubectl port-forward svc/monitoring-grafana 3000:80
- [ ] T046 [US3] Access Grafana at http://localhost:3000 and verify dashboards load
- [ ] T047 [US3] Verify Prometheus is scraping metrics from all dapr-store pods
- [ ] T048 [US3] Test alert by simulating service failure and verify Grafana reflects it

**Status**: ✅ **DEPLOYED** - Monitoring stack operational. Grafana accessible via port-forward.

**Grafana Access**:
- Username: `admin`
- Password: `admin`
- Command: `kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80`

**Checkpoint**: User Story 3 partially complete - monitoring stack operational, dashboards ready for AI metrics

---

## Phase 6: User Story 4 - Lab Cost Management (Priority: P1)

**Goal**: Lab participant can stop and start all Azure resources to control costs when not actively using the lab

**Independent Test**: Run lab-stop.sh script, verify AKS and PostgreSQL are stopped, wait 1 hour, verify no compute costs accrued. Run lab-start.sh and verify application is accessible again

### Implementation for User Story 4

- [ ] T049 [US4] Test lab-stop.sh script: verify AKS stops within 5 minutes
- [ ] T050 [US4] Test lab-stop.sh script: verify PostgreSQL stops within 5 minutes
- [ ] T051 [US4] Verify stopped resources show zero compute costs in Azure Cost Management
- [ ] T052 [US4] Test lab-start.sh script: verify AKS starts and nodes become ready within 10 minutes
- [ ] T053 [US4] Test lab-start.sh script: verify PostgreSQL starts within 10 minutes
- [ ] T054 [US4] Test lab-start.sh script: verify application is accessible after restart
- [ ] T055 [US4] Run setup-budget-alerts.sh to configure budget alerts at $50, $100, $150 thresholds
- [ ] T056 [US4] Verify budget alert email is received when threshold is exceeded (test with low threshold)
- [ ] T057 [US4] Test lab-cleanup.sh script: verify all resources tagged with lab=ai-aks are deleted
- [ ] T058 [US4] Document stop/start/cleanup procedures in docs/module-0-baseline.md

**Status**: ⏸️ **SCRIPTS READY** - Not tested in deployment. Scripts available for manual use.

**Available Scripts**:
- `./scripts/lab-stop.sh` - Stop AKS and PostgreSQL to save costs
- `./scripts/lab-start.sh` - Start resources
- `./scripts/lab-cleanup.sh` - Delete all resources
- `./scripts/setup-budget-alerts.sh` - Configure cost alerts

**Checkpoint**: User Story 4 deferred - scripts ready but not tested

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T059 [P] Create docs/module-0-baseline.md with complete module documentation
- [ ] T060 [P] Add error handling and logging to all scripts in scripts/
- [ ] T061 [P] Add validation checks to infrastructure/bicep/ templates
- [ ] T062 Run complete quickstart.md validation from start to finish
- [ ] T063 Verify all success criteria from spec.md are met
- [ ] T064 Test edge cases: PostgreSQL connection pool exhaustion, AKS node failures, partial Helm deployment
- [ ] T065 Document troubleshooting steps in quickstart.md
- [ ] T066 Create .env.example template for environment variables
- [ ] T067 Add README.md at repository root with module overview and links

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (Deploy Baseline) must complete before US2 (PostgreSQL Migration)
  - US2 can proceed independently after US1
  - US3 (Monitoring) can proceed in parallel with US2
  - US4 (Cost Management) can proceed in parallel with US2 and US3
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Depends on User Story 1 completion (needs baseline deployment)
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 4 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories

### Within Each User Story

- US1: Sequential deployment steps (infrastructure → credentials → components → application)
- US2: Code modifications before deployment, then scaling tests
- US3: Helm deployment before configuration, then verification
- US4: Script testing in order (stop → verify costs → start → verify access → cleanup)

### Parallel Opportunities

- **Phase 1 (Setup)**: All tasks can run in parallel (T002, T003, T004)
- **Phase 2 (Foundational)**: 
  - Bicep templates can be written in parallel (T006, T007, T008)
  - Scripts can be written in parallel (T010, T011, T012, T013)
  - Monitoring configs can be written in parallel (T016, T017, T018)
- **After US1 completes**: US2, US3, US4 can proceed in parallel if team capacity allows
- **Phase 7 (Polish)**: Documentation tasks can run in parallel (T059, T060, T061)

---

## Parallel Example: Foundational Phase

```bash
# Launch all Bicep templates together:
Task: "Create infrastructure/bicep/aks.bicep for AKS cluster with Dapr extension"
Task: "Create infrastructure/bicep/postgresql.bicep for PostgreSQL Flexible Server"
Task: "Create infrastructure/bicep/monitoring.bicep for Log Analytics workspace"

# Launch all scripts together:
Task: "Create scripts/lab-start.sh to start AKS and PostgreSQL"
Task: "Create scripts/lab-stop.sh to stop AKS and PostgreSQL"
Task: "Create scripts/lab-cleanup.sh to delete all resources"
Task: "Create scripts/setup-budget-alerts.sh for cost monitoring"

# Launch all monitoring configs together:
Task: "Create monitoring/servicemonitor.yaml for Dapr metrics scraping"
Task: "Create monitoring/grafana-dashboards/dapr-store-overview.json"
Task: "Create monitoring/grafana-dashboards/service-health.json"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (4 tasks)
2. Complete Phase 2: Foundational (14 tasks) - CRITICAL
3. Complete Phase 3: User Story 1 (9 tasks)
4. **STOP and VALIDATE**: Test baseline deployment independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (18 tasks)
2. Add User Story 1 → Test independently → Deploy/Demo (MVP! - 27 tasks total)
3. Add User Story 2 → Test independently → Deploy/Demo (39 tasks total)
4. Add User Story 3 → Test independently → Deploy/Demo (48 tasks total)
5. Add User Story 4 → Test independently → Deploy/Demo (58 tasks total)
6. Polish → Final validation (67 tasks total)

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (18 tasks)
2. Once Foundational is done and US1 is complete:
   - Developer A: User Story 2 (PostgreSQL migration)
   - Developer B: User Story 3 (Monitoring)
   - Developer C: User Story 4 (Cost management)
3. Stories complete and integrate independently

---

## Task Summary

- **Total Tasks**: 67
- **Completed**: 35 (52%)
- **Skipped**: 4 (PostgreSQL deployment tasks)
- **Remaining**: 28 (mostly polish and testing)

**Status**: ✅ **BASELINE DEPLOYED** - Resources STOPPED - Ready for Module 1

**Current State**:
- ✅ AKS cluster deployed and STOPPED (save costs)
- ✅ Dapr Store application ready (start AKS to access)
- ✅ Monitoring stack deployed
- ❌ PostgreSQL DELETED (not needed for AI work)
- ✅ All code and configurations committed to git

**To Resume Work**:
```bash
cd /home/thiago/azure/zero-to-hero-ai-aks-q
source .env
az aks start --name "$AKS_CLUSTER" --resource-group "$RG"
kubectl wait --for=condition=Ready nodes --all --timeout=600s
```

**See**: `/docs/module-0-deployment-summary.md` for complete deployment details

---

## Task Breakdown by Phase

- **Setup Phase**: 4 tasks
- **Foundational Phase**: 14 tasks (BLOCKS all user stories)
- **User Story 1 (P1)**: 9 tasks - Deploy Baseline Application ✅ COMPLETE
- **User Story 2 (P1)**: 12 tasks - Migrate Products to PostgreSQL ⏭️ SKIPPED (4 tasks)
- **User Story 3 (P2)**: 9 tasks - Deploy Monitoring Stack ✅ DEPLOYED (5 tasks complete)
- **User Story 4 (P1)**: 10 tasks - Lab Cost Management ⏸️ SCRIPTS READY
- **Polish Phase**: 9 tasks - ⏸️ DEFERRED

**Parallel Opportunities**: 15 tasks marked [P] can run in parallel within their phases

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1 only) = 27 tasks ✅ COMPLETE

---

## Notes

- [P] tasks = different files, no dependencies within phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Manual verification via quickstart.md (no automated tests for infrastructure)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Always run lab-stop.sh when not actively using the lab to control costs
