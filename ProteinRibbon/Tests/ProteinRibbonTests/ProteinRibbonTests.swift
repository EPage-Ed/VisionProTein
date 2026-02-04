//
//  ProteinRibbonTests.swift
//  ProteinRibbonTests
//
//  Tests for ProteinRibbon package.
//

import XCTest
import simd
@testable import ProteinRibbon

final class ProteinRibbonTests: XCTestCase {

    // MARK: - Sample PDB Data

    let samplePDB = """
    HEADER    TEST PROTEIN
    HELIX    1   1 ALA A   2  ALA A   6  1                                   5
    SHEET    1   A 2 GLY A  10  VAL A  12  0
    ATOM      1  N   ALA A   1       0.000   0.000   0.000  1.00 20.00           N
    ATOM      2  CA  ALA A   1       1.458   0.000   0.000  1.00 20.00           C
    ATOM      3  C   ALA A   1       2.009   1.420   0.000  1.00 20.00           C
    ATOM      4  O   ALA A   1       1.246   2.390   0.000  1.00 20.00           O
    ATOM      5  N   ALA A   2       3.500   3.800   0.000  1.00 20.00           N
    ATOM      6  CA  ALA A   2       4.500   3.800   1.000  1.00 20.00           C
    ATOM      7  C   ALA A   2       5.500   3.800   2.000  1.00 20.00           C
    ATOM      8  O   ALA A   2       5.500   4.500   3.000  1.00 20.00           O
    ATOM      9  N   ALA A   3       6.500   7.600   3.000  1.00 20.00           N
    ATOM     10  CA  ALA A   3       7.500   7.600   4.000  1.00 20.00           C
    ATOM     11  C   ALA A   3       8.500   7.600   5.000  1.00 20.00           C
    ATOM     12  O   ALA A   3       8.500   8.300   6.000  1.00 20.00           O
    ATOM     13  N   ALA A   4       9.500  11.400   6.000  1.00 20.00           N
    ATOM     14  CA  ALA A   4      10.500  11.400   7.000  1.00 20.00           C
    ATOM     15  C   ALA A   4      11.500  11.400   8.000  1.00 20.00           C
    ATOM     16  O   ALA A   4      11.500  12.100   9.000  1.00 20.00           O
    ATOM     17  N   ALA A   5      12.500  15.200   9.000  1.00 20.00           N
    ATOM     18  CA  ALA A   5      13.500  15.200  10.000  1.00 20.00           C
    ATOM     19  C   ALA A   5      14.500  15.200  11.000  1.00 20.00           C
    ATOM     20  O   ALA A   5      14.500  15.900  12.000  1.00 20.00           O
    ATOM     21  N   ALA A   6      15.500  19.000  12.000  1.00 20.00           N
    ATOM     22  CA  ALA A   6      16.500  19.000  13.000  1.00 20.00           C
    ATOM     23  C   ALA A   6      17.500  19.000  14.000  1.00 20.00           C
    ATOM     24  O   ALA A   6      17.500  19.700  15.000  1.00 20.00           O
    ATOM     25  N   GLY A   7      18.500  22.800  15.000  1.00 20.00           N
    ATOM     26  CA  GLY A   7      19.500  22.800  16.000  1.00 20.00           C
    ATOM     27  C   GLY A   7      20.500  22.800  17.000  1.00 20.00           C
    ATOM     28  O   GLY A   7      20.500  23.500  18.000  1.00 20.00           O
    ATOM     29  N   GLY A   8      21.500  26.600  18.000  1.00 20.00           N
    ATOM     30  CA  GLY A   8      22.500  26.600  19.000  1.00 20.00           C
    ATOM     31  C   GLY A   8      23.500  26.600  20.000  1.00 20.00           C
    ATOM     32  O   GLY A   8      23.500  27.300  21.000  1.00 20.00           O
    ATOM     33  N   GLY A   9      24.500  30.400  21.000  1.00 20.00           N
    ATOM     34  CA  GLY A   9      25.500  30.400  22.000  1.00 20.00           C
    ATOM     35  C   GLY A   9      26.500  30.400  23.000  1.00 20.00           C
    ATOM     36  O   GLY A   9      26.500  31.100  24.000  1.00 20.00           O
    ATOM     37  N   GLY A  10      27.500  34.200  24.000  1.00 20.00           N
    ATOM     38  CA  GLY A  10      28.500  34.200  25.000  1.00 20.00           C
    ATOM     39  C   GLY A  10      29.500  34.200  26.000  1.00 20.00           C
    ATOM     40  O   GLY A  10      29.500  34.900  27.000  1.00 20.00           O
    ATOM     41  N   VAL A  11      30.500  38.000  27.000  1.00 20.00           N
    ATOM     42  CA  VAL A  11      31.500  38.000  28.000  1.00 20.00           C
    ATOM     43  C   VAL A  11      32.500  38.000  29.000  1.00 20.00           C
    ATOM     44  O   VAL A  11      32.500  38.700  30.000  1.00 20.00           O
    ATOM     45  N   VAL A  12      33.500  41.800  30.000  1.00 20.00           N
    ATOM     46  CA  VAL A  12      34.500  41.800  31.000  1.00 20.00           C
    ATOM     47  C   VAL A  12      35.500  41.800  32.000  1.00 20.00           C
    ATOM     48  O   VAL A  12      35.500  42.500  33.000  1.00 20.00           O
    END
    """

    // MARK: - PDB Parser Tests

    func testPDBParserBasic() {
        let structure = PDBParser.parse(samplePDB)

        XCTAssertEqual(structure.atoms.count, 48, "Should parse 48 atoms")
        XCTAssertEqual(structure.residues.count, 12, "Should have 12 residues")
        XCTAssertEqual(structure.helices.count, 1, "Should have 1 helix")
        XCTAssertEqual(structure.sheets.count, 1, "Should have 1 sheet")
    }

    func testPDBParserAtomPositions() {
        let structure = PDBParser.parse(samplePDB)

        guard let firstAtom = structure.atoms.first else {
            XCTFail("Should have at least one atom")
            return
        }

        XCTAssertEqual(firstAtom.position.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(firstAtom.position.y, 0.0, accuracy: 0.001)
        XCTAssertEqual(firstAtom.position.z, 0.0, accuracy: 0.001)
        XCTAssertEqual(firstAtom.element, "N")
        XCTAssertEqual(firstAtom.residueName, "ALA")
    }

    func testPDBParserHelixRecord() {
        let structure = PDBParser.parse(samplePDB)

        guard let helix = structure.helices.first else {
            XCTFail("Should have at least one helix")
            return
        }

        XCTAssertEqual(helix.startResidue, 2)
        XCTAssertEqual(helix.endResidue, 6)
        XCTAssertEqual(helix.startChain, "A")
    }

    func testPDBParserSheetRecord() {
        let structure = PDBParser.parse(samplePDB)

        guard let sheet = structure.sheets.first else {
            XCTFail("Should have at least one sheet")
            return
        }

        XCTAssertEqual(sheet.startResidue, 10)
        XCTAssertEqual(sheet.endResidue, 12)
        XCTAssertEqual(sheet.startChain, "A")
    }

    // MARK: - Secondary Structure Tests

    func testSecondaryStructureClassification() {
        let structure = PDBParser.parse(samplePDB)
        let segments = SecondaryStructureClassifier.classify(
            residues: structure.residues,
            helices: structure.helices,
            sheets: structure.sheets
        )

        XCTAssertFalse(segments.isEmpty, "Should have segments")

        // Check that we have helix, sheet, and coil segments
        let hasHelix = segments.contains { $0.type == .helix }
        let hasSheet = segments.contains { $0.type == .sheet }
        let hasCoil = segments.contains { $0.type == .coil }

        XCTAssertTrue(hasHelix, "Should have helix segment")
        XCTAssertTrue(hasSheet, "Should have sheet segment")
        XCTAssertTrue(hasCoil, "Should have coil segment")
    }

    // MARK: - Spline Interpolation Tests

    func testCatmullRomSpline() {
        let points: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 1, 0),
            SIMD3<Float>(2, 0, 0),
            SIMD3<Float>(3, 1, 0),
            SIMD3<Float>(4, 0, 0)
        ]

        let splinePoints = SplineInterpolation.catmullRom(points: points, samplesPerSegment: 4)

        XCTAssertGreaterThan(splinePoints.count, points.count, "Should have more interpolated points")

        // Check that spline passes near control points
        let firstPoint = splinePoints.first!
        XCTAssertEqual(firstPoint.position.x, 0, accuracy: 0.1)
    }

    func testSplineWithFewPoints() {
        let points: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 1, 0)
        ]

        let splinePoints = SplineInterpolation.catmullRom(points: points, samplesPerSegment: 4)

        XCTAssertEqual(splinePoints.count, 2, "With fewer than 4 points, should return original")
    }

    // MARK: - TNB Frame Tests

    func testTNBFrameGeneration() {
        let points: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 1, 0),
            SIMD3<Float>(3, 1, 0),
            SIMD3<Float>(4, 0, 0)
        ]

        let frames = TNBFrameGenerator.rotationMinimizingFrames(along: points)

        XCTAssertEqual(frames.count, points.count, "Should have one frame per point")

        // Check orthogonality
        for frame in frames {
            let dotTN = simd_dot(frame.tangent, frame.normal)
            let dotTB = simd_dot(frame.tangent, frame.binormal)
            let dotNB = simd_dot(frame.normal, frame.binormal)

            XCTAssertEqual(dotTN, 0, accuracy: 0.01, "T and N should be orthogonal")
            XCTAssertEqual(dotTB, 0, accuracy: 0.01, "T and B should be orthogonal")
            XCTAssertEqual(dotNB, 0, accuracy: 0.01, "N and B should be orthogonal")
        }
    }

    func testFrameUnitVectors() {
        let points: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 1, 1),
            SIMD3<Float>(2, 2, 2),
            SIMD3<Float>(3, 2, 3)
        ]

        let frames = TNBFrameGenerator.rotationMinimizingFrames(along: points)

        for frame in frames {
            XCTAssertEqual(simd_length(frame.tangent), 1.0, accuracy: 0.01)
            XCTAssertEqual(simd_length(frame.normal), 1.0, accuracy: 0.01)
            XCTAssertEqual(simd_length(frame.binormal), 1.0, accuracy: 0.01)
        }
    }

    // MARK: - Color Scheme Tests

    func testStructureColors() {
        XCTAssertEqual(ColorSchemes.color(for: .helix), ColorSchemes.helixColor)
        XCTAssertEqual(ColorSchemes.color(for: .sheet), ColorSchemes.sheetColor)
        XCTAssertEqual(ColorSchemes.color(for: .coil), ColorSchemes.coilColor)
    }

    func testResidueTypeColors() {
        // Hydrophobic
        XCTAssertEqual(ColorSchemes.color(forResidueName: "ALA"), ColorSchemes.hydrophobicColor)
        XCTAssertEqual(ColorSchemes.color(forResidueName: "VAL"), ColorSchemes.hydrophobicColor)

        // Polar
        XCTAssertEqual(ColorSchemes.color(forResidueName: "SER"), ColorSchemes.polarColor)

        // Positive
        XCTAssertEqual(ColorSchemes.color(forResidueName: "LYS"), ColorSchemes.positiveColor)

        // Negative
        XCTAssertEqual(ColorSchemes.color(forResidueName: "ASP"), ColorSchemes.negativeColor)

        // Special
        XCTAssertEqual(ColorSchemes.color(forResidueName: "GLY"), ColorSchemes.specialColor)
    }

    func testResidueGradientColors() {
        let color0 = ColorSchemes.color(forResidueIndex: 0, totalResidues: 10)
        let color9 = ColorSchemes.color(forResidueIndex: 9, totalResidues: 10)

        // First should be blue-ish, last should be red-ish
        XCTAssertGreaterThan(color0.z, color0.x, "First residue should be more blue")
        XCTAssertGreaterThan(color9.x, color9.z, "Last residue should be more red")
    }

    // MARK: - Mesh Builder Tests

    func testRibbonMeshGeneration() {
        let frames = [
            TNBFrame(position: SIMD3<Float>(0, 0, 0),
                     tangent: SIMD3<Float>(1, 0, 0),
                     normal: SIMD3<Float>(0, 1, 0),
                     binormal: SIMD3<Float>(0, 0, 1)),
            TNBFrame(position: SIMD3<Float>(1, 0, 0),
                     tangent: SIMD3<Float>(1, 0, 0),
                     normal: SIMD3<Float>(0, 1, 0),
                     binormal: SIMD3<Float>(0, 0, 1)),
            TNBFrame(position: SIMD3<Float>(2, 0, 0),
                     tangent: SIMD3<Float>(1, 0, 0),
                     normal: SIMD3<Float>(0, 1, 0),
                     binormal: SIMD3<Float>(0, 0, 1))
        ]

        let profiles = [
            RibbonProfile(halfWidth: 0.5, halfThickness: 0.1),
            RibbonProfile(halfWidth: 0.5, halfThickness: 0.1),
            RibbonProfile(halfWidth: 0.5, halfThickness: 0.1)
        ]

        let colors = [
            SIMD4<Float>(1, 0, 0, 1),
            SIMD4<Float>(0, 1, 0, 1),
            SIMD4<Float>(0, 0, 1, 1)
        ]

        let mesh = MeshBuilder.buildRibbonMesh(
            frames: frames,
            profiles: profiles,
            colors: colors,
            addEndCaps: true
        )

        XCTAssertGreaterThan(mesh.positions.count, 0, "Should have vertices")
        XCTAssertGreaterThan(mesh.normals.count, 0, "Should have normals")
        XCTAssertGreaterThan(mesh.indices.count, 0, "Should have indices")
        XCTAssertEqual(mesh.positions.count, mesh.normals.count, "Should have equal positions and normals")
        XCTAssertEqual(mesh.positions.count, mesh.colors.count, "Should have equal positions and colors")
    }

    // MARK: - Integration Tests

    func testFullEntityGeneration() {
        let entity = ProteinRibbon.entity(from: samplePDB)

        XCTAssertNotNil(entity, "Should create an entity")
        XCTAssertEqual(entity.name, "ProteinRibbon")
    }

    func testEntityWithOptions() {
        var options = ProteinRibbon.Options()
        options.colorScheme = .byChain
        options.scale = 0.02
        options.samplesPerResidue = 4

        let entity = ProteinRibbon.entity(from: samplePDB, options: options)

        XCTAssertNotNil(entity, "Should create an entity with custom options")
    }

    func testStructureSummary() {
        let summary = ProteinRibbon.structureSummary(from: samplePDB)

        XCTAssertTrue(summary.contains("Atoms: 48"))
        XCTAssertTrue(summary.contains("Residues: 12"))
        XCTAssertTrue(summary.contains("Helices: 1"))
        XCTAssertTrue(summary.contains("Sheets: 1"))
    }

    // MARK: - Edge Cases

    func testEmptyPDBString() {
        let entity = ProteinRibbon.entity(from: "")
        XCTAssertNotNil(entity, "Should handle empty string")
    }

    func testPDBWithOnlyComments() {
        let pdb = """
        HEADER    TEST
        REMARK This is a comment
        END
        """
        let entity = ProteinRibbon.entity(from: pdb)
        XCTAssertNotNil(entity, "Should handle PDB with no atoms")
    }
}
