import SwiftUI

/// 켤 때 홈의 덩어리가 아래에서부터 하나씩 올라와 자리에 앉는 모양.
///
/// 디딤(모루) 홈의 조립과 같은 값이다. 하는 일은 `offset` 과 `opacity` 둘뿐이다 —
/// `blur` 는 매 프레임 오프스크린 렌더링을 부르는데, 이 움직임이 도는 때가 하필
/// 첫 화면을 그리느라 가장 바쁜 때다.
enum AppearStagger {
    /// 덩어리 사이 간격.
    static let interval: Double = 0.1
    /// 아래로 밀려 있는 거리.
    static let distance: CGFloat = 48

    static func delay(_ order: Int) -> Double { Double(order) * interval }
}

/// 등장이 어디까지 왔나. 화면이 하나 들고 덩어리마다 넘긴다.
struct AppearState {
    /// 자리에 앉았나.
    var isSettled = false
    /// 움직임을 보여 줄 차례인가. 한 번 본 화면을 다시 들를 때는 `false` 라 제자리에 있다.
    var animates = false
}

extension View {
    /// 이 덩어리를 `order` 째로 앉힌다. 0 부터, `order × 0.1초` 늦게 온다.
    func staggeredAppear(order: Int, state: AppearState) -> some View {
        modifier(StaggeredAppearModifier(order: order, state: state))
    }
}

/// `offset` 은 배치를 안 바꾼다. 자리는 처음부터 최종 배치 그대로고 그림만 밀려 있다 —
/// 배치를 건드리면 스크롤 높이가 움직이는 도중에 자라 화면이 출렁인다.
private struct StaggeredAppearModifier: ViewModifier {
    let order: Int
    let state: AppearState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            // 덩어리 하나를 통짜로 다룬다. 안 묶으면 덩어리 안의 배치까지 함께 움직인다.
            .geometryGroup()
            .offset(y: offset)
            .opacity(state.isSettled ? 1 : 0)
            .animation(animation, value: state.isSettled)
    }

    /// 움직임 줄이기면 아예 안 밀린다. 짙어지는 것만 남는다.
    private var offset: CGFloat {
        guard !reduceMotion, !state.isSettled else { return 0 }
        return AppearStagger.distance
    }

    private var animation: Animation? {
        guard state.animates else { return nil }
        guard !reduceMotion else { return .easeOut(duration: 0.2) }
        return .spring(response: 0.42, dampingFraction: 0.82)
            .delay(AppearStagger.delay(order))
    }
}
