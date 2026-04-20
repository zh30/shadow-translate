import SwiftUI

public enum Theme {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
    }

    public enum Size {
        public static let popupWidth: CGFloat = 440
        public static let popupMinHeight: CGFloat = 280
        public static let popupMaxHeight: CGFloat = 520
        public static let mainWindowMinWidth: CGFloat = 960
        public static let mainWindowMinHeight: CGFloat = 600
    }

    public static let animation: Animation = .smooth(duration: 0.25)
    public static let springAnimation: Animation = .spring(duration: 0.3, bounce: 0.15)
}

// MARK: - View Modifiers

public struct MaterialBackground: ViewModifier {
    public func body(content: Content) -> some View {
        content.background(.regularMaterial)
    }
}

public extension View {
    func materialBackground() -> some View {
        modifier(MaterialBackground())
    }

    func cardStyle() -> some View {
        padding(Theme.Spacing.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }
}