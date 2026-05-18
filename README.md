# LATeachingSuite.jl

[![CI](https://github.com/ea42gh/LATeachingSuite.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ea42gh/LATeachingSuite.jl/actions/workflows/CI.yml)

`LATeachingSuite` is the umbrella package for teaching-oriented linear algebra
workflows built on top of `GenLAProblems`.

It provides:

- the full `GenLAProblems` surface via re-export
- a curated `WorkflowDisplay` submodule for notebook/display helpers
- a curated `PythonBridge` submodule for PythonCall-backed integration helpers
- canonical umbrella bundle wrappers:
  `ge_bundle`, `qr_bundle`, `eig_bundle`, `svd_bundle`
- top-level umbrella bridge/display wrappers such as:
  `load_LAFigureSpecs`, `load_matrixlayout`, `show_svg`, `py_show_svg`

## Status

This package still re-exports `GenLAProblems`, but it now also owns part of the
curated umbrella surface directly. As the refactor progresses, more
workflow/display and bridge ownership can migrate here while preserving a
single-import user experience.

## Package Roles

The current stack has four package roles:

- `LATeachingSuite`
  Canonical Julia umbrella facade. This is the intended one-import entrypoint
  for teaching workflows, display helpers, Python bridge helpers, and
  umbrella-level bundle wrappers.
- `GenLAProblems`
  Canonical Julia problem-generation core. It owns matrix/problem generation,
  reduction helpers, and math-first utilities.
- `LAFigureSpecs`
  Canonical Python algorithm/spec facade. It builds GE/QR/eigen/SVD specs and
  convenience render workflows on top of `matrixlayout`.
- `matrixlayout`
  Internal Python layout/render engine for small matrix-focused teaching
  displays.

## Dependency Structure

The intended dependency structure is:

```text
LATeachingSuite
  -> GenLAProblems
  -> LAFigureSpecs
       -> matrixlayout
```

For Julia workflows that need the Python-backed display stack, the effective
interop path is:

```text
LATeachingSuite -> GenLAProblems / PythonBridge -> LAFigureSpecs -> matrixlayout
```

## Which Package To Import

- Julia users should normally import `LATeachingSuite`.
- Julia users who only want generation and math helpers may import
  `GenLAProblems` directly.
- Python users should import `LAFigureSpecs`.
- `matrixlayout` is primarily an internal engine, not the preferred end-user
  entrypoint for the teaching stack.

## Architecture Notes

See [docs/architecture.md](docs/architecture.md) for a more detailed description
of package responsibilities, interoperability expectations, and migration
direction.
