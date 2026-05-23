# LATeachingSuite.jl

[![CI](https://github.com/ea42gh/LATeachingSuite.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ea42gh/LATeachingSuite.jl/actions/workflows/CI.yml)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/ea42gh/LATeachingSuite.jl/HEAD?filepath=LATeachingSuite_demo.ipynb)
[![Docs](https://img.shields.io/badge/docs-architecture-blue.svg)](https://github.com/ea42gh/LATeachingSuite.jl/blob/main/docs/architecture.md)

`LATeachingSuite` is the umbrella package for teaching-oriented linear algebra
workflows built on top of `GenLAProblems`.

It provides:

- the full `GenLAProblems` surface via re-export
- explicit top-level ownership of the canonical Julia GE/workflow surface:
  `ShowGE`, `ref!`, `show_layout!`, `show_system`,
  `show_backsubstitution!`, `show_solution!`
- matrix accessors for `ShowGE` workflows:
  `lhs_matrix`, `rhs_matrix`, `rhs_column`
- a curated `WorkflowDisplay` submodule for notebook/display helpers
- a curated `PythonBridge` submodule for PythonCall-backed integration helpers
- canonical umbrella bundle wrappers:
  `ge_bundle`, `qr_bundle`, `eig_bundle`, `svd_bundle`
- canonical matrix extraction helpers for bundle specs:
  `qr_matrices_from_spec`, `eig_matrices_from_spec`, `svd_matrices_from_spec`
- direct QR factor extractors for bundle specs:
  `q_factor_from_spec`, `r_factor_from_spec`
- semantic spec-query helpers:
  `eig_eigenvalues`, `svd_singular_values`,
  `svd_rank`, `eig_eigenvectors`, `svd_left_vectors`, `svd_right_vectors`
- canonical Julia render helpers:
  `ge_svg`, `qr_svg`, `eig_svg`, `svd_svg`
- canonical compute+render QR helper:
  `qr_figure`
- top-level umbrella bridge/display wrappers such as:
  `load_LAFigureSpecs`, `load_matrixlayout`, `show_svg`, `py_show_svg`

When you want both the rendered figure and the computed matrices, use the bundle
helpers and then extract matrices from the returned spec:

- `svg, qr_spec = qr_bundle(A)` then `qr_matrices_from_spec(qr_spec)`
- `svg, qr_mats = qr_figure(A)` then `qr_matrices_from_grid(qr_mats)`
- `svg, qr_spec = qr_bundle(A)` then `q_factor_from_spec(qr_spec)`,
  `r_factor_from_spec(qr_spec)` if you only need the final QR factors
- `svg, eig_spec = eig_bundle(A)` then `eig_matrices_from_spec(eig_spec)`
- `svg, svd_spec = svd_bundle(A)` then `svd_matrices_from_spec(svd_spec)`

Additional semantic queries are available on the same specs:

- `eig_eigenvalues(eig_spec)` returns `(multiplicity, λ)` pairs
- `eig_eigenvectors(eig_spec, λ)` returns the eigenvector group for eigenvalue `λ`
- `svd_singular_values(svd_spec)` returns `(multiplicity, σ)` pairs
- `svd_rank(svd_spec)` returns the rank implied by the nonzero singular values
- `svd_left_vectors(svd_spec, σ)` returns the left singular vector group for `σ`
- `svd_right_vectors(svd_spec, σ)` returns the right singular vector group for `σ`

For `ShowGE`, RHS data is organized as one or more RHS matrices:

- `ShowGE(A, B)` uses one RHS matrix `B`
- `ShowGE(A, (B1, B2, ...))` uses multiple RHS matrices
- `b_mat` selects which RHS matrix
- `b_col` selects a column within that RHS matrix

Use the accessors to inspect the selected matrices and columns:

- `lhs_matrix(pb; step=:final)`
- `rhs_matrix(pb, b_mat=1; step=:final)`
- `rhs_column(pb, b_mat=1, b_col=1; step=:final)`
- `solutions(pb; b_mat=1, b_col=nothing)`

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
LATeachingSuite / PythonBridge -> LAFigureSpecs -> matrixlayout
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
of package responsibilities and interoperability expectations.
