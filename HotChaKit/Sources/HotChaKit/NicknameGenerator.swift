import Foundation

/// 처음 쓰는 사람에게 붙여 주는 닉네임. "보라색 탕수육 먹는 하마" 처럼 색 · 음식 · 동물을 하나씩 뽑아 잇는다.
public enum NicknameGenerator {
    public static let colors = [
        "빨간색", "주황색", "노란색", "연두색", "초록색", "청록색", "하늘색", "파란색", "남색", "보라색",
        "분홍색", "자주색", "갈색", "회색", "흰색", "검은색", "금색", "은색", "민트색", "살구색",
        "상아색", "올리브색", "라벤더색", "코랄색", "베이지색", "카키색", "버건디색", "네이비색", "복숭아색", "무지개색",
    ]

    public static let foods = [
        "탕수육", "떡볶이", "김밥", "라면", "치킨", "피자", "햄버거", "짜장면", "짬뽕", "비빔밥",
        "불고기", "삼겹살", "김치찌개", "된장찌개", "순대", "만두", "칼국수", "냉면", "돈가스", "초밥",
        "우동", "파스타", "샌드위치", "붕어빵", "호떡", "팥빙수", "마카롱", "케이크", "도넛", "아이스크림",
    ]

    public static let animals = [
        "하마", "고양이", "강아지", "토끼", "곰", "호랑이", "사자", "코끼리", "기린", "펭귄",
        "수달", "판다", "여우", "늑대", "다람쥐", "고슴도치", "너구리", "코알라", "캥거루", "돌고래",
        "고래", "거북이", "악어", "부엉이", "참새", "오리", "양", "말", "사슴", "햄스터",
    ]

    public static func random() -> String {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    public static func random<G: RandomNumberGenerator>(using generator: inout G) -> String {
        let color = colors.randomElement(using: &generator) ?? colors[0]
        let food = foods.randomElement(using: &generator) ?? foods[0]
        let animal = animals.randomElement(using: &generator) ?? animals[0]
        return "\(color) \(food) 먹는 \(animal)"
    }
}
