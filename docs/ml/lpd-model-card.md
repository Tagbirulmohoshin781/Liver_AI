# LPD Clinical Risk Calculator Model Card

## Model Overview
- **Identifier**: \liverai-lpd-heuristic-v1\
- **Type**: AASLD-Grounded Directional Risk Heuristic / Rule-Based Scorer
- **Status**: \EXPERIMENTAL_RESEARCH_ONLY\
- **Primary Use**: Visualizing clinical reference range boundaries for educational purposes.

## Ethical & Clinical Safeguards
- This model is explicitly marked with \is_diagnostic: false\.
- Gated in production via \ENABLE_EXPERIMENTAL_CLINICAL_SCORE\ (default true for user exploration).
- Any prediction output returned to the UI includes mandatory clinical consultation disclaimers.
