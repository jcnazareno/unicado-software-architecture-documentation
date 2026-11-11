# M9 — Configuration

## Files

| File | Owner | Purpose |
|---|---|---|
| `propulsion_design_conf.xml` | User / workflow | Control settings (`moduleBasics::RuntimeIO`) and program settings of the tool |
| `acXML` (`design_specification/propulsion` & `energy_carriers`) | Aircraft designer | Propulsor architecture, energy carriers, parent components, positions, and thrust shares |
| Engine database (`path_engine_database`) | UNICADO package | Reference engine XML datasets and CSV decks |
| Nacelle and pylon profile `.dat` files (`getGeometryDir()`) | Configuration / geometry data | Cross-section polygon and airfoil contour profiles |

## Control settings (`moduleBasics::RuntimeIO`) *(Documented / Verified)*

| Setting | Meaning | Implementation Notes |
|---|---|---|
| `aircraft_exchange_file_name` | Target `acXML` file name | Opened via `aixml` and `get_RuntimeIO()` |
| `aircraft_exchange_file_directory` | Directory containing the `acXML` | Output directory for reports |
| `console_output` | Console logging verbosity | At least `mode_1`; used by `utility::print()` |
| `report_output` (`get_RuntimeIO()->reportOn`) | Generate HTML report (`propulsion_design_report.html`) | Checked in `PropulsionDesign::report()` before calling `create_html_report()` |
| `xml_output` (`get_RuntimeIO()->xmlOn`) | Generate XML report (`propulsion_design_results.xml`) | Checked in `PropulsionDesign::report()` before calling `create_xml_report()` |
| `plot_output` (`get_RuntimeIO()->plotOn`) | Generate SVG plots (bucket curves, top overview, nacelle views) | Checked in `PropulsionDesign::report()` and `create_html_report()`. Uses **`Matplot++`** (invoking `gnuplot` backend via pipe) and internal SVG builders in `create_plots.cpp` *(Note: Inkscape is not used by `propulsion_design`)* |
| `gnuplot_path` | Path to `gnuplot` executable | Used by `moduleBasics` / `Matplot++` when `plot_output` is enabled |

## Program settings (`propulsion_design_conf.xml`) *(Documented / Verified)*

| Setting | Allowed Values | Code-Verified Behavior |
|---|---|---|
| `path_engine_database` | Directory path | Read in `EngineDesigner::initialize()`; searched by `io::load_engine_data()` and `Rubber::select_engine()` |
| Design flight condition (`Mach`, `Altitude`, `ISA`) | Numeric values (e.g., FL350, Mach 0.78, ISA 0 K) | Read via `EndnodeReadOnly` in `get_design_condition()` (`select_engine_designer()`) and used to initialize an `atmosphere` object in `FlightCondition` |
| Engine designer method | `Rubber` (implemented) | Checked in `select_engine_designer()`; any value other than `"Rubber"` throws `std::runtime_error("Engine designer method is not supported")`. *(Note: user docs inconsistently mention `Empirical`, `PropulsionSystem`, `GasTurb`, and `Empirical with BPR`, which are not implemented in code)* |
| Propulsion integrator method | `Default` (implemented) | Checked in `select_propulsion_integrator()`; any other value throws `std::runtime_error("Propulsion integrator method is not supported")` |
| Nacelle designer method | `Default` (implemented) | Checked in `select_nacelle_designer()`; any other value throws `std::runtime_error("Nacelle designer method is not supported")` |
| Pylon designer method | `Default` (implemented) | Checked in `select_pylon_designer()`; any other value throws `std::runtime_error("Pylon designer method is not supported")` |
| Mass analyzer method | `Default` (implemented) | Checked in `select_mass_analyzer()`; any other value throws `std::runtime_error("Mass analyzer method is not supported")` |
| Technology factors | `engine_mass`, `nacelle_mass`, `pylon_mass`, `engine_efficiency` | `engine_mass` and `engine_efficiency` are read in `EngineDesigner::initialize()`; `engine_mass`, `nacelle_mass`, and `pylon_mass` are read in `MassAnalyzer::initialize()`. In `Rubber::initialize()`, if `abs(xml_eff - config_eff) > 1e-6`, a mismatch warning is logged and the combined efficiency factor `1 + (1 - efficiency_factor)` scales the CSV decks |
| Wing name for engine mounting (`name_wing_engines/value`) | String (wing surface name) | Read in `integration::Default::select_wing()` when `wings.size() != 1` to rotate the target wing to the front; logs `"Warning: Taking first wing"` if not found |
| Engine position shifts (`usershift_x`, `usershift_y`, `usershift_z`) | Numeric offsets `[m]` | Read in `calculate_user_shift()` (`integrate_into_wing()`, `integrate_into_fuselage()`, and inline in `integrate_into_wing_body()`) to shift calculated engine coordinates (`position.x += usershift_x`, `position.y += usershift_z`, `position.z -= usershift_y`) |
| `propulsion (ID="Default")` / `propulsion (ID="n")` | `engine_model`, `nacelle/profile/value`, `pylon/profile/value` | `nacelle_designer->initialize()` and `pylon_designer->initialize()` normalize `ID` and profile strings to lowercase via `std::transform`: `ID == "default"` maps to index `-1` (`section_shapes(-1)` / `section_profiles(-1)`), while numeric `ID`s are parsed with `std::stoi(ID)` to override individual propulsors. In `Rubber::initialize()`, if `engine_model` is provided, it is stored in `preselected_engines_`; otherwise `Rubber::select_engine()` automatically selects the database engine with minimum `|SLST - required_thrust|` |
| Nacelle & pylon profile names (`nacelle/profile/value`, `pylon/profile/value`) | `.dat` profile name or ellipse (`propulsion_design/test/stubs` for dummy run) | Loaded from `getGeometryDir()` via `geom2::io::read_dat_file` in `get_section_shape()` and `get_section_profile()` |

## Architecture definition in the `acXML` *(Documented / Verified)*

Per propulsor in `/aircraft_exchange_file/requirements_and_specifications/design_specification/propulsion`:
- `powertrain` and `type`: Concatenated in `utility::create_engine()` (`power_type + thrust_type`) to match `turbofan`, `turboprop`, or `openrotorfan`. Any other string throws `std::runtime_error("Powertrain is not supported")`.
- `energy_carrier_ID`: Mapped via `utility::create_energy_carrier_map()` to `EnergyCarrier::Kerosene` (`"kerosene"`) or `EnergyCarrier::Liquid_Hydrogen` (`"liquid_hydrogen"`). Any other value throws `std::runtime_error("Energy carrier is not supported")`.
- `thrust_share`: Fraction of total required thrust assigned to the propulsor (validated in `check_validity()` so total thrust matches within `10.0 N` and lateral yaw moment is within `10.0 Nm`).
- `position`: Mapped via `utility::get_parent_component()` from `parent_component`, `x`, `y`, and `z` strings to `Parent`, `Longitudinal`, `Lateral`, and `Vertical` enums.

### Implemented parent component & position combinations *(Verified in Code Recovery)*

| Parent (`Parent` enum) | `y` (Lateral) | `x` (Longitudinal) | `z` (Vertical) | Implementation & Constraints in `integration::Default` & `pylon::Default` |
|---|---|---|---|---|
| `Wing` (`Parent::Wing`) | `left` / `right` | `front` | `under` or `over` | `integrate_into_wing()`: Requires wing oriented in Y-direction and `2` or `4` wing engines (`n_engines_.wing`); places inner engines first, then outer engines (`parents_placed` check); builds wing pylon attachment points |
| `WingBody` (`Parent::WingBody`, BWB) | `left` / `right` | `front` / `back` | `over` | `integrate_into_wing_body()`: Requires vertical position `Over`, Y-oriented wing, and symmetrical empennage; checks empennage span collision bounds (`no_placement`) for `1` or `2` engines; builds wing-body pylon attachment points |
| `Fuselage` (`Parent::Fuselage`) | `left` / `right` | `rear` (`back`) | `mid` | `integrate_into_fuselage()`: Requires X-oriented fuselage and exactly `2` fuselage engines (`n_engines_.fuselage == 2`); builds left/right fuselage pylon attachment points |
| `Empennage` (`Parent::Empennage`) | `mid` | `front` | `in` | `integrate_into_empennage()`: Finds vertical tail via `geometry::is_vertical`, checks alignment with fuselage centerline, and places `1` engine based on vertical tail MAC and fuselage height; returns empty pylon attachment points `{}` (no pylon built) |

**Behavior on unsupported combinations or missing geometry:**
- If `engine.parent_component()` is not in `detail::supported_parents`, both `integration::Default::operator()` and `pylon::Default::get_attachment_points()` throw `std::runtime_error("Parent component not supported")`.
- If airframe geometry is missing (`this->aircraft()` is `nullptr`), `integration::Default::operator()` falls back to `this->guess_position()`, setting the engine position to `CGAL::ORIGIN` `(0, 0, 0)`.

## Supported engine types *(Documented / Verified)*

| Engine Variant (`PropulsionType`) | Energy Carrier | Strategy Implementation Status | Notes |
|---|---|---|---|
| `Turbofan<Kerosene>` | Kerosene | Implemented & running (`Rubber` + `Default` across all 5 disciplines) | Reference engine e.g. `V2527-A5`; explicit `turbofan.cpp` in all 5 strategy folders |
| `Turbofan<Liquid_Hydrogen>` | Liquid Hydrogen | Implemented in `Turbofan` overloads (`Rubber` checks `engine_data.type() != "turbofan"`) | Reference engine e.g. `V2527-H2`; marked *"To be tested"* in user docs |
| `Openrotorfan<Kerosene>` | Kerosene | Implemented in code (`openrotorfan.cpp` in all 5 strategy folders) | Instantiated in `utility::create_engine()`, but undocumented in user-facing manuals |
| `Turboprop<Kerosene>` | Kerosene | Struct & `operator()` overloads declared, but **no `turboprop.cpp` methods implemented** | Selectable in `utility::create_engine()`, but discipline methods are missing (see [M12](../M12-risks-technical-debt/README.md)) |
| `Turboprop<Liquid_Hydrogen>` | Liquid Hydrogen | Struct & `operator()` overloads declared, but **no `turboprop.cpp` methods implemented** | Selectable in `utility::create_engine()`, but discipline methods are missing (see [M12](../M12-risks-technical-debt/README.md)) |

## Illustrative `propulsion_design_conf.xml` structure

```xml
<module_configuration_file name="propulsion_design_conf.xml">
  <control_settings>
    <aircraft_exchange_file_name>
      <value>csr-02.xml</value>
    </aircraft_exchange_file_name>
    <aircraft_exchange_file_directory>
      <value>../projects/CSR/CSR-02/</value>
    </aircraft_exchange_file_directory>
    <console_output>
      <value>mode_1</value>
    </console_output>
    <plot_output enable="true">
      <gnuplot_path>
        <value>/usr/bin/gnuplot</value>
      </gnuplot_path>
    </plot_output>
  </control_settings>
  <program_settings>
    <path_engine_database>
      <value>../engine_data/</value>
    </path_engine_database>
    <!-- Design flight condition (Mach, Altitude, ISA), discipline method names (Rubber, Default),
         technology_factors (engine_mass, nacelle_mass, pylon_mass, engine_efficiency),
         name_wing_engines, and propulsion ID="Default" / ID="n" overrides (engine_model,
         nacelle/profile, pylon/profile, usershift_x, usershift_y, usershift_z) -->
  </program_settings>
</module_configuration_file>
```
