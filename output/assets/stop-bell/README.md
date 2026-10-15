# 하차벨 에셋

`HotChaStopBell`은 홈 상태 배너와 안내 완료 후 Live Activity에 쓰는 투명 PNG다. 기존 종 모양의 추상 아이콘 대신 국내 시내버스에 설치된 빨간 `STOP` 하차 요청 버튼을 표현했다. 사진 복제가 아니라 실물의 형태를 참고해 생성한 앱용 렌더링이다.

- [앱 PNG](../../../HotCha/HotCha/Resources/Assets.xcassets/HotChaStopBell.imageset/StopBell.png)
- [위젯 PNG](../../../HotCha/HotchaLive/Assets.xcassets/HotChaStopBell.imageset/StopBell.png) — 216px 로 줄인 사본. 큰 그림은 Live Activity 에서 뜨지 않는다
- [서울시 버스 내부 하차벨 사진](https://world.seoul.go.kr/service/movement/public-transportation/)
- [현대 일렉시티 타운 내부·하차벨 자료](https://www.hyundai.com/kr/ko/c/products/bus/elec-city-town/gallery-detail/interior)
- [KGM 상용 버스 실내 자료의 빨간 STOP 버튼](https://www.kg-mobility.com/attached/contents/display/image/9000008/KGC090_12p.pdf)

## 최종 생성 프롬프트

```text
Use case: stylized-concept
Asset type: transparent PNG cutout asset for the 76-point illustration on the right side of a Korean iOS transit app home banner
Primary request: ONE recognizable Korean city-bus stop-request button (하차벨), modeled from actual Korean bus interiors: a compact off-white/soft warm-gray plastic mounting housing, glowing translucent saturated ruby-red oval/rounded-rectangle press surface with a crisp simple white "STOP" label, a slim grey bezel and two tiny mounting screws. Seen slightly from the front-right in a shallow three-quarter product view, almost front-facing so the red press surface is instantly readable at tiny UI size. A convincing physical push button, not a hanging bell, not a generic notification icon, not an emergency alarm.
Style/medium: clean high-quality realistic 3D product cutout matching the existing HotCha Korean bus asset collection; smooth semi-matte molded plastic, subtle translucent red material and restrained highlights.
Composition/framing: a single complete object centered and filling roughly 78% of a square canvas, generous transparent margin, no holder pole or scene. The red face occupies most of the silhouette.
Lighting/mood: soft studio upper-left illumination.
Constraints: genuine transparent alpha, no drop shadow floor, background, card, border, vehicle, hand, human, logo, brand, extra words, watermark or purple recoloring. Make STOP text exact or omit it if lettering cannot be rendered cleanly.
```
