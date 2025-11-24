# Session Script: Building Intelligent Apps on AKS - From API to Agents

**Title:** Building Intelligent Applications: Quick Guide to AI on AKS
**Duration:** 45 Minutes
**Speaker:** [Your Name]

---

## 1. Introduction & The "Shift" (0:00 - 0:05)

**Speaker Notes:**
*   Welcome everyone. Today is about bridging the gap between "I have a Kubernetes cluster" and "I have an Intelligent App."
*   We are witnessing a shift:
    *   **Yesterday:** Apps were static. You clicked a button, it saved a record.
    *   **Today:** Apps are intelligent. They generate content, predict user needs, and understand natural language.
*   But how do you build this? You don't just "sprinkle AI" on top. You need an architecture.

### 📰 What's New in AKS & AI (The News)
*Before we dive into the code, let's look at the toolbox we have in late 2025:*
1.  **KAITO (Kubernetes AI Toolchain Operator):** The game changer for open-source models. No more wrestling with Python dependencies and GPU drivers manually. You define a CRD, and AKS provisions the GPU node and serves the model.
2.  **WASM (WebAssembly) on AKS:** For ultra-lightweight AI inference tasks that don't need a full container.
3.  **Semantic Kernel & AutoGen:** The SDKs that are making "Agents" a reality, allowing LLMs to call *your* code.
4.  **Azure OpenAI "On Your Data":** RAG (Retrieval Augmented Generation) is now a standard pattern, not a hack.

---

## 2. The Demo: "Dapr Store" (0:05 - 0:10)

**Speaker Notes:**
*   We aren't starting from scratch. We are using the **Dapr Store**.
*   **Review of the App:**
    *   It's a standard e-commerce microservices app.
    *   **Tech Stack:** Go (Backend), Vue.js (Frontend), Redis (State/PubSub), PostgreSQL (Products).
    *   **Architecture:** It uses **Dapr** (Distributed Application Runtime).
*   **Why Dapr?**
    *   It abstracts the "plumbing."
    *   Service-to-service invocation (Frontend -> Backend).
    *   Pub/Sub (Cart -> Orders).
    *   This is crucial for AI because it lets us plug in "AI Services" just like any other microservice.

---

## 3. The Journey: Levels 1 to 5 (0:10 - 0:40)

*We will walk through 5 levels of AI maturity.*

### Level 1: GenAI via API (The "Easy Button")
*   **Concept:** Use a powerful, hosted model (GPT-4) for creative tasks.
*   **Scenario:** The "Product Description" field is empty.
*   **Implementation:**
    *   The `Products Service` detects missing text.
    *   It calls **Azure OpenAI Service** API.
    *   *Prompt:* "Write a catchy description for a [Product Name]."
*   **Key Tech:** Azure OpenAI, Kubernetes Secrets (for API keys).

### Level 2: Bring Your Own (Open) Model
*   **Concept:** Cost control and data privacy. We don't need GPT-4 to calculate vector similarity.
*   **Scenario:** "Similar Products" recommendation.
*   **Implementation:**
    *   We use **KAITO** to deploy `all-MiniLM-L6-v2` (a small embedding model) on an AKS node.
    *   The `Recommendation Service` sends product names to this local model to get vectors.
    *   It calculates cosine similarity locally.
*   **Key Tech:** KAITO, Hugging Face, Local Inference.

### Level 3: Custom Training (Your Data)
*   **Concept:** Generic models don't know *your* business patterns.
*   **Scenario:** Fraud Detection.
*   **Implementation:**
    *   We extract order history from the Dapr State Store (Redis/Postgres).
    *   We use **Azure Machine Learning (AML)** to train a `Scikit-Learn` classification model.
    *   The model learns that "High value order + New IP address = High Risk."
*   **Key Tech:** Azure ML, Python, Scikit-Learn.

### Level 4: MLOps & Event-Driven AI
*   **Concept:** AI isn't just a chatbot; it's part of the transaction flow.
*   **Scenario:** Real-time Fraud Scoring.
*   **Implementation:**
    *   User clicks "Buy".
    *   `Cart Service` publishes `OrderCreated` event.
    *   `Order Service` subscribes. **BEFORE** processing, it calls the Level 3 Fraud Model (now containerized on AKS).
    *   If `Score > 0.8`, the order is flagged `ReviewNeeded`.
*   **Key Tech:** Dapr Pub/Sub, GitHub Actions (for CI/CD of the model).

### 🚀 Level 5: Agents (The New Frontier)
*   **Concept:** Moving from "Passive AI" (answering questions) to "Active AI" (performing tasks).
*   **Scenario:** The **"Smart Inventory Agent"**.
*   **The Problem:** Usually, a human looks at a dashboard and reorders stock.
*   **The Agent Solution:**
    *   We build a background service using **Semantic Kernel**.
    *   We give the Agent "Tools" (Plugins):
        1.  `check_inventory()` (Dapr call to Products Service).
        2.  `predict_demand()` (Call to our Level 3 ML model).
        3.  `send_email()` (Dapr Output Binding to SendGrid).
    *   **The Loop:**
        *   The Agent runs every hour.
        *   *Thought:* "I see 'Classic T-Shirt' is low (5 items)."
        *   *Thought:* "Demand prediction says we will sell 20 this week."
        *   *Action:* "I will draft a reorder email to the supplier."
*   **Key Tech:** Semantic Kernel / AutoGen, Dapr Bindings.

---

## 4. Conclusion (0:40 - 0:45)

*   **Recap:**
    *   We started with a simple API call (L1).
    *   We optimized costs with open models (L2).
    *   We solved specific business problems with custom training (L3).
    *   We automated it with MLOps (L4).
    *   We gave it autonomy with Agents (L5).
*   **Call to Action:**
    *   Don't try to jump to Level 5 immediately.
    *   Start with Level 1: Add a description generator.
    *   Clone the repo: `github.com/Azure-Samples/dapr-store`.
    *   Deploy to AKS and start building!

---
