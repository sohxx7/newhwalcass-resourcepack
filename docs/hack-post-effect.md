# Hack 노이즈 애니메이션 (26.3)

효과 ID: `hwalcass:hack`.

원본 `packs/base/assets/minecraft/textures/misc/hack.png`의 붉은 색상, 사각형이
겹친 노이즈, 상하 윤곽과 투명도를 유지한다. 가로 띠마다 내부 패턴이 서로 다른
방향과 속도로 이동하고, 일부 얇은 띠에 짧은 수평 어긋남을 더한다.
게임 화면 좌표와 원본 알파 윤곽은 고정되어 있다.

`hwalcass:textures/effect/hack.png`는 원본의 바이트 그대로 복사한 텍스처다.
RGB 분리, 추가 색상, 블룸, 화면 흔들림은 사용하지 않는다.

신규팩의 기존 빌드/적용 흐름(`/build` → `/r`) 이후 수동 확인:

```mcfunction
posteffect add @s hwalcass:hack
posteffect remove @s hwalcass:hack
```

기존 스킬의 camera_overlay를 제거하고 실제 스킬에 자동 적용·해제 연결을 완료했다.
수동 검사에서는 기존 Hack 카메라 오버레이와 중복 표시되지 않도록 한다.

`post_effect/hack.json`의 `HackConfig`: `Motion`은 이동량(0~1), `Speed`는 속도다.
`Motion=0`이면 원본 모습으로 표시한다.

검증: 실제 26.3 포스트 체인 코덱, 텍스처 조회, include 로더와 GLSL 컴파일러.
별도 OpenGL 두 패스 렌더링으로 네 화면 크기, 장시간 값, 중앙·장면 알파 보존,
상하 노이즈 변화 확인. `Motion=0` 원본 합성과의 RGB 차이는 8비트 기준 최대 1.
실제 게임 화면은 아직 확인하지 않았다.
