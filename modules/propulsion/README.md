# propulsion_design — architecture documentation

Architecture documentation for the UNICADO **propulsion_design** sizing tool (v3.0.0).
It follows a standardized module template combining **arc42** and the **C4 model** (Context, Container, Component, and a 5-tier Code Level hierarchy from Depth Level 0 to Level 4).

| # | Section | Standard | What it answers |
|---|---------|----------|-----------------|
| M1 | [Context](M1-context/README.md) | C4 (Context Level) | Who and what does the module talk to? |
| M2 | [Components](M2-components/README.md) | C4 (Component Level) | Which building blocks is it made of? |
| M3 | [Responsibilities](M3-responsibilities/README.md) | arc42 | Which block is responsible for what? |
| M4 | [Interfaces](M4-interfaces/README.md) | C4 (General) / arc42 | Which files, XML nodes and APIs does it read and write? |
| M5 | [Dependencies](M5-dependencies/README.md) | C4 (Code Level) | Which libraries, headers and build targets does it need? |
| M6 | [Data flow](M6-data-flow/README.md) | C4 (Code Level) | How do data move and transform from input to output? |
| M7 | [Runtime](M7-runtime/README.md) | C4 (Code Level) | What happens, in which order, when it runs (Levels 0–4)? |
| M9 | [Configuration](M9-configuration/README.md) | arc42 | What can users set, and where? |
| M12 | [Risks and technical debt](M12-risks-technical-debt/README.md) | arc42 | What is fragile, unfinished, or architecturally coupled? |
| M14 | [Machine-readable model](M14-machine-readable-model/README.md) | C4 (Code Level) / YAML / DSL / XML | The architecture in YAML, Structurizr DSL, and draw.io XML formats |

## How to read the markers

- **Documented**: taken from the official `propulsion_design` documentation or API reference.
- **Verified (Code Recovery)**: recovered and validated directly against the C++ source code and `CMakeLists.txt` via static code analysis and developer walkthroughs.
- **TODO**: information that neither the public documentation nor the `propulsion_design` repository alone specifies (e.g., full downstream consumer list across external repositories).

## Sources

- [Introduction](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/documentation/sizing/propulsion_design/)
- [Overview](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/documentation/sizing/propulsion_design/overview/)
- [Getting started](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/documentation/sizing/propulsion_design/getting-started/)
- [Engineering principles](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/documentation/sizing/propulsion_design/engineering_principles/)
- [Software architecture](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/documentation/sizing/propulsion_design/software_architecture/)
- [Changelog](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/documentation/sizing/propulsion_design/changelog/)
- [API reference: classes](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/propulsion_design/classes/), [files](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/propulsion_design/files/), [namespaces](https://unicado.pages.rwth-aachen.de/unicado.gitlab.io/propulsion_design/namespaces/)

Status: baseline architecture recovered and validated against the `propulsion_design` C++ source code (November 2026).
