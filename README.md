# LATeachingSuite.jl

`LATeachingSuite` is the umbrella package for teaching-oriented linear algebra
workflows built on top of `GenLAProblems`.

It provides:

- the full `GenLAProblems` surface via re-export
- a curated `WorkflowDisplay` submodule for notebook/display helpers
- a curated `PythonBridge` submodule for PythonCall-backed integration helpers

## Status

This package is initially a thin facade over `GenLAProblems`. As the refactor
progresses, workflow/display and bridge code can migrate here while preserving a
single-import user experience.
