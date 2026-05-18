# Migration Checklist

This file records the decisions that should be made before, and during, the
stack refactor.

## Pre-Refactor Decision Checklist

### 1. Final User Entrypoints

Decide and treat as canonical:

- Python canonical import: `import LAFigureSpecs`
- Julia canonical import: `using LATeachingSuite`
- Julia core-only import remains allowed: `using GenLAProblems`

### 2. Long-Term Package Roles

Confirm the target roles:

- `matrixlayout`
  Internal Python layout/render engine.
- `LAFigureSpecs`
  Canonical Python algorithm/spec facade.
- `GenLAProblems`
  Julia problem-generation and math core.
- `LATeachingSuite`
  Julia umbrella facade for workflow/display/bridge use.

### 3. Migration Compatibility Policy

Decide and document:

- top-level capabilities must remain reachable during migration
- compatibility wrappers are allowed temporarily
- historical `nM.*` names do not need to be preserved once modern equivalents
  are documented
- whether moved Julia workflow names remain temporarily available from
  `GenLAProblems`

### 4. Notebook Migration Strategy

Decide:

- final intended notebook import: `using LATeachingSuite`
- gradual notebook migration vs one coordinated migration pass
- priority notebooks that must stay working throughout the migration

### 5. Priority Notebook Smoke Set

Maintain at least one representative notebook for each family:

- one GE/system notebook
- one QR notebook
- one eig/SVD notebook
- one matrix-layout display notebook
- one problem-generation notebook

### 6. Python/Julia Interoperability Contract

Explicitly decide which of the following are contractual:

- Python module/import names used by Julia
- keyword names/defaults used via PythonCall
- bundle keys and bundle structure
- spec dict field names used by Julia wrappers
- matrix extraction return shapes
- display/render helper semantics

### 7. `GenLAProblems` Ownership Boundary

Confirm which families remain in the core package long-term:

- problem generation
- reduction helpers
- QR/eigen/SVD generation
- exact arithmetic helpers
- optional symbolic helpers

### 8. `LATeachingSuite` Ownership Boundary

Confirm which families belong in the umbrella package long-term:

- `ShowGE`
- `show_*` workflow/display helpers
- `nM`
- Python bridge helpers
- `*_matrices_from_spec` / `*_matrices_from_grid`
- curated re-export of `GenLAProblems`

### 9. Testing Policy

Require green checks for:

- `matrixlayout`
- `LAFigureSpecs`
- `GenLAProblems.jl`
- `LATeachingSuite.jl`

Also decide:

- whether notebook smoke tests are required in CI
- whether Julia bridge tests are required per capability family

### 10. Release / Versioning Policy

Decide:

- one coordinated breaking-change wave vs staged releases
- whether temporary wrappers should emit deprecation warnings
- whether milestone tags/releases will be created after each migration phase

### 11. Documentation Source Of Truth

Keep the tracked architecture/source-of-truth docs here:

- `docs/architecture.md`
- `docs/migration.md`

### 12. Migration Tracking

Use this file to record:

- decisions made
- open questions
- completed migration slices
- compatibility wrappers still pending removal

## Recommended Defaults

If no contrary decision is made, use these defaults:

- canonical imports:
  - Python: `LAFigureSpecs`
  - Julia: `LATeachingSuite`
- migration style:
  - gradual
  - compatibility wrappers allowed
- historical `nM.*`:
  - not preserved once modern documented equivalents exist
- notebook strategy:
  - maintain a fixed representative smoke set
- interoperability contract:
  - preserve bundle keys, spec fields used by Julia, matrix extraction shapes,
    and display-helper semantics

## Decision Log

Fill this section in as decisions are finalized.

### Accepted

- `nM.*` need not be preserved once equivalent newer functionality exists.

### Open

- Should moved Julia workflow/display names remain temporarily re-exported from
  `GenLAProblems` after they are re-homed into `LATeachingSuite`?
- Will notebook migration be gradual or coordinated in one pass?
- Which exact notebooks constitute the required smoke set?
