# UI coverage matrix

This file records what the current Playwright suite verifies. Treat the list as test evidence, not an assumption that every FlexiRule component has already been covered.

| Area | Initial automated checks | Coverage status |
| --- | --- | --- |
| Frappe Desk session | Login and visible navbar; setup-wizard redirect is reported as an actionable setup failure | Baseline |
| RuleFlow workspace | Workspace header, the New Rule / Rule List / Rule Builder / Execution Logs shortcuts, Total Rules / Active Rules cards | Baseline |
| Rule list | A real inactive Rule appears in the list; its native Visual Builder action opens that Rule's builder | Baseline |
| Rule form | Rule Name, Contact Link selection, Trigger Event selection, native save response and Visual Builder action | Baseline |
| Builder entry | Lazy-loaded builder constructor and contracts API exist; canvas and Zoom In / Zoom Out / Fit View controls render | Baseline |
| Action insertion | Insert a Condition action using the current ActionZone and give it a custom label | Partial |
| Action configuration | Modal opens; Raw Configuration can be opened and exited; modal can be closed | Partial: one action type |
| Graph lifecycle | Custom action label remains after Save Rule and page reload | Baseline |
| Responsive layout | Workspace and builder at 1440x900 and 1024x768; element bounds, computed styles and horizontal document overflow are recorded | Baseline |
| Runtime diagnostics | Uncaught page errors fail a passing test; console errors and failed requests are attached to test results | Baseline |
| Screenshots | Explicit opt-in screenshots through CAPTURE_SCREENSHOTS=1 | Operational |

## Follow-on component matrix

Expand with separate, focused tests as features are verified against the live FlexiRule UI:

- ActionZone: search, keyboard navigation, no-result state, selecting every supported action type, operation/mode selection, Process selection and operation selection, custom labels, paste flow, and popover dismissal.
- Node components: Entry/Start, Condition, Loop, Switch, Stop, Wait, Set Value/Assignment, Notify, Raise Error, Query/Fetch, Document Action, Process and Sub-Rule; selection, toolbar, editing, deletion, read-only state, error/status indicators, long labels and disabled-node visibility.
- Configuration: each corresponding config component; mandatory fields, valid/invalid states, editing, save/cancel, raw JSON transition, previous/next action navigation, responsive and RTL states.
- Rule metadata: all trigger types, dependent/hidden fields, link dropdown/autocomplete, activation lock/deactivation dialog, invalid graph validation, and permission-visible controls.
- Canvas interactions: add/delete/connect nodes, true/false branches, loop body/return links, drag/drop, auto-layout, zoom/pan, undo/redo, clipboard, keyboard shortcuts, disabled nodes, dirty state, save failures and reload persistence.
- Value resolution and condition UI: each resolver family and operator/value editor, nested AND/OR groups, type-specific controls, search and validation.
- Accessibility/layout: focus order, keyboard-only use, accessible names, focus trap/return, minimum viewport, horizontal overflow, clipped content, contrast, long text, and RTL.
- Errors and resilience: missing API permissions, backend validation responses, network failures, stale contract cache and failed lazy bundle loading.

Do not add speculative selectors to check a component that was never inspected in the current app source. First inspect its actual contract and rendered markup, then add assertions around supported behavior. If a product/UI change is intentional, update the test and this coverage record together.