---
name: resume
description: "Drive the current task to completion after the model stopped to ask for confirmation."
disable-model-invocation: true
---

# Resume

You were invoked because a turn ended with work still pending. The task is every item in the plan (if the conversation names one) and in the last user message that is not yet done. When the two disagree, the last message wins.

## Drive it

Drive the remaining work to the end. A step flows straight into the next: it is complete when its result is in hand, and the next one starts in the same turn. Work silently through the steps (preserving the `[flow] fase N · gate pendiente: X` status line when `opencode-flow` is active); the report waits until the run is over.

- Every pending item gets addressed, in order.
- Verified means the real command ran and you read its full output — or the edited file was re-read in full and checked against the instruction or spec.
- A broken step is repaired in place; the run continues with the repair.
- An ambiguous instruction gets the most reasonable reading, with the assumption named in the closing report.

## Stop only for the user

- A fact only the user holds: a credential, a choice between two valid designs, or permission for a destructive action.
- The task is done.
- The last message contained nothing pending — say so in one line and stop.

## Closing report

One report, once the run is over: what changed, what was verified (command output or file content), and what is left.
