# ProteinSpheres Package

High-performance sphere-based protein visualization using GPU instancing.

## Features

- Efficient GPU instancing for rendering thousands of atoms
- CPK coloring scheme (color by element)
- Configurable atom scaling
- Support for custom positioning (useful for folding/unfolding animations)
- Level-of-detail (LOD) support (planned)

## Installation in Xcode

To use this package in your VisionProTein project:

1. In Xcode, select the VisionProTein project in the Project Navigator
2. Select the VisionProTein target
3. Go to the "Frameworks, Libraries, and Embedded Content" section
4. Click the "+" button
5. Select "Add Package Dependency..."
6. Choose "Add Local..." and select the `Packages/ProteinSpheres` directory
7. Click "Add Package"

Alternatively, you can add it via the project's Package Dependencies:

1. In Xcode, select the project file (not the target)
2. Go to the "Package Dependencies" tab
3. Click the "+" button
4. Select "Add Local..."
5. Navigate to and select the `Packages/ProteinSpheres` folder
6. Set the dependency rule to "Branch: main" or "Up to Next Major Version"

## Usage

```swift
import ProteinSpheres

// Convert PDB residue to ProteinSpheres residue
let sphereResidue = ProteinSpheres.Residue.from(pdbResidue: pdbResidue)

// Generate a single residue entity
let residueEntity = ProteinSpheres.generateResidueEntity(
    residue: sphereResidue, 
    scale: 1.0
)

// Generate a complete protein
let proteinEntity = ProteinSpheres.generateProteinEntity(
    residues: sphereResidues,
    scale: 1.0
)
```

## Performance

This implementation uses GPU instancing to efficiently render proteins with thousands of atoms. Atoms of the same color are batched together and rendered in a single draw call, significantly improving performance compared to individual sphere entities.

## Architecture

- `Atom`: Represents a single atom with position, element, color, and radius
- `Residue`: Represents a protein residue containing multiple atoms
- `ProteinSpheres`: Main class with static methods for generating RealityKit entities
- `PDBAdapter`: Helper extensions for converting from PDB format

## Comparison with Original Implementation

The new `ProteinSpheres` package provides:

1. **Better organization**: Separated into its own package
2. **Cleaner API**: Simple, focused static methods
3. **Same performance**: Uses the same GPU instancing approach
4. **Easier maintenance**: Self-contained with clear dependencies
5. **Reusability**: Can be used in other projects

