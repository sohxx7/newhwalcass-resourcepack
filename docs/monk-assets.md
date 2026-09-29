# Monk 리소스

Minecraft 1.21.8용 `dor:char/monk/*` item model. 아래 구슬·VFX 9종은 공통 평면 모델 `dor:item/char/monk/_billboard`를 상속한다. 두 면에 같은 텍스처를 쓰며 방향 음영과 AO를 끈다. 셰이더 전용 서명/색상 데이터는 사용하지 않는다.

| item_model | 내용 |
| --- | --- |
| `dor:char/monk/ball_0` | 금속 구슬 기본 각도 |
| `dor:char/monk/ball_1` | 정면 |
| `dor:char/monk/ball_2` | 좌측 |
| `dor:char/monk/ball_3` | 우측 |
| `dor:char/monk/ball_4` | 위쪽 |
| `dor:char/monk/ball_5` | 아래쪽 |
| `dor:char/monk/orb_yellow` | 광륜을 줄인 노란 에너지 구슬 |
| `dor:char/monk/orb_purple` | 같은 효과의 보라색 색조 버전 |
| `dor:char/monk/ult` | 중앙 검은색을 유지한 신성한 눈 VFX, 최신 v6 시안 |

금속 구슬은 256×256이며 프레임별 실제 크기/중심을 맞췄다. 각 발사에 하나씩 고르는 정적 바리에이션으로, 정밀한 연속 3D 회전 애니메이션은 아니다. 노랑/보라 에너지 구슬은 프레임 256×256, 2열 29행, 58프레임을 각 1틱씩 재생한다(2.90초). 궁 텍스처는 512×512로 축소했다.

텍스처는 `assets/dor/textures/item/char/monk/`에 있어 기본 item 텍스처 디렉터리 atlas 소스를 이용한다. atlas JSON에 개별 등록할 필요가 없다. 추적 정보는 `sources/monk-assets.json`에 있다.

## 확인 명령

팩을 `/build` 후 `/r`로 적용하고 다음을 실행한다.

```mcfunction
give @s minecraft:paper[minecraft:item_model="dor:char/monk/ball_0"]
summon minecraft:item_display ~ ~1.5 ~ {Tags:["monk_asset_preview"],billboard:"center",item_display:"fixed",brightness:{block:15,sky:15},shadow_radius:0f,transformation:{translation:[0f,0f,0f],left_rotation:[0f,0f,0f,1f],scale:[0.5f,0.5f,0.5f],right_rotation:[0f,0f,0f,1f]},item:{id:"minecraft:paper",count:1,components:{"minecraft:item_model":"dor:char/monk/ball_0"}}}
kill @e[type=minecraft:item_display,tag=monk_asset_preview]
```

위 명령의 item model ID를 표의 다른 값으로 바꾸면 된다. `billboard`는 모델 JSON의 속성이 아니라 디스플레이 엔티티의 속성이므로 실제 스킬 구현에서도 `billboard:"center"`를 설정한다. `brightness`는 텍스처에 구워진 명암을 보기 위한 밝기 설정이다. 엔티티 `transformation.scale`로 게임상의 크기를 정하며 GUI/손 표현에 따로 크기 변형을 넣지 않았다.

mcmeta 재생 위치는 클라이언트 텍스처마다 공유되며, 소환할 때 첫 프레임으로 초기화되지 않는다. 이 두 에너지 텍스처는 반복 효과 용도다.

## 적용 상태

Class151 수도승의 양손 염주·모자 지급과 좌/우클릭·F·궁 스킬에 연결했다. 실제 서버에서 구슬 배치·이동·곡선 연출을 확인했다. 생성 이미지의 알파와 사용자 조정 display를 유지하며 공용 셰이더는 변경하지 않았다.

## 무기·모자 — Blockbench MCP 제작

승인된 컨셉을 Minecraft Java 1.21.8용 입체 큐브 모델로 구현했다. Blockbench 5.1.6 / MCP 1.9.3에서 생성·텍스처 적용·착용 미리보기·Java 내보내기를 수행했다.

| item_model | 모델 | 편집 원본 |
| --- | --- | --- |
| `dor:char/monk/wp` | 금색·청록 염주 7개, 상아색 손목 천, 보라색 수술 (235큐브) | `sources/monk/monk_wp.bbmodel` |
| `dor:char/monk/hat` | 머리띠 사용자 수정본 (24큐브) | `sources/monk/monk_hat.bbmodel` |

공유 텍스처: `assets/dor/textures/item/char/monk/equipment.png` (128×128). 두 모델은 `_billboard`를 상속하지 않는다. BB 프로젝트 버전 `1.21.6`은 1.21.6~1.21.10 호환 범위다. 메시는 쓰지 않으며 회전은 단일 축 ±45도만 사용했다.

`wp`는 양손 3인칭에서 손목에 맞추고 1인칭·GUI·바닥 표시도 지정했다. 바닐라의 일반 아이템은 1인칭에서 플레이어 팔을 함께 그리지 않으므로 이 모델도 1인칭에서는 팔찌만 표시한다. 플레이어 스킨의 팔을 임의로 모델에 그려 넣지 않았다. `hat`은 머리 표시를 지정했다. 일반/슬림 팔, 스킨 바깥 레이어와 게임 내 사용 동작에 따른 최종 간섭 여부는 인게임에서 확인한다.

```mcfunction
give @s minecraft:paper[minecraft:item_model="dor:char/monk/wp"]
give @s minecraft:paper[minecraft:item_model="dor:char/monk/hat"]
```

모자는 머리 슬롯에 올려 확인한다(아래 명령은 현재 머리 장비를 교체한다).

```mcfunction
item replace entity @s armor.head with minecraft:paper[minecraft:item_model="dor:char/monk/hat"]
```

Blockbench 렌더 및 머리·양손 착용 미리보기 확인, 모델/텍스처/item 참조·큐브 범위·UV·편집 원본 임베디드 PNG 검사, 리팩 ZIP 빌드를 수행했다. Class151 캐릭터 지급 코드와 연결했으며 사용자 조정 display를 그대로 적용했다.

사용자 display 조정 반영: 3인칭 오른손 scale 0.8 / 왼손 0.85, 양손 rotation `[90,-90,0]`; 1인칭 양손 translation `[0.25,3,0]`; GUI scale 1.75. `.bbmodel`과 내보낸 `wp.json`의 display 일치를 확인했다.

머리띠는 사용자가 수정·내보낸 24큐브 버전을 그대로 유지했다. `monk_hat.bbmodel`과 `hat.json`의 좌표·display 및 item/텍스처 연결을 확인하고 추적 해시를 갱신했다.
