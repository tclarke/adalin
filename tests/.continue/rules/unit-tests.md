---
description: Information on unit tests
applies_to: [unit-tests,tests]
---

For unit testing in this project:
 1. Use the `aunit` framework for writing and running unit tests.
 2. Place all unit test files in the `tests/src` directory.
 3. Follow the naming convention `tests-<functionality>.adb` for test files.
 4. Ensure that each test case is independent and does not rely on the state of other tests.
 5. Use assertions provided by the `aunit` framework to validate expected outcomes.
 6. Run unit tests regularly during development to catch issues early.
 7. Document each test case with comments explaining the purpose and expected results.
 8. Review and update unit tests as necessary when changes are made to the codebase to ensure they remain relevant and effective.
 9. Aim for high code coverage with unit tests, but prioritize meaningful tests that cover critical functionality over achieving 100% coverage.
 10. Build and run unit tests by executing `alr run` in the `tests` directory.