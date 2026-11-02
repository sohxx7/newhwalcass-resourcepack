# 상태이상 HUD (26.3 포스트이펙트)

화면 오른쪽 위에 상태이상 카드가 뜬다. 새로 걸리면 오른쪽 끝에 붙고 기존 카드는 한 칸씩 왼쪽으로 밀린다.
풀리면 그 자리가 다음 프레임부터 자동으로 메워진다. 아직 서버 데이터팩에는 연결하지 않았다.

| 효과 ID | 상태 | 원본 |
| --- | --- | --- |
| `hwalcass:status/stun` | 기절 | `40px-Stun_icon.png` |
| `hwalcass:status/root` | 속박 | `40px-Root_icon.png` |
| `hwalcass:status/silence` | 침묵 | `40px-Silence_icon.png` |
| `hwalcass:status/disarm` | 무장해제 | `40px-Disarm_icon.png` |
| `hwalcass:status/grounded` | 이동기 봉인 | `40px-Grounded_icon.png` |
| `hwalcass:status/grievous` | 치유 감소 | `40px-Grievous_Wounds_icon.png` |

## 서버가 할 일

걸릴 때 add, 풀릴 때 remove만 하면 된다. 칸 번호를 관리하지 않는다.

```mcfunction
posteffect add @s hwalcass:status/stun
posteffect remove @s hwalcass:status/stun
```

- 이미 걸린 상태를 다시 add하면 무시된다. 자리는 그대로이고, 시간 갱신은 서버 쪽 타이머만 늘리면 된다.
- 사망·관전·라운드 종료 때는 6개를 모두 remove한다. `posteffect clear`는 다른 스킬 효과까지 지우므로 쓰지 않는다.

## 원리

26.3은 플레이어마다 포스트이펙트를 목록으로 들고 있다(`ClientboundPostEffectsPacket`).

- `add`는 목록 끝에 붙이고, 이미 있으면 아무것도 하지 않는다.
- `remove`는 나머지 순서를 유지한다.

그래서 목록 순서 = 걸린 순서이고, 클라는 그 순서대로 패스를 돌린다.
각 상태의 패스(`shaders/post/status_icon.fsh`)는 매 프레임 다음 세 가지를 한다.

1. 오른쪽 위 줄에 이미 그려진 카드가 몇 장인지 센다. 카드마다 위쪽 가운데에 서명 픽셀 2개(RGB 28,30,38 / 30,28,38)를 박아 둔다. 배경과 거의 같은 색이라 눈에 띄지 않는다.
2. 그려진 카드들을 한 칸(58px) 왼쪽으로 옮긴다. 정수 픽셀 복사라 서명도 그대로 따라간다.
3. 자기 카드를 오른쪽 끝에 그린다.

결과적으로 가장 최근 것이 오른쪽 끝에 오고, 먼저 걸린 것일수록 왼쪽에 있다. 매 프레임 새 화면에서 다시 계산하므로 남는 상태가 없다.
7장째부터는 가장 오래된 것이 왼쪽 끝 밖으로 밀려나 안 보인다.

## 다른 방식과 비교

- **칸별 효과(종류×칸)를 서버가 매번 옮겨 붙이는 방식:** 상태가 바뀔 때마다 서버가 remove/add를 여러 번 해야 해서 이 방식으로 바꿨다.
- **보스바·타이틀·액션바:** 위치가 가운데나 아래로 고정이라 오른쪽 위에 둘 수 없다.
- **디스플레이 엔티티 HUD:** 플레이어마다 엔티티를 태우고 동기화해야 해서 무겁다.
- **바닐라 물약 아이콘 교체:** 실제 물약 효과가 같이 걸리고, 정렬이 "최근 것이 오른쪽"이 아니다.

## 다른 포스트이펙트로부터 보호

화면 전체를 바꾸는 효과(흑백·반전·왜곡·테두리 등)가 카드 위에 덮이면 카드 색과 서명이 바뀐다.
그러면 뒤에 붙는 상태이상이 카드 수를 잘못 센다.
그래서 서버가 쓰는 `hwalcass:` 효과 14종의 최종 색을 만드는 셰이더 13개는 모두 맨 앞에서 `statusHudKeep`을 부른다.
이미 그려진 카드 위의 픽셀이면 원래 색을 그대로 내보내고 끝낸다.

- 대상: `electro_composite`, `electro_pool`, `fire_border`, `hack`, `jett`, `jinx`, `kasimo_composite`, `kasimo2`, `predator_flip`, `predator_kimchi`, `raingirl_film`, `shinobu`, `superstar`
- 효과가 붙는 순서와 상관없이 카드는 물들지 않는다. 카드가 아직 없는 프레임에서는 아무것도 막지 않는다.
- 카드 줄 바깥 픽셀은 위치 비교 몇 번만 하고 바로 원래 처리로 넘어간다.

**새 포스트이펙트를 만들 때:** 최종 색을 만드는 패스(`minecraft:main`을 읽는 패스)에 아래 두 줄을 넣는다.

```glsl
#include <hwalcass:status_hud.glsl>          // #extension 줄 다음
    if (statusHudKeep(InSampler, texCoord, fragColor)) return;   // main() 첫 줄
```

바닐라 효과(`minecraft:invert` 등)는 보호하지 않는다. 지금 서버는 바닐라 효과를 쓰지 않는다.

## 구성

| 파일 | 내용 |
| --- | --- |
| `shaders/include/status_hud.glsl` | 배치·서명 판별·`statusHudKeep` 공용 코드 |
| `shaders/post/status_icon.fsh` | 세기 → 밀기 → 그리기 |
| `textures/effect/status/<id>.png` | 52×52 불투명 카드 |
| `post_effect/status/<id>.json` | 그리기 패스(`swap`) + 원래 화면으로 되돌리는 `blit` 패스 |
| `sources/statushud/statushud_gen.py` | 카드·JSON 생성기, 셰이더 알고리즘을 numpy로 똑같이 돌리는 미리보기 |
| `sources/statushud/icons/` | 받은 원본 아이콘 |

카드 테두리는 모두 같은 어두운 1px 테를 쓴다. 그 안쪽 강조 테두리는 아이콘 색에서 자동으로 뽑는다(기절 보라, 침묵 파랑, 치유 감소·이동기 봉인 주황, 속박·무장해제 은색).

크기는 화면 높이에 비례하고 GUI 크기와는 무관하다. 1080p 기준 값은 다음과 같다.
- 카드 52px(텍스처와 1:1), 간격 6px
- 위 끝에서 15px, 오른쪽 끝에서 16px

카드 한 장마다 전체 화면 패스 2번이 추가된다. 카드 줄 밖의 픽셀은 바로 원래 색을 돌려준다.

## 검증

- 26.3 클라이언트 `PostChainConfig.CODEC`으로 JSON 6개를 읽었다(오류 0).
- `status_icon.fsh`와 보호를 넣은 기존 셰이더를 포함해 `shaders/post/*.fsh` 17개 전부를 컴파일했다.
  - 조건: Vulkan 1.2·자동 바인딩 glslang
  - `hwalcass:` include도 펼쳐서 컴파일했다.
- 셰이더와 같은 알고리즘을 numpy로 돌려 확인했다. 해상도는 1280×720, 1920×1080, 2560×1440이다.
  - 걸린 순서대로 1~4장
  - 중간 것 풀림 → 빈칸 메움
  - 6장 전부
  - 카드 2장 → 흑백 효과 → 카드 1장: 보호 있으면 3장 유지, 없으면 깨짐
- 실제 게임 클라이언트 화면(OpenGL·Vulkan)은 확인하지 않았다.
