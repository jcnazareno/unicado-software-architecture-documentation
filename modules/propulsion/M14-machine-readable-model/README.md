# M14 — Machine-readable model

The recovered baseline architecture of `propulsion_design` is stored in three machine-readable formats for version control, automated analysis, and diagram rendering:

| File / Artifact | Format | Use |
|---|---|---|
| [`propulsion_design.model.yaml`](propulsion_design.model.yaml) | YAML | Single source of truth for scripts: CI file-completeness checks, documentation generators, and dependency analysis |
| [`workspace.dsl`](workspace.dsl) | Structurizr DSL (C4) | Renders the C4 Level 1 (Context), Level 2 (Container), and Level 3 (Component) views with Structurizr Lite or Structurizr CLI |
| **C4 Level 4 (Code Level) & Build XML Models (`*.drawio`)**:<br>• [`../M5-dependencies/PropulsionDesign_CMake.drawio`](../M5-dependencies/PropulsionDesign_CMake.drawio)<br>• [`../M7-runtime/PropulsionDesign_MainCPP.drawio`](../M7-runtime/PropulsionDesign_MainCPP.drawio)<br>• [`../M7-runtime/PropulsionDesign_Initialize.drawio`](../M7-runtime/PropulsionDesign_Initialize.drawio)<br>• [`../M7-runtime/PropulsionDesign_Run.drawio`](../M7-runtime/PropulsionDesign_Run.drawio)<br>• [`../M7-runtime/PropulsionDesign_Update.drawio`](../M7-runtime/PropulsionDesign_Update.drawio)<br>• [`../M7-runtime/PropulsionDesign_Report.drawio`](../M7-runtime/PropulsionDesign_Report.drawio)<br>• [`../M7-runtime/PropulsionDesign_Save.drawio`](../M7-runtime/PropulsionDesign_Save.drawio) | draw.io XML (`mxfile`) | Machine-readable XML representations of the static build/dependency graph and C4 Level 4 (Code Level, Depth Levels 0–4) execution and data-flow diagrams |

## Render the C4 Structurizr diagrams

```bash
docker run -it --rm -p 8080:8080 -v "$PWD":/usr/local/structurizr structurizr/lite
# open http://localhost:8080
```

## Check source-code traceability in CI (sketch)

```python
import yaml, pathlib
model = yaml.safe_load(open("propulsion_design.model.yaml"))
src = pathlib.Path("aircraft-design/propulsion_design/src")
listed = {f for c in model["components"] for f in c.get("files", [])}
actual = {str(p.relative_to(src)) for p in src.rglob("*") if p.suffix in {".h", ".cpp"}}
missing, stale = actual - listed, listed - actual
assert not missing and not stale, f"unlisted: {missing}, stale: {stale}"
```

Keep the YAML, Structurizr DSL, and `.drawio` XML models in sync with the Markdown sections (`M1–M7`, `M9`, `M12`).
