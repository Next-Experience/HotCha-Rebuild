import Testing

@testable import HotChaKit

@Suite struct 닉네임_만들기 {
    @Test func 색_음식_동물이_서른_개씩이다() {
        #expect(NicknameGenerator.colors.count == 30)
        #expect(NicknameGenerator.foods.count == 30)
        #expect(NicknameGenerator.animals.count == 30)
    }

    @Test func 같은_낱말이_두_번_들어_있지_않다() {
        #expect(Set(NicknameGenerator.colors).count == NicknameGenerator.colors.count)
        #expect(Set(NicknameGenerator.foods).count == NicknameGenerator.foods.count)
        #expect(Set(NicknameGenerator.animals).count == NicknameGenerator.animals.count)
    }

    @Test func 색_음식_먹는_동물_순서로_잇는다() {
        let parts = NicknameGenerator.random().split(separator: " ").map(String.init)
        #expect(parts.count == 4)
        #expect(NicknameGenerator.colors.contains(parts[0]))
        #expect(NicknameGenerator.foods.contains(parts[1]))
        #expect(parts[2] == "먹는")
        #expect(NicknameGenerator.animals.contains(parts[3]))
    }
}
