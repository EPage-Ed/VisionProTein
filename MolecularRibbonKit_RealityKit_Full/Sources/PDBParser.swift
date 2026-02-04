
import Foundation

public struct Atom {
    public var x: Float
    public var y: Float
    public var z: Float
    public var residue: String
    public var chain: String
    public var atomName: String
}

public class PDBParser {
    public init() {}

    public func parse(_ pdb: String) -> [Atom] {
        var atoms:[Atom]=[]
        for line in pdb.split(separator:"\n") {
            if line.starts(with:"ATOM") || line.starts(with:"HETATM") {
                let x = Float(line[30:38].trimmingCharacters(in:.whitespaces)) ?? 0
                let y = Float(line[38:46].trimmingCharacters(in:.whitespaces)) ?? 0
                let z = Float(line[46:54].trimmingCharacters(in:.whitespaces)) ?? 0
                let res = String(line[17:20]).trimmingCharacters(in:.whitespaces)
                let chain = String(line[21]).trimmingCharacters(in:.whitespaces)
                let atom = String(line[12:16]).trimmingCharacters(in:.whitespaces)
                atoms.append(Atom(x:x,y:y,z:z,residue:res,chain:chain,atomName:atom))
            }
        }
        return atoms
    }
}
