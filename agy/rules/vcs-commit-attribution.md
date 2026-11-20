---
trigger: always_on
---

# VCS commit attribution

Whenever authoring a version control commit message (git, jj, hg, etc.), always include this trailer on its own line at the end of the message (separated by a blank line):

`Assisted-by: Antigravity (agy)`

- Applies to `git commit -m ...`, amended commits, and commit messages drafted for the user.
- Do not duplicate the trailer if it is already present.
