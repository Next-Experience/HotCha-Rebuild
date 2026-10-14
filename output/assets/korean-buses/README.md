# 한국 버스 유형별 PNG 에셋

앱의 SearchBusUtil 및 내장 routes.route_type 값을 확인하고 한국 전기버스 외관·실차 도색을 웹에서 검색했다. 현재 제조사 외형과 2024–2025 사진, 기존 도색 계획 자료를 함께 참고했다. 모든 유형의 2026 실차 사진을 확보한 것은 아니며 근거 날짜와 콘셉트 여부를 아래에 명시했다.

13종 모두 기본 제공 이미지 생성 도구로 독립 생성한 투명 PNG다. 실제 차량의 창문 띠·출입문·짐칸·차체 높이와 길이 차이를 중심으로 재해석했으며 제조사 로고·광고·노선 문구·해치 캐릭터는 넣지 않았다. 정확한 실차 설계도나 공식 도색 자료가 아니라 앱용 렌더링 에셋이다.

앱 에셋 카탈로그에 등록했고 `BusArt`가 노선 유형에 맞는 대표 그림을 선택한다. 기존 8종 클레이 에셋은 보존했다. 같은 유형에도 여러 제조사·차종·도색이 있으므로 화면의 그림은 실제 배차 차량을 식별한다는 뜻이 아니다. 특히 시외·공항·농어촌 그림은 전기버스로 한정하지 않았다.

## 에셋과 적용 범위

### 서울 간선

- 리소스: `HotChaBusSeoulTrunk`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusSeoulTrunk.imageset/SeoulTrunk.png)
- 서울 간선 대표색인 파란색 + 현재 일렉시티 저상 차체. 2026 현재 공식 제품 외형을 참고한 디자인 해석.

### 서울 지선

- 리소스: `HotChaBusSeoulFeeder`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusSeoulFeeder.imageset/SeoulFeeder.png)
- 서울 지선 초록색. 2024-06-15 서울 7727번 전기버스 사진의 녹색·흰 어깨선 참고.

### 마을

- 리소스: `HotChaBusVillage`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusVillage.imageset/Village.png)
- 현재 공식 일렉시티 타운 및 2026 카탈로그. 짧은 중형 저상 전기버스 차체 + 초록 도색.

### 남산 순환

- 리소스: `HotChaBusNamsanCirculator`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusNamsanCirculator.imageset/NamsanCirculator.png)
- 2025-11-07 서울시 기사 속 01A 해치버스 분홍 도색. 캐릭터는 복제하지 않고 색상만 해석. 모든 순환버스에 공통 적용할 색이 아니다.

### 창원 시내

- 리소스: `HotChaBusChangwonCity`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusChangwonCity.imageset/ChangwonCity.png)
- 2023 도입 계획으로 발표된 창원 하늘색·흰 물결 도색 + 현재 일렉시티 외형. 도색 근거 기사 발표는 2022-11-22로, 이를 2025 사진으로 주장하지 않는다.

### 지방 일반 시내

- 리소스: `HotChaBusLocalCity`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusLocalCity.imageset/LocalCity.png)
- 2025년 전주 파란 전기버스·진주 분홍 시내버스 사진과 현대 일렉시티 차체를 비교했다. 지역마다 도색이 달라 흰색·청록 포인트의 중립적인 저상 시내버스 그림으로 만들었다. `일반버스`와 `시내버스`에 쓰되 창원 코드의 일반버스는 기존 창원 그림을 우선한다.

### 농어촌

- 리소스: `HotChaBusRural`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusRural.imageset/Rural.png)
- 2025년 하동 운행 사진의 짧은 녹색·흰색 차체를 참고했다. 대표 그림이며 농어촌 차량이 모두 같은 모델이나 색이라는 뜻은 아니다. `농어촌(일반)버스`와 `농어촌(좌석)버스`에 쓴다.

### 시외

- 리소스: `HotChaBusIntercity`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusIntercity.imageset/Intercity.png)
- 현대 유니버스 공식 차체와 국내 운행 코치 사진을 참고해 높은 객실·앞문 하나·하부 짐칸을 표현했다. 특정 운수사 도색을 복제하지 않은 은색·남색 콘셉트. `시외버스`에 쓴다.

### 공항

- 리소스: `HotChaBusAirport`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusAirport.imageset/Airport.png)
- 공항리무진 운영사 사이트의 금색 6002번 실차 사진을 참고한 높은 코치와 하부 짐칸. 전체 공항버스의 공통 색은 아니다. 서울 코드 `1`과 `공항버스`에 쓴다.

### 급행 대표색

- 리소스: `HotChaBusExpressRed`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusExpressRed.imageset/ExpressRed.png)
- 2024-11-26 소개된 KGM 빨간 전기버스 외관과 급행 대표 빨강을 결합한 콘셉트. 특정 급행 노선이 해당 전기차를 운행한다고 검증한 것은 아니다. 전국 급행의 실제 도색을 뜻하지 않는다.

### 광역 좌석 수소전기

- 리소스: `HotChaBusMetropolitanSeat`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusMetropolitanSeat.imageset/MetropolitanSeat.png)
- 2024-06-10 인천 1100/1500 빨간 유니버스 FCEV 사진 참고. 수소연료전지 전기버스다. 배터리 전기버스로 표기하지 않는다.

### 경기 광역 이층

- 리소스: `HotChaBusGyeonggiDoubleDecker`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusGyeonggiDoubleDecker.imageset/GyeonggiDoubleDecker.png)
- 2024-03-06 기사에 제공된 경기 7780 전기 이층버스 사진. 흰 전면·파랑·노랑 측면·두 층과 3축 참고.

### 광역급행 M 이층

- 리소스: `HotChaBusMDoubleDecker`
- [PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/KoreanBuses/HotChaBusMDoubleDecker.imageset/MDoubleDecker.png)
- 2024-06-05 서울에서 촬영된 M4101/M4108 일렉시티 이층버스의 파란 도색. M버스 전체가 이층이라는 의미는 아니다.

## 참고 자료

- [현대 일렉시티 현재 공식 제품 외형](https://www.hyundai.com/kr/ko/c/products/bus/elec-city)
- [일렉시티 타운 공식 제품·2026 카탈로그](https://www.hyundai.com/kr/ko/c/products/bus/elec-city-town)
- [일렉시티 이층버스 공식 외형](https://www.hyundai.com/kr/ko/c/products/bus/elec-city-double-decker)
- [서울 버스 분류(2026-03-09 수정)](https://news.seoul.go.kr/traffic/archives/1706)
- [서울 지선 전기버스 사진(촬영 2024-06-15)](https://busphoto.eu/photo/647910/?vid=1087298)
- [분홍 01A 순환버스 사진(기사 2025-11-07)](https://mediahub.seoul.go.kr/archives/2016062)
- [남산 01B 사진과 순환 해치버스 안내(2024-11)](https://mediahub.seoul.go.kr/archives/2012815)
- [창원 새 전기버스 도색 계획(2022-11-22, 2023 도입 계획)](https://www.yna.co.kr/view/AKR20221122101500052)
- [경기 전기 이층버스 실제 사진(2024-03-06)](https://www.fnnews.com/news/202403060923267105)
- [경기도 공식 전기 이층버스 도입 자료](https://gnews.gg.go.kr/briefing/brief_gongbo_view.do?BS_CODE=S017&number=60675)
- [파란 M4101 전기 이층버스 사진(촬영 2024-06-05)](https://fotobus.msk.ru/photo/3440383/)
- [빨간 인천 광역 수소전기버스 사진(촬영 2024-06-10)](https://fotobus.msk.ru/photo/3352128/)
- [KGM 빨간 전기버스 사진(기사 2024-11-26)](https://china.kyungjeilbo.com/view/20241126074858394)
- [현대 유니버스 공식 제품 외형](https://www.hyundai.com/kr/ko/c/products/bus/universe)
- [2025년 전주 파란 시내 전기버스 사진](https://www.nocutnews.co.kr/news/6325518)
- [2025년 진주 분홍 시내버스 사진](https://www.sisajournal.com/news/articleView.html?idxno=333282)
- [2025년 하동 농어촌버스 운행 사진](https://kstar.kbs.co.kr/list_view.html?idx=357608)
- [공항리무진 운영사 사이트와 금색 6002 차량 사진](https://airportlimousine.co.kr/en/)

## 최종 생성 프롬프트

### SeoulTrunk

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A full-size single-deck Hyundai Elec City-style battery-electric low-floor bus. Deep cobalt blue body with matching blue lower panels, black windscreen mask and broad black window belt, restrained white/cream slim trim and grey rooftop battery/HVAC box. Inspired by Seoul blue trunk service. Two axles.

### SeoulFeeder

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A full-size Hyundai Elec City-style single-deck battery-electric low-floor bus. Vibrant apple-green body, lime-green roof shoulders with a slim flowing white roof stripe, black panoramic windshield and continuous black window belt, dark grey rooftop battery enclosure. Inspired by Seoul green feeder electric buses photographed in 2024. Two axles.

### Village

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A SHORT mid-size 9m Hyundai Elec City Town-style battery-electric low-floor village bus, noticeably shorter wheelbase and fewer side windows than full-size city bus. Medium leafy-green body, black upper front and black side glazing, thin electric-blue line below windscreen, compact grey rooftop equipment. Based on current 2026 official Elec City Town model exterior. Two axles.

### NamsanCirculator

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A full-size single-deck Korean electric low-floor bus. Distinctive rose-pink main body with pale pink and cream flowing side panels, black window belt, small pastel mint detail at lower side, rooftop EV equipment. Based on the actual PINK 01A Haechi Namsan circulator photographed November 2025, but omit all characters and mascot artwork. Keep bus silhouette authentic.

### ChangwonCity

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A full-size Hyundai Elec City-style single-deck low-floor electric bus. Sky-cyan sides fading toward deeper blue at rear, SILVER-WHITE lower front bumper, black windscreen and black window belt, flowing broad white wave graphics on cyan side, dark grey rooftop battery housing. Changwon city new wave livery as introduced 2023, simplified flowing shapes without lettering. Two axles.

### ExpressRed

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A modern full-size KGM Commercial-style battery-electric low-floor city bus. Rich red body and red lower front fascia with cream-white thin lower side accent, black panoramic upper front and broad black side window band, subtle rooftop battery enclosure. Angular compact slim LED headlights softened into clay. Manufacturer red-electric-bus reference from November 2024. City-bus shape with two doors, NOT a tall coach. This is a representative red express concept, not a specific operating route.

### MetropolitanSeat

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A taller SINGLE-DECK Hyundai Universe-style hydrogen fuel-cell electric seated metropolitan coach. Red body, narrow cream-white sweeping side stripe, tall curved black front windscreen, black window belt with high aligned windows, single passenger door near front, enclosed luggage panels below windows and compact discreet rooftop hydrogen equipment. Modern slim angular LED headlights. Based on actual red Incheon metropolitan Universe FCEV buses photographed June 2024. Clearly taller coach proportions than low-floor city bus. Two axles.

### GyeonggiDoubleDecker

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A TALL modern Hyundai Elec City Double Decker battery-electric metropolitan bus, two distinct levels of black side windows, three axles, compact smooth rectangular form. WHITE front and upper side bridge, deep royal-blue lower front/side panels, strong golden-yellow rear/lower side panels and a few simplified angular blue/yellow electric-themed chevrons. Actual Gyeonggi 2024 double-decker livery reference; no lettering. Authentic straight tall windscreen and slim LED headlights.

### MDoubleDecker

Use case: stylized-concept. Asset type: one individually exported transparent PNG illustration for a Korean transit app, part of a coherent matte-clay bus collection. Create ONE isolated modern Korean bus, mildly elevated front-right three-quarter orthographic camera, vehicle nose facing viewer-left, square composition, 15% transparent margin. Friendly rounded corners but authentic rectangular bus silhouette and realistic wheelbase; not a chubby toy with round headlights. Matte clay exterior, broad clean shapes legible at 64px. Soft upper-left lighting, restrained highlights. Flat front with huge dark charcoal panoramic windscreen, narrow horizontal LED-running-light strip and stacked small vertical headlamps, black side window band, slim black mirrors, grey hubs and black tyres. Realistic Korean low-floor front and middle doors and discreet rooftop EV equipment when specified. Actual vehicle colors, NO violet-brand recoloring. Genuine transparent alpha background, no floor, scene, podium, border or icon tile. No readable text, route numbers, badges, advertisements, logos, people, mascots or watermark; blank destination display. A TALL modern Hyundai Elec City Double Decker battery-electric metropolitan M-bus, two rows of dark windows, THREE axles. Deep BLUE main body with WHITE front edge trim and subtle white flowing shoulder accent, broad dark upper/lower glazing, no yellow panels. Actual blue M4101/M4108 buses photographed Seoul June 2024, omit route lettering. Authentic tall straight windscreen and slim LED headlights.

### LocalCity

Primary request: nationwide generic 지방 일반 시내버스. Full-size modern Korean single-deck low-floor electric city bus, about 11 m long, flat upright front, deep dark panoramic front windshield, horizontal narrow LED daytime lights, broad side window strip, TWO passenger doors at front and center, TWO axles, discreet rooftop battery/HVAC housings. A restrained white-light-silver body with blue-cyan lower panels and tiny fresh teal accent; intentionally city-neutral because real cities use very different colors. Inspired by real 2025 Jeonju blue electric city bus, 2025 Jinju pink city bus, and Hyundai Elec City official exterior, without copying any city's branding. Use case: stylized-concept. Asset type: one transparent PNG for an iOS Korean bus app, same cutout product-render language as an existing coherent KoreanBuses collection. Exactly one full bus, front-left nose nearer viewer and right side visible in a gently elevated three-quarter view, centered in square canvas with 12% clear margin. Authentic Korean bus proportions and doors, realistic glass and wheels; high-quality soft studio lighting, restrained highlights, smooth semi-matte painted metal with modest dimension. Genuine transparent alpha background, no floor, shadow ground, scenery, border or icon tile. No route digits, readable text, logos, plate numbers, people, advertisements or watermarks. Do not use purple.

### Rural

Primary request: Korean 농어촌버스. Clearly SHORTER 8–9 m rural route bus with TWO axles, slightly higher practical body than a low-floor city bus, flat compact front, large rectangular windows, one obvious folding passenger door near front, rear side windows, small roof HVAC; realistic—not a school bus or minivan. Warm ivory-white upper body and leaf-green lower body with a simple green belt, matching real 2025 Hadong green-and-white countryside bus photo but with no exact operator identity. No EV-specific battery box unless natural on a recent midibus. Use case: stylized-concept. Asset type: one transparent PNG for an iOS Korean bus app, same cutout product-render language as an existing coherent KoreanBuses collection. Exactly one full bus, front-left nose nearer viewer and right side visible in a gently elevated three-quarter view, centered in square canvas with 12% clear margin. Authentic Korean bus proportions and doors, realistic glass and wheels; high-quality soft studio lighting, restrained highlights, smooth semi-matte painted metal with modest dimension. Genuine transparent alpha background, no floor, shadow ground, scenery, border or icon tile. No route digits, readable text, logos, plate numbers, people, advertisements or watermarks. Do not use purple.

### Intercity

Primary request: Korean 시외버스. A long-distance modern Korean high-deck coach inspired by Hyundai Universe and Kia Granbird actual coach exteriors. Taller smooth sloping windshield, single narrow passenger door at front, continuous high dark tinted side-window band, long two-axle coach body, clearly visible large underfloor luggage bay panel seams, no center door, no rooftop battery box. Quiet silver-white body and deep navy blue lower side sweep with a subtle thin sky-blue accent, plausible regional operator livery but no particular company branding. Distinct from low-floor city bus. Use case: stylized-concept. Asset type: one transparent PNG for an iOS Korean bus app, same cutout product-render language as an existing coherent KoreanBuses collection. Exactly one full bus, front-left nose nearer viewer and right side visible in a gently elevated three-quarter view, centered in square canvas with 12% clear margin. Authentic Korean bus proportions and doors, realistic glass and wheels; high-quality soft studio lighting, restrained highlights, smooth semi-matte painted metal with modest dimension. Genuine transparent alpha background, no floor, shadow ground, scenery, border or icon tile. No route digits, readable text, logos, plate numbers, people, advertisements or watermarks. Do not use purple.

### Airport

Primary request: Korean 공항리무진 버스. Modern high-deck airport coach inspired by the real gold-colored Airport Limousine Co. 6002 bus seen on its official site, combined with current Hyundai Universe/Kia Granbird coach shape. Rich muted champagne gold and warm ivory body, dark continuous elevated window band, one front passenger door, prominent low luggage-compartment doors along side, two axles, elegant broad windscreen and slim LED lamps. Premium yet believable functional public airport bus, no airline marks or wings or airplane symbol. Use case: stylized-concept. Asset type: one transparent PNG for an iOS Korean bus app, same cutout product-render language as an existing coherent KoreanBuses collection. Exactly one full bus, front-left nose nearer viewer and right side visible in a gently elevated three-quarter view, centered in square canvas with 12% clear margin. Authentic Korean bus proportions and doors, realistic glass and wheels; high-quality soft studio lighting, restrained highlights, smooth semi-matte painted metal with modest dimension. Genuine transparent alpha background, no floor, shadow ground, scenery, border or icon tile. No route digits, readable text, logos, plate numbers, people, advertisements or watermarks. Do not use purple.
