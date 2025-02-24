//
//  CityModel.swift
//  HotCha
//
//  Created by 문재윤 on 2/10/25.
//

import Foundation

// City Model
struct City: Hashable {
    let city_code: String
    let city_area: String
    let city_name: String
    let city_x: Double
    let city_y: Double
}

let cities: [City] = [
        // 서울
    City(city_code: "1", city_area: "서울", city_name: "강남구", city_x: 127.0495556, city_y: 37.514575),
    City(city_code: "1", city_area: "서울", city_name: "강동구", city_x: 127.1258639, city_y: 37.52736667),
    City(city_code: "1", city_area: "서울", city_name: "강북구", city_x: 127.0277194, city_y: 37.63695556),
    City(city_code: "1", city_area: "서울", city_name: "강서구", city_x: 126.851675, city_y: 37.54815556),
    City(city_code: "1", city_area: "서울", city_name: "관악구", city_x: 126.9538444, city_y: 37.47538611),
    City(city_code: "1", city_area: "서울", city_name: "광진구", city_x: 127.0845333, city_y: 37.53573889),
    City(city_code: "1", city_area: "서울", city_name: "구로구", city_x: 126.8895972, city_y: 37.49265),
    City(city_code: "1", city_area: "서울", city_name: "금천구", city_x: 126.9041972, city_y: 37.44910833),
    City(city_code: "1", city_area: "서울", city_name: "노원구", city_x: 127.0583889, city_y: 37.65146111),
    City(city_code: "1", city_area: "서울", city_name: "도봉구", city_x: 127.0495222, city_y: 37.66583333),
    City(city_code: "1", city_area: "서울", city_name: "동대문구", city_x: 127.0421417, city_y: 37.571625),
    City(city_code: "1", city_area: "서울", city_name: "동작구", city_x: 126.941575, city_y: 37.50965556),
    City(city_code: "1", city_area: "서울", city_name: "마포구", city_x: 126.9105306, city_y: 37.56070556),
    City(city_code: "1", city_area: "서울", city_name: "서대문구", city_x: 126.9388972, city_y: 37.57636667),
    City(city_code: "1", city_area: "서울", city_name: "서초구", city_x: 127.0348111, city_y: 37.48078611),
    City(city_code: "1", city_area: "서울", city_name: "성동구", city_x: 127.039, city_y: 37.56061111),
    City(city_code: "1", city_area: "서울", city_name: "성북구", city_x: 127.0203333, city_y: 37.58638333),
    City(city_code: "1", city_area: "서울", city_name: "송파구", city_x: 127.1079306, city_y: 37.51175556),
    City(city_code: "1", city_area: "서울", city_name: "양천구", city_x: 126.8687083, city_y: 37.51423056),
    City(city_code: "1", city_area: "서울", city_name: "영등포구", city_x: 126.8983417, city_y: 37.52361111),
    City(city_code: "1", city_area: "서울", city_name: "용산구", city_x: 126.9675222, city_y: 37.53609444),
    City(city_code: "1", city_area: "서울", city_name: "은평구", city_x: 126.9312417, city_y: 37.59996944),
    City(city_code: "1", city_area: "서울", city_name: "종로구", city_x: 126.9816417, city_y: 37.57037778),
    City(city_code: "1", city_area: "서울", city_name: "중구", city_x: 126.9996417, city_y: 37.56100278),
    City(city_code: "1", city_area: "서울", city_name: "중랑구", city_x: 127.0947778, city_y: 37.60380556),

        // 부산
    City(city_code: "21", city_area: "부산시", city_name: "강서구", city_x: 128.9829083, city_y: 35.20916389),
    City(city_code: "21", city_area: "부산시", city_name: "금정구", city_x: 129.0943194, city_y: 35.24007778),
    City(city_code: "21", city_area: "부산시", city_name: "남구", city_x: 129.0865, city_y: 35.13340833),
    City(city_code: "21", city_area: "부산시", city_name: "동구", city_x: 129.059175, city_y: 35.13589444),
    City(city_code: "21", city_area: "부산시", city_name: "동래구", city_x: 129.0858556, city_y: 35.20187222),
    City(city_code: "21", city_area: "부산시", city_name: "부산진구", city_x: 129.0553194, city_y: 35.15995278),
    City(city_code: "21", city_area: "부산시", city_name: "북구", city_x: 128.992475, city_y: 35.19418056),
    City(city_code: "21", city_area: "부산시", city_name: "사상구", city_x: 128.9933333, city_y: 35.14946667),
    City(city_code: "21", city_area: "부산시", city_name: "사하구", city_x: 128.9770417, city_y: 35.10142778),
    City(city_code: "21", city_area: "부산시", city_name: "서구", city_x: 129.0263778, city_y: 35.09483611),
    City(city_code: "21", city_area: "부산시", city_name: "수영구", city_x: 129.115375, city_y: 35.14246667),
    City(city_code: "21", city_area: "부산시", city_name: "연제구", city_x: 129.082075, city_y: 35.17318611),
    City(city_code: "21", city_area: "부산시", city_name: "영도구", city_x: 129.0701861, city_y: 35.08811667),
    City(city_code: "21", city_area: "부산시", city_name: "중구", city_x: 129.0345083, city_y: 35.10321667),
    City(city_code: "21", city_area: "부산시", city_name: "해운대구", city_x: 129.1658083, city_y: 35.16001944),
    City(city_code: "21", city_area: "부산시", city_name: "기장군", city_x: 129.2222873, city_y: 35.24477541),
           
    // 세종
    City(city_code: "12", city_area: "세종특별자치시", city_name: "세종시", city_x: 127.289926, city_y: 36.48545),

    // 제주
    City(city_code: "39", city_area: "제주", city_name: "서귀포시", city_x: 126.5125556, city_y: 33.25235),
    City(city_code: "39", city_area: "제주", city_name: "제주시", city_x: 126.5332083, city_y: 33.49631111),

    // 광주
    City(city_code: "24", city_area: "광주시", city_name: "남구", city_x: 126.9025572, city_y: 35.13301749),
    City(city_code: "24", city_area: "광주시", city_name: "동구", city_x: 126.9230903, city_y: 35.14627776),
    City(city_code: "24", city_area: "광주시", city_name: "북구", city_x: 126.9010806, city_y: 35.1812138),
    City(city_code: "24", city_area: "광주시", city_name: "서구", city_x: 126.8895063, city_y: 35.1525164),
    City(city_code: "24", city_area: "광주시", city_name: "광산구", city_x: 126.793668, city_y: 35.13995836),

    // 울산
    City(city_code: "26", city_area: "울산시", city_name: "남구", city_x: 129.3301754, city_y: 35.54404265),
    City(city_code: "26", city_area: "울산시", city_name: "동구", city_x: 129.4166919, city_y: 35.50516996),
    City(city_code: "26", city_area: "울산시", city_name: "북구", city_x: 129.361245, city_y: 35.58270783),
    City(city_code: "26", city_area: "울산시", city_name: "울주군", city_x: 129.2424748, city_y: 35.52230648),
    City(city_code: "26", city_area: "울산시", city_name: "중구", city_x: 129.3328162, city_y: 35.56971228),

    // 인천
    City(city_code: "23", city_area: "인천시", city_name: "강화군", city_x: 126.4878417, city_y: 37.74692907),
    City(city_code: "23", city_area: "인천시", city_name: "계양구", city_x: 126.737744, city_y: 37.53770728),
    City(city_code: "23", city_area: "인천시", city_name: "남구", city_x: 126.6502972, city_y: 37.46369169),
    City(city_code: "23", city_area: "인천시", city_name: "남동구", city_x: 126.7309669, city_y: 37.44971062),
    City(city_code: "23", city_area: "인천시", city_name: "동구", city_x: 126.6432441, city_y: 37.47401607),
    City(city_code: "23", city_area: "인천시", city_name: "미추홀구", city_x: 126.6502972, city_y: 37.46369169),
    City(city_code: "23", city_area: "인천시", city_name: "부평구", city_x: 126.7219068, city_y: 37.50784204),
    City(city_code: "23", city_area: "인천시", city_name: "서구", city_x: 126.6759616, city_y: 37.54546372),
    City(city_code: "23", city_area: "인천시", city_name: "연수구", city_x: 126.6782658, city_y: 37.41038125),
    City(city_code: "23", city_area: "인천시", city_name: "중구", city_x: 126.6217617, city_y: 37.47384843),

    // 대전
    City(city_code: "25", city_area: "대전시", city_name: "대덕구", city_x: 127.4170933, city_y: 36.35218384),
    City(city_code: "25", city_area: "대전시", city_name: "동구", city_x: 127.4548596, city_y: 36.31204028),
    City(city_code: "25", city_area: "대전시", city_name: "서구", city_x: 127.3834158, city_y: 36.35707299),
    City(city_code: "25", city_area: "대전시", city_name: "유성구", city_x: 127.3561363, city_y: 36.36405586),
    City(city_code: "25", city_area: "대전시", city_name: "중구", city_x: 127.421381, city_y: 36.32582989),

    // 대구
    City(city_code: "22", city_area: "대구시", city_name: "달서구", city_x: 128.5350639, city_y: 35.82692778),
    City(city_code: "22", city_area: "대구시", city_name: "수성구", city_x: 128.6328667, city_y: 35.85520833),
    City(city_code: "22", city_area: "대구시", city_name: "남구", city_x: 128.597702, city_y: 35.84621351),
    City(city_code: "22", city_area: "대구시", city_name: "달서구", city_x: 128.5325905, city_y: 35.82997744),
    City(city_code: "22", city_area: "대구시", city_name: "달성군", city_x: 128.4313995, city_y: 35.77475029),
    City(city_code: "22", city_area: "대구시", city_name: "동구", city_x: 128.6355584, city_y: 35.88682728),
    City(city_code: "22", city_area: "대구시", city_name: "북구", city_x: 128.5828924, city_y: 35.8858646),
    City(city_code: "22", city_area: "대구시", city_name: "서구", city_x: 128.5591601, city_y: 35.87194054),
    City(city_code: "22", city_area: "대구시", city_name: "수성구", city_x: 128.6307011, city_y: 35.85835148),
    City(city_code: "22", city_area: "대구시", city_name: "중구", city_x: 128.6061745, city_y: 35.86952722),
    
     
    // 경기도
    City(city_code: "31010", city_area: "경기도", city_name: "수원시", city_x: 127.0122222, city_y: 37.30101111),
    City(city_code: "31020", city_area: "경기도", city_name: "성남시", city_x: 127.1477194, city_y: 37.44749167),
    City(city_code: "31030", city_area: "경기도", city_name: "의정부시", city_x: 127.0358417, city_y: 37.73528889),
    City(city_code: "31040", city_area: "경기도", city_name: "안양시", city_x: 126.9533556, city_y: 37.3897),
    City(city_code: "31050", city_area: "경기도", city_name: "부천시", city_x: 126.766, city_y: 37.5035917),
    City(city_code: "31060", city_area: "경기도", city_name: "광명시", city_x: 126.8667083, city_y: 37.47575),
    City(city_code: "31070", city_area: "경기도", city_name: "평택시", city_x: 127.1146556, city_y: 36.98943889),
    City(city_code: "31080", city_area: "경기도", city_name: "동두천시", city_x: 127.0626528, city_y: 37.90091667),
    City(city_code: "31090", city_area: "경기도", city_name: "안산시", city_x: 126.8468194, city_y: 37.29851944),
    City(city_code: "31100", city_area: "경기도", city_name: "고양시", city_x: 126.7770556, city_y: 37.65590833),
    City(city_code: "31110", city_area: "경기도", city_name: "과천시", city_x: 126.9898, city_y: 37.42637222),
    City(city_code: "31120", city_area: "경기도", city_name: "구리시", city_x: 127.1318639, city_y: 37.591625),
    City(city_code: "31130", city_area: "경기도", city_name: "남양주시", city_x: 127.2186333, city_y: 37.63317778),
    City(city_code: "31140", city_area: "경기도", city_name: "오산시", city_x: 127.0796417, city_y: 37.14691389),
    City(city_code: "31150", city_area: "경기도", city_name: "시흥시", city_x: 126.8050778, city_y: 37.37731944),
    City(city_code: "31160", city_area: "경기도", city_name: "군포시", city_x: 126.9375, city_y: 37.35865833),
    City(city_code: "31170", city_area: "경기도", city_name: "의왕시", city_x: 126.9703889, city_y: 37.34195),
    City(city_code: "31180", city_area: "경기도", city_name: "하남시", city_x: 127.217, city_y: 37.53649722),
    City(city_code: "31190", city_area: "경기도", city_name: "용인시", city_x: 127.2038444, city_y: 37.23147778),
    City(city_code: "31200", city_area: "경기도", city_name: "파주시", city_x: 126.7819528, city_y: 37.75708333),
    City(city_code: "31210", city_area: "경기도", city_name: "이천시", city_x: 127.4432194, city_y: 37.27543611),
    City(city_code: "31220", city_area: "경기도", city_name: "안성시", city_x: 127.2818444, city_y: 37.005175),
    City(city_code: "31230", city_area: "경기도", city_name: "김포시", city_x: 126.7177778, city_y: 37.61245833),
    City(city_code: "31240", city_area: "경기도", city_name: "화성시", city_x: 126.8335306, city_y: 37.19681667),
    City(city_code: "31250", city_area: "경기도", city_name: "광주시", city_x: 127.2577861, city_y: 37.41450556),
    City(city_code: "31260", city_area: "경기도", city_name: "양주시", city_x: 127.0478194, city_y: 37.78245),
    City(city_code: "31270", city_area: "경기도", city_name: "포천시", city_x: 127.2024194, city_y: 37.89215556),
    City(city_code: "31320", city_area: "경기도", city_name: "여주시", city_x: 127.6396222, city_y: 37.29535833),
    City(city_code: "31350", city_area: "경기도", city_name: "연천군", city_x: 127.0770667, city_y: 38.09336389),
    City(city_code: "31370", city_area: "경기도", city_name: "가평군", city_x: 127.5117778, city_y: 37.82883056),
    City(city_code: "31380", city_area: "경기도", city_name: "양평군", city_x: 127.4898861, city_y: 37.48893611),
            
    // 강원도
    City(city_code: "32010", city_area: "강원도", city_name: "춘천시", city_x: 127.7323111, city_y: 37.87854167),
    City(city_code: "32020", city_area: "강원도", city_name: "원주시", city_x: 127.9220556, city_y: 37.33908333),
    City(city_code: "32021", city_area: "강원도", city_name: "횡성군", city_x: 127.9872222, city_y: 37.48895833),
    City(city_code: "32050", city_area: "강원도", city_name: "태백시", city_x: 128.9879972, city_y: 37.16122778),
    City(city_code: "32310", city_area: "강원도", city_name: "홍천군", city_x: 127.8908417, city_y: 37.69442222),
    City(city_code: "32360", city_area: "강원도", city_name: "철원군", city_x: 127.3157333, city_y: 38.14405556),
    City(city_code: "32410", city_area: "강원도", city_name: "양양군", city_x: 128.6213556, city_y: 38.07283333),
        
    // 충청북도
    City(city_code: "33010", city_area: "충청북도", city_name: "청주시", city_x: 127.5117306, city_y: 36.58399722),
    City(city_code: "33020", city_area: "충청북도", city_name: "충주시", city_x: 127.9281444, city_y: 36.98818056),
    City(city_code: "33030", city_area: "충청북도", city_name: "제천시", city_x: 128.1931528, city_y: 37.12976944),
    City(city_code: "33320", city_area: "충청북도", city_name: "보은군", city_x: 127.7316083, city_y: 36.48653333),
    City(city_code: "33330", city_area: "충청북도", city_name: "옥천군", city_x: 127.5736333, city_y: 36.30355),
    City(city_code: "33340", city_area: "충청북도", city_name: "영동군", city_x: 127.7856111, city_y: 36.17205833),
    City(city_code: "33350", city_area: "충청북도", city_name: "진천군", city_x: 127.4376444, city_y: 36.85253889),
    City(city_code: "33360", city_area: "충청북도", city_name: "괴산군", city_x: 127.7888306, city_y: 36.81243056),
    City(city_code: "33370", city_area: "충청북도", city_name: "음성군", city_x: 127.6926222, city_y: 36.93740556),
    City(city_code: "33380", city_area: "충청북도", city_name: "단양군", city_x: 128.3678417, city_y: 36.98178056),

    // 충청남도
    City(city_code: "34010", city_area: "충청남도", city_name: "천안시", city_x: 127.1524667, city_y: 36.804125),
    City(city_code: "34020", city_area: "충청남도", city_name: "공주시", city_x: 127.1211194, city_y: 36.44361389),
    City(city_code: "34040", city_area: "충청남도", city_name: "아산시", city_x: 127.0046417, city_y: 36.78710556),
    City(city_code: "34050", city_area: "충청남도", city_name: "서산시", city_x: 126.4521639, city_y: 36.78209722),
    City(city_code: "34060", city_area: "충청남도", city_name: "논산시", city_x: 127.1009111, city_y: 36.18420278),
    City(city_code: "34330", city_area: "충청남도", city_name: "부여군", city_x: 126.9118639, city_y: 36.27282222),
    City(city_code: "34390", city_area: "충청남도", city_name: "당진시", city_x: 126.6302528, city_y: 36.89075),

    // 경상도
    City(city_code: "38010", city_area: "경상남도", city_name: "창원시", city_x: 128.6813, city_y: 35.2282),
    City(city_code: "38030", city_area: "경상남도", city_name: "진주시", city_x: 128.1101, city_y: 35.1855),
    City(city_code: "38070", city_area: "경상남도", city_name: "김해시", city_x: 128.8815, city_y: 35.2325),
    City(city_code: "37010", city_area: "경상북도", city_name: "포항시", city_x: 129.3431, city_y: 36.0195),
    City(city_code: "37020", city_area: "경상북도", city_name: "경주시", city_x: 129.2247, city_y: 35.8565),

    // 전라도
    City(city_code: "36020", city_area: "전라남도", city_name: "여수시", city_x: 127.6619, city_y: 34.7608),
    City(city_code: "35020", city_area: "전라북도", city_name: "군산시", city_x: 126.7357, city_y: 35.9744),
        
    ]

