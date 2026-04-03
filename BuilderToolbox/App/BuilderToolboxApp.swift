import SwiftUI

@main
struct BuilderToolboxApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var projectsVM = ProjectsViewModel()
    @StateObject private var shoppingVM = ShoppingViewModel()
    @StateObject private var tasksVM = TasksViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(projectsVM)
                .environmentObject(shoppingVM)
                .environmentObject(tasksVM)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
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
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation { showSplash = false }
            }
        }
    }
}
