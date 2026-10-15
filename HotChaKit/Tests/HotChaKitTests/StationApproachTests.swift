import Foundation
import Testing

@testable import HotChaKit

/// 대전역 근처를 목적지로 둔다. 북쪽으로 m 만큼 떨어진 자리를 만든다 (위도 1도 ≈ 111.2km).
private let 대전역 = GeoPoint(latitude: 36.3323, longitude: 127.4344)
private func 북쪽(_ meters: Double) -> GeoPoint {
    GeoPoint(latitude: 대전역.latitude + meters / 111_195, longitude: 대전역.longitude)
}
private let 출발 = Date(timeIntervalSinceReferenceDate: 0)
private func 초(_ seconds: TimeInterval) -> Date { 출발.addingTimeInterval(seconds) }

@Suite struct 역_거리_알람 {
    @Test func 반경_안에_들어오면_한_번만_울린다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        #expect(!approach.update(location: 북쪽(30_000), accuracy: 30, at: 초(0)).shouldFireAlarm)
        let inside = approach.update(location: 북쪽(9_000), accuracy: 30, at: 초(120))
        #expect(inside.shouldFireAlarm)
        #expect(inside.reason == .reached)
        #expect(!approach.update(location: 북쪽(5_000), accuracy: 30, at: 초(150)).shouldFireAlarm)
        #expect(approach.alarmFired)
    }

    @Test func 흐린_위치로는_울리지_않고_거리도_바꾸지_않는다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        _ = approach.update(location: 북쪽(30_000), accuracy: 30, at: 초(0))
        // 터널 안에서 기지국으로 잡은 위치. 반경 안이라고 나와도 믿지 않는다.
        let blurry = approach.update(location: 북쪽(8_000), accuracy: 3_000, at: 초(60))
        #expect(!blurry.shouldFireAlarm)
        #expect(approach.lastDistance.map { abs($0 - 30_000) < 50 } == true)
    }

    @Test func 반경이_0_이하면_만들지_않는다() {
        #expect(StationApproach(destination: 대전역, radius: 0) == nil)
    }
}

@Suite struct 터널_신호_끊김 {
    @Test func 반경_두_배_안에서_신호가_끊기면_미리_울린다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        _ = approach.update(location: 북쪽(15_000), accuracy: 30, at: 초(0))
        let lost = approach.tick(now: 초(StationApproach.signalLossTimeout + 1))
        #expect(lost.shouldFireAlarm)
        #expect(lost.reason == .signalLost)
        #expect(approach.alarmFired)
    }

    @Test func 신호가_끊긴_지_얼마_안_됐으면_기다린다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        _ = approach.update(location: 북쪽(15_000), accuracy: 30, at: 초(0))
        #expect(!approach.tick(now: 초(StationApproach.signalLossTimeout - 1)).shouldFireAlarm)
    }

    @Test func 멀리서_신호가_끊기면_울리지_않는다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        _ = approach.update(location: 북쪽(25_000), accuracy: 30, at: 초(0))
        #expect(!approach.tick(now: 초(600)).shouldFireAlarm)
    }

    @Test func 흐린_위치만_오는_동안도_신호가_끊긴_것이다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        _ = approach.update(location: 북쪽(15_000), accuracy: 30, at: 초(0))
        _ = approach.update(location: 북쪽(14_000), accuracy: 2_000, at: 초(60))
        #expect(approach.tick(now: 초(StationApproach.signalLossTimeout + 1)).shouldFireAlarm)
    }

    @Test func 위치를_한_번도_못_받았으면_울리지_않는다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        #expect(!approach.tick(now: 초(600)).shouldFireAlarm)
    }

    @Test func 신호로_울린_뒤에는_반경에_들어와도_다시_울리지_않는다() throws {
        var approach = try #require(StationApproach(destination: 대전역, radius: 10_000))
        _ = approach.update(location: 북쪽(15_000), accuracy: 30, at: 초(0))
        _ = approach.tick(now: 초(StationApproach.signalLossTimeout + 1))
        #expect(!approach.update(location: 북쪽(3_000), accuracy: 30, at: 초(200)).shouldFireAlarm)
    }
}
