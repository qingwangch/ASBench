# Optimal Workflow Execution

## 3. Optimal Workflow Execution

Based on the current evaluation framework, the recommended analysis strategies for isoform-level and event-level assessment are summarized below.

---

## 3.1 Isoform Analysis

For **isoform-level analysis**, the recommended workflow consists of three major steps:

### Alignment
- **STAR**

### Quantification
One of the following quantification tools can be used:

- **RSEM**
- **eXpress**
- **Cuffdiff**

### Differential analysis
- **edgeR v1**
- **edgeR v2**

### Recommended workflow summary

```text
Isoform:
STAR
→ RSEM / eXpress / Cuffdiff
→ edgeR v1 or edgeR v2
```

### Notes

- **STAR** is recommended as the aligner for consistent transcriptome-aware mapping.
- **RSEM**, **eXpress**, and **Cuffdiff** represent alternative quantification strategies for isoform abundance estimation.
- **edgeR v1/v2** should be used for downstream differential isoform analysis according to the benchmark design.

---

## 3.2 Event Analysis

For **event-level alternative splicing analysis**, the recommended workflow also begins with STAR alignment, followed by event-oriented splicing tools.

### Alignment
- **STAR**

### Event quantification / differential splicing
- **SUPPA2**
- **rMATS**

### Recommended workflow summary

```text
Event:
STAR
→ SUPPA2 / rMATS
```

### Notes

- **SUPPA2** is recommended for PSI/dPSI-based event quantification and differential splicing analysis.
- **rMATS** is recommended as an additional event-level method for exon/event-based splicing detection.
- These two tools can be used as complementary approaches depending on the benchmark objective.

---

## 3.3 Summary

### Isoform
```text
STAR + (RSEM / eXpress / Cuffdiff) + edgeR v1/v2
```

### Event
```text
STAR + SUPPA2 / rMATS
```

---

## 3.4 Suggested Markdown Figure or Table Integration

This section can be integrated into the project documentation as a standalone workflow recommendation page, or inserted into a broader benchmarking report.

Example compact presentation:

| Analysis level | Alignment | Quantification / event detection | Differential analysis |
|---|---|---|---|
| Isoform | STAR | RSEM / eXpress / Cuffdiff | edgeR v1 / edgeR v2 |
| Event | STAR | SUPPA2 / rMATS | - |

---

## 3.5 Suggested File Name

Recommended file name:

```text
optimal_workflow_execution.md
```
