import Testing

@testable import HotChaKit

/// 남북으로 곧게 뻗은 노선. 정류장 간격은 약 400m (위도 0.0036도).
private func 직선_노선(_ count: Int) -> [GeoPoint] {
    (0..<count).map { GeoPoint(latitude: 37.5 - Double($0) * 0.0036, longitude: 127.0) }
}

@Suite struct 출발_정류장 {
    @Test func 가장_가까운_정류장에서_출발한다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 8, alarmStopsBefore: 2))
        let update = tracker.update(location: stops[3])
        #expect(update.currentIndex == 3)
        #expect(update.remaining == 5)
        #expect(update.isFirstFix)
    }

    @Test func 두_정류장_사이에서는_더_가까운_쪽에서_출발한다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 8, alarmStopsBefore: 2))
        // 0번에서 100m 내려온 자리. 1번까지는 300m 남았다.
        let update = tracker.update(location: GeoPoint(latitude: 37.5 - 0.0009, longitude: 127.0))
        #expect(update.currentIndex == 0)
    }

    @Test func 목적지를_지난_정류장은_출발점이_아니다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 4, alarmStopsBefore: 2))
        let update = tracker.update(location: stops[9])
        #expect(update.currentIndex <= 4)
    }

    @Test func 왕복_노선이_같은_자리를_두_번_지나면_목적지_쪽_순번을_고른다() throws {
        // 0→1→2 로 갔다가 2→1→0 자리로 되돌아오는 노선. 1번과 3번이 길 건너 같은 자리다.
        let out = 직선_노선(3)
        let stops = out + [out[1], out[0]]
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 4, alarmStopsBefore: 1))
        let update = tracker.update(location: out[1])
        #expect(update.currentIndex == 3)
    }
}

@Suite struct 정류장_따라가기 {
    @Test func 다음_정류장_반경에_들어오면_한_칸_전진한다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 9, alarmStopsBefore: 2))
        _ = tracker.update(location: stops[0])
        #expect(tracker.update(location: stops[1]).currentIndex == 1)
    }

    @Test func 도착_반경_밖이면_전진하지_않는다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 9, alarmStopsBefore: 2))
        _ = tracker.update(location: stops[0])
        // 0번과 1번의 한가운데(각 200m). 반경 경계를 살짝 벗어난 0번 쪽.
        let update = tracker.update(location: GeoPoint(latitude: 37.5 - 0.0015, longitude: 127.0))
        #expect(update.currentIndex == 0)
    }

    @Test func 정류장을_하나_건너뛰어도_따라잡는다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 9, alarmStopsBefore: 2))
        _ = tracker.update(location: stops[0])
        let update = tracker.update(location: stops[2])
        #expect(update.currentIndex == 2)
        #expect(update.remaining == 7)
    }

    @Test func 뒤로는_가지_않는다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 9, alarmStopsBefore: 2))
        _ = tracker.update(location: stops[3])
        #expect(tracker.update(location: stops[1]).currentIndex == 3)
    }
}

@Suite struct 알람_시점 {
    @Test func N정류장_전에_알람이_한_번만_울린다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 6, alarmStopsBefore: 2))
        let fired = (0...6).map { tracker.update(location: stops[$0]).shouldFireAlarm }
        #expect(fired == [false, false, false, false, true, false, false])
    }

    @Test func 알람_정류장을_건너뛰어도_울린다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 6, alarmStopsBefore: 2))
        _ = tracker.update(location: stops[2])
        _ = tracker.update(location: stops[3])
        // 4번(알람 정류장)을 놓치고 5번에서 위치가 잡혔다.
        #expect(tracker.update(location: stops[5]).shouldFireAlarm)
    }

    @Test func 시작부터_N보다_가까우면_바로_울리지_않고_한_정류장_전에_울린다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 6, alarmStopsBefore: 3))
        // 목적지 2정류장 전에서 탔다. N=3 이지만 타자마자 울리면 안 된다.
        #expect(!tracker.update(location: stops[4]).shouldFireAlarm)
        #expect(tracker.update(location: stops[5]).shouldFireAlarm)
    }

    @Test func 목적지_바로_앞에서_타면_도착할_때_울린다() throws {
        let stops = 직선_노선(10)
        var tracker = try #require(RouteTracker(stops: stops, destinationIndex: 6, alarmStopsBefore: 2))
        #expect(!tracker.update(location: stops[5]).shouldFireAlarm)
        #expect(tracker.update(location: stops[6]).shouldFireAlarm)
    }

    @Test func 알람_정류장은_노선_앞쪽_끝을_넘지_않는다() throws {
        let tracker = try #require(RouteTracker(stops: 직선_노선(5), destinationIndex: 1, alarmStopsBefore: 3))
        #expect(tracker.alarmStopIndex == 0)
    }

    @Test func 목적지가_노선_밖이면_만들_수_없다() {
        #expect(RouteTracker(stops: 직선_노선(5), destinationIndex: 5, alarmStopsBefore: 2) == nil)
    }
}

@Suite struct 거리_계산 {
    @Test func 위도_0_0036도는_약_400m다() {
        let a = GeoPoint(latitude: 37.5, longitude: 127.0)
        let b = GeoPoint(latitude: 37.5036, longitude: 127.0)
        #expect(abs(a.distance(to: b) - 400) < 2)
    }
}

@Suite struct 이동_거리 {
    @Test func 정류장_사이를_순서대로_더한다() {
        // 400m 간격의 정류장 넷을 지나면 약 1.2km 다.
        #expect(abs(직선_노선(10).pathLength(from: 2, to: 5) - 1200) < 6)
    }

    @Test func 움직이지_않았거나_뒤로_가면_0이다() {
        let stops = 직선_노선(10)
        #expect(stops.pathLength(from: 3, to: 3) == 0)
        #expect(stops.pathLength(from: 5, to: 2) == 0)
        #expect(stops.pathLength(from: 0, to: 99) == 0)
    }
}
