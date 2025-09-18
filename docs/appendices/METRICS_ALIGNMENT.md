# Metrics Alignment (P95/P99, Baselines, Methodology)

Purpose: unify targets across PRD.

## Baseline Devices

- iPhone 12 (A14)
- iPhone SE (2022)
- Current-year flagship

## Methodology

- Cold vs warm start defined; airplane mode off; screen brightness 50%
- Measure P50/P95; 3 runs per scenario; exclude first run when needed
- Tools: MetricKit, os_signpost, Xcode Instruments, ASC metrics

## Targets

- App launch (cold): P95 < 1.2s
- Memory (normal use): P95 < 60MB; capture/OCR peak P95 < 300MB
- Search latency: P95 < 300ms (5k items indexed)
- OCR single image: P95 < 2.5s under standard lighting

## Reporting

- Weekly dashboard; threshold alerts when regressions exceed 10%
