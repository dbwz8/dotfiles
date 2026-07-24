---
name: schedule
description: Create periodic, source-grounded Google Sheets snapshots of Performance Modeling team project allocations and a Gantt-style project timeline in the user's Google Drive Shared area. Use when asked to make, refresh, or review a Performance Modeling staffing schedule, capacity plan, project allocation report, or Gantt chart showing each team member's percentage by project.
---

# Performance Modeling Schedule

Create a dated scheduling snapshot that makes current allocation evidence, gaps, and assumptions easy to review. Treat the Sheet as a planning artifact, not an authoritative time-tracking record.

## Defaults

- Create a new Sheet for each run; do not overwrite a prior snapshot unless explicitly asked.
- Use the current calendar month plus the next five calendar months unless the user supplies a period.
- Name the file `Performance Modeling Schedule - YYYY-MM-DD` using the run date.
- Resolve the user's `Shared` destination by searching Drive and inspecting candidate folders or shared drives. Write only after one target is unambiguous. Do not silently fall back to My Drive.
- Discover the current team roster from the supplied source or targeted current team material. Do not assume a person is on the team solely because they appeared in an old schedule.
- Record the as-of time, reporting period, sources, and explicit assumptions in the Sheet.

## Gather Schedule Evidence

Start with the most recent Performance Modeling schedule or allocation plan, then gather only the material needed to update it:

1. Inspect targeted current project-planning, staffing, and roadmap documents.
2. Inspect the current team weekly update or status material for project ownership and changes.
3. Inspect team calendars only for dates, PTO, and milestone timing that affect the chart.
4. Use targeted project or team-member searches in available trackers or collaboration tools only to fill a specific gap.

Keep concise source and assumption notes in the `Gantt` tab, including a stable identifier or link, retrieval date, and what each source supports. Mark a percentage as `Confirmed` only when an explicit planning source supports it. When estimating, label it `Estimated` and give the evidence and calculation basis in Notes; never present an estimate as a confirmed allocation.

## Estimate Missing Percentages

When a person has active work but no explicit percentage, estimate the remaining monthly capacity rather than leaving it blank:

1. Reserve any confirmed project, PTO, or leave percentage first.
2. List the person's current projects supported by the gathered evidence for that month.
3. Weight each project by the strongest evidence: `3` for named primary ownership or a near-term deliverable, `2` for active implementation or a recurring workstream, and `1` for support, review, or a single meeting mention.
4. Divide the remaining capacity in proportion to those weights. Round to whole percentages and adjust the largest allocation by the rounding remainder so the person-month totals 100%.
5. If no project is supported, assign the remaining capacity to `Unallocated` rather than guessing a project.

Use `Estimated` in the Confidence column and record a concise note such as `Estimated: primary owner of Project A (weight 3); supporting Project B (weight 1).` Do not convert an estimate to `Confirmed` in a later run without new explicit evidence.

For each team member and month, allocations must total 100%. Use `PTO / Leave`, `Unallocated`, or `TBD` as an explicit capacity category for remaining time rather than inventing a project assignment. Flag totals other than 100% for review. Use whole percentages unless the source requires finer precision.

## Create the Google Sheet

Before creating or editing the Sheet, use the Google Drive and Google Sheets skills and follow their required creation, import, and chart-validation workflow. Preserve the resolved Shared folder or shared-drive location and verify the created native Google Sheet by Drive readback before reporting it.

Create exactly these two tabs in this order:

1. `Gantt`
   - At monthly granularity, use a six-month Gantt-style calendar grid with three-letter month columns such as `Jul` through `Dec`; do not display day offsets or relative-time axes.
   - Group the grid by project. Add a green project row, then blue Gantt-style rows only for people with a nonzero allocation to that project. Fill active month cells blue and display the allocation percentage; leave inactive month cells blank so the blue cells form the timeline bar. Exclude `TBD`, `Unallocated`, and `PTO / Leave` unless the user asks to display them.
   - Link the month headers, project/person rows, allocation cells, and capacity totals to `Gantt Data` with formulas, so edits to existing inputs recalculate the display without manual copying.
   - Put a blank row before the yellow `Monthly allocation total by person` header. Highlight a monthly total red above 100%, green at 100%, and leave it unfilled below 100%.
   - Use synthetic active-month spans only when the user expressly requests an illustrative example; do not present them as a forecast.

2. `Gantt Data`
   - Keep only the structured project-person monthly inputs that drive `Gantt`, grouped into clearly marked Team Member sections so each person can edit their own project rows.
   - Within each section, repeat the team member on every project row and keep the monthly allocation cells alongside that project.

Use frozen header rows, filters on the source table, legible column widths, and restrained formatting. Do not use color as the only indicator of confidence or capacity category.

## Review Before Delivery

1. Verify the file is a native Google Sheet in the intended Shared location.
2. Verify every Gantt row traces to its supporting data and the displayed period matches the requested or default window.
3. Verify each person-month total is visibly flagged when it exceeds 100%.
4. Re-read the title, chart title, team roster, tab names, and at least one allocation row and chart row after writing.
5. Return only the verified Sheet link, reporting period, and concise notes on unresolved allocation gaps. Do not claim an inference is confirmed.
