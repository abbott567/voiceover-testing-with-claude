# Screen reader testing with Claude Code, VoiceOver and Gherkin

This is the companion repo for my blog post [Screen reader testing with Claude Code, VoiceOver and Gherkin](https://www.craigabbott.co.uk/blog/2026/screen-reader-testing-with-claude-code-voiceover-and-gherkin/). Everything the post asks you to create is in here, ready to clone, plus a small sign-in page to test against.

VoiceOver on macOS has an AppleScript dictionary, so a script can turn it on, move its cursor and read back the last thing it said. Gherkin scenarios describe what a screen reader user should hear. Claude Code reads the scenarios, drives VoiceOver through a small wrapper script, and reports what was actually announced.

The post explains the why and the how in detail. This README only covers getting the repo running.

## What's in here

| Path | What it is |
| --- | --- |
| `.claude/CLAUDE.md` | Instructions for Claude Code: how to drive VoiceOver, how to report, the hard rules and the step vocabulary |
| `.claude/settings.json` | Permission rules, so Claude can only run the wrapper and open pages in Safari |
| `.claude/scripts/vo.sh` | The wrapper around VoiceOver's AppleScript dictionary |
| `.claude/refs/` | Where `setup.sh` puts a copy of the VoiceOver dictionary, for Claude to check before proposing any AppleScript |
| `features/sign-in.feature` | The example Gherkin scenarios from the post |
| `app/` | A dependency-free sign-in page and server to run the scenarios against |
| `skill/voiceover-testing/` | The same instructions and wrapper packaged as a Claude Code skill, for use across projects |
| `setup.sh` | Copies the dictionary and makes the scripts executable |
| `smoke-test.sh` | Proves your terminal can drive VoiceOver before Claude gets involved |

## You'll need

- A Mac. This drives VoiceOver, so it won't work with NVDA or JAWS.
- [Claude Code](https://claude.com/claude-code), run from a terminal.
- Node.js 18 or later, for the example app. It has no dependencies, so there's nothing to install.

## Setup

Most of this is macOS permissions, and it only needs doing once.

### 1. Run the setup script

```bash
./setup.sh
```

This copies your Mac's VoiceOver dictionary into `.claude/refs/voiceover.sdef` and makes the scripts executable. The dictionary changes a little between macOS versions, which is why it's copied from your machine rather than committed here.

### 2. Allow AppleScript to control VoiceOver

Open VoiceOver Utility (System Settings, then Accessibility, then VoiceOver, then "Open VoiceOver Utility"). In the General pane, check "Allow VoiceOver to be controlled with AppleScript".

### 3. Give your terminal the Accessibility permission

System Settings, then Privacy & Security, then Accessibility. Add the app you run Claude Code from and switch it on. If that's the VS Code terminal, it's VS Code that needs the permission, not Terminal.

### 4. Make VoiceOver predictable

Still in VoiceOver Utility:

- Web, then the General tab (called Page Loading on older versions of macOS): uncheck both options under "When loading a new web page" and set "While a web page loads" to "Do Nothing".
- Navigation: uncheck "Allow cursor wrapping".

If you use VoiceOver day to day, export your preferences from VoiceOver Utility first, or use a separate user account for testing, so you can put them back.

### 5. Prove it works

Open any web page in Safari, make sure VoiceOver is off, then run:

```bash
./smoke-test.sh
```

You should hear VoiceOver start, it should switch to Safari and move the cursor, then it should quit and print the last phrase it spoke. The first time, macOS asks whether your terminal app may control VoiceOver. Choose "Allow". If it errors, check steps 2 and 3.

## Run the scenarios

Start the example app, which serves the sign-in page at http://127.0.0.1:8080/sign-in:

```bash
npm start
```

In another terminal, open Claude Code in this folder and ask:

> Run features/sign-in.feature and report.

Claude reads the feature file, starts VoiceOver, opens the page in Safari, walks the cursor through it capturing what VoiceOver announces after every move, compares what it captured with the `Then` steps, writes a report, and turns VoiceOver off again.

### What to expect

All three scenarios run with the subcommands in the wrapper. The post leaves two of them, `find` and `activate`, for you to add when Claude stops and proposes them. They're already here so the demo works end to end:

| Subcommand | What it does |
| --- | --- |
| `vo.sh find "Sign in" button` | Moves to the top of the page, then right, until an announcement contains the first argument as whole words and the rest anywhere. Prints the announcement it stopped on. |
| `vo.sh activate` | Presses the item in the VoiceOver cursor, like VO-Space. It uses the dictionary's `perform action` command. |

Every command that moves the cursor or presses something prints what VoiceOver announced as a result, and `vo.sh last` prints it again. That's a change from the post, where `last` reads VoiceOver's "last phrase" once. It turns out VoiceOver announces an item in chunks and "last phrase" only holds the latest one, so the wrapper now collects everything said over the next couple of seconds.

Three things about what VoiceOver actually says, all seen on macOS 26 and 27:

- **Role names.** Text inputs are "email field", "secure text field" or "text field", not "edit text", which is why the feature file checks for "field". Links and headings are role first ("link Enter your email address", "heading level 1 Sign in"), buttons are name first ("Sign in button").
- **Text fields announce in two steps.** The first move onto a field says the label. The next move enters it and says the full thing, including the role and any error message. `find "<label>" field` deals with that.
- **Autofill menus.** Safari opens an autofill menu when the cursor reaches a password field, and so does 1Password if you have it. The next move closes it, which is why a button after a password field is announced as "Closing menu Sign in button". The example app is served on 127.0.0.1 rather than localhost, because Safari fills saved localhost passwords in too, and that interrupts the email field's announcement as well.

If you want to see the feedback loop from the post, delete `find` and `activate` from `.claude/scripts/vo.sh` and set their rows in the step vocabulary in `.claude/CLAUDE.md` back to "needs a new subcommand". Claude should then stop at the first step it can't do and propose them.

Then read the captured announcements yourself. The pass and fail marks are Claude's opinion. The announcements are the evidence.

### Seeing a failure

The example app does the right thing: submitting an empty form moves focus to the error summary. To see what a failing report looks like, comment out the `summary.focus()` line near the bottom of `app/sign-in.html`. The error summary still renders, but focus stays on the button, which is the exact failure shown in the post.

## Using it as a skill instead

If you want this across projects rather than copied into each one, use the skill version.

1. Copy the skill into your personal skills folder, along with the dictionary:

   ```bash
   cp -R skill/voiceover-testing ~/.claude/skills/
   mkdir -p ~/.claude/skills/voiceover-testing/refs
   cp /System/Library/CoreServices/VoiceOver.app/Contents/Resources/VoiceOver.sdef ~/.claude/skills/voiceover-testing/refs/voiceover.sdef
   chmod +x ~/.claude/skills/voiceover-testing/scripts/vo.sh
   ```

2. Allow the wrapper in `~/.claude/settings.json`, so the rule follows you between projects:

   ```json
   {
     "permissions": {
       "allow": [
         "Bash(~/.claude/skills/voiceover-testing/scripts/vo.sh *)",
         "Bash(open -a Safari *)"
       ]
     }
   }
   ```

   Permission rules match the command text as Claude writes it. If Claude uses the expanded path (`/Users/you/.claude/...`), add that form as well.

3. Each project's `CLAUDE.md` then only needs the project-specific bits:

   ```markdown
   ## Screen reader testing
   Use the voiceover-testing skill. The app runs at `http://127.0.0.1:8080`
   and the scenarios are in `features/`.
   ```

## What this does and doesn't catch

It's good at missing or incorrect labels, heading structure, reading order, focus handling, hidden content being announced, and decorative images that aren't hidden. It doesn't hear anything, so it won't notice pronunciation, pauses or the wrong voice. It's VoiceOver only, so passing here says nothing about NVDA or JAWS. And it isn't a replacement for testing with people who use screen readers every day.

For repeatable pass or fail tests in a CI pipeline, look at [Guidepup](https://www.guidepup.dev/), which is built for exactly that.

## Licence

MIT. See [LICENSE](LICENSE).
