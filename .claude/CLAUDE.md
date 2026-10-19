# Screen reader testing with VoiceOver

## What this project is
Gherkin scenarios in `features/` describe how the site under test should
behave with VoiceOver. Your job is to run them against the running app and
report pass or fail, with the exact phrases VoiceOver spoke.

## Where the app is
The app runs at `http://127.0.0.1:8080`. Paths in the scenarios are
relative to this. If it isn't responding, stop and ask me to start it
rather than starting it yourself.

## VoiceOver dictionary
The VoiceOver AppleScript dictionary is in `.claude/refs/voiceover.sdef`.
This is the source of truth for what VoiceOver can do, so always check it
before writing any osascript. If the file is missing, stop and ask me to
run `./setup.sh`.

## How to drive VoiceOver
- Only use `.claude/scripts/vo.sh` to control VoiceOver. Never write ad hoc
  osascript commands. If a step can't be done with the existing subcommands,
  stop and tell me, and propose a new subcommand to add to the wrapper.
  Check the dictionary first to make sure it's actually possible.
- Every wrapper command that moves the cursor or presses something prints
  what VoiceOver announced as a result. Log that verbatim after every step.
  `vo.sh last` prints it again if you need it.
- Give VoiceOver a second after opening a page before moving the cursor.
- Never mark a step as passed on an assumption. If you didn't capture a
  phrase, that step fails, and you say why.

## Reporting
- One line per step: pass or fail, the step text, the phrase captured.
- Quote VoiceOver output exactly. Don't tidy it up or paraphrase it.
- Where a Then step fails, say what was announced instead and, if you can
  tell, which element it came from.
- Finish with a short summary: scenarios run, passed, failed.

## Hard rules
- Don't change any VoiceOver Utility settings.
- Turn VoiceOver off at the end with `vo.sh stop`.
- Don't edit the app's source code to make a scenario pass.

## Step vocabulary

Only use these steps. If a scenario needs something else, stop testing and propose the step and the vo.sh subcommand that would support it.

| Step | What to do |
| --- | --- |
| Given VoiceOver is running | `vo.sh start` if it isn't already |
| Given I am on "<path>" | `open -a Safari` with the base URL plus the path, then wait a second |
| When I move the VoiceOver cursor to the first item | `vo.sh first` |
| When I move the VoiceOver cursor to the next item | `vo.sh next` |
| When I move through the page | `vo.sh first`, then `vo.sh next` until VoiceOver gives its hint about exiting the web area, or announces nothing new twice in a row |
| When I move the VoiceOver cursor to the "<label>" field | `vo.sh find "<label>" field` |
| When I activate the "<name>" button | `vo.sh find "<name>" button`, then `vo.sh activate` |
| Then the announcement should include "<text>" | the last announcement contains the text |
| Then the announcement should not include "<text>" | the last announcement does not contain the text |
| Then the first heading announced should include "<text>" | the first announcement containing "heading level" includes the text |
| Then no heading level should be skipped | across all announcements, heading levels never jump by more than one |
| Then the error summary should list "<text>" | `vo.sh next` through the error summary until an announcement includes the text |

Text fields announce in two steps: the first move announces the label, for example "Email address", and the next move enters the field and announces the full thing, for example "Email address Error: Enter your email address email field". `vo.sh find "<label>" field` handles that for you. When walking with `vo.sh next`, expect to encounter both.
