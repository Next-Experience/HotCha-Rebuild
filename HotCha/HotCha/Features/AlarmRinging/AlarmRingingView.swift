//
//  AlarmRingingView.swift
//  HotCha
//
//  알람이 울릴 때 화면 전체를 덮는 화면. 버스·정류장 안내가 같은 화면을 쓴다.
//  무엇을 해야 하는지(내릴 준비)와 어디서 내리는지만 크게 보여 주고, 행동은 둘뿐이다.
//

import SwiftUI

struct AlarmRingingContent: Equatable {
    /// 내릴 정류장
    let destination: String
    /// "152번 · 2정류장 남았어요" 같은 한 줄
    let detail: String

    /// 개발자 메뉴의 「알람 화면 미리 보기」에서 쓰는 보기
    static let preview = AlarmRingingContent(destination: "두산위브아파트입구", detail: "152번 · 2정류장 남았어요")
}

extension Notification.Name {
    /// 알람 화면에서 안내를 끝냈다. 열려 있는 안내 화면이 닫힌다.
    static let alarmGuidanceFinished = Notification.Name("AlarmGuidanceFinished")
    /// 개발자 메뉴에서 알람 화면을 미리 띄운다.
    static let previewAlarmRinging = Notification.Name("PreviewAlarmRinging")
}

struct AlarmRingingView: View {
    let content: AlarmRingingContent
    /// 알람만 끄고 안내는 이어 간다.
    let onConfirm: () -> Void
    /// 안내를 끝낸다.
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swinging = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Image(Clay.bell.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 168, height: 168)
                // 고리를 축으로 종이 좌우로 흔들린다.
                .rotationEffect(.degrees(swinging ? 9 : -9), anchor: .top)
                .accessibilityHidden(true)

            Text("내릴 준비를 해주세요")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 28)

            Text(content.destination)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Text(content.detail)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous))
                .padding(.top, 14)

            Spacer(minLength: 24)

            VStack(spacing: 6) {
                Button(action: onConfirm) {
                    Text("확인했어요")
                        .font(.headline)
                        .foregroundStyle(Color("mainpurple"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white, in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
                }
                Text("알람만 끄고 안내는 계속돼요")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.bottom, 12)

                Button(action: onFinish) {
                    Text("안내 종료")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("mainpurple").ignoresSafeArea())
        .sensoryFeedback(.warning, trigger: appeared)
        .accessibilityElement(children: .contain)
        .onAppear {
            appeared = true
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                swinging = true
            }
        }
    }
}

#Preview {
    AlarmRingingView(content: .preview, onConfirm: {}, onFinish: {})
}
