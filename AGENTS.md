# LATeachingSuite.jl Notes

## Role

`LATeachingSuite` is the canonical Julia umbrella package for the teaching
stack.

It should provide:

- one-import access to the normal Julia user workflow
- re-export of the supported `GenLAProblems` core surface
- workflow/display helpers
- Python bridge helpers that reach `LAFigureSpecs` and `matrixlayout`
- umbrella-owned bundle wrappers such as:
  `ge_bundle`, `qr_bundle`, `eig_bundle`, `svd_bundle`
- top-level ownership of the canonical Julia GE/workflow entry points such as
  `ShowGE`, `ref!`, `show_layout!`, `show_system`, and the backsub/solution
  helpers, even if they delegate internally to `GenLAProblems`
- canonical modern replacements for legacy `nM` render helpers such as
  `ge_svg`, `qr_svg`, `eig_svg`, `svd_svg`

## Package Relationships

The intended stack is:

- `LATeachingSuite` -> `GenLAProblems`
- `LATeachingSuite` -> `GenLAProblems` / Python bridge -> `LAFigureSpecs`
- `LAFigureSpecs` -> `matrixlayout`

Maintain Python/Julia interoperability across any migration slice that touches
the umbrella surface.

For canonical top-level teaching/display capabilities:

- require capability parity between the Julia umbrella surface and the Python
  facade
- when the same capability is intentionally exposed in both languages, require
  name parity as well

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

## Documentation Task

For any migration or refactor slice that changes behavior, API shape, package
roles, examples, or tests, update all relevant documentation files in the same
slice.

This includes, as applicable:

- `README.md`
- `docs/architecture.md`
- `docs/migration.md`
- Binder/demo notebooks and their instructions
- package-local comments or examples that describe public behavior

Do not leave code and documentation intentionally out of sync between slices.

## Unit Test Task

For any migration or refactor slice that changes behavior, API shape, package
roles, examples, or compatibility wrappers, update the relevant unit tests in
the same slice.

This means:

- update existing tests when intended behavior changes
- add characterization tests when behavior is supposed to stay the same
- add tests for new canonical umbrella wrappers or bridge entry points
- keep Julia/Python interop tests aligned with any touched bridge behavior

Do not leave code changes waiting on a later test-only cleanup pass.

## Migration Direction

Prefer moving integration-facing workflow/display and bridge ownership toward
`LATeachingSuite` while preserving current top-level capabilities for users.

For bundle-style Julia access to Python figure helpers:

- prefer umbrella-owned names without `_tbl`, e.g. `ge_bundle`
- do not restore those bundle helpers as part of the intended
  `GenLAProblems` core surface
- treat `nM.*` as deprecated compatibility surface and prefer explicit
  umbrella names for GE/QR rendering and bundle access
- when replacing legacy `nM` helpers, prefer direct `*_svg` umbrella helpers
  for SVG-only workflows and `*_bundle` wrappers only when the spec payload
  is also needed
