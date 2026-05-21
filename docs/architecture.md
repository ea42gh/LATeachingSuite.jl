# Architecture

`LATeachingSuite` is the umbrella package for the teaching-oriented linear
algebra stack in this monorepo.

This document records the roles of the packages and their interrelationships.

## Layer Overview

The stack is organized into four layers:

1. `matrixlayout`
   Internal Python layout/render engine.

2. `LAFigureSpecs`
   Canonical Python algorithm/spec facade on top of `matrixlayout`.

3. `GenLAProblems`
   Canonical Julia problem-generation core.

4. `LATeachingSuite`
   Canonical Julia umbrella facade.

## Responsibilities

### `matrixlayout`

Owns:

- layout-only spec handling
- TeX generation
- SVG rendering boundary
- formatting/decorator helpers

Does not own:

- linear algebra algorithms
- Julia workflow state
- pedagogical problem generation

### `LAFigureSpecs`

Owns:

- GE / QR / eigen / SVD algorithmic spec construction
- top-level Python convenience APIs
- Python-facing rendering helpers for the teaching stack

Role:

- canonical Python import for the teaching figure layer
- direct client of `matrixlayout`

### `GenLAProblems`

Owns:

- matrix/problem generation
- supporting matrix constructors used by those generators
- exact arithmetic and math-first utilities that directly support generation

Role:

- canonical Julia generation package
- should avoid workflow/display and reduction-algorithm ownership

### `LATeachingSuite`

Owns:

- one-import Julia convenience facade
- reduction helpers
- workflow/display helpers
- top-level Julia ownership of `ShowGE` and related GE workflow helpers
- `ShowGE` matrix/column accessors:
  `lhs_matrix`, `rhs_matrix`, `rhs_column`
- curated Python bridge access
- umbrella-level bundle wrappers:
  `ge_bundle`, `qr_bundle`, `eig_bundle`, `svd_bundle`
- canonical Julia render helpers:
  `ge_svg`, `qr_svg`, `eig_svg`, `svd_svg`
- canonical compute+render QR helper:
  `qr_figure`
- re-export of `GenLAProblems`

Role:

- canonical Julia user-facing package for teaching workflows
- canonical home for curated Julia access to Python bundle-style helpers
- canonical top-level and source-level home for the GE workflow/display entry
  points

## Dependency Diagram

The intended dependency structure is:

```text
LATeachingSuite
  -> GenLAProblems
  -> LAFigureSpecs
       -> matrixlayout
```

For Python-backed Julia display workflows, the effective interoperability path
is:

```text
LATeachingSuite / PythonBridge -> LAFigureSpecs -> matrixlayout
```

## User Entry Points

Preferred imports:

- Julia general use: `using LATeachingSuite`
- Julia generation-only use: `using GenLAProblems`
- Python use: `import LAFigureSpecs`

Preferred bundle-style Julia entry points:

- `LATeachingSuite.ge_bundle`
- `LATeachingSuite.qr_bundle`
- `LATeachingSuite.eig_bundle`
- `LATeachingSuite.svd_bundle`
- `LATeachingSuite.qr_matrices_from_spec`
- `LATeachingSuite.q_factor_from_spec`
- `LATeachingSuite.r_factor_from_spec`
- `LATeachingSuite.eig_matrices_from_spec`
- `LATeachingSuite.svd_matrices_from_spec`
- `LATeachingSuite.eig_svg`
- `LATeachingSuite.svd_svg`

Non-preferred but still useful:

- `matrixlayout` as a direct renderer/spec engine

## Interoperability

Python/Julia interoperability is part of the product surface, not just an
implementation detail.

Julia wrappers rely on:

- Python module/import paths used from Julia
- keyword names and defaults used through PythonCall
- return shapes for specs, bundles, and extracted matrix helpers
- display/render semantics relied on by Julia wrappers

For canonical top-level teaching/display capabilities:

- require capability parity between `LATeachingSuite` and `LAFigureSpecs`
- when the same capability is intentionally offered in both languages, require
  name parity as well

## Compatibility Surfaces

The legacy `nM.*` compatibility layer has been removed. Prefer the canonical
top-level APIs:

- `ge_bundle`, `qr_bundle`, `eig_bundle`, `svd_bundle`
- `qr_matrices_from_spec`, `qr_matrices_from_grid`,
  `q_factor_from_spec`, `r_factor_from_spec`,
  `eig_matrices_from_spec`, `svd_matrices_from_spec`
- `ge_svg`, `qr_svg`, `eig_svg`, `svd_svg`
- `load_LAFigureSpecs()`, `load_matrixlayout()`
