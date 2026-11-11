workspace "UNICADO propulsion_design" "C4 model of the propulsion_design sizing tool (v3.0.0)" {

    model {
        designer = person "Aircraft Designer" "Configures propulsion architecture, design methods, and technology factors."

        unicado = softwareSystem "UNICADO" "Conceptual aircraft design environment." {
            loop = container "Aircraft Design Loop" "Executes the sizing tool iteratively after upstream sizing modules." "RCE Workflow"
            upstream = container "Upstream Sizing Tools" "Initial sizing, constraint analysis, mass estimation, systems design." "C++ Tools"
            downstream = container "Downstream Sizing Tools" "Aerodynamics, Weight & Balance, and Mission Analysis consuming propulsion data." "C++ Tools"
            acxml = container "Aircraft Exchange File" "Central shared aircraft data model across all UNICADO sizing tools." "acXML" "File"
            engineDb = container "Engine Database" "Repository of unscaled reference engine decks (e.g., V2527-A5)." "engineXML & CSV" "File"
            geomData = container "Geometry & Airfoil Data" "Airfoil and polygon cross-section profiles for airframe, nacelles & pylons." ".dat Files" "File"

            pd = container "propulsion_design" "Coordinator (PropulsionDesign : public Module). Sizes engines, nacelles, and pylons; integrates them onto the airframe; calculates propulsion masses & performance." "C++20 Executable Binary" {
                coordinator = component "PropulsionDesign Coordinator" "Inherits Module: orchestrates initialize(), run(), update(), report(), and save(). Builds airframe geometry, creates/sorts propulsors, dispatches strategies via std::visit, checks validity." "C++ Class (propulsion_design.h/.cpp)"
                strategyBase = component "PropulsionStrategy & Domain Model" "Defines PropulsionStrategy base interface, Propulsion<Carrier> hierarchy (Turbofan, Turboprop, Openrotorfan), PropulsionType std::variant, PointMass, and geometry::Aircraft." "propulsion_strategy.h, propulsion.h, utility.h"
                engineDesigner = component "1. EngineDesigner Strategy" "Selects optimal engine or scales preselected deck; searches N1 bucket point; writes scaled CSV decks." "src/engine_design/ (design::Rubber)"
                nacelleDesigner = component "2. NacelleDesigner Strategy" "Generates 3D polygon cross-section surfaces for nacelle and engine core based on fan/engine dimensions." "src/nacelle/ (nacelle::Default)"
                integrator = component "3. PropulsionIntegrator Strategy" "Computes 3D placement coordinates on wing, fuselage, empennage, or wing-body." "src/integration/ (integration::Default)"
                pylonDesigner = component "4. PylonDesigner Strategy" "Generates 3D airfoil section surfaces connecting nacelle attachment points to parent airframe surface." "src/pylon/ (pylon::Default)"
                massAnalyzer = component "5. MassAnalyzer Strategy" "Computes point masses, CG vectors & Eigen inertia tensors for engine, nacelle, and pylon." "src/mass/ (mass::Default)"
                io = component "XML & Engine I/O Subsystem" "io::AircraftXML (inserts reference offset, masses & engines into acXML v3) and io::load_engine_data / load_engine_scaled." "src/io/ (aircraft_xml, engine_xml)"
                report = component "Report & Plot Subsystem" "report::generate_data() computes N1 BucketCurves; creates HTML report, XML results, SVG views & Matplot++ bucket curve plots." "src/report/ (report_data, create_*)"
            }
            config = container "Configuration File" "Stores selected design methods (Rubber, Default), technology factors, and directory paths." "XML (propulsion_design_conf.xml)" "File"
            projectDecks = container "Project Engine Deck Directory" "Scaled engine performance decks exported for the current aircraft project." "CSV & engineXML Files" "File"
            reports = container "Report & Plot Output" "propulsion_design_report.html, propulsion_design_results.xml & SVG plots." "HTML, XML & SVG Files" "File"
        }

        unicadoLibs = softwareSystem "UNICADO & 3rd-Party Libraries" "moduleBasics, strategy, aixml, aircraftGeometry2, engine, atmosphere, unitConversion, Eigen3, Matplot++." "Library"
        gnuplot = softwareSystem "gnuplot" "Invoked by Matplot++ to render engine bucket curve SVG plots (optional)." "External"

        designer -> config "Sets methods and factors [XML]"
        designer -> pd "Configures & runs [XML / CLI]"
        loop -> pd "Executes each iteration [CLI]"
        upstream -> acxml "Writes T/W, MTOM, off-takes"
        pd -> acxml "Reads inputs & writes propulsion results [aixml / io::AircraftXML]"
        pd -> config "Reads settings & methods [aixml]"
        pd -> engineDb "Reads reference decks [io::load_engine_data]"
        pd -> geomData "Reads airframe, nacelle & pylon .dat profiles [aircraftGeometry2]"
        pd -> projectDecks "Writes scaled CSV decks [write_deck_value()]"
        pd -> reports "Writes HTML, XML & SVG geometry [moduleBasics / svg]"
        pd -> gnuplot "Sends bucket curve plot commands [Matplot++]"
        gnuplot -> reports "Exports bucket curve SVG"
        downstream -> acxml "Reads propulsion geometry, mass & engine results [acXML]"

        coordinator -> config "Reads configuration [aixml]"
        coordinator -> unicadoLibs "Inherits Module & builds geometry"
        coordinator -> engineDesigner "1. Sizes engine [std::visit]"
        coordinator -> nacelleDesigner "2. Sizes nacelle [std::visit]"
        coordinator -> integrator "3. Places engine [std::visit]"
        coordinator -> pylonDesigner "4. Sizes pylon [std::visit]"
        coordinator -> massAnalyzer "5. Analyzes mass [std::visit]"
        coordinator -> io "Inserts results in update()"
        coordinator -> report "Generates data & reports"

        engineDesigner -> io "Loads engines"
        engineDesigner -> projectDecks "Writes scaled CSV decks"
        engineDesigner -> strategyBase "Updates model, scale & bucket"
        nacelleDesigner -> strategyBase "Sets nacelle & core surfaces"
        integrator -> strategyBase "Sets 3D position"
        pylonDesigner -> strategyBase "Sets pylon surface"
        massAnalyzer -> strategyBase "Sets PointMasses"
        report -> io "Loads scaled engines"
        report -> reports "Writes HTML, XML & SVG plots"
        io -> engineDb "Loads engineXML & CSV decks"
        io -> acxml "Reads/writes acXML [aixml]"
    }

    views {
        systemContext unicado "Context" {
            include *
            autoLayout lr
        }
        container unicado "Containers" {
            include *
            autoLayout lr
        }
        component pd "Components" {
            include *
            autoLayout tb
        }
        styles {
            element "Person" { shape Person background #08427b color #ffffff }
            element "File" { shape Folder background #1168bd color #ffffff }
            element "Library" { background #687681 color #ffffff }
            element "External" { background #687681 color #ffffff }
            element "Container" { background #1168bd color #ffffff }
            element "Component" { background #1f6feb color #ffffff }
        }
    }
}
