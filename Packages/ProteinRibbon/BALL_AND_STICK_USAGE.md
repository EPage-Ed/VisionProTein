# Ball-and-Stick Rendering Usage

The ProteinRibbon package now supports ball-and-stick molecular visualization in addition to ribbon diagrams. Atoms are rendered as colored, opaque spheres and bonds as cylinders with split coloring.

## Basic Usage

```swift
import ProteinRibbon

// Load PDB file
let pdbString = try String(contentsOf: pdbFileURL)

// Create ball-and-stick model with default CPK coloring
let entity = ProteinRibbon.ballAndStickEntity(from: pdbString)
scene.addChild(entity)
```

## Convenience Methods

### CPK Element Coloring
```swift
let entity = ProteinRibbon.ballAndStickCPK(from: pdbString)
```
Standard CPK colors: Carbon=gray, Nitrogen=blue, Oxygen=red, Sulfur=yellow, etc.

### Backbone Only
```swift
let entity = ProteinRibbon.backboneOnly(from: pdbString)
```
Shows only N, CA, C, O atoms with larger spheres and thicker bonds.

### Large Atoms
```swift
let entity = ProteinRibbon.ballAndStickLarge(from: pdbString)
```
Creates larger atoms (0.5x scale) and thicker bonds (0.25 Å radius).

## Custom Options

```swift
let options = ProteinRibbon.BallAndStickOptions(
    atomScale: 0.3,              // Multiplier for atom van der Waals radii
    bondRadius: 0.15,            // Bond cylinder radius in Angstroms
    sphereSegments: 16,          // Smoothness of spheres/cylinders
    colorScheme: .byElement,     // Coloring scheme
    scale: 0.01,                 // Angstroms to scene units
    bondTolerance: 1.3,          // Bond detection tolerance
    maxBondLength: 2.0,          // Maximum bond length in Angstroms
    backboneOnly: false,         // Show only backbone atoms
    showHydrogens: false         // Include hydrogen atoms
)

let entity = ProteinRibbon.ballAndStickEntity(from: pdbString, options: options)
```

## Color Schemes

### By Element (CPK)
```swift
options.colorScheme = .byElement
```
Standard chemical element colors.

### By Residue Type
```swift
options.colorScheme = .byResidueType
```
Colors based on amino acid properties:
- Yellow: Hydrophobic (ALA, VAL, LEU, ILE, MET, PHE, TRP, TYR)
- Cyan: Polar (SER, THR, ASN, GLN)
- Blue: Positive charge (LYS, ARG, HIS)
- Red: Negative charge (ASP, GLU)
- Magenta: Special (GLY, PRO, CYS)

### By Chain
```swift
options.colorScheme = .byChain
```
Different color for each protein chain.

### Uniform Color
```swift
options.colorScheme = .uniform(SIMD4<Float>(0.7, 0.7, 0.7, 1.0))
```
Single color for all atoms.

## Bond Detection

Bonds are automatically detected based on:
- **Covalent radii sum**: Atoms are bonded if distance ≤ (r₁ + r₂) × tolerance
- **Tolerance**: Default 1.3 (130% of expected bond length)
- **Max bond length**: Default 2.0 Å (prevents spurious long-range bonds)

Bonds are rendered as two half-cylinders, each colored to match its connected atom.

## Filtering Atoms

### Backbone Only
```swift
options.backboneOnly = true
```
Shows only N, CA, C, O atoms (useful for large proteins).

### Hide Hydrogens
```swift
options.showHydrogens = false  // Default
```
Hydrogens are hidden by default to reduce visual clutter.

## Example: Combined Ribbon and Ball-and-Stick

```swift
// Create ribbon diagram
let ribbonEntity = ProteinRibbon.entity(from: pdbString)
ribbonEntity.position.y = 0

// Create ball-and-stick of active site (atoms 100-150)
let structure = ProteinRibbon.parseStructure(from: pdbString)
let activeSiteAtoms = Array(structure.atoms[100...150])
// ... (would need manual filtering and custom build)

// Or use backbone-only ball-and-stick as overlay
let backboneEntity = ProteinRibbon.backboneOnly(from: pdbString)
backboneEntity.position.y = 0.01  // Slight offset

scene.addChild(ribbonEntity)
scene.addChild(backboneEntity)
```

## Rendering Details

The ball-and-stick renderer creates properly colored, opaque geometry using the following approach:

- **Grouped by color**: Atoms and bonds are grouped by color to minimize entity count
- **Separate entities**: Each color group becomes a separate ModelEntity with its own material
- **Material-based coloring**: Colors are applied via SimpleMaterial tint (not per-vertex colors)
- **Opaque spheres**: All atoms are rendered as solid, opaque spheres with proper lighting

This approach ensures:
- ✓ Accurate, vibrant colors matching CPK standards
- ✓ Proper opacity (no transparency unless requested)
- ✓ Good performance through entity grouping
- ✓ Realistic lighting and shading

## Performance Considerations

- **Sphere/cylinder segments**: Default 16 provides good balance
  - Lower (8-12) for better performance with large molecules
  - Higher (20-32) for publication-quality rendering

- **Backbone only**: Significantly reduces geometry for large proteins

- **Bond detection**: O(n²) algorithm - can be slow for very large structures (>10,000 atoms)
  - Consider using `backboneOnly` for proteins with >5,000 atoms

## Comparison with Ribbon Diagrams

| Feature | Ball-and-Stick | Ribbon Diagram |
|---------|----------------|----------------|
| Shows atoms | ✓ | ✗ |
| Shows bonds | ✓ | ✗ |
| Shows secondary structure | ✗ | ✓ |
| Suitable for small molecules | ✓ | ✗ |
| Suitable for large proteins | Backbone only | ✓ |
| Element information | ✓ | ✗ |
| Active site visualization | ✓ | ✗ |

Use ball-and-stick for:
- Small molecules and ligands
- Active site detail views
- Understanding atomic connectivity
- Chemical accuracy

Use ribbon diagrams for:
- Large protein structures
- Secondary structure visualization
- Overall protein fold
- Comparative analysis
