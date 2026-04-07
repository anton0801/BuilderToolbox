import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPageData] = [
        OnboardingPageData(
            id: 0,
            title: "Scan Your Room",
            subtitle: "Use your camera to measure spaces and automatically generate accurate room plans.",
            icon: "camera.viewfinder",
            accentColor: Color(hex: "#2D7DD2"),
            illustration: .scan
        ),
        OnboardingPageData(
            id: 1,
            title: "Create Room Layouts",
            subtitle: "Design detailed floor plans with walls, doors, windows and custom dimensions.",
            icon: "square.grid.3x3.fill",
            accentColor: Color(hex: "#F4A623"),
            illustration: .layout
        ),
        OnboardingPageData(
            id: 2,
            title: "Plan Furniture Placement",
            subtitle: "Drag and drop furniture to visualize your space before buying anything.",
            icon: "chair.fill",
            accentColor: Color(hex: "#27AE60"),
            illustration: .furniture
        ),
    ]

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#0F1923").ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            appState.hasCompletedOnboarding = true
                        }
                    }
                    .font(BTFont.body())
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        OnboardingPageView(data: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Bottom controls
                VStack(spacing: 24) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.btAccent : Color.white.opacity(0.25))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                appState.hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                                .font(BTFont.headline())
                            Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [pages[currentPage].accentColor, pages[currentPage].accentColor.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: pages[currentPage].accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPageData: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let illustration: IllustrationType
}

enum IllustrationType {
    case scan, layout, furniture
}

struct OnboardingPageView: View {
    let data: OnboardingPageData
    @State private var appear = false
    @State private var illustrationAnimate = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(data.accentColor.opacity(0.08))
                    .frame(width: 260, height: 260)
                    .scaleEffect(illustrationAnimate ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: illustrationAnimate)

                switch data.illustration {
                case .scan:
                    ScanIllustration(color: data.accentColor, animate: illustrationAnimate)
                case .layout:
                    LayoutIllustration(color: data.accentColor, animate: illustrationAnimate)
                case .furniture:
                    FurnitureIllustration(color: data.accentColor, animate: illustrationAnimate)
                }
            }
            .frame(height: 260)
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.8)

            Spacer().frame(height: 48)

            // Text
            VStack(spacing: 14) {
                Text(data.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(data.subtitle)
                    .font(BTFont.body(15))
                    .foregroundColor(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) { appear = true }
            withAnimation(.easeInOut(duration: 0.1).delay(0.3)) { illustrationAnimate = true }
        }
        .onDisappear { appear = false }
    }
}

// MARK: - Illustrations
struct ScanIllustration: View {
    let color: Color
    let animate: Bool
    @State private var scanY: CGFloat = -60

    var body: some View {
        ZStack {
            // Room outline
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.6), lineWidth: 2)
                .frame(width: 140, height: 120)

            // Corner markers
            ForEach([CGPoint(x: -70, y: -60), CGPoint(x: 70, y: -60),
                     CGPoint(x: -70, y: 60), CGPoint(x: 70, y: 60)], id: \.x) { pt in
                Circle().fill(color).frame(width: 8, height: 8).offset(x: pt.x, y: pt.y)
            }

            // Scan line
            Rectangle()
                .fill(LinearGradient(colors: [Color.clear, color.opacity(0.8), Color.clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 140, height: 2)
                .offset(y: scanY)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        scanY = 60
                    }
                }

            // Dimension lines
            DimensionLine(length: 140, isHorizontal: true).offset(y: 80)
            DimensionLine(length: 120, isHorizontal: false).offset(x: -90)
        }
        .frame(width: 200, height: 200)
    }
}

struct LayoutIllustration: View {
    let color: Color
    let animate: Bool

    var body: some View {
        ZStack {
            // Floor plan grid
            ForEach(0..<4) { row in
                ForEach(0..<4) { col in
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                        .frame(width: 36, height: 36)
                        .offset(x: CGFloat(col - 1) * 38, y: CGFloat(row - 1) * 38)
                }
            }
            // Rooms highlighted
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.3))
                .frame(width: 74, height: 74)
                .offset(x: -19, y: -19)
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.2))
                .frame(width: 36, height: 74)
                .offset(x: 57, y: -19)
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.15))
                .frame(width: 114, height: 36)
                .offset(x: 0, y: 57)

            // Labels
            Text("LIVING")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .offset(x: -19, y: -19)
            Text("BED")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .offset(x: 57, y: -19)
        }
        .frame(width: 180, height: 180)
    }
}

struct FurnitureIllustration: View {
    let color: Color
    let animate: Bool
    @State private var sofaOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Room
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 2)
                .frame(width: 160, height: 140)

            // Sofa
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.6))
                .frame(width: 90, height: 36)
                .offset(y: -20 + sofaOffset)
                .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)

            // Table
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.3))
                .frame(width: 50, height: 30)
                .offset(y: 26)

            // Bed
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.4))
                .frame(width: 40, height: 60)
                .offset(x: 55, y: 0)

            // Drag indicator
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .offset(y: -20 + sofaOffset)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.5)) {
                sofaOffset = -10
            }
        }
        .frame(width: 200, height: 180)
    }
}

struct DimensionLine: View {
    let length: CGFloat
    let isHorizontal: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: isHorizontal ? length : 1, height: isHorizontal ? 1 : length)
            HStack {
                if isHorizontal {
                    Text("5.2m").font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            .rotationEffect(isHorizontal ? .zero : .degrees(-90))
        }
    }
}
