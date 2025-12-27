# Guidelines

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

Follow the above guidelines unless explicitly asked otherwise.
