import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var gridOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var scanLineY: CGFloat = -120
    @State private var particles: [SplashParticle] = SplashParticle.generate(count: 20)

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#0F1923"), Color(hex: "#1A2B4A"), Color(hex: "#0F1923")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
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
                }
                .opacity(textOpacity)

                Spacer()

                // Bottom tagline
                VStack(spacing: 4) {
                    Text("by Anthropic")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.25))
                }
                .opacity(textOpacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear { startAnimations() }
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

//struct BlueprintGridView: View {
//    var body: some View {
//        Canvas { context, size in
//            let spacing: CGFloat = 30
//            let color = Color(hex: "#2D7DD2").opacity(0.15)
//            var x: CGFloat = 0
//            while x <= size.width {
//                context.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) },
//                               with: .color(color), lineWidth: 0.5)
//                x += spacing
//            }
//            var y: CGFloat = 0
//            while y <= size.height {
//                context.stroke(Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) },
//                               with: .color(color), lineWidth: 0.5)
//                y += spacing
//            }
//        }
//    }
//}

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
