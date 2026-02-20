//
//  VisionProTeinApp.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import SwiftUI
import RealityKitContent

enum TabItem: CaseIterable {
  case listenNow
  case browse
  case musicVideos
  case radio
  case library
  case search
  
  var name: String {
    switch self {
    case .listenNow: return "Listen Now"
    case .browse: return "Browse"
    case .musicVideos: return "Music Videos"
    case .radio: return "Radio"
    case .library: return "Library"
    case .search: return "Search"
    }
  }
  
  var image: String {
    switch self {
    case .listenNow: return "play.circle"
    case .browse: return "square.grid.2x2"
    case .musicVideos: return "music.note.tv"
    case .radio: return "dot.radiowaves.left.and.right"
    case .library: return "music.note.list"
    case .search: return "magnifyingglass"
    }
  }
}

struct MainView: View {
  @Environment(\.openImmersiveSpace) var openImmersiveSpace
  @ObservedObject var model : ARModel
  @State private var selectedTab: TabItem = .listenNow
  
  var body: some View {
    ZStack {
      TabView(selection: $selectedTab) {
        ContentView(model: model)
          .glassBackgroundEffect()
          .tabItem {
            Label("Explore", systemImage: "eye")
          }
          .tag(TabItem.browse)
        InfoView()
          .glassBackgroundEffect()
          .tabItem {
            Label("Info", systemImage: "info.circle")
          }
          .tag(TabItem.search)
      }
      .opacity((model.preloadingComplete && model.immersiveSpaceReady) ? 1 : 0)
      LoadingView(model: model)
        .opacity((model.preloadingComplete && model.immersiveSpaceReady) ? 0 : 1)
    }
  }
}


@main
struct VisionProTeinApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.openImmersiveSpace) var openImmersiveSpace
  @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
  @StateObject var model = ARModel()
  @State private var showImmersiveSpace = false

  init() {
    MoleculeComponent.registerComponent()
    ProteinComponent.registerComponent()
    GestureComponent.registerComponent()
    InstanceAnimationComponent.registerComponent()
    InstanceAnimationSystem.registerSystem()
    
    try? PDB.CompleteParseResult.clearAllCache()
//    NotificationCenter.default.post(name: .init("EntityScale"), object: nil, userInfo: ["scale":entity.scale])
    /*
    NotificationCenter.default.addObserver(forName: .init("EntityScale"), object: nil, queue: .main) { [self] note in
      if let scale = note.userInfo?["scale"] as? SIMD3<Float> {
        model.ligandScale(scale: scale)
//        model.ligand?.scale = scale
      }
    }
     */

  }
  
  var body: some Scene {
    WindowGroup {
      MainView(model: model)
        .frame(minWidth: 1024, minHeight: 600)
      /*
       .onDisappear {
       Task {
       await dismissImmersiveSpace()
       model.immersiveSpaceIsShown = false
       }
       }
       */
        .onAppear {
        }
        .task(id: scenePhase) {
          switch scenePhase {
          case .inactive, .background:
            model.immersiveSpaceIsShown = false
            showImmersiveSpace = false
          case .active:
            if !model.immersiveSpaceIsShown {
              showImmersiveSpace = true
            }
          default:
            break
          }
        }
      //        .task {
      //          showImmersiveSpace = true
      //          //      await openImmersiveSpace(id: "ImmersiveSpace")
      //          //      model.immersiveSpaceIsShown = true
      //        }
        .onChange(of: showImmersiveSpace) { _, newValue in
          Task {
            if newValue {
              await openImmersiveSpace(id: "ImmersiveSpace")
            } else if model.immersiveSpaceIsShown {
              model.immersiveSpaceIsShown = false
              await dismissImmersiveSpace()
            }
          }
        }
    }
    .defaultSize(width: 1024, height: 600)
    .windowResizability(.contentSize)

    ImmersiveSpace(id: "ImmersiveSpace") {
      ImmersiveView(model: model)
        .task(id: scenePhase) {
          switch scenePhase {
          case .inactive, .background:
            model.immersiveSpaceIsShown = false
          case .active:
            model.immersiveSpaceIsShown = true
          default:
            break
          }
        }
    }
    .immersionStyle(selection: .constant(.mixed), in: .mixed)
    .immersiveEnvironmentBehavior(.coexist)
  }
}

#Preview {
  MainView(model: ARModel())
}

