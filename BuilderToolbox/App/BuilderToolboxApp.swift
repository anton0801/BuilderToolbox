import SwiftUI

struct BuilderToolConfig {
    static let appID = "6761608713"
    static let devKey = "aq89LxRNQwPDrmD2dgrcN7"
}

@main
struct BuilderToolboxApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
    
}

struct RootView: View {
    
    @StateObject private var appState = ApplicationMainState()
    @StateObject private var projectsVM = ProjectsViewModel()
    @StateObject private var shoppingVM = ShoppingViewModel()
    @StateObject private var tasksVM = TasksViewModel()

    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            } else if !appState.isLoggedIn {
                WelcomeView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else {
                MainTabView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .environmentObject(appState)
        .environmentObject(projectsVM)
        .environmentObject(shoppingVM)
        .environmentObject(tasksVM)
        .preferredColorScheme(appState.colorScheme)
    }
}
