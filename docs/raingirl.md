# 레인걸(153) — 우산 v3 (2026-10-11)

계단식 천을 연속 경사 패널로 교체했다. 기존 하늘색/은색, 손잡이 중심 `(6,-11.5,8.5)`, 장착 기준 및 아이템 ID를 유지한다.

| item_model (`dor:char/raingirl/…`) | 이전→현재 요소 | 병합 조각 | 내용 |
| --- | ---: | ---: | --- |
| `umbrella_open` | 536→119 | 4 | 8폭 × 6단 곡면 천, 흰 끝단, 안감, 곡선 살과 지지대 |
| `umbrella_closed` | 271→78 | 7 | 실제로 안/밖으로 접힌 16면 주름, 좁아지는 끝, 고정끈과 단추 |
| `umbrella_canopy` | 530→113 | 4 | 펼친 천/살과 같은 형상, 원래 투사체 중심으로 이동 |
| `umbrella_stick` | 6→6 | 1 | 원래 모델/텍스처/display 변경 없음 |

## Minecraft 내보내기

- 실제 게임에는 일반 Java 요소만 사용한다. 각 요소는 한 축으로만 -45~45도 범위에서 회전한다. 1.21.8의 임의 소수 각도를 이용한다.
- 부품의 추가 회전은 `minecraft:composite` 하위 모델의 `display`로 합성한다. 90도 회전은 좌표/면 방향/UV에 구워 조각 수를 줄였다.
- 천은 알파 마스크로 폭이 변하는 사다리꼴 패널을 표현한다. 각 패널의 앞면과 뒷면을 별도로 정의했으며 음수 크기, 반대 면 강제 렌더, 셰이더가 필요 없다.
- `umbrella_smooth.png`는 2048×2048 원단 아틀라스다. `umbrella.png`는 대/손잡이용 원본 팔레트로 보존한다.
- 기존 `display`에 조각 회전을 곱했으므로 JSON의 숫자 자체는 달라진다. 양손/GUI/ground/fixed/head 8가지 최종 변환을 원본 기준과 수치 비교했고 오차는 0.000001 모델 단위 미만이다.
- 원본 단일 `models/.../umbrella_open.json`, `umbrella_closed.json`, `umbrella_canopy.json`은 제거하고 `models/.../parts/…`로 대체했다. 게임에서 사용하는 **item_model ID는 동일**하다.
- 병합은 아이템 하나 안에서 처리하며 추가 item_display 엔티티를 소환하지 않는다.

## 중요: 투사체는 FIXED로 표시

`item_display: none`은 모델의 display 변환을 사용하지 않아 병합 부품이 분해되어 보인다. `class/153.sk`의 `rgFx`에서 **umbrella_canopy만** `ItemDisplayTransform.FIXED`로 지정했다. 나머지 효과/속도/판정/데미지는 변경하지 않았다. 투사체 fixed는 기본 scale=1이며 원본 중심 이동 `(2,-7.995,-0.5)`를 보존한다.

```mcfunction
/give @s minecraft:carrot_on_a_stick[item_model="dor:char/raingirl/umbrella_open"]
/give @s minecraft:carrot_on_a_stick[item_model="dor:char/raingirl/umbrella_closed"]
/give @s minecraft:carrot_on_a_stick[item_model="dor:char/raingirl/umbrella_stick"]
/summon minecraft:item_display ~ ~1.5 ~ {Tags:["raingirl_preview"],item_display:"fixed",transformation:{translation:[0f,0f,0f],left_rotation:[0f,0f,0f,1f],scale:[0.6f,0.6f,0.6f],right_rotation:[0f,0f,0f,1f]},item:{id:"minecraft:paper",count:1,components:{"minecraft:item_model":"dor:char/raingirl/umbrella_canopy"}}}
/kill @e[type=minecraft:item_display,tag=raingirl_preview]
```

## 텍스처 경계 개선 (2026-10-11)

- 원단 아틀라스 1024→2048px, 타일 128→256px. 각 타일 안쪽 실제 UV 영역은 240px, 사방 8px는 이웃 타일 색 번짐 방지용 여백이다.
- 기존 알파 경계 바깥 2px 덧칠과 알파를 무시한 봉제선 그리기를 제거했다. 정확한 사다리꼴 마스크 안쪽에만 선을 그리며 8×8 서브샘플로 가장자리 커버리지를 계산한다.
- 투명 영역 RGB도 유지하고 타일 가장자리를 여백으로 연장해 필터링 시 검은 테두리 및 다른 타일 샘플링을 줄인다. 픽셀 단위 반복 원단 노이즈도 제거했다.
- 40개 UV 조각 검사: 원래 도형 바깥 픽셀 중심에 남은 불투명 픽셀 13,746→0. 형상/개수/회전/display/금속 재질은 변경하지 않았다.
- 새 JSON UV 및 텍스처 내장 bbmodel 세 종류를 함께 갱신. 백업/미리보기/검증은 `output/raingirl-umbrella-2048/`에 있다. 이 폴더가 텍스처 최신본이며 v3 미리보기는 이전 1024px 버전이다.
- 이번 변경 적용은 `/build` → `/r <닉네임>`만 필요하다. 실제 게임 화면은 미확인. 화면 해상도/거리와 클라이언트 필터링에 따른 미세한 앨리어싱은 남을 수 있다.

## 삼각형 구멍 및 장착 위치 수정 (2026-10-11, 최신)

- 실제 게임에서 보인 큰 삼각형 구멍의 원인은 해상도가 아니라 **UV 90°/270° 회전 방향 오류**였다. 생성기/미리보기의 정점 순서는 Minecraft FaceInfo와 반대인데 같은 UV roll 부호를 적용했다. 이전 대칭/자체 미리보기 검증만으로 이 오류를 잡지 못했다.
- Mojang 공식 1.21.8 client.jar의 FaceInfo, BlockElementFace.UVs, Quadrant 바이트코드를 대조했다. 별도 렌더에서 사용자 스크린샷과 같은 구멍을 재현했고, 합성 조각 UV를 수정한 뒤 사라지는 것을 확인했다. 총 100요소의 면 설정을 교정. 2048 텍스처/형상/요소 수는 그대로다.
- `minecraft_face_corners_1_21_8.json`은 공식 클라이언트 정점 순서다. validate_umbrella_smooth.py에 독립 Minecraft UV 규칙 검사 추가. 생성 전 의도한 면과 최종 클라이언트 규칙으로 복원한 면의 월드 좌표/UV도 대조했다.
- 펼침: 3인칭 양손 설정은 그대로. 1인칭은 scale 0.45→0.30, 회전 [-12,0,-18]와 손잡이 기준 바깥/아래 이동 [2.5,-1.5,0] 적용(왼손 대칭). 투척 중 들고 있는 stick도 같은 1인칭 변환으로 맞춰 교체 시 튀지 않는다.
- 접힘: 1인칭 양손 설정은 그대로. 화산/삿갓의 +Y 검 모델처럼 3인칭 X 회전을 120°→0°로 바꾸고 기존 손잡이 중심에 재고정했다. 3인칭 크기 0.8 유지. 다른 캐릭터의 JSON은 수정하지 않았다.
- 최신 백업/수정 전후 클라이언트 규칙 렌더/독립 검증: `output/raingirl-hole-fix/`. firstperson-comparison.png는 70° 기본 1인칭 투영 **시뮬레이션**이며 실제 게임 캡처가 아니다.
- 적용은 `/build` → `/r <닉네임>`. 이번 변경에 Skript 수정은 없으며 실제 플레이 화면 재확인은 아직 하지 않았다.

## 편집 / 재생성

- `sources/raingirl/umbrella_open.bbmodel`, `umbrella_closed.bbmodel`, `umbrella_canopy.bbmodel`: 재질 내장, 조립된 편집용 Free Model 메시. 일반 Java 내보내기로 바로 저장하지 말 것: 메시와 조립 회전 정보가 손실된다.
- `generate_umbrella_smooth.py <출력폴더>`: 현재 Java 패널/병합 아이템/텍스처/bbmodel 생성기. 출력폴더만 수정하며 live pack을 직접 덮어쓰지 않는다.
- `validate_umbrella_smooth.py <출력폴더>`: 90도 굽기 전후 형상/UV, 여덟 display 문맥, 각도/범위/면/UV 검사.
- `smooth_baseline/`: 재현에 필요한 기존 display/하드웨어/팔레트. 초기 38/39 원본은 `original/`에 보존한다.
- **구형 `generate_umbrella.py`는 v2 계단 모델 생성기이므로 실행하지 않는다.**
- 이전 모델 전체 백업: `C:/단타/0활카스/output/raingirl-umbrella-v3/before`.
- 비교/미리보기: 같은 폴더의 `comparison.png`, `preview.png`; 정적 검증 `validation.json`.

## 적용 / 검증 범위

팩에 반영하고 `tools/build.py`의 ZIP 파일 대조 검증을 수행했다. 서버 리로드 및 실제 게임 화면 검증은 아직 수행하지 않았다.

1. `/sk reload class/153`
2. `/build`
3. `/r <닉네임>`

데이터팩 변경은 없으므로 dpreload는 필요 없다. 실제 클라이언트에서 양손 펼침/접힘, 투사체 회전, 위/아래 면을 확인한다.

---

## 스킬 연출 리소스 (`generate_vfx.py`)

| item_model | 용도 |
| --- | --- |
| `dor:char/raingirl/cloud` | 소나기 구름(복셀 102큐브). 떠다니며 흔들린다 |
| `dor:char/raingirl/stormcloud` | cloud 와 같은 모양의 먹구름 텍스처. 비가 내릴 때·비구름 지대 |
| `dor:char/raingirl/rain` | 파란 빗줄기 빌보드(32×64, 8프레임 애니메이션). `billboard:"vertical"` + scale (폭, 높이, 1) |
| `dor:char/raingirl/sunrain` | 금빛 여우비 빗줄기(같은 방식, 반짝임 포함) |
| `dor:char/raingirl/bolt` | 번개 빔 조각(z 1칸 길이, 흰 심+하늘색 빛). 조각 방향으로 세우고 scale z = 조각 길이 |
| `dor:char/raingirl/hail` | 우박 얼음 결정 |
| `dor:char/raingirl/ring` | 바닥 충격파/범위 링(수평 평면). 내려찍기 예고·충격파, 비구름 지대 경계 |

- `_plane`(세로 평면)·`_floor`(수평 평면)은 공용 부모 모델이다.
| `dor:char/raingirl/slice_a` / `slice_b` | 태풍의 눈 바닥 원판의 60° 조각(두 톤 번갈아). 6개를 yaw 0/60/…/300 으로 깔면 위에서 본 우산처럼 6조각 원판이 된다 |

- 조각 텍스처는 꼭짓점이 중앙, 조각이 텍스처 왼쪽(모델 -x)을 향한다. 아이템 디스플레이는 모델을 Y축 180° 돌려 그리므로 엔티티 yaw = 조각 각도로 둔다(계산값). 인게임에서 어긋나면 `153.sk` 의 `3.sliceyaw`(회전)·`3.slicemirror`(좌우)로 보정한다.
- 확인: `summon minecraft:item_display ~ ~2 ~ {item_display:"none",item:{id:"minecraft:stick",count:1,components:{"minecraft:item_model":"dor:char/raingirl/cloud"}}}`

## 궁 조각 실루엣 수정 (2026-10-11)

- 사용자 스케치에 맞춰 slice_a/b의 볼록한 원호를 오목한 포물선 끝단으로 변경. 6조각 조립 시 우산의 뾰족한 살 끝과 그 사이로 당겨진 천이 보인다.
- 128×128 → 1024×1024, 4배 샘플링으로 경계 처리. 기존 하늘색 두 톤/반투명 면을 유지하고 테두리를 얇게 정리했다.
- 기존 모델/item 정의/중심/좌우 방향/끝점 반경/엔티티 배치/판정은 유지. 궁 12초 등 Skript 변경 없음.
- 재생성: `python sources/raingirl/generate_vfx.py <출력 assets/dor 경로> --slices-only`. 다른 VFX를 재생성하지 않는 옵션이다.
- 백업 및 6조각 합성 비교: `output/raingirl-ult-scallop/` (워크스페이스 기준). 미리보기는 실제 게임 캡처가 아니다.
- 팩 원본에 반영. 사용자 보류 요청에 따라 GitHub 신리팩 배포는 별도 진행하며, 클라이언트에서는 갱신된 리팩을 받아야 보인다.
