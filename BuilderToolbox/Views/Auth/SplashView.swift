import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var gridOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var scanLineY: CGFloat = -120
    @State private var particles: [SplashParticle] = SplashParticle.generate(count: 20)
    
    @StateObject private var app: BuilderToolApplication
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = UserDefaultsStorageService()
        let validation = SupabaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        _app = StateObject(wrappedValue: BuilderToolApplication(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#0F1923"), Color(hex: "#1A2B4A"), Color(hex: "#0F1923")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image("splash_back_bg")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 10)
                        .opacity(0.7)
                }
                .ignoresSafeArea()
                
                // Blueprint grid
                BlueprintGridView()
                    .opacity(gridOpacity)
                    .ignoresSafeArea()
                
                // Particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.btAccent.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                }
                
                NavigationLink(
                    destination: BuilderToolWebView().navigationBarHidden(true),
                    isActive: $app.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $app.navigateToMain
                ) { EmptyView() }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo container
                    ZStack {
                        // Outer pulse ring
                        Circle()
                            .stroke(Color.btSecondary.opacity(0.2), lineWidth: 1)
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseScale)
                        
                        Circle()
                            .stroke(Color.btAccent.opacity(0.15), lineWidth: 1)
                            .frame(width: 110, height: 110)
                            .scaleEffect(1.0 / pulseScale)
                        
                        // Logo bg
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "#1E3A5F"), Color(hex: "#152840")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 88, height: 88)
                            .shadow(color: Color.btSecondary.opacity(0.4), radius: 20, x: 0, y: 8)
                        
                        // Room icon with scan line
                        ZStack {
                            // Room outline
                            RoomLogoShape()
                                .stroke(Color.btAccent, lineWidth: 2.5)
                                .frame(width: 46, height: 42)
                            
                            // Scan line
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.clear, Color.btSecondary.opacity(0.8), Color.clear],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: 46, height: 2)
                                .offset(y: scanLineY)
                                .clipped()
                        }
                        .frame(width: 46, height: 42)
                        .clipped()
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    Spacer().frame(height: 32)
                    
                    // App name
                    VStack(spacing: 8) {
                        Text("BuilderToolbox")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                        
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color.btAccent.opacity(0.5))
                                .frame(width: 30, height: 1)
                            Text("Scan and plan your room")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))
                                .tracking(1)
                            Rectangle()
                                .fill(Color.btAccent.opacity(0.5))
                                .frame(width: 30, height: 1)
                        }
                        
                        ProgressView()
                            .tint(.white)
                    }
                    .opacity(textOpacity)
                    
                    Spacer()
                    
                    
                }
            }
            .onAppear {
                startAnimations()
                setupStreams()
                setupNetworkMonitoring()
                app.initialize()
            }
            .fullScreenCover(isPresented: $app.showPermissionPrompt) {
                BuilderToolNotificationView(app: app)
            }
            .fullScreenCover(isPresented: $app.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func startAnimations() {
        withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
            gridOpacity = 0.12
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.2).delay(0.6)) {
            scanLineY = 120
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            textOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.5)) {
            pulseScale = 1.15
        }
        // Animate particles
        for i in particles.indices {
            withAnimation(.easeInOut(duration: Double.random(in: 1.5...3.0)).repeatForever(autoreverses: true).delay(Double.random(in: 0...1.5))) {
                particles[i].opacity = Double.random(in: 0.05...0.3)
            }
        }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                app.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                app.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                app.networkStatusChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

struct RoomLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Room outline (L-shaped floor plan)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.55, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        // Door arc
        path.move(to: CGPoint(x: w * 0.1, y: h))
        path.addArc(center: CGPoint(x: w * 0.1, y: h * 0.78),
                    radius: h * 0.22, startAngle: .degrees(90),
                    endAngle: .degrees(0), clockwise: true)
        return path
    }
}

struct SplashParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double

    static func generate(count: Int) -> [SplashParticle] {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        return (0..<count).map { _ in
            SplashParticle(
                x: CGFloat.random(in: 0...screenW),
                y: CGFloat.random(in: 0...screenH),
                size: CGFloat.random(in: 2...5),
                opacity: 0.05
            )
        }
    }
}

struct BuilderToolNotificationView: View {
    let app: BuilderToolApplication
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "builder_toolbox_p_bg_l" : "builder_toolbox_p_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 4) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("Lalezar-Regular", size: 25))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .lineSpacing(0)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("Lalezar-Regular", size: 18))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .lineSpacing(0)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                app.requestPermission()
            } label: {
                Image("builder_toolbox_p_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                app.deferPermission()
            } label: {
                Image("builder_toolbox_p_btn2")
                    .resizable()
                    .frame(width: 280, height: 40)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(geometry.size.width > geometry.size.height ? "builder_toolbox_wifi_bg_l" : "builder_toolbox_wifi_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 10)
                    .opacity(0.7)
                
                Image("builder_toolbox_wifi_alert")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}
