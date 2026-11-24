Write **clean, easy-to-understand, production-ready Go code**.

Priorities:

* **Readability and code quality come first.**
* Keep the code **minimalistic**, but not at the cost of clarity.
* Prefer **simple, solid designs** over clever or overly abstract solutions.
* If wrapping logic into a struct improves readability and cohesion, do it.
* Write tests that reflect **business logic**, preferably at the module level: a test should verify a business scenario end-to-end through the module, not a tiny function in isolation. A good example is a test of the usecase layer with mocks (via a mocking library) only for the layers that depend on external systems (connectors, repositories), driven by real business examples and corner cases. A test of a large module built the same way is equally good.
* TDD applies at the usecase/module level: the first failing test is a business scenario through the usecase with mocked external boundaries. Do not write per-function tests just to satisfy TDD; "every new function has a test" is replaced by "every business scenario has a test".
* In `writing-plans`, size tasks so that each task's failing test is a usecase-level scenario.
* Mocks: `mockery` where the repo already uses it (config in `.mockery.yaml`, generation via `go generate`), assertions via `testify`. Do not hand-write mocks; if an interface has no mock yet, add it to `.mockery.yaml` and regenerate.

Code style requirements:

* Do **not** create tiny helper functions or methods that are only used once and contain just a few lines.
* Do **not** split logic into extra methods unless that extraction clearly improves readability, reuse, or structure.
* A method should contain the logic implied by its name and should not be created without real need.
* Functions and methods should be **large enough to be meaningful**, but still easy to read.
* Avoid unnecessary fragmentation of logic.

Validation and checks:

* Use the **validator** library for validation.
* Do **not** add defensive checks for impossible or unrealistic states just to be safe.
* Do **not** bloat the code with redundant nil checks, zero-value checks, or similar guards when such states are not realistically expected in this project.
* Add only those checks that are justified by real execution paths or domain logic.

Project context:

* Read as much existing code as needed to **fully understand the project and the surrounding context** before making changes.
* If something in the task is unclear, ask the user clarifying questions.

Comments:

* Add comments **only when they genuinely help explain non-obvious logic**.
* Keep comments minimal.
* All code comments must be **in Russian**.

Git / workflow restrictions:

* **Do not commit or push anything.**
* **Do not create or switch branches or git worktrees.**
* **Do not merge, pull, rebase, stash, or create pull requests.**
* **Do not interact with remote `origin` in any way.**
* **Always stage new files you create in a repository with `git add -- <explicit file paths>`; no separate approval is required.** Stage only those new files, never unrelated changes or ignored files.
* Perform all other git actions only if I explicitly request that exact git action. Staging new files does not authorize commits, pushes, or any other git actions.
* Assume all work is local only.

Subagents:

* Spawning subagents is **allowed** — for parallel investigation, fresh-context code review, and document review.
* **Code quality outranks token cost.** Never trade quality for cheapness: do not skip a review stage, do not shrink context, and ignore `subagent-driven-development`'s "use the least powerful model" advice — pick the model the job deserves.
* Subagents inherit every rule in this file. In particular they **must not commit, push, or create branches or worktrees**.
* In `superpowers:subagent-driven-development`: drop the "Commit your work" step from the implementer prompt. The implementer reports changed files instead.
* Give the code quality reviewer the working-tree diff (`git diff`, `git status --short`) instead of `BASE_SHA`/`HEAD_SHA`.

Superpowers specs and plans:

* Write specs and plans outside the repository: `~/.claude/superpowers/<repo-name>/YYYY-MM-DD-<topic>-design.md` and `...-plan.md`.
* Do **not** read old specs and plans (in that folder or in `docs/superpowers` of any repo) or use them as context unless I point to a specific file. `docs/superpowers` is not project documentation.

Completion requirements:

* The linter and the full unit-test suite run **once**, by the main agent, at the end of the whole user request — not after each plan task, review fix, or subagent.
* While working, run only the tests of the packages being changed (TDD red/green included).
* Re-run a check only if code changed since its last run. In `verification-before-completion`, "fresh evidence" means "run after the last code change", not "run in this message".
* Subagents: the implementer runs tests and lint only for the packages it changed and puts the output in its report. Reviewers read the diff and that output; they run targeted tests only to check a specific suspicion. The main agent does not re-run checks after each subagent.
* Update the README if the changes altered what it describes.

General expectation:

* The final solution should feel like code written by a strong senior Go developer: **concise, practical, maintainable, and without unnecessary abstractions or boilerplate**.
