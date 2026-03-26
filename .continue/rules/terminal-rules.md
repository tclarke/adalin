---
description: General rules for running terminal commands.
---

Always use alr to build and run the project. Don't call gprbuild directly.
When the visual studio code platform is windows always use powershell to run terminal commands.

When the visual studio code platform is linux or macos always use bash to run terminal commands.

When using Powershell, make sure that escape characters are properly handled. For example, use double backticks (``) when a backtick is needed in a command.

When using Bash, make sure to properly escape special characters as needed. For example, use a backslash (\) before special characters to prevent them from being interpreted by the shell.