//
//  PDBAdapter.swift
//  ProteinSpheres
//
//  Adapter to convert PDB types to ProteinSpheres types
//

import Foundation

/// Adapter to help convert from external PDB atom types
public extension Atom {
    /// Create an Atom from components that match PDB format
    static func fromPDB(
        serial: Int,
        name: String,
        resName: String,
        chainID: String,
        resSeq: Int,
        x: Double,
        y: Double,
        z: Double,
        element: String
    ) -> Atom {
        return Atom(
            serial: serial,
            name: name,
            resName: resName,
            chainID: chainID,
            resSeq: resSeq,
            x: x,
            y: y,
            z: z,
            element: element
        )
    }
}

/// Adapter to help convert from external PDB residue types
public extension Residue {
    /// Create a Residue from components
    static func fromPDB(
        id: Int,
        serNum: Int,
        chainID: String,
        resName: String,
        atoms: [Atom]
    ) -> Residue {
        return Residue(
            id: id,
            serNum: serNum,
            chainID: chainID,
            resName: resName,
            atoms: atoms
        )
    }
}
