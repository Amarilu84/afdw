# Contributing Guidelines

Thank you for considering contributing to **AFDW (Anti-Forensic Drive Wiper)**!\
This project is security-sensitive, so please review these guidelines carefully.

---

## Ways to Contribute

- **Bug Reports**: If something doesn’t work, open an [issue](../../issues). Include your OS, shell version, and exact error messages.
- **Feature Requests**: Suggest improvements, new flags, or usability ideas. Explain the use case clearly.
- **Pull Requests**: Submit code improvements (see below). Please keep PRs focused and small.

---

## Safety First

This project is destructive by design. To keep users safe:
- Do **not** submit PRs that remove confirmations or safety checks.
- Any changes that affect the wiping logic must be thoroughly explained and justified.
- Test your changes on a disposable device before submitting.

---

## Pull Request Process

1. Fork the repo and create your feature branch:
   git checkout -b feature/my-feature

2. Make your changes, following these style notes:
   * Code must remain compatible with Bash 4+ and avoid unnecessary dependencies.
   * Use clear comments to explain tricky logic.
   * Match existing formatting and spacing.

3. Update documentation:
   * Update `README.md` if user-facing behavior changes.
   * Add to `CHANGELOG.md` under the **\[Unreleased]** section.

4. Test your changes on at least one Linux environment.

5. Push your branch and open a Pull Request. Clearly describe what you changed and why.

## Code Style and Compatibility

- This project is written for **Bash (4.0 or newer)**.  
- Use standard Bash features (`[[ .. ]]`, `(( .. ))`, functions, etc.) consistently.  
- Do not introduce code that requires non-Bash shells (e.g., zsh-only, ksh-only features).  
- Keep external dependencies to a minimum (stick to standard Linux utilities).  
- Match existing indentation, spacing, and comment style.  

---

## Code of Conduct

This project follows a simple rule:
Be respectful, constructive, and helpful.
No toxicity, personal attacks, or dismissive behavior will be tolerated.

---

## Tips for First-Time Contributors

* Start small (typo fixes, documentation improvements).
* Read through open issues labeled **good first issue**.
* Don’t be afraid to ask questions—discussions are welcome.

---

Thank you for helping make AFDW better and safer!

---
oRioN NetheRstaR
