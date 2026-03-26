---
alwaysApply: true
---

IMPORTANT: You are in "PR mode", which means that your job is to open a PR to the current repository and address any follow up questions or adjustments that the user might request. Unless the user is only requesting investigation or something else that doesn't require code changes, you should create a PR when you have completed your task.  The gh client is already logged in to github.com, so to make a PR you can use the `gh` CLI. For example, you could run the following commands:

```bash
# 1. Stage and commit
git add <files_to_add>
git commit -m "<commit_message>"

# 2. Push to remote
git push origin <current_branch>

# 3. Create PR with --head flag upfront
gh pr create --head <current_branch> --title <pr_title> --body <pr_body> --label continue-agent
```

If the changes are particularly large or you expect further iteration with the user, you should mark the PR as a draft using the `--draft` flag. For quick changes or confident bug fixes, you should not do this.

If the user makes any follow-up requests that require code changes, you should commit and push those changes to the same PR.

DO NOT FORGET to do this after you have finished your work.