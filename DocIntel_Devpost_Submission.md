# DocIntel Agent — Devpost Submission
## Google Cloud Rapid Agent Hackathon

---

## FIELD: Project Name (max 60 chars)
```
DocIntel Agent
```

---

## FIELD: Elevator Pitch (max 200 chars)
```
Multi-agent AI that audits government social programs in real time — offline OCR on handwritten records, fraud detection, and guaranteeing $10B+ in public funds reach the people who need them most.
```
Character count: 197 ✓

---

## FIELD: About the Project (Markdown)

```markdown
## Inspiration

In Colombia — and across Latin America — 162 million people live in poverty. Governments invest billions every year in social programs: food markets, youth employment, rural women's funds. But the only proof that resources actually reached a beneficiary is a **handwritten paper record** signed in a remote village with no internet.

Auditing those records is humanly impossible at scale. That gap is where corruption thrives.

We're LIFE·IN·CO, a technology company from Colombia. We asked ourselves: *what if AI could be physically present at every single delivery, in real time, even where there is no connectivity?* That question became **DocIntel Agent**.

---

## What It Does

DocIntel Agent is a **multi-agent AI platform** that operates at two levels:

### 1. Field App (Flutter + ML Kit — works fully offline)
A mobile application used by field operators in remote areas:
- **Module 1 — Identity Auth**: Biometric validation of the field operator before they can record anything. Only authorized personnel can submit.
- **Module 2 — OCR Capture**: Operator photographs the handwritten record. Google ML Kit runs on-device OCR — no internet required. Works in the Amazon, Chocó, and Cauca regions where connectivity is zero.
- **Module 3 — Beneficiary Registration**: Logs beneficiary data + geolocation. Stores locally when offline, syncs to AlloyDB when connectivity is available.

### 2. Multi-Agent Audit Platform (Vertex AI / Gemini + AlloyDB)
When records sync to Google Cloud, three specialized agents evaluate every record simultaneously:

| Agent | Function |
|---|---|
| **Compliance Agent** | Validates record integrity: all fields complete, signature present, fingerprint captured |
| **Impact Agent** | Verifies correct quantities delivered (e.g., food programs: 500g promised vs. 250g delivered) |
| **Anti-Fraud Agent** | Cross-validates operator and beneficiary identity; flags subsidies reaching ineligible recipients |

The platform triggers **geolocated real-time alerts** to regulators: *"Anomaly detected in resource allocation — Municipality X, Program Y."*

---

## How We Built It

**Full Google-native stack:**

- **Flutter** — cross-platform mobile app (Android + iOS), runs on a $200 smartphone
- **ML Kit (Firebase)** — on-device OCR, zero connectivity required
- **Gemini 2.5 Flash** — high-volume OCR extraction and calligraphic profiling
- **Gemini 2.5 Pro** — high-risk field validation and critical document analysis
- **AlloyDB (Google Cloud)** — structured storage of all records with full auditability
- **Google Drive API** — document ingestion pipeline
- **Google Sheets API** — audited output with full traceability
- **Vertex AI** — multi-agent orchestration layer
- **Python + FastAPI** — backend pipeline and agent coordination

The pipeline processes a document in under **2.3 seconds** end-to-end:  
Ingestion (240ms) → OCR (820ms) → High-risk validation (640ms) → QA drill-down (380ms) → Audited output (150ms)

---

## Challenges We Ran Into

**Connectivity is a design constraint, not a bug.** In Colombia's Caribbean, Amazonian, and Pacific regions, internet infrastructure was never built — or was corrupted away. Designing an AI system that works *first* offline and syncs *later* required a complete rethinking of the pipeline architecture.

**Handwriting variability is extreme.** Each field operator fills records according to their own interpretation. No two documents look the same. We built a 3-layer OCR cascade (path-only → Gemini Flash → Gemini Pro) that handles everything from clean printed text to difficult cursive handwriting in low-light conditions.

**Scale demands affordability.** A system auditing 500,000+ records at $391/document wouldn't work. We reduced the cost to under $1/document through intelligent cascade routing.

---

## Accomplishments We're Proud Of

- **15,548 records processed in production** for the JEP (Colombia's Special Jurisdiction for Peace) program
- **870 records processed in a single day** for the FINDETER Rueda de Negocios program at ~$1 total cost
- **2 of Colombia's largest auditing firms** as active clients
- Direct impact on government programs with over **8 billion COP (~$2M USD)** under management
- **Offline-first** AI that runs on the Android phone already in the field operator's pocket
- Validated pipeline operating in the **Amazon, Chocó, Cauca** regions — the most disconnected territories in Colombia

---

## What We Learned

The greatest technical challenge in AI for social impact is not the model — it's the **last mile**. Getting intelligence to work reliably where infrastructure doesn't exist requires building for constraints first and for performance second.

We also learned that **document inconsistency is a human variable**, not a technical one. The solution isn't perfect OCR; it's a smart cascade that knows when to escalate.

---

## What's Next

- **Scale to 500,000 records** by end of 2026, with a 10x growth path to 5M+
- **LATAM expansion**: Mexico (Bienestar, 30M beneficiaries), Brazil (Bolsa Familia, 21M families), Peru, Bolivia
- **Africa and Asia**: The same infrastructure gap exists across sub-Saharan Africa and South Asia — 400M+ people in social programs audited by paper records
- **Real-time government dashboard**: Live anomaly map for regulators and anti-corruption agencies
- **SDG alignment**: Direct impact on SDG 1 (No Poverty), SDG 10 (Reduced Inequalities), SDG 16 (Peace, Justice and Strong Institutions), SDG 17 (Partnerships)

> *In Latin America, 4.8% of GDP is lost to public spending inefficiency — $18 billion COP per year in transfer leakage alone (BID). DocIntel Agent is the infrastructure that closes that gap.*
```

---

## FIELD: Built With
```
Flutter, ML Kit, Firebase, Gemini 2.5 Flash, Gemini 2.5 Pro, Vertex AI, AlloyDB, Google Drive API, Google Sheets API, Google Cloud Run, Python, FastAPI
```

---

## FIELD: Additional Info — Answers

| Field | Answer |
|---|---|
| Submitter Type | Company / Startup |
| Organization Name | LIFE·IN·CO |
| Government Employee | No |
| Country of Residence | Colombia |
| Province (Canada) | N/A |
| Partner Track | (select track with AlloyDB or Vertex AI focus) |
| New or Existing prior to May 5, 2026 | Existing — new agentic capabilities built for hackathon |
| Open Source Repo URL | https://github.com/lifeinco/docintel-agent (create with MIT license) |
| Hosted Project URL | (landing page URL — build next) |
| Google Cloud Products Used | Vertex AI, Gemini 2.5 Flash, Gemini 2.5 Pro, AlloyDB, Firebase ML Kit, Google Drive API, Google Sheets API, Google Cloud Run |
| Other Tools/Products | Flutter, Python, FastAPI, ML Kit |
| First time using Arize | Yes |
| First time using Elastic | Yes |
| First time using Fivetran | Yes |
| First time using GitLab | Yes |
| First time using MongoDB | Yes |
| First time using Dynatrace | Yes |

---

## NOTES FOR MEDIA SECTION
Upload the following to the Devpost project:
1. Screenshot of the pipeline trace (the "Así procesa DocIntel Agent un documento real" screen)
2. App mockups (3 screens: Auth → OCR capture → Beneficiary data)
3. Architecture diagram (agent flow)
4. Demo video or link to landing page demo

---

*Generated by LIFE·IN·CO for Google Cloud Rapid Agent Hackathon*
*Deadline: 16 hours remaining as of submission*
