# M12 — Risks and technical debt

Severity: **H** = wrong results, silent failures, or blocked users/maintainers; **M** = slows development, increases fragility, or limits studies; **L** = cosmetic or documentation inconsistency.

---

## 1. Technical Debt Record: Implicit Module Interfaces and Hard-Coded Strategy Selection

### Summary
The `aircraft_design` modules have clear phase boundaries (`initialize`, `run`, `update`, `report`, `save`), but they have no formal input/output contracts. Calculation code reads XML directly, and `propulsion_design` selects its strategies with `if/else` chains instead of the framework's registry.
**Status:** Partially addressed (the debt is now visible in the recovered baseline architecture, not yet resolved in source code).

### Debt item 1: XML reads inside calculation code (Severity: H)
- **Description:** Calculation functions fetch values by path from the module configuration XML or `acXML` during execution, instead of receiving typed input arguments.
- **Evidence:**
  - `energy_based.cpp:132-205`: `EnergyBased::operator()()` mixes config reads, `acXML` reads, directory scanning, object construction, and calculation in one function.
  - `propulsion_design` stages read user settings directly from `configuration()`:
    - `engine_design.h:108-112`
    - `mass_analysis.h:72-74`
    - `default_integration.h:212-215`
    - `rubber_design.cpp:65`
  - `engine_mass` is read in two stages (`EngineDesigner` and `MassAnalyzer`), and `Rubber` re-reads `engine_efficiency` from the XML although the base class already stores it.
  - `EngineData` returns `0.0` for a missing node (test `ReadMissingValue`), so wrong input can pass silently.
- **Impact:**
  - The real inputs of a function are visible only by inspecting its body.
  - A calculation cannot be unit-tested without constructing a valid XML tree.
  - A schema or XML node rename breaks calculation code at run time.
  - Calculations cannot be reused with another input source (optimizer, Python API, batch studies).
  - Duplicated XML reads across strategies can drift apart.
- **Required Modification (from Requirement R2):**
  - Refactor submodules to establish formal data interface contracts (standardized typed input/output parameters), completely separating configuration/exchange XML reading functions from engineering mathematical calculation functions.

### Debt item 2: Strategy selection bypasses the framework registry in `propulsion_design` (Severity: M/H)
- **Description:** The UNICADO framework provides `StrategySelector` (`strategySelector.h`) for path-based strategy registration. `propulsion_design` implements the `Strategy` interface (`PropulsionStrategy : public Strategy`) but selects its five discipline strategies with `if (method == "...") ... else throw` chains in `propulsion_design.cpp:242-346` (`select_engine_designer()`, `select_propulsion_integrator()`, `select_nacelle_designer()`, `select_pylon_designer()`, `select_mass_analyzer()`).
- **Contributing causes:**
  - Strategy constructors are not uniform (different arguments per class: e.g., `Rubber` takes `XML`, `EngineDataDir`, and `FlightCondition`; `integration::Default` takes `XML`, `AircraftGeometry`, and `EngineCount`), so a generic factory cannot instantiate them uniformly.
  - `PropulsionStrategy` takes the configuration `std::shared_ptr<node>`, not `RuntimeIO`, which is what `registerStrategy<S>()` expects.
  - Five cooperating discipline stages do not fit the selector's one-strategy-per-module design.
- **Impact:**
  - Adding a new method requires editing the module core (`propulsion_design.cpp`) and adding a conditional branch with custom constructor wiring.
  - New configuration keys are named after the method (`.../Rubber/...`), so the XML schema changes as well.
  - All contributors edit the same selection functions, increasing merge-conflict risk.
  - Unsupported method names fail only at run time.
  - Current state: one branch per stage (`Rubber` / `Default`), so the cost is latent and compounds as soon as a second fidelity method is added.
- **Required Modification (from Requirement R3):**
  - Develop standardized extension templates (uniform abstract base interfaces and Markdown developer integration guides) and refactor central strategy selection logic to support modular plug-and-play registration.

---

## 2. Architectural & Documentation Debts Exposed by Stakeholder Gap Analysis (Table 5.4.1)

| ID | Related Req. | Technical / Documentation Debt | Severity | Observed Gap | Required Modification |
|---|---|---|---|---|---|
| D11 | R1 | Isolated multi-file C4 diagrams without interactive cross-file linkage | L | C1–C4 diagrams exist as separate files in the repository (e.g., clicking `initialize()` in `PropulsionDesign_MainCPP.drawio` does not automatically open `PropulsionDesign_Initialize.drawio`) | Link generated diagrams across levels and enforce a "docs-as-code" policy requiring co-located diagram updates during merge requests |
| D12 | R4 | Absence of automated "docs-as-code" governance | M | While diagrams are now co-located in the repository, there is no automated CI governance enforcing synchronization when C++ source files change | Adopt a "docs-as-code" review requirement in GitLab merge requests so C++ changes and architecture diagrams are updated together |
| D13 | R5 | Implicit mapping between C++ variable names and aircraft design theory equations | M | Execution flows and subroutines are documented, but the mapping between code variables and textbook sizing equations remains implicit for students and new researchers | Supplement visual diagrams with parameter reference guides linking code variables directly to aircraft design theory definitions |
| D14 | R6 | Unstandardized build environments and missing CI build/regression validation | H | Frequent runtime and build errors due to library version drift, conflicting local Python/CMake setups, and lack of automated regression checks | Establish standardized build configuration templates (e.g., CMake presets) and automated compilation and CSR-02 regression validation in CI |
| D15 | — | Duplicate source file names across all five discipline subfolders | L | `turbofan.cpp` and `openrotorfan.cpp` each appear five times (`engine_design/rubber/`, `nacelle/default/`, `pylon/default/`, `integration/default/`, `mass/default/`), hindering IDE navigation | Prefix implementation files by discipline (e.g., `rubber_turbofan.cpp`, `nacelle_turbofan.cpp`, `mass_turbofan.cpp`) |

---

## 3. Domain & Implementation Risks and Legacy Documentation Debts

### Risks

| ID | Risk | Severity | Evidence | Mitigation |
|---|---|---|---|---|
| R1 | Hydrogen turbofan (`Turbofan<Liquid_Hydrogen>`) is selectable but untested | H | Status marked `"To be tested"` in docs; `Rubber::operator()` only checks `engine_data.type() != "turbofan"` | Add a dedicated LH2 regression test case and log an explicit validation warning when selected |
| R2 | Turboprops (`Turboprop<Kerosene/Liquid_Hydrogen>`) are instantiated by `utility::create_engine()` but have no strategy implementations | H | `turbofan.cpp` and `openrotorfan.cpp` exist in all 5 disciplines, but no `turboprop.cpp` exists | Fail early with an explicit error message or implement turboprop discipline methods |
| R3 | Adding a powertrain or energy carrier requires touching every discipline strategy (combinatorial growth) | M | `PropulsionStrategy` requires a separate `operator()` overload for every `Propulsion<EnergyCarrier>` variant | Provide default base overloads that throw a descriptive `"not implemented for <variant>"` error |
| R4 | Rubber engine scaling loses physical validity far from the reference engine thrust | M | Fixed scaling exponents ($1.0, 0.5, 0.4, 1.1$) and constant base TSFC; reference SLST is evaluated near $N_1 \approx 0.95$ | Document valid scale-factor bounds and emit a warning when `SF` falls outside validated limits (e.g., `0.6–1.6`) |
| R5 | Engines are sized independently without aerodynamic/acoustic interference modeling | M | `PropulsionDesign::run()` sizes each propulsor independently in sequence | Document limitation; spanwise collision checks exist only for `Wing` and `WingBody` |
| R6 | Changing the `acXML` output structure breaks downstream tools silently | H | Downstream consumers read `/aircraft_exchange_file/component_design/propulsion` directly by XML path | Maintain schema version adapters in `io::AircraftXML` and validate `acXML` schemas in CI |

### Legacy Documentation & Codebase Inconsistencies

| ID | Debt | Severity | Evidence |
|---|---|---|---|
| D1 | `Empirical` and `PropulsionSystem` engine design methods are documented as planned but not implemented | M | `select_engine_designer()` only accepts `"Rubber"` |
| D2 | User documentation contradicts itself on available engine methods | L | *Getting Started* lists `"Empirical with BPR, Rubber, GasTurb"`; *Engineering Principles* and `select_engine_designer()` only support `"Rubber"` |
| D3 | Shaft power off-take input node path is duplicated under the bleed air node name in legacy user docs | L | *Getting Started* documentation vs. `create_propulsors()` (`bleed_air` and `power_demand`) |
| D4 | Doxygen / API reference copy-paste errors | L | `generate_empty_deck_data` documents parameters of `scale_deck_data_values`; `insert(Openrotorfan)` is described as turboprop; `PropulsionStrategy` constructor documents a non-existent `settings` parameter |
| D5 | `Openrotorfan<Kerosene>` and `Parent::WingBody` are implemented in C++ code but omitted from user manuals | L | Implemented in `utility::create_engine()`, `openrotorfan.cpp` across all 5 disciplines, and `integrate_into_wing_body()` |
| D8 | Simplified nacelle geometry (zero wall thickness, no short vs. long duct distinction) | L | *Engineering Principles* and `nacelle::Default` |
| D9 | Legacy docs state `inkscape_path` is required for plots, whereas code uses `Matplot++` + `gnuplot` to export SVGs directly | L | `create_plots.cpp` and `PropulsionDesign_CMake.drawio` |
| D10 | Most public lifecycle functions lack Doxygen API descriptions | L | API reference |
