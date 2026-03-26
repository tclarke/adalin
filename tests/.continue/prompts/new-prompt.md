---
name: Fix issues
description: This will run tests and apps and identify warnings and errors. It will then attempt to fix them and run the tests again to verify that the issues have been resolved. It will also run SPARK and fix issues.
invokable: true
---

Run unit tests and applications to identify warnings and errors. Attempt to fix any issues found and run the tests again to verify that the issues have been resolved. After all issues have been addressed, run gnatprprove on all SPARK enabled packages to identify any remaining issues. Attempt to fix any issues found and run gnatprprove again to verify that all issues have been resolved.