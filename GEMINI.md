# Agent Instructions

**CRITICAL:** This file contains mandatory project guidelines. You MUST
consult and follow these rules whenever performing code reviews, editing files,
or answering questions about the project structure.

## Guidelines

When ask to review the `README.md`

- Make sure to state that code was generated with AI assistance in a
dedicated acknowledgements section
- Make sure the file ends in a newline

When asked to review `Makefile`

- Avoid `.PHONY` targets by using `MAKEFLAGS += --make-all`
- Do not modify target recipes
- Do not introduce new variables
- Add a descriptive header explaining the functionality of the `Makefile`
- Make sure the file ends in a newline

When asked to review `TODO.md`

- Update sentence structure to be gramatically correct and domain appropriate
- Add linked references where possible
- Ensure each of the To-do, Resolved, and Closed sections always exist, even
if empty
- Do not delete entries
- Do not merge entries

When asked to review files in `dotfiles/bash`

- Add descriptions to any `bash` functions
- Run `make format-bash check-bash` at the end and resolve any issues

Follow the above guidelines unless explicitly asked otherwise.
