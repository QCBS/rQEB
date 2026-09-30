# RAG-LLM Guide: Reproducing the Study Screening & Extraction Pipeline
### Based on Jaureguiberry et al. (2022), *Sci. Adv.* 8, eabm9982 — "The direct drivers of recent global anthropogenic biodiversity loss"

This guide translates the paper's "Screening of studies extracted from literature and other sources" methodology (plus the adjacent eligibility and extraction steps it depends on) into an operational pipeline a retrieval-augmented LLM can follow when given full-text PDFs/text of candidate papers. Each stage below corresponds to a stage in the original paper and includes: **purpose**, **inputs**, **decision rules**, **fields to extract**, and a **suggested LLM prompt skeleton**.

---

## 0. Prerequisites / Inputs the Pipeline Assumes

Before screening begins, you need:
- A pooled candidate list of studies (from database search + expert/gray-literature additions), ideally already deduplicated.
- For each candidate: title, abstract, keywords, and — for studies advancing past initial screening — full text.
- A fixed taxonomy of **direct drivers** (5 classes) and **biodiversity indicators/EBV classes** (used throughout screening and extraction, not just at the end):

**Direct driver classes (5):**
1. Land/sea use change
2. Direct exploitation of natural resources
3. Climate change
4. Pollution
5. Invasive alien species

**EBV (Essential Biodiversity Variable) classes (6):**
1. Genetic composition
2. Species populations
3. Species traits
4. Community composition
5. Ecosystem structure
6. Ecosystem function

Threats that don't map cleanly onto one of the 5 driver classes (e.g., fire, recreational disturbance) are **out of scope** and should not be coded as a driver.

---

## Stage 1 — Title/Abstract/Keyword Screening

**Purpose:** Cheaply triage a large candidate pool down to a manageable set worth reading in full.

**Input to the LLM:** title + abstract + keywords only (no full text needed yet).

**Ranking heuristic used in the source paper** (useful if your candidate pool is very large and you need to prioritize): order candidates first by how many independent search strategies/queries returned them, second by recency of publication — on the logic that more-frequently-retrieved and more-recent studies are more likely relevant. This is a *prioritization* heuristic, not a hard inclusion filter.

**Decision rule — retain a study if it plausibly meets ALL three of:**
1. It appears to compare the impacts of **at least two** of the five direct driver classes (not just mention multiple drivers in passing — there must be an actual comparison).
2. It appears to report on **at least one biodiversity indicator or EBV class** (i.e., some measurable facet of the state of biodiversity, not e.g. purely socioeconomic outcomes).
3. It concerns impacts **in the past or present** — NOT purely projected/future/scenario-modeled impacts. (Reviews and meta-analyses of past/present findings are eligible; forward-looking projection studies are excluded.)

**Output:** a binary label (`retain` / `exclude`) plus a 1–2 sentence justification, so a human (or downstream stage) can audit false negatives.

**Prompt skeleton:**
```
You are screening a candidate study for inclusion in a systematic review of direct
drivers of biodiversity loss. Based ONLY on the title, abstract, and keywords below,
decide whether this study should advance to full-text review.

Title: {title}
Abstract: {abstract}
Keywords: {keywords}

Answer YES only if the abstract plausibly indicates:
(a) a comparison of impacts from ≥2 of these drivers: land/sea use change, direct
    exploitation of natural resources, climate change, pollution, invasive alien species;
(b) some biodiversity outcome/indicator is measured or discussed;
(c) the comparison concerns observed/historical impacts, not only future projections.

Output: {"decision": "retain"|"exclude", "reason": "<1-2 sentences>"}
```

---

## Stage 2 — Full-Text Eligibility Assessment

**Purpose:** Confirm the study actually qualifies for the meta-analysis, using the full text.

**Input:** full text of the study.

**Eligibility attributes to extract and evaluate** (mirror the paper's eligibility criteria):

| Attribute | Allowed values | Notes |
|---|---|---|
| Type of analysis | `empirical data`, `review`, `meta-analysis` | "Empirical data" = uses any primary or existing dataset, not just newly collected data. |
| Indicator(s) targeted | one or more from a controlled indicator list (e.g., species richness, Red List Index, Living Planet Index, land cover, etc.) | Indicators intrinsically tied to only one driver (i.e., they can't be used to compare drivers) are not usable. |
| EBV class(es) targeted | one or more of the 6 EBV classes | |
| Temporal-change assessment | `not applicable` (non-empirical, e.g. reviews), `not assessed` (no observed change reported), `assessed` (direct or indirect estimate of temporal change in biodiversity state) | |
| Number of drivers analyzed | integer 0–5 | Must be ≥2 to be usable downstream. |
| Scale of driver-impact comparison | `none`, `nominal` (drivers listed but not compared), `ordinal` (qualitatively ranked), `ratio` (quantitatively partitioned/estimated) | Only `ordinal` or `ratio` support pairwise scoring (see Stage 4). |
| Publication year | year | |

**Eligibility decision rule:**
- Include if: published in/after 2005 **AND** estimates (at least on an ordinal scale) the impacts of **≥2 drivers** on the temporal change of **≥1 biodiversity indicator or EBV class**.
- Reviews/meta-analyses of otherwise-eligible original studies are also eligible.
- Exception: if a needed indicator is poorly represented in post-2005 literature, pre-2005 studies on that indicator may also be included (only apply this exception if you are deliberately filling an indicator gap, not as a general relaxation).
- If several eligible studies clearly draw on the **same underlying data source** (e.g., re-analyses of the same monitoring dataset), retain only the most recent and drop the earlier duplicates ("redundancy check").

**Prompt skeleton:**
```
You are assessing full-text eligibility of a study for a meta-analysis of direct
drivers of biodiversity change. Extract the following as structured JSON, then give
an eligibility verdict.

Full text: {full_text}

Fields to extract:
- analysis_type: "empirical" | "review" | "meta-analysis"
- indicators: [list]
- ebv_classes: [subset of {genetic composition, species populations, species traits,
  community composition, ecosystem structure, ecosystem function}]
- temporal_change_assessed: "not applicable" | "not assessed" | "assessed"
- n_drivers_compared: integer (0-5)
- comparison_scale: "none" | "nominal" | "ordinal" | "ratio"
- publication_year: integer
- likely_duplicate_source_of: <citation, if this looks like a re-analysis of another
  study's dataset already in your corpus, else null>

Eligibility verdict: "eligible" if published >=2005 AND n_drivers_compared >= 2 AND
comparison_scale in {ordinal, ratio}. Note any pre-2005 exception reasoning if relevant.
```

---

## Stage 3 — Extraction of Assessments from Eligible Studies

**Purpose:** A single eligible study may yield **multiple independent "assessments"** — e.g., different indicators, different EBV classes, different regions/realms, or different taxonomic groups analyzed separately. Each such combination is extracted as its own record, because the downstream analysis operates on assessments, not studies.

**For each assessment found within a study, extract:**

| Field | Values / format |
|---|---|
| Spatial coverage | `local` (< 1 country), `regional` (1 country to several countries), `continental` (all/representative countries of a continent), `global` |
| IPBES region | `Africa`, `Americas`, `Asia and the Pacific`, `Europe and Central Asia`, `several regions` (list which), `all regions`, `unclear/not specified` |
| Realm | `freshwater`, `marine`, `terrestrial`, `several realms` (list which), `all realms`, `unclear/not specified` |
| Indicator | from controlled indicator list |
| EBV class | one of the 6 |
| Higher taxon | e.g., vertebrate group, plant, invertebrate, etc. (not applicable for ecosystem-structure-type measures) |
| Drivers compared | subset of the 5 driver classes, each with... |
| Driver impact rank | integer ranking per driver within this assessment, 1 = highest impact; ties allowed |

**Key rule:** if a study reports impacts separately by indicator, EBV class, region, realm, or taxonomic group, treat **each separate breakdown as its own assessment record** rather than collapsing them into one.

**Prompt skeleton:**
```
This study is eligible. Identify every distinct "assessment" it contains — i.e.,
every separate combination of (indicator, EBV class, region, realm, taxonomic group)
for which the paper independently ranks or compares driver impacts. For each
assessment, extract:

- spatial_coverage: "local"|"regional"|"continental"|"global"
- ipbes_region(s)
- realm(s)
- indicator
- ebv_class
- higher_taxon (or "not applicable")
- drivers_compared: [list of 2-5 from the 5-driver taxonomy]
- driver_ranks: {driver_name: integer_rank, ...}  # 1 = most impactful; ties allowed

Return one JSON object per assessment.
```

---

## Stage 4 — Convert Rankings to Pairwise Head-to-Head Scores

**Purpose:** Make heterogeneous rankings (2, 3, 4, or 5 drivers; ties allowed) comparable by decomposing each assessment's ranking into pairwise comparisons.

**Rule:** For every pair of drivers compared within an assessment:
- The more-important driver scores **1**, the less-important scores **0**.
- Tied drivers each score **0.5**.
- An assessment ranking *k* drivers yields C(k,2) pairwise comparisons.

**Prompt/code skeleton (this step is best done as deterministic code, not LLM generation, once ranks are extracted):**
```python
from itertools import combinations

def pairwise_scores(driver_ranks: dict) -> list[dict]:
    pairs = []
    for a, b in combinations(driver_ranks.items(), 2):
        (driver_a, rank_a), (driver_b, rank_b) = a, b
        if rank_a == rank_b:
            score_a, score_b = 0.5, 0.5
        elif rank_a < rank_b:  # lower rank number = more important
            score_a, score_b = 1, 0
        else:
            score_a, score_b = 0, 1
        pairs.append({"driver_1": driver_a, "driver_2": driver_b,
                       "score_1": score_a, "score_2": score_b})
    return pairs
```

---

## Stage 5 — Weighting Assessments

**Purpose:** Prevent studies with broad geographic scope or well-represented indicators from being over- or under-counted relative to their true information content.

**Two weights, multiplied together per assessment:**

1. **Scale weight** (spatial coverage): `local = 1`, `regional = 3`, `continental = 7`, `global = 15`. (Designed so one larger-scale assessment just outweighs two assessments at the next scale down.)
2. **Indicator weight**: inversely proportional to how much total scale-weight that indicator already has across the dataset being analyzed (so under-represented indicators are up-weighted). Recompute this within whatever subset (e.g., bootstrap sample, region, realm) is currently being analyzed.

```python
def indicator_weight(indicator: str, scale_weight_sums_by_indicator: dict) -> float:
    total = scale_weight_sums_by_indicator[indicator]
    return 1.0 / total  # then typically re-normalized across the dataset
```

Each pairwise head-to-head score is multiplied by `scale_weight * indicator_weight` before aggregation.

---

## Stage 6 — Aggregating into Dominance Hierarchies

**Purpose:** Reproduce the driver "dominance hierarchy" (this stage is standard downstream statistics, included here for completeness — likely done in R/Python rather than by the LLM).

- Sum weighted pairwise scores across all assessments in a subset (overall / per-realm / per-region / per-EBV-class) into a driver × driver matrix.
- Compute each driver's dominance as its **normalized David's score** (e.g., via the `EloRating` R package's `DS` function, or an equivalent implementation).
- Obtain confidence intervals via **bootstrapping** (resample studies with replacement, recompute indicator weights within each replicate).
- Test significance of pairwise dominance differences and of "steepness" of the hierarchy via bootstrap/permutation tests, with **multiple-testing correction** (Benjamini–Yekutieli) applied to reported P values.

This stage is a statistical/computational pipeline, not an LLM extraction task — the LLM's job ends at producing the structured, weighted pairwise-comparison table from Stages 1–5.

---

## Summary: What the RAG-LLM Should Output at Each Stage

| Stage | LLM Task | Output granularity |
|---|---|---|
| 1 | Title/abstract screening | 1 record per candidate paper |
| 2 | Full-text eligibility check | 1 record per paper |
| 3 | Assessment extraction | ≥1 record per eligible paper (one per indicator/EBV/region/realm/taxon combination) |
| 4 | Pairwise score conversion | deterministic code, not LLM |
| 5 | Weighting | deterministic code, using metadata from Stage 3 |
| 6 | Hierarchy synthesis | statistical pipeline (R/Python), outside LLM scope |

**Audit trail recommendation:** at every LLM stage, require a short natural-language justification alongside the structured output, and log the exact prompt + input text used, so disagreements between the LLM pipeline and a human reviewer (or between LLM runs) can be traced back to a specific extraction decision.
