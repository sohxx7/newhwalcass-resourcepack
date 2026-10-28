# Electro / Pool (26.3)

효과 ID는 `hwalcass:electro`, `hwalcass:electro_pool`이다.
신규팩의 기존 `/build` → `/r` 흐름으로 리소스를 갱신한 뒤 확인한다.

```mcfunction
posteffect add @s hwalcass:electro
posteffect remove @s hwalcass:electro
posteffect add @s hwalcass:electro_pool
posteffect remove @s hwalcass:electro_pool
```

## Electro

사용자가 선택한 이전 녹색 번개 버전을 대화에 보존된 최종 GLSL 코드와 설정으로
복원했다. 이전 Prism 작업 폴더와 ZIP은 현재 찾을 수 없어 파일 단위 동일성은
확인할 수 없다. 상하 각각 3개 긴 방전, 가지, 밝은 중심과 녹색 외곽광, 독립적인
재점화 타이밍, 두 방향 블룸과 합성 등 당시 구성을 사용한다.

첫 번째/네 번째 패스의 `ElectroConfig` 기본값:
Intensity=1.18, EdgeHeight=0.24, Speed=1.0, Distortion=0.18.
PNG 입력은 사용하지 않는다.

## Pool

원본 `electro_pool.png`의 청록색→흰색 5겹과 반투명도 130/255를 기준으로 한다.
상하 각 경계를 주기 곡선으로 근사했다. 원본과 정지 곡선의 평균 경계 오차는
각 겹당 약 0.35~1.42 원본 픽셀이다. 겹마다 흐름에 작은 차이를 주며 상하 물결은
서로 반대 방향으로 흐른다. 12초 주기를 연속 함수로 구성해 순간 이동이나
텍스처 반복 경계가 없다. 실제 PNG 입력은 사용하지 않는다.

`PoolConfig`: Motion=1.0, Speed=1.0. 0이면 정지한다.

## 미리보기와 검증

이후 효과의 GIF 미리보기는 모두 `C:\단타\0활카스\posteffect`에 저장한다.
현재 파일: `superstar.gif`, `hack.gif`, `electro.gif`, `pool.gif`.
미리보기는 별도 GPU 렌더링이며 실제 게임 화면 캡처가 아니다.

26.3 실제 포스트 체인 코덱, include 로더, 양쪽 깊이 규약의 GLSL 컴파일 검증 통과.
JSON의 모든 렌더 패스를 GPU에서 실행하고 4개 화면 크기 및 장시간 값을 검사했다.
중앙과 장면 알파를 보존하며 pool의 0초/12초 출력 차이는 RGB 최대 1이다.
Class30의 기존 camera_overlay를 제거하고 적 적중 조건·스킨별 적용·궁 종료에 포스트이펙트를 연결했다.
