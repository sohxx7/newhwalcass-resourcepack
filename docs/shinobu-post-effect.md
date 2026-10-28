# Shinobu / Shinobu2 두 프레임 속도선 (26.3)

효과 ID: `hwalcass:shinobu`, `hwalcass:shinobu2`.

원본 `packs/base/assets/minecraft/textures/misc/shinobu.png`, `shinobu2.png`를 수정 없이 전용 텍스처로 복사했다. 두 버전은 각각 원본 보라색/자주색과 투명도를 그대로 사용한다.

공통 셰이더 `shaders/post/shinobu.fsh`가 두 장면을 80ms씩 보여준다. A는 원본 그대로, B는 원본 속도선만 좌우 반전하고 중앙 기준 1.10배 확대해 선 배치와 길이를 바꾼다. 월드 좌표는 그대로이며 프레임 사이의 보간·페이드·노이즈는 없다. 전체 주기는 160ms이다.

`ShinobuConfig`: `Motion=1`, `FrameRate=12.5`. `Motion=0`은 원본 정지 오버레이를 재현한다. 두 효과는 같은 셰이더와 타이밍을 사용한다.

수동 확인:

```mcfunction
posteffect add @s hwalcass:shinobu
posteffect remove @s hwalcass:shinobu
posteffect add @s hwalcass:shinobu2
posteffect remove @s hwalcass:shinobu2
```

Class109의 기존 HP별 `camera_overlay`를 대체했다. HP 12 이상은 shinobu, 1~11은 shinobu2이며 체력 변경 시 두 효과가 중첩되지 않도록 교체한다.

GIF: `C:\단타\0활카스\posteffect\shinobu.gif`, `shinobu2.gif`. 각각 2프레임, 프레임당 80ms. 실제 셰이더를 합성 검증 장면에 적용한 렌더이며 게임 캡처가 아니다.

검증: 실제 26.3 리소스 로더, PostChainConfig, 외부 텍스처 조회, 게임 셰이더 컴파일러 통과. GPU에서 원본 합성 최대 RGB 오차 1, 두 프레임 유지 및 반복, 중앙 시야·알파 보존을 검사했다. 4개 해상도와 장시간 타임스탬프에서도 렌더링했다. 실제 게임 클라이언트에서는 아직 확인하지 않았다.
