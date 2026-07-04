---
name: weekly-update
description: Produce Dave Wecker's structured weekly update from the current week's Obsidian/Drive notes, calendar events, Slack activity, Jira/Confluence, Outline, Gmail, GitHub, and other available work sources. Use when asked for a weekly update, weekly status, Dave's TODOs, team activity/blockers/accomplishments, or an end-of-week summary grounded in Dave's work sources.
---

# Weekly Update

## Purpose

Produce a source-grounded weekly update for Dave Wecker. Pull from available work sources, preferring the IonQ MCP gateway when it exposes the needed source. Explicitly note gaps when a relevant source is unavailable.

## Source Gathering

Default to a fast, bounded pass. Only do a deep sweep if Dave explicitly asks for a "deep", "exhaustive", or "full" weekly update.

Prefer IonQ MCP gateway tools for shared work sources, including Google Drive, Google Calendar, Slack, Jira, Confluence, and Outline. Use standalone connectors only when the gateway does not expose a needed non-Slack source. Do not use the standalone `slack-reader` connector when IonQ gateway Slack tools are available.

Use the best available source access in this order:

1. Dave's active notes/TODOs and Obsidian notes.
   - Search local Obsidian and IonQ/Google Drive first for exact or short queries: `TODO.md`, `Diary.md`, `weekly update`, and `performance modeling`.
   - Always include current-week notes from these Obsidian folders when accessible: `Diary`, `Interviews`, `Meetings`, `Work`, and `Other Work`.
   - For each of those folders, prefer files modified during the report week, files whose title/path includes the report week dates, and files matching high-signal terms from the calendar or direct reports' names.
   - Fetch high-confidence current files, usually `TODO.md`, `Diary.md`, relevant 1:1 notes, meeting notes, interview notes, and work notes from the folders above.
   - Do not run broad Drive searches with full-text fetching outside `Diary`, `Interviews`, `Meetings`, `Work`, and `Other Work` unless the first pass finds no active TODO or notes source.
   - If Obsidian is available only through Drive, treat markdown files in those folders as the Obsidian source.

2. Calendar.
   - Inspect the report week's events, today's remaining meetings, and the following work week's events when a calendar connector is already available.
   - Summarize calendar data into schedule context rather than dumping a raw agenda.
   - Include key meetings, 1:1s, interviews, deadlines, OOO/PTO, holidays, and meetings that imply follow-up work.
   - If no calendar connector is available, use tool discovery once. If none is found, record the source gap and do not keep searching.

3. Slack through the IonQ gateway.
   - Keep Slack reads targeted to the week and to likely high-signal sources.
   - Do not list all recent Slack conversations unless the targeted searches fail.
   - Start with the direct reports' DMs and the `performance-modeling-team` channel when available.
   - Follow only Slack links found in Dave's active TODOs/notes, or conversations returned by exact searches for the direct reports' names.
   - Read public/broad channels only when a TODO, note, or direct report activity points to them.
   - Default read budget: at most 12 Slack conversation/thread reads total, plus at most 2 additional reads for calendar-equivalent meeting context if needed.
   - Do not download Slack attachments unless the report would otherwise be materially wrong.

4. Jira and Confluence through the IonQ gateway.
   - Use Atlassian/Rovo search for issue, project, and document discovery unless Dave gives an exact JQL or CQL task.
   - Search only targeted terms from TODOs, calendar events, Slack links, direct reports, and active workstream names.
   - Fetch issues or pages that are clearly current-week relevant, assigned to Dave or a direct report, or referenced by already-read sources.
   - Include ticket state, owner, blockers, deadlines, and recent decisions when they change the TODO list, team activity, schedule context, or outstanding problems.
   - Avoid broad project sweeps unless Dave asks for a deep update.

5. Outline and other internal docs through the IonQ gateway.
   - Search targeted workstream terms, meeting names, and direct-report names when notes/Slack/calendar imply an internal doc may hold status or decisions.
   - Prefer recently updated documents and documents linked from Slack, calendar descriptions, Drive notes, Jira, or Confluence.
   - Use docs to clarify decisions, owners, risks, and cross-team asks; do not turn the weekly update into a document inventory.

6. Gmail and Drive-native files.
   - Use Gmail only for targeted gaps: HR/promotions, recruiting/interviews, staffing, approvals, deadlines, travel/OOO, or email threads explicitly referenced by TODOs, calendar, Slack, Jira, Confluence, or notes.
   - Use Drive-native Docs/Sheets/Slides when linked or high-confidence search results indicate they contain meeting notes, planning docs, status trackers, or review materials.
   - Do not browse the inbox or Drive broadly for general activity.

7. GitHub.
   - Use GitHub only for technical workstreams where repos, PRs, issues, or commits are named by TODOs, Slack, Jira, Confluence, calendar, or notes.
   - Search targeted repositories, PRs, and issues for current-week activity by Dave or the direct reports when technical signal is otherwise thin.
   - Include PR/issue state, owner, blocker, review need, or merge status only when it affects the report.

If a connector is not already available, use tool discovery only once per source type. Do not use web search for private work sources unless Dave explicitly asks.

Keep a compact source log while gathering: date ranges searched, Obsidian/Drive files checked, calendar ranges inspected, Slack channels/DMs or search terms used, Jira/Confluence/Outline searches and fetched items, targeted Gmail/GitHub searches, collaboration opportunity terms checked, and source gaps.

## Workflow

1. Determine the week.
   - Anchor to the actual current date.
   - Default to starting on the most recent Monday that is at least 7 days before today, ending today, inclusive, so mid-week reports cover activity since the previous full Monday.
   - If Dave explicitly asks for a calendar-week report, use Monday through Friday for a full week, or Monday through today when mid-week.
   - Use this range in the title and section headers.

2. Gather Dave's TODOs.
   - Prefer Dave's active TODO source over reconstructing TODOs from Slack or trackers.
   - Search Slack, calendar, Jira/Confluence, Outline, Gmail, Drive, and GitHub only to clarify open TODOs, add urgency, or follow links from the TODO source.
   - Include only currently open TODOs. Omit any item that appears completed in any source, including `[x]`, struck-through text, "done", "completed", "closed", or equivalent language.
   - Never list completed work as completed; leave it out entirely.
   - Categorize open TODOs under Promotions / HR, Staffing / Org, Technical, Management, and Today's Meetings.
   - For Today's Meetings, list only upcoming meetings for the current day, with time and concise context.
   - Mark urgency with tags such as `(overdue)`, `(deadline passed)`, or `(urgent)` when the sources support it.

3. Gather team activity.
   - Cover each direct report individually: Frederik Hardervig, Amrit Poudel, Finn Buessen, Lucas Slattery, and Matthias Scott-Jones.
   - Also cover Dave Wecker's own activity and blockers.
   - Use this order: direct report DMs through IonQ Slack, `performance-modeling-team`, Slack links from TODOs/notes, calendar-linked docs, Jira/Confluence/Outline items, targeted GitHub PRs/issues for technical work, then exact-name searches if signal is still thin.
   - For each person, summarize what they have been doing this week, accomplishments, and potential blockers or issues.
   - If someone is on PTO, say so clearly and include the return date when known.
   - Include Slack IDs when confidently known; otherwise use the person's name without inventing an ID.
   - If the bounded pass has no evidence for a person, say "No clear source signal found" rather than expanding into unrelated channels.

4. Build Arch Staff Popcorn context.
   - Add a dedicated `Popcorn (Arch Staff)` section immediately after the title separator and before Dave's TODOs.
   - Use it for Dave's 3-minute Arch Staff Meeting update on what his group has done since last week.
   - Follow the Arch Staff format: Accomplishments, Collaboration, and Radar.
   - Keep it speakable: use short prompt bullets grouped under Accomplishments, Collaboration, and Radar.
   - Do not force all context into one sentence per category. Use 2-4 bullets per subsection, usually no more than 12 bullets and 150 words total.
   - Prefer fragments Dave can speak from over polished prose. Each bullet should hold one thought and avoid semicolon or comma chains.
   - Make it team-level, not a full status dump. Pull the highest-signal items from Dave's activity, direct reports, open cross-team asks, calendar/Slack context, Jira/Confluence/Outline decisions, and technical tracker status.
   - When Arch Staff Meeting appears in the calendar, inspect the invite description and any attached/referenced notes. If Slack meeting notes or parking-lot examples are readily available, use at most 2 extra reads to calibrate style.
   - Do not include raw source citations in the Popcorn section; keep sources in the report footnote.

5. Build schedule context.
   - Add a dedicated `Schedule Context` section after Dave's TODOs.
   - Cover the report week and the following work week in separate subsections.
   - For the report week, summarize important completed meetings, 1:1s, interviews, workstream meetings, OOO/PTO, and calendar-driven deadlines.
   - For the following work week, summarize holidays, OOO/PTO, upcoming 1:1s, recurring meetings, deadlines, and meetings that should drive preparation or follow-up.
   - Keep the schedule concise and decision-oriented; avoid listing low-signal personal events or raw calendar noise.
   - For today's remaining meetings, keep the existing TODO subsection as action-oriented meeting prompts.

6. Identify potential collaboration areas.
   - Add a dedicated `Potential Collaboration Areas` section after team activity and before outstanding problems.
   - Use already-read sources first, then a bounded targeted pass across Slack, calendar-linked docs, Jira/Confluence, Outline, Drive-native files, Gmail, and GitHub when those sources are available.
   - Look for current-week or upcoming workstreams, requests, problems, staffing gaps, design discussions, technical blockers, or planning docs that match Dave's team's active work or team-member skills.
   - Treat team fit as evidence-based: derive it from Dave's TODOs, direct-report activity, known workstreams, and source-grounded mentions of skills or responsibilities. Do not invent skills or infer sensitive personnel details.
   - Prefer opportunities that are not already covered by Dave's TODOs, team activity, recurring meetings, or active ownership. If an item is already known, include it only when the sources reveal a new partner, unresolved ask, or adjacent outreach opportunity.
   - For each candidate, include the collaboration area, source signal, why Dave's team may fit, suggested contact or team when known, and a concrete outreach step.
   - Keep the section concise: usually 3-6 bullets. If no credible new opportunities are found, say "No clear new collaboration opportunities found" rather than stretching weak evidence.
   - Avoid turning this into a broad org scan; search targeted terms from current team work, direct-report names, project names, and recurring technical themes.

7. Identify outstanding problems.
   - Surface unresolved cross-cutting issues, blockers, risks, and deadlines going into next week.
   - Include owner, needed unblock, and deadline when known.
   - Build this mostly from Dave's open TODOs, unresolved Slack threads, Jira/Confluence/Outline items, and GitHub PRs/issues already read; do not start a new broad search just for this section.

8. Write the report to Dave's Obsidian Weekly Update output file.
   - Final destination is the existing Google Drive / Obsidian markdown file `IonQ/Diary/Weekly Update output.md`.
   - Prefer writing the local synced Obsidian file directly when available: `/mnt/c/Users/wecker/Documents/ObsidianSync/IonQ/Diary/Weekly Update output.md`.
   - Use file ID `1svvdFwwgyh8HFb1VkLXYWdI4MBBPrclu` and parent folder `IonQ/Diary` when confirming the target.
   - Overwrite that same file on every run; do not create a dated output file unless Dave explicitly asks for one.
   - When the local synced path is not writable but `gws` is available, upload the generated markdown with:
     `gws drive files update --params '{"fileId":"1svvdFwwgyh8HFb1VkLXYWdI4MBBPrclu","supportsAllDrives":true}' --upload <local-markdown-path> --upload-content-type text/markdown --format json`
   - If a local staging file is needed for upload, use a temporary path only as an implementation detail and treat the Drive file as the report output.
   - Do not wrap the report in ```markdown or any other code block.
   - Do not create or update a canvas.
   - In the conversation, report the Drive target and a brief note on sources or gaps; do not paste the full report unless Dave explicitly asks.
   - Use Obsidian task syntax `- [ ]` for every TODO item and meeting action.
   - Use ordinary Markdown headings, separators, bold labels, bullets, and blockquotes that render cleanly when pasted into Obsidian.
   - Avoid emoji in headings so the report stays simple and searchable in Obsidian.
   - Be specific: include names, dates, meeting times, context, and source-grounded urgency.
   - If evidence is thin, state "No clear source signal found" rather than guessing.
   - Include a sources footnote at the bottom.

## Output Template

# Weekly Update - [Month Day-Day, Year]

---

## Popcorn (Arch Staff)

**Accomplishments**

* [short speak-from bullet on shipped or moved-forward work]

**Collaboration**

* [short speak-from bullet on help needed, help offered, or cross-team alignment]

**Radar**

* [short speak-from bullet on risks, deadlines, staffing, PTO, decisions, or constraints]

---

## Dave's TODOs

*Sources: [list sources checked]*

**Promotions / HR**

- [ ] [TODO item with context]

**Staffing / Org**

- [ ] [TODO item with context]

**Technical**

- [ ] [TODO item with context]

**Management**

- [ ] [TODO item with context]

**Today's Meetings ([Day Month Date])**

- [ ] [Meeting name - time] *(context if relevant)*

---

## Schedule Context

**Report Week ([Month Day-Day])**

* [key schedule item and why it matters]

**Following Work Week ([Month Day-Day])**

* [upcoming meeting, OOO/PTO, deadline, or prep item]

---

## Team Activity, Blockers & Accomplishments - [Week range]

---

**[Team Member Name]** @[slack_id if known]

*What they've been doing:*

* [activity]

*Accomplishments:*

* [accomplishment]

*Potential blockers / issues:*

* [blocker or issue]

---

[repeat for each direct report, then Dave Wecker]

---

## Potential Collaboration Areas

* **[Area / workstream]** - [source signal; why Dave's team may fit; suggested contact/team; proposed outreach step]

---

## Outstanding Problems / Issues

* **[Issue name]** - [description, owner, what's needed]

---

> *Sources: [Calendar range, Slack activity summary, Obsidian/Drive files checked, Jira/Confluence/Outline items, targeted Gmail/GitHub searches, notes on data gaps]*
