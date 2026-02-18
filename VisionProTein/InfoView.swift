//
//  InfoView.swift
//  VisionProTein
//

import SwiftUI

// MARK: - Section Header

private struct SectionHeader: View {
  let title: String
  let systemImage: String
  
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.title2)
        .foregroundStyle(.green)
      Text(title)
        .font(.title2)
        .fontWeight(.semibold)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 4)
  }
}

// MARK: - Glossary Card

private struct GlossaryCard: View {
  let term: String
  let definition: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(term)
        .font(.headline)
        .foregroundStyle(.green)
      Text(definition)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.white.opacity(0.08))
    }
    .overlay {
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color.white.opacity(0.18), lineWidth: 1)
    }
  }
}

// MARK: - Atom Color Row

private struct AtomColorRow: View {
  let element: String
  let elementName: String
  let color: Color
  let description: String
  
  var body: some View {
    HStack(spacing: 14) {
      Circle()
        .fill(color)
        .frame(width: 28, height: 28)
        .shadow(color: color.opacity(0.6), radius: 4)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(element)
            .font(.headline)
            .monospacedDigit()
          Text(elementName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Text(description)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      Spacer()
    }
  }
}

// MARK: - Gesture Step

private struct GestureStep: View {
  let systemImage: String
  let title: String
  let description: String
  
  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: systemImage)
        .font(.title3)
        .foregroundStyle(.green)
        .frame(width: 32)
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

// MARK: - Visualization Mode Card

private struct VisModeCard: View {
  let name: String
  let systemImage: String
  let description: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
          .font(.title3)
          .foregroundStyle(.green)
        Text(name)
          .font(.headline)
      }
      Text(description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.white.opacity(0.08))
    }
    .overlay {
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color.white.opacity(0.18), lineWidth: 1)
    }
  }
}

// MARK: - Ribbon Color Legend Row

private struct RibbonColorLegendRow: View {
  let color: Color
  let label: String
  let description: String
  
  var body: some View {
    HStack(spacing: 10) {
      RoundedRectangle(cornerRadius: 4)
        .fill(color)
        .frame(width: 20, height: 20)
      VStack(alignment: .leading, spacing: 1) {
        Text(label)
          .font(.subheadline)
          .fontWeight(.medium)
        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
  }
}

// MARK: - InfoView

struct InfoView: View {
  // Glossary terms
  private let glossaryItems: [(term: String, definition: String)] = [
    ("Protein",
     "A large biological molecule made of one or more chains of amino acids. Proteins perform nearly every function in living cells — from structural support to catalyzing chemical reactions."),
    ("Ligand",
     "A small molecule that binds to a specific site on a protein. Ligands can act as substrates, inhibitors, or activators and are crucial in drug design and biochemical signaling."),
    ("Residue",
     "A single amino acid unit within a protein chain. Residues are linked end-to-end by peptide bonds to form the backbone of the protein."),
    ("Binding",
     "The non-covalent interaction between a protein and a ligand (or another molecule). Binding is highly specific and underlies processes like enzyme catalysis, immune response, and signal transduction."),
    ("Ball & Stick",
     "A visualization style that represents each atom as a sphere (the 'ball') and each chemical bond as a cylinder (the 'stick'). Atoms are colored by element using the standard CPK color scheme."),
    ("Ribbon",
     "A schematic cartoon representation of a protein's backbone. Helices appear as coiled ribbons, beta sheets as flat arrows, and loops as thin tubes, making secondary structure immediately visible."),
    ("Sphere",
     "A space-filling (van der Waals) representation where each atom is drawn as a large sphere proportional to its atomic radius. Useful for visualizing the overall shape and surface of the molecule."),
  ]
  
  // CPK atom colors (matching ElementColors in BallAndStick.swift)
  private let atomColors: [(element: String, name: String, color: Color, description: String)] = [
    ("H",  "Hydrogen",  Color(red: 1.0, green: 1.0, blue: 1.0), "Most abundant element in proteins"),
    ("C",  "Carbon",    Color(red: 0.5, green: 0.5, blue: 0.5), "The backbone of all organic molecules"),
    ("N",  "Nitrogen",  Color(red: 0.2, green: 0.3, blue: 1.0), "Found in the peptide backbone and side chains"),
    ("O",  "Oxygen",    Color(red: 1.0, green: 0.2, blue: 0.2), "Highly electronegative; key in hydrogen bonding"),
    ("S",  "Sulfur",    Color(red: 1.0, green: 1.0, blue: 0.2), "Present in cysteine and methionine"),
    ("P",  "Phosphorus",Color(red: 1.0, green: 0.5, blue: 0.0), "Found in nucleic acids and some ligands"),
    ("FE", "Iron",      Color(red: 0.9, green: 0.5, blue: 0.0), "Metal cofactor, e.g. in hemoglobin heme groups"),
    ("ZN", "Zinc",      Color(red: 0.5, green: 0.5, blue: 0.7), "Structural metal in zinc-finger proteins"),
    ("CA", "Calcium",   Color(red: 0.5, green: 0.5, blue: 0.5), "Signaling ion and structural cofactor"),
  ]
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        
        // Header
        VStack(alignment: .leading, spacing: 6) {
          Text("Vision \(Text("ProTein").foregroundStyle(Color.green))")
            .font(.largeTitle)
            .fontWeight(.bold)
          Text("An immersive 3D protein structure viewer for Apple Vision Pro")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
        
        Divider()
        
        // MARK: Glossary
        VStack(alignment: .leading, spacing: 14) {
          SectionHeader(title: "Glossary", systemImage: "text.book.closed")
          
          LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(glossaryItems, id: \.term) { item in
              GlossaryCard(term: item.term, definition: item.definition)
            }
          }
        }
        
        Divider()
        
        // MARK: Visualization Modes
        VStack(alignment: .leading, spacing: 14) {
          SectionHeader(title: "Visualization Modes", systemImage: "eye")
          
          LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            VisModeCard(
              name: "Sphere",
              systemImage: "circle.fill",
              description: "Space-filling view. Each atom is drawn as a large sphere. Toggle Folded/Unfolded to spread chains apart for a clearer view of individual chains."
            )
            VisModeCard(
              name: "Ribbon",
              systemImage: "waveform.path",
              description: "Cartoon backbone trace. Helices → coiled ribbons, sheets → flat arrows, loops → thin tubes. Choose a coloring scheme from the Ribbon menu."
            )
            VisModeCard(
              name: "Ball & Stick",
              systemImage: "atom",
              description: "Atomic detail view. Atoms as colored spheres, bonds as gray cylinders. Enable Ligands and Bindings for extra detail. Use Tag Mode to label residues."
            )
          }
          
          // Ribbon color schemes
          VStack(alignment: .leading, spacing: 10) {
            Text("Ribbon Color Schemes")
              .font(.subheadline)
              .fontWeight(.semibold)
              .padding(.top, 4)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 10) {
              RibbonColorLegendRow(color: Color(red: 0.9, green: 0.2, blue: 0.2), label: "Structure — Helix", description: "Alpha helices shown in red")
              RibbonColorLegendRow(color: Color(red: 0.2, green: 0.4, blue: 0.9), label: "Structure — Sheet", description: "Beta sheets shown in blue")
              RibbonColorLegendRow(color: Color(red: 0.2, green: 0.8, blue: 0.3), label: "Structure — Coil", description: "Loops and coils shown in green")
              RibbonColorLegendRow(color: Color(red: 0.8, green: 0.8, blue: 0.2), label: "Type — Hydrophobic", description: "ALA, VAL, LEU, ILE, MET, PHE, TRP, TYR")
              RibbonColorLegendRow(color: Color(red: 0.2, green: 0.8, blue: 0.8), label: "Type — Polar", description: "SER, THR, ASN, GLN")
              RibbonColorLegendRow(color: Color(red: 0.8, green: 0.4, blue: 0.8), label: "Type — Special", description: "GLY, PRO, CYS")
            }
            .padding(.horizontal, 4)
          }
          .padding(14)
          .background {
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.white.opacity(0.06))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 14)
              .stroke(Color.white.opacity(0.14), lineWidth: 1)
          }
        }
        
        Divider()
        
        // MARK: Atom Colors (CPK)
        VStack(alignment: .leading, spacing: 14) {
          SectionHeader(title: "Atom Colors (CPK)", systemImage: "paintpalette")
          
          Text("The Ball & Stick view uses the standard CPK (Corey–Pauling–Koltun) color convention.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          
          LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 12) {
            ForEach(atomColors, id: \.element) { atom in
              AtomColorRow(
                element: atom.element,
                elementName: atom.name,
                color: atom.color,
                description: atom.description
              )
            }
          }
        }
        
        Divider()
        
        // MARK: How to Use
        VStack(alignment: .leading, spacing: 14) {
          SectionHeader(title: "How to Use", systemImage: "hand.raised")
          
          // Loading structures
          VStack(alignment: .leading, spacing: 10) {
            Text("Loading a Structure")
              .font(.subheadline)
              .fontWeight(.semibold)
            
            GestureStep(
              systemImage: "doc.badge.plus",
              title: "Tap the Load button",
              description: "The Load button (document icon) appears in the top-right ornament. Tap it to reveal the list of available PDB structures."
            )
            GestureStep(
              systemImage: "list.bullet",
              title: "Choose a structure",
              description: "Select any entry from the list (e.g. 4HHB Human Haemoglobin). The structure loads directly into your space."
            )
          }
          .padding(14)
          .background {
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.white.opacity(0.06))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 14)
              .stroke(Color.white.opacity(0.14), lineWidth: 1)
          }
          
          // Gestures
          VStack(alignment: .leading, spacing: 10) {
            Text("Manipulating the Model")
              .font(.subheadline)
              .fontWeight(.semibold)
            
            GestureStep(
              systemImage: "hand.pinch",
              title: "Pinch & Drag — Move",
              description: "Pinch the protein with one hand and drag to reposition it anywhere in your space."
            )
            GestureStep(
              systemImage: "arrow.up.left.and.arrow.down.right",
              title: "Two-Handed Pinch — Scale",
              description: "Pinch with both hands and move them apart or together to scale the model up or down."
            )
            GestureStep(
              systemImage: "rotate.3d",
              title: "Two-Handed Rotate",
              description: "Pinch with both hands and rotate them around each other to spin the molecule in 3D."
            )
          }
          .padding(14)
          .background {
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.white.opacity(0.06))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 14)
              .stroke(Color.white.opacity(0.14), lineWidth: 1)
          }
          
          // Tag Mode
          VStack(alignment: .leading, spacing: 10) {
            Text("Tag Mode")
              .font(.subheadline)
              .fontWeight(.semibold)
            
            GestureStep(
              systemImage: "hand.point.up.left",
              title: "Enable Tag Mode",
              description: "In the control panel, enable Ball & Stick and then turn on Tag Mode. Small indicator spheres will appear on your left thumb and middle finger."
            )
            GestureStep(
              systemImage: "hand.pinch.fill",
              title: "Left-Hand Pinch to Tag",
              description: "Reach toward an atom with your left hand and pinch (bring thumb and middle finger together). The residue under your fingertip is tagged and added to the Tagged Residues list."
            )
            GestureStep(
              systemImage: "list.star",
              title: "Tagged Residues Panel",
              description: "Tagged residues appear in the panel below the controls, highlighted in yellow. Tap any residue name to select it and view its details — name, chain, sequence number, and amino acid description."
            )
            GestureStep(
              systemImage: "link",
              title: "Show Bindings",
              description: "Toggle Bindings in the control panel to highlight residues near the ligand binding site. Adjust the Extension slider (0–15 Å) to widen or narrow the binding shell."
            )
          }
          .padding(14)
          .background {
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.white.opacity(0.06))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 14)
              .stroke(Color.white.opacity(0.14), lineWidth: 1)
          }
          
          // Skybox
          VStack(alignment: .leading, spacing: 10) {
            Text("Environment")
              .font(.subheadline)
              .fontWeight(.semibold)
            
            GestureStep(
              systemImage: "fossil.shell",
              title: "Skybox",
              description: "Tap the Skybox button (shell icon) to adjust the opacity of the immersive environment background. Slide to 0% for a clear passthrough view."
            )
            GestureStep(
              systemImage: "square.split.2x2",
              title: "Folded / Unfolded (Sphere mode)",
              description: "When Sphere mode is active, toggle Folded to animate the protein chains spreading apart — great for distinguishing multi-chain proteins like hemoglobin."
            )
          }
          .padding(14)
          .background {
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.white.opacity(0.06))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 14)
              .stroke(Color.white.opacity(0.14), lineWidth: 1)
          }
        }
        
        Spacer(minLength: 20)
      }
      .padding(28)
    }
  }
}

#Preview(windowStyle: .automatic) {
  InfoView()
//    .frame(width: 900)
}
