# NoShowGuard: Outpatient Clinic No-Show Risk Prediction & Qualitative Root-Cause Analysis

**Repository Link:** `https://github.com/mohan/noshowguard` *(Replace with your public repository URL upon upload)*

---

## 1. Project Summary (Parts 1–4)

* **Part 1 (Data Engineering & Pipeline):** Parsed and type-validated 1,020 raw appointment bookings, rejecting 32 invalid records (12 blank age, 20 blank distance), and cleaned 990 unique appointments to establish a baseline no-show rate of 22.0% (218 no-shows) with an average booking lead time of 11.8 days (29.9% exceeding 14 days).
* **Part 2 (Relational Database & SQL Analytics):** Modeled and loaded the normalized database schema (`clinics` and `appointments`) with 998 SQL INSERT statements, identifying significant cross-clinic variance where specific metro and tier-2 clinics experienced no-show rates above 25%.
* **Part 3 (Machine Learning & Operational Risk Scoring):** Evaluated predictive models strictly on training cross-validation; a regularized Logistic Regression pipeline won with a 5-fold CV ROC-AUC of 0.774 and achieved a test ROC-AUC of 0.789, proving that lowering the decision threshold to 0.35 flagged 49 patients while doubling test recall to 57.1% and revealing that receiving an appointment reminder is associated with 69% lower odds of a no-show ($OR \approx 0.31$, $\beta = -0.58$).
* **Part 4 (GenAI LLM Call-Center Root-Cause Extraction):** Deployed Gemini Flash with CRAFT prompt engineering and Pydantic validation on patient follow-up notes, revealing that 100% (2 of 2) of patient-reported forgetfulness/missed reminders occurred on appointments where no reminder was sent, while transit barriers (20%) and work conflicts (20%) drove remaining preventable absences.

---

## 2. Business Recommendation

To significantly reduce outpatient clinic no-shows from the current baseline of **22.0% (218 of 990 bookings)**, clinic operations should immediately deploy the calibrated Logistic Regression model at decision threshold **0.35** to screen the appointment schedule each evening. The front desk can realistically contact the **49 high-risk patients (24.7% of the schedule)** flagged by the model on held-out test data, successfully capturing **57.1% of all impending no-shows** with **57.1% precision** and an **ROC-AUC of 0.789**. Because sending an appointment reminder is associated with a **69% reduction in the odds of a no-show ($OR \approx 0.31$)**, and qualitative LLM analysis confirmed that **100% (2 of 2)** of patients citing forgetfulness had received no reminder, the primary operational intervention must be automated multi-channel SMS/WhatsApp confirmations for all bookings, supplemented by prioritized manual phone calls for the 49 flagged high-risk individuals. Furthermore, for patients with lead times exceeding **14 days (29.9% of bookings)** or facing transit barriers (accounting for **20%** of note root causes), clinics should offer flexible rebooking windows and telemedicine options.

---

## 3. Model Selection & Threshold Justification

* **Chosen Model:** Logistic Regression with `StandardScaler` embedded inside a leak-free scikit-learn `Pipeline`.
* **Selection Metric (Training Only):** During 5-fold cross-validation on the training set ($n=792$), Logistic Regression attained the highest out-of-sample discrimination (**CV ROC-AUC = 0.7737**), outperforming the constrained Decision Tree (0.6784), default Random Forest (0.7466), and hyperparameter-tuned Random Forest (0.7673).
* **Test Discrimination:** On the held-out test partition ($n=198$), Logistic Regression maintained superior discrimination (**ROC-AUC = 0.7889**).
* **Operational Threshold (0.35 vs 0.50):** Threshold **0.35** was selected via out-of-fold training probability optimization because it achieved a higher F1-score (**0.4892 vs 0.3471**) and nearly doubled recall (**0.4675 vs 0.2485**). In healthcare operations, recall is prioritized over precision because a missed no-show wastes an expensive doctor consultation slot, whereas contacting a compliant patient costs only one minute of front-desk calling time.

---

## 4. Methodological & Operational Limitations

1. **Observational Data vs. Causal Inference:** The data are strictly observational. While reminders are associated with 69% lower odds of non-attendance, this does not prove causality (e.g., more conscientious patients may provide accurate contact numbers and independently possess higher attendance propensity).
2. **Small Qualitative Sample Size:** The 10 call-center follow-up notes analyzed via GenAI serve as an illustrative proof-of-concept and cannot statistically represent the comprehensive root-cause distribution across all 990 patients or diverse clinic geographies.
3. **Cross-Sectional Random Partitioning vs. Temporal Backtesting:** The train/test split was performed randomly across records rather than temporally (training on historical dates and predicting future dates). Additionally, multi-booking patients were not grouped by `patient_id`, allowing records from the same individual to span both splits, and Task 1.3 cleaning statistics (medians, IQR fences) were computed over all 990 records before splitting, introducing mild data leakage.

---

## 5. Submission Manifest

- `PART-1.ipynb`: Data ingestion, cleaning pass 1 & 2, feature engineering, Open-Meteo API enrichment.
- `PART-2.sql`: DDL schema definitions, database queries, and clinic performance analytics.
- `PART-3.ipynb`: Machine learning modeling, decision tree overfitting analysis, model selection, threshold tuning.
- `PART-4.ipynb`: GenAI LLM note classification, Pydantic validation, edge-case testing, and merged synthesis.
- `appointments_clean.csv`: 990 cleaned, validated appointment records.
- `clinics_enriched.csv`: 8 clinic records enriched with weather data.
- `load_data.sql`: 998 INSERT statements for relational loading.
- `rejected_rows.json`: 32 rejected raw records from Task 1.1.
- `test_risk_scores.csv`: 198 test-set predictions with risk probabilities and decision flags.
- `notes_analysed.csv`: 10 structured, validated call-center follow-up note classifications.
- `README.md`: Executive summary, business recommendations, model rationale, and limitations.
