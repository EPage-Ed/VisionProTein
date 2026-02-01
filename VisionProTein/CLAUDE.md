# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode visionOS project. Open `VisionProTein.xcodeproj` in Xcode and build for visionOS simulator or device.

```bash
# Open in Xcode
open ../VisionProTein.xcodeproj
```

No command-line build system is configured. Use Xcode's build/run (Cmd+R).

## Architecture Overview

VisionProTein is an Apple Vision Pro app for visualizing and interacting with 3D protein structures in AR.

### Core Data Flow

```
PDB Parser (PDB.swift) → [Atoms, Residues, Secondary Structure]
         ↓
Molecule Factory Methods (Molecule.swift + extensions)
         ↓
ARModel (state management, @ObservableObject)
         ↓
RealityView (renders rootEntity in immersive space)
```

### Key Components

| File | Purpose |
|------|---------|
| `ARModel.swift` | Central state container. Manages protein/ligand entities, residue selection, hand tracking, rendering modes |
| `PDB.swift` | Parses PDB file format. Returns atoms, residues, HELIX/SHEET records |
| `Molecule.swift` | Static factory methods that generate RealityKit ModelEntity from parsed data |
| `Molecule+Richardson.swift` | Builds cartoon ribbon diagrams (helices, sheets, coils) using Catmull-Rom interpolation |
| `Molecule+ResidueEntity.swift` | Per-residue entity generation with instanced atom spheres |
| `GestureComponent.swift` | RealityKit component for drag/rotate/scale gesture handling |
| `GestureExtensions.swift` | Bridges SwiftUI gestures to GestureComponent state machine |

### Views

- **ContentView**: 2D window with controls, residue list, and details panel
- **ImmersiveView**: 3D immersive space where proteins are rendered and manipulated
- **ProteinListView**: List of available proteins to load

### Entity Hierarchy

```
rootEntity
├── ProteinTag (parent for all residues)
│   ├── Residue entities (one per amino acid)
│   │   └── Atom groups (instanced spheres by element color)
│   └── Ribbon (secondary structure, toggleable)
└── Ligand (if present)
```

### Rendering Modes (ModelState enum)

- **resizing**: Ball-and-stick with collision detection, drag/scale enabled
- **tagging**: Selection mode, tap to highlight residues
- **ribbon**: Hides atoms, shows Richardson diagram (helices=red cylinders, sheets=blue arrows)

### Custom RealityKit Components

- **MoleculeComponent**: Attached to residue entities, stores Residue metadata
- **ProteinComponent**: Marker component for protein parent entity
- **GestureComponent**: Configures drag/rotate/scale capabilities per entity

### Rendering Optimization

Uses `MeshInstancesComponent` and `LowLevelInstanceData` to batch atoms by element color, reducing draw calls significantly for large proteins.

## Local Packages

- `Packages/RealityKitContent/` - RealityKit scene content
- `Packages/MolecularRender/` - Custom rendering utilities
- `Packages/MolecularRibbonKit/` - Advanced ribbon diagram builder

## PDB Files

Sample protein structures are in `PDB/` directory (1nc9.pdb, 3nir.pdb, 4HR9.pdb, Biotin.pdb).
