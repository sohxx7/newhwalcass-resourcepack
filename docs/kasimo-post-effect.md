# Kasimo / Kasimo2 (26.3)

효과 ID: `hwalcass:kasimo`, `hwalcass:kasimo2`.

## Kasimo

사용자가 선택한 electro 셰이더를 바탕으로 상하좌우 네 방향의 노란 방전을
구성했다. 밝은 중심, 노란 외곽광과 가지, 독립적인 재점화 타이밍을 사용한다.
가로와 세로 모두 화면 높이를 기준으로 굵기를 계산한다. 모서리에서는 두
방향의 에너지를 더하지 않고 큰 값을 선택해 과도한 중복 발광을 줄인다.
ElectroConfig와 기존 5패스 구조를 사용하며 외부 PNG 입력은 없다.

## Kasimo2

원본의 보라·파랑 물방울과 하이라이트를 보존한다. 원본을 85개 독립 물방울/접촉
그룹으로 분리하여 각각의 스프라이트가 부드럽게 떠 움직이도록 했다. 원형 자체를
왜곡하지 않으며 화면 경계에서 잘려 있던 물방울은 잘린 면이 드러나지 않게
이동 방향을 제한한다. 6초 주기로 연속 반복하고 중앙 시야는 비운다.
DropConfig 기본값은 Motion=1.0, Speed=1.0이며 Motion=0은 원본 정지 이미지다.

신규팩의 `/build` → `/r` 이후 수동 확인:

```mcfunction
posteffect add @s hwalcass:kasimo
posteffect remove @s hwalcass:kasimo
posteffect add @s hwalcass:kasimo2
posteffect remove @s hwalcass:kasimo2
```

GIF: `C:\단타\0활카스\posteffect\kasimo.gif`, `kasimo2.gif`.
별도 GPU 렌더링이며 기존 스킬의 camera_overlay를 포스트이펙트로 대체했다.

검증: 26.3 코덱, 텍스처 조회, 실제 include 로더와 양쪽 깊이 규약의 컴파일 통과.
GPU에서 전체 JSON 패스, 네 화면 크기, 장시간, 중앙/장면 알파 보존을 확인했다.
Kasimo2 원본 정지 비교 RGB 오차 최대 1, 6초 반복 시작/끝 비교 오차 0이며
상하 물방울 움직임과 중앙 화면 보존도 검사했다. 실제 게임 화면은 아직 확인하지 않았다.
