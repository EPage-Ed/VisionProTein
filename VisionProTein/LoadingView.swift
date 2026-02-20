//
//  LoadingView.swift
//  VisionProTein
//
//  Created by Claude Code
//

import SwiftUI

struct LoadingView: View {
  @ObservedObject var model : ARModel
  @State private var currentFile: String = ""
//  @State private var loadingComplete: Bool = false
  @State private var loadProgress: Double = 0.0

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 40) {
        // Header
        VStack(spacing: 10) {
          Text("VisionProTein")
            .font(.system(size: 60, weight: .bold, design: .rounded))
            .foregroundStyle(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
              )
            )

          Text("Protein Visualization for Vision Pro")
            .font(.title3)
            .foregroundColor(.secondary)
        }

        Spacer()

        // Progress section
        VStack(spacing: 20) {
          if !model.loadingComplete {
            VStack(spacing: 15) {
              Text("Loading Protein Structures")
                .font(.title2)
                .fontWeight(.semibold)

              if !currentFile.isEmpty {
                Text("Processing: \(currentFile)")
                  .font(.body)
                  .foregroundColor(.secondary)
              }

              // Progress bar
              ProgressView(value: loadProgress, total: 1.0)
                .progressViewStyle(.linear)
                .animation(.linear(duration: 1.0), value: loadProgress)
                .frame(width: 400)
                .tint(.blue)

              HStack {
                ProgressView()
                  .controlSize(.small)
                  .opacity(loadProgress < 1 ? 1 : 0)
                Text("\(Int(loadProgress * 100))%")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
          } else {
            VStack(spacing: 15) {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

              Text("Ready!")
                .font(.title)
                .fontWeight(.bold)

//              Text("Loaded \(model.cachedPDBs.count) protein structures")
              Text("Protein Structures Loaded")
                .font(.body)
                .foregroundColor(.secondary)
              
              Button {
                withAnimation {
                  model.preloadingComplete = true
                }
              } label: {
                Text("Enter")
                  .font(.title)
                  .foregroundColor(.white)
                  .padding()
              }
              .tint(Color.blue)
              .cornerRadius(8)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
          }
        }

        Spacer()
      }
      .padding()
    }
    .task {
      try! await Task.sleep(for: .seconds(0.1))
      await loadPDBs()
    }
  }

  @MainActor
  private func loadPDBs() async {
    // Run the loading in a background task
    await Task.detached(priority: .userInitiated) {
      let results = PDB.CompleteParseResult.loadAllBundlePDBs { name, progress in
        Task { @MainActor in
          if let name = name {
            self.currentFile = name
          }
          withAnimation(.easeInOut(duration: 1.0)) {
            self.loadProgress = progress
          }
        }
      }

      // Update the model on the main actor
      await MainActor.run {
        self.model.cachedPDBs = results
        withAnimation {
          self.model.loadingComplete = true
        }
      }
    }.value
  }
}

#Preview {
  LoadingView(model: ARModel())
}
