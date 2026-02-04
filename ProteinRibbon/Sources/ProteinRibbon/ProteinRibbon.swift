//
//  ProteinRibbon.swift
//  ProteinRibbon
//
//  Public API for generating RealityKit ModelEntity from PDB strings.
//

import Foundation
import simd
import RealityKit

/// ProteinRibbon generates Richardson diagram (cartoon ribbon) representations
/// of protein structures for RealityKit visualization.
///
/// Example usage:
/// ```swift
/// let pdbString = try String(contentsOf: pdbFileURL)
/// let entity = ProteinRibbon.entity(from: pdbString)
/// scene.addChild(entity)
/// ```
public struct ProteinRibbon {

    // MARK: - Options

    /// Configuration options for ribbon rendering
    public struct Options {
        /// Color scheme to use for the ribbon
        public var colorScheme: ColorScheme

        /// Width of alpha helix ribbons in Angstroms
        public var helixWidth: Float

        /// Width of beta sheet ribbons in Angstroms
        public var sheetWidth: Float

        /// Radius of coil tubes in Angstroms
        public var coilRadius: Float

        /// Number of interpolated samples per residue (affects smoothness)
        public var samplesPerResidue: Int

        /// Scale factor to convert Angstroms to scene units
        /// Default: 0.01 (1 Angstrom = 0.01 scene units)
        public var scale: Float

        /// Whether to create separate entities for each secondary structure segment
        /// This allows for per-segment materials but creates more entities
        public var separateSegments: Bool

        /// Uniform color to use when colorScheme is .uniform
        public var uniformColor: SIMD4<Float>

        /// Length of the arrow head tip extending forward from sheet terminus (in Angstroms)
        /// Default: 2.4 (1.5 * sheetWidth)
        public var sheetArrowLength: Float

        /// How far arrow wings extend beyond the ribbon width (in Angstroms)
        /// Default: 0.8 (0.5 * sheetWidth)
        public var sheetArrowWingExtension: Float

        /// Number of segments for smooth ribbon cross-sections (more = smoother)
        /// Default: 20
        public var smoothSegments: Int

        /// Number of smoothing iterations for positions and frames (reduces kinks and twisting)
        /// Default: 5
        public var frameSmoothingIterations: Int

        /// Creates default rendering options
        public init(
            colorScheme: ColorScheme = .byStructure,
            helixWidth: Float = 1.2,
            sheetWidth: Float = 1.6,
            coilRadius: Float = 0.3,
            samplesPerResidue: Int = 24,
            scale: Float = 0.01,
            separateSegments: Bool = true,
            uniformColor: SIMD4<Float> = SIMD4<Float>(0.7, 0.7, 0.7, 1.0),
            sheetArrowLength: Float = 2.4,
            sheetArrowWingExtension: Float = 0.8,
            smoothSegments: Int = 20,
            frameSmoothingIterations: Int = 5
        ) {
            self.colorScheme = colorScheme
            self.helixWidth = helixWidth
            self.sheetWidth = sheetWidth
            self.coilRadius = coilRadius
            self.samplesPerResidue = samplesPerResidue
            self.scale = scale
            self.separateSegments = separateSegments
            self.uniformColor = uniformColor
            self.sheetArrowLength = sheetArrowLength
            self.sheetArrowWingExtension = sheetArrowWingExtension
            self.smoothSegments = smoothSegments
            self.frameSmoothingIterations = frameSmoothingIterations
        }
    }

    // MARK: - Public API

    /// Generates a RealityKit ModelEntity from a PDB format string
    /// - Parameters:
    ///   - pdbString: The raw PDB file content
    ///   - options: Rendering options (uses defaults if not specified)
    /// - Returns: A ModelEntity containing the protein ribbon visualization
    public static func entity(
        from pdbString: String,
        options: Options = Options()
    ) -> ModelEntity {
        // Parse the PDB string
        let structure = PDBParser.parse(pdbString)

        guard !structure.residues.isEmpty else {
            print("ProteinRibbon: No residues found in PDB string")
            return ModelEntity()
        }

        // Build the entity
        if options.separateSegments {
            // Build with separate segment entities as children
            let parent = ModelEntity()
            parent.name = "ProteinRibbon"

            let segments = RealityKitEntityBuilder.buildSegmentedEntities(
                from: structure,
                options: options
            )

            for segment in segments {
                parent.addChild(segment)
            }

            return parent
        } else {
            // Build as single combined mesh
            return RealityKitEntityBuilder.buildEntity(from: structure, options: options)
        }
    }

    /// Generates a RealityKit Entity hierarchy from a PDB format string
    /// Returns an Entity parent containing ModelEntity children for each segment
    /// - Parameters:
    ///   - pdbString: The raw PDB file content
    ///   - options: Rendering options
    /// - Returns: An Entity containing child ModelEntities for each segment
    public static func entityHierarchy(
        from pdbString: String,
        options: Options = Options()
    ) -> Entity {
        let structure = PDBParser.parse(pdbString)

        guard !structure.residues.isEmpty else {
            print("ProteinRibbon: No residues found in PDB string")
            return Entity()
        }

        return RealityKitEntityBuilder.buildParentEntity(from: structure, options: options)
    }

    /// Parses a PDB string and returns the structure data
    /// Useful for inspection or custom rendering
    /// - Parameter pdbString: The raw PDB file content
    /// - Returns: Parsed PDB structure
    public static func parseStructure(from pdbString: String) -> PDBStructure {
        return PDBParser.parse(pdbString)
    }

    /// Returns secondary structure segments from a parsed structure
    /// - Parameter structure: Parsed PDB structure
    /// - Returns: Array of secondary structure segments
    public static func secondaryStructure(from structure: PDBStructure) -> [SecondaryStructureSegment] {
        return SecondaryStructureClassifier.classify(
            residues: structure.residues,
            helices: structure.helices,
            sheets: structure.sheets
        )
    }

    // MARK: - Ball-and-Stick Rendering

    /// Generates a ball-and-stick ModelEntity from a PDB format string
    /// Shows atoms as spheres and bonds as cylinders
    /// - Parameters:
    ///   - pdbString: The raw PDB file content
    ///   - options: Ball-and-stick rendering options (uses defaults if not specified)
    /// - Returns: A ModelEntity containing the ball-and-stick visualization
    public static func ballAndStickEntity(
        from pdbString: String,
        options: BallAndStickOptions = BallAndStickOptions()
    ) -> ModelEntity {
        let structure = PDBParser.parse(pdbString)

        guard !structure.atoms.isEmpty else {
            print("ProteinRibbon: No atoms found in PDB string")
            return ModelEntity()
        }

        return BallAndStickBuilder.buildEntity(from: structure, options: options)
    }
}

// MARK: - Convenience Methods

extension ProteinRibbon {
    // MARK: Ribbon Convenience Methods

    /// Creates an entity with default structure coloring (red helix, blue sheet, green coil)
    public static func structureColoredEntity(from pdbString: String) -> ModelEntity {
        return entity(from: pdbString, options: Options(colorScheme: .byStructure))
    }

    /// Creates an entity with chain coloring
    public static func chainColoredEntity(from pdbString: String) -> ModelEntity {
        return entity(from: pdbString, options: Options(colorScheme: .byChain))
    }

    /// Creates an entity with rainbow gradient coloring
    public static func rainbowEntity(from pdbString: String) -> ModelEntity {
        return entity(from: pdbString, options: Options(colorScheme: .byResidue))
    }

    /// Creates an entity with residue type coloring (hydrophobic, polar, charged)
    public static func typeColoredEntity(from pdbString: String) -> ModelEntity {
        return entity(from: pdbString, options: Options(colorScheme: .byResidueType))
    }

    // MARK: Ball-and-Stick Convenience Methods

    /// Creates a ball-and-stick entity with CPK element coloring
    public static func ballAndStickCPK(from pdbString: String) -> ModelEntity {
        return ballAndStickEntity(from: pdbString, options: BallAndStickOptions(colorScheme: .byElement))
    }

    /// Creates a ball-and-stick entity showing only backbone atoms (N, CA, C, O)
    public static func backboneOnly(from pdbString: String) -> ModelEntity {
        return ballAndStickEntity(
            from: pdbString,
            options: BallAndStickOptions(
                atomScale: 0.4,
                bondRadius: 0.2,
                colorScheme: .byElement,
                backboneOnly: true
            )
        )
    }

    /// Creates a ball-and-stick entity with larger atoms and thicker bonds
    public static func ballAndStickLarge(from pdbString: String) -> ModelEntity {
        return ballAndStickEntity(
            from: pdbString,
            options: BallAndStickOptions(
                atomScale: 0.5,
                bondRadius: 0.25,
                colorScheme: .byElement
            )
        )
    }
}

// MARK: - Debug/Info

extension ProteinRibbon {
    /// Returns a summary of the parsed structure
    public static func structureSummary(from pdbString: String) -> String {
        let structure = PDBParser.parse(pdbString)
        let segments = secondaryStructure(from: structure)

        var summary = "PDB Structure Summary:\n"
        summary += "  Atoms: \(structure.atoms.count)\n"
        summary += "  Residues: \(structure.residues.count)\n"
        summary += "  Chains: \(structure.chains.joined(separator: ", "))\n"
        summary += "  Helices: \(structure.helices.count)\n"
        summary += "  Sheets: \(structure.sheets.count)\n"
        summary += "\nSecondary Structure Segments:\n"

        for (i, segment) in segments.enumerated() {
            summary += "  \(i + 1). \(segment.type.rawValue.capitalized) "
            summary += "(chain \(segment.chainID), "
            summary += "residues \(segment.startIndex + 1)-\(segment.endIndex + 1), "
            summary += "length \(segment.length))\n"
        }

        return summary
    }
}
