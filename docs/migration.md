# Package Boundaries

This file records the current package boundaries for the teaching-oriented
linear algebra stack.

## Canonical entrypoints

- Python: `import LAFigureSpecs`
- Julia teaching workflows: `using LATeachingSuite`
- Julia generation-only use: `using GenLAProblems`

## Package roles

- `matrixlayout`
  Internal Python layout/render engine.
- `LAFigureSpecs`
  Canonical Python algorithm/spec facade.
- `GenLAProblems`
  Julia problem-generation core.
- `LATeachingSuite`
  Julia umbrella facade for workflow, display, and Python-bridge access.

## Julia surface ownership

`LATeachingSuite` owns:

- `ShowGE`
- `lhs_matrix`, `rhs_matrix`, `rhs_column`
- reduction helpers
- workflow/display helpers
- bundle wrappers
- `ge_svg`, `qr_svg`, `eig_svg`, `svd_svg`
- `qr_matrices_from_spec`
- `q_factor_from_spec`
- `r_factor_from_spec`
- `eig_matrices_from_spec`
- `svd_matrices_from_spec`
- curated Python bridge helpers

`GenLAProblems` owns:

- matrix/problem generators
- supporting matrix constructors used by those generators
- exact arithmetic helpers that directly support generation

## Compatibility notes

- The removed `nM.*` compatibility surface is no longer available.
- Prefer `ge_bundle`, `qr_bundle`, `eig_bundle`, `svd_bundle`,
  `qr_matrices_from_spec`, `qr_matrices_from_grid`,
  `q_factor_from_spec`, `r_factor_from_spec`,
  `eig_matrices_from_spec`, `svd_matrices_from_spec`,
  `ge_svg`, `qr_svg`, `eig_svg`, and `svd_svg` for Julia teaching code.
- Prefer `load_LAFigureSpecs()` and `load_matrixlayout()` over direct access to
  Python implementation modules.
