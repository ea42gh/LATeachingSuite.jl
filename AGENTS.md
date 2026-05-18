# LATeachingSuite.jl Notes

## Role

`LATeachingSuite` is the canonical Julia umbrella package for the teaching
stack.

It should provide:

- one-import access to the normal Julia user workflow
- re-export of the supported `GenLAProblems` core surface
- workflow/display helpers
- Python bridge helpers that reach `LAFigureSpecs` and `matrixlayout`

## Package Relationships

The intended stack is:

- `LATeachingSuite` -> `GenLAProblems`
- `LATeachingSuite` -> `GenLAProblems` / Python bridge -> `LAFigureSpecs`
- `LAFigureSpecs` -> `matrixlayout`

Maintain Python/Julia interoperability across any migration slice that touches
the umbrella surface.

## README Policy

The `README.md` should carry user-facing status badges for the umbrella package.

Current badge policy:

- keep a CI badge in the README
- add a docs badge later, when deployed docs exist
- add a Binder badge later, when a maintained Binder environment exists

Do not add placeholder docs or Binder badges before those targets are real.

## CI Expectations

`LATeachingSuite` CI should cover:

- Julia package tests
- umbrella-package re-export surface checks
- at least one Julia-to-Python bridge smoke path through `LAFigureSpecs`

## Migration Direction

Prefer moving integration-facing workflow/display and bridge ownership toward
`LATeachingSuite` while preserving current top-level capabilities for users.
