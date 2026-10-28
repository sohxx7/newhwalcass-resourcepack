# Jett 좌우 바람 (26.3)

효과 ID: `hwalcass:jett`.

원본 `packs/base/assets/minecraft/textures/misc/jett.png`의 흰 바람 결과 낮은
불투명도를 유지한다. 왼쪽과 오른쪽에 서로 다른 위상의 큰 굴곡과 작은 잔물결이
위쪽으로 흐른다. 바람 텍스처의 좌표만 움직이며 장면 좌표와 중앙 화면은 고정이다.
위아래 경계는 고정해 이미지 끝이 노출되지 않고 6초 주기로 끊김 없이 반복된다.

신규팩의 `/build` → `/r` 이후 수동 확인:

```mcfunction
posteffect add @s hwalcass:jett
posteffect remove @s hwalcass:jett
```

`JettConfig`: Motion=1.0, Speed=1.0. Motion=0이면 원본을 그대로 표시한다.
텍스처는 원본을 바이트 그대로 복사했다. 기존 스킬의 자동 적용·해제 연결을 완료했다.

GIF: `C:\단타\0활카스\posteffect\jett.gif` (별도 GPU 렌더링, 180프레임/6초).
26.3 실제 포스트 체인 코덱, 텍스처 조회, include/GLSL 컴파일 검증 통과.
GPU 두 패스 렌더링에서 네 화면 크기, 장시간, 중앙·장면 알파 보존을 확인했다.
Motion=0의 원본 비교 및 반복 시작/끝 비교에서 RGB 차이는 최대 1이다.
실제 게임 화면은 아직 확인하지 않았다.
