# Analytics Event Spec

Purpose: align measurement with PRD metrics and RTM mapping. All events must be privacy-safe and child-friendly.

## Conventions

- ID: snake_case
- Time: ms (int)
- Sampling: 100% unless specified
- PII: None; use anonymous IDs; for minors, no cross-app tracking

## Core Events (v6.0)

- capture_started { source: camera|album, batch: int }
- capture_ocr_completed { duration_ms: int, ocr_confidence: float, edited: boolean }
- item_tagged { tags: [string], subject: string }
- review_session_started { set_size: int, algo: spaced|manual }
- review_card_swiped { direction: right|left|again, item_id: string, time_spent_ms: int }
- notification_delivered { type: review, deep_link: string }
- notification_opened { type: review }
- search_performed { query_length: int, filters: [string], result_count: int }

## Dashboard Mapping

- Acquisition: App Store Connect / custom
- Engagement: review_*, search_*
- Quality: crash rate, latency distributions

## Retention & Privacy

- Data retention: 180 days (aggregated), raw 30 days
- K-anonymity: do not show cohorts < 5 users
- Opt-out: respect OS analytics opt-out
