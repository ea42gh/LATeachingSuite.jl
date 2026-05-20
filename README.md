# LATeachingSuite.jl

[![CI](https://github.com/ea42gh/LATeachingSuite.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ea42gh/LATeachingSuite.jl/actions/workflows/CI.yml)

`LATeachingSuite` is the umbrella package for teaching-oriented linear algebra
workflows built on top of `GenLAProblems`.

It provides:

- the full `GenLAProblems` surface via re-export
- explicit top-level ownership of the canonical Julia GE/workflow surface:
  `ShowGE`, `ref!`, `show_layout!`, `show_system`,
  `show_backsubstitution!`, `show_solution!`
- a curated `WorkflowDisplay` submodule for notebook/display helpers
- a curated `PythonBridge` submodule for PythonCall-backed integration helpers
- canonical umbrella bundle wrappers:
  `ge_bundle`, `qr_bundle`, `eig_bundle`, `svd_bundle`
- canonical modern replacements for legacy `nM` render helpers:
  `ge_svg`, `qr_svg`, `qr_figure`
- top-level umbrella bridge/display wrappers such as:
  `load_LAFigureSpecs`, `load_matrixlayout`, `show_svg`, `py_show_svg`

## Status

This package still re-exports `GenLAProblems`, but it now also owns part of the
curated umbrella surface directly. As the refactor progresses, more
workflow/display and bridge ownership can migrate here while preserving a
single-import user experience.

The historical `nM.*` surface should now be treated as deprecated. Prefer the
modern umbrella names instead:

- `nM.show_ge_tbl` -> `ge_svg` or `ge_bundle` if you also need the spec
- `nM.show_qr_tbl` -> `qr_bundle`
- `nM.show_eig_tbl` -> `eig_bundle`
- `nM.show_svd_tbl` -> `svd_bundle`
- `nM.show_ge` / `nM.ge` -> `ge_svg`
- `nM.show_qr` -> `qr_svg` or `qr_figure` if you also need computed matrices
- `nM.qr_svg` / `nM.qr_tbl_svg` -> `qr_svg`
- `nM.eig_tbl_svg` -> `eig_svg`
- `nM.svd_tbl_svg` -> `svd_svg`
- `nM.gram_schmidt_qr` -> `qr_figure`
- `nM.la` -> `load_LAFigureSpecs()`
- `nM.ml` -> `load_matrixlayout()`

## Package Roles

The current stack has four package roles:

- `LATeachingSuite`
  Canonical Julia umbrella facade. This is the intended one-import entrypoint
  for teaching workflows, display helpers, Python bridge helpers, and
  umbrella-level bundle wrappers.
- `GenLAProblems`
  Canonical Julia problem-generation core. It owns matrix/problem generation
  and supporting matrix constructors.
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
