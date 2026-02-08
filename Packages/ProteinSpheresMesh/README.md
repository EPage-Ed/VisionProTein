# ProteinSpheresMesh

A Swift package for rendering protein structures as spheres using efficient mesh instancing in RealityKit.

## Overview

ProteinSpheresMesh provides a space-filling sphere representation of protein structures, where each atom is rendered as a sphere with its van der Waals radius. This package uses GPU instancing with one mesh per atom type (element) for optimal rendering performance.

## Features

- **Efficient Rendering**: Uses RealityKit mesh instancing - one mesh per element type
- **Van der Waals Radii**: Atoms rendered at their standard van der Waals radii
- **CPK Coloring**: Standard element colors (carbon gray, nitrogen blue, oxygen red, etc.)
- **PDB Parser**: Built-in parser for PDB format strings
- **Customizable**: Adjustable sphere sizes, color schemes, and rendering options

## Usage

### Basic Usage

```swift
import ProteinSpheresMesh

// Create sphere representation from PDB string
let pdbString = """
ATOM      1  N   MET A   1      20.154  29.699   5.276  1.00 49.05           N
ATOM      2  CA  MET A   1      21.311  28.862   5.588  1.00 49.05           C
...
"""

let spheresEntity = ProteinSpheresMesh.spheresCPK(from: pdbString)
```

### Custom Options

```swift
// Create larger spheres with custom scale
let largeEntity = ProteinSpheresMesh.spheresLarge(from: pdbString)

// Or use completely custom options
let options = ProteinSpheresMesh.Options(
    atomScale: 1.2,          // 120% of van der Waals radius
    sphereSegments: 20,      // Higher quality spheres
    colorScheme: .byElement, // CPK coloring
    scale: 0.01,            // Angstroms to scene units
    showHydrogens: false     // Hide hydrogens
)

let customEntity = ProteinSpheresMesh.spheresEntity(from: pdbString, options: options)
```

### Color Schemes

- `.byElement` - CPK (Corey-Pauling-Koltun) element colors
- `.byChain` - Different color per chain
- `.uniform(color)` - Single color for all atoms

## Architecture

The package uses a three-tier architecture:

1. **PDB Parser**: Parses PDB format strings into structured data
2. **Spheres Builder**: Groups atoms by element and creates instanced meshes
3. **Public API**: Convenient methods for common use cases

Each element type (C, N, O, S, etc.) gets its own ModelEntity with a single mesh and multiple instances positioned at atom locations. This approach minimizes draw calls and maximizes GPU efficiency.

## Structure

```
Packages/ProteinSpheresMesh/
├── Package.swift
├── README.md
└── Sources/
    └── ProteinSpheresMesh/
        └── ProteinSpheresMesh.swift  # Main implementation
```

## Integration

This package is designed to work alongside other protein visualization packages in the VisionProTein project:

- **ProteinRibbon**: Cartoon/ribbon representation with secondary structure
- **MolecularRender**: Ball-and-stick representation with bonds
- **ProteinSpheresMesh**: Space-filling sphere representation (this package)

## Performance

Rendering efficiency through mesh instancing:
- **10,000 atoms**: ~10-15 entity objects (one per element type)
- **Without instancing**: Would require 10,000 entity objects
- **Result**: ~1000x reduction in entity count

## Requirements

- visionOS 1.0+
- iOS 17.0+
- Swift 5.9+
- RealityKit

## License

Part of the VisionProTein project.
