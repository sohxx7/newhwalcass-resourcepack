# Jinx / Jinx SG 속도감 (26.3)

효과 ID: `hwalcass:jinx`, `hwalcass:jinx_sg`.

원본 이미지에서 세로 줄과 방사형 속도선을 분리했다. 가려진 세로 줄은 같은
열의 인접 픽셀로 복원해 직선을 유지한다. 왼쪽 줄은 위로, 오른쪽 줄은 아래로
흐르며 줄마다 속도가 다르다. 외곽 속도선은 원래 방향을 유지한 채 바깥으로
짧게 뻗고 사라진다. 중앙 시야와 장면 좌표는 변형하지 않는다.

두 효과는 같은 `jinx.fsh`, 선 배치, 타이밍, 설정을 사용한다. 일반 버전은 원본의
파랑/보라, SG 버전은 원본의 분홍/흰색이다. 원본 및 분리된 두 레이어의 알파
배치는 양쪽 버전에서 동일함을 확인했다. 6초 주기로 연결된다.

신규팩의 `/build` → `/r` 이후 수동 확인:

```mcfunction
posteffect add @s hwalcass:jinx
posteffect remove @s hwalcass:jinx
posteffect add @s hwalcass:jinx_sg
posteffect remove @s hwalcass:jinx_sg
```

`JinxConfig`: Motion=1.0, Speed=1.0. Motion=0은 원본 정지 이미지다.
기존 스킬의 camera_overlay를 포스트이펙트로 대체했다.

GIF: `C:\단타\0활카스\posteffect\jinx.gif`, `jinx_sg.gif`.
각 180프레임/6초의 별도 GPU 렌더링이며 실제 게임 캡처는 아니다.

검증: 26.3 실제 코덱, 모든 텍스처 조회, include 로더와 GLSL 컴파일러 통과.
GPU의 JSON 두 패스에서 네 화면 크기와 장시간 값, 중앙·장면 알파 보존을 검사했다.
원본 정지 합성 RGB 오차는 최대 1, 0초/6초 반복 비교 오차는 양쪽 모두 0이다.
