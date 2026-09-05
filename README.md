# Newhwalcass Resource Pack

활카스 Minecraft 1.21.8용 신규·업데이트 리소스팩. 플라워 스페셜의 현재 플레이어 스킨 분신과 무지개 tint 셰이더가 포함되어 있습니다.

## 설치

1. [최신 릴리스](https://github.com/sohxx7/newhwalcass-resourcepack/releases/latest)에서 `Newhwalcass.zip`을 다운로드합니다.
2. Minecraft의 `resourcepacks` 폴더에 넣고 리소스팩 설정에서 활성화합니다.
3. 기존 본체 팩 `lHwalcass.zip`보다 위에 배치합니다. 이 저장소는 Newhwalcass 업데이트 팩이며 본체 팩은 별도로 필요합니다.

## 수정 및 빌드

`assets/` 아래 모델·텍스처·사운드·셰이더를 수정한 뒤 Python 3으로 실행합니다.

```sh
python tools/build.py
```

결과는 `dist/Newhwalcass.zip`입니다. GitHub의 자동 생성 Source code ZIP 대신 이 빌드 파일을 게임에 넣습니다.

## 플라워 스페셜

- 현재 플레이어 스킨의 6색 분신이 3초간 회전·가속하며 몸으로 합쳐집니다.
- 합체 후 8초 동안 같은 스킨의 본체 모델에 무지개 tint와 이동 잔상을 적용합니다.
- 스킨의 얼굴·옷 명암을 유지하며 fullbright로 렌더링합니다. 주변 지형에 광원을 생성하지는 않습니다.
- 동작에는 활카스 서버의 Class138 데이터팩과 `138_special.sk`가 필요합니다. 리소스팩만으로 스킬이나 피해가 발생하지 않습니다.
- 대응 서버에서 테스트 명령은 `/플라워스페셜테스트`이며, 본체 연출은 F5로 확인할 수 있습니다.

주요 파일:

- `assets/minecraft/items/flowery_special/`: 현재 프로필을 사용하는 6종 스킨 파츠
- `assets/minecraft/models/item/flowery_special/`: 일반·슬림 체형 모델
- `assets/minecraft/shaders/core/entity.vsh`, `entity.fsh`: 기존 스킨 UV 렌더러와 플라워 전용 tint

전용 파츠는 translation.y의 32~37번 슬롯을 사용합니다. Block brightness 0~15는 색상, sky brightness 15/14/13/12는 불투명도입니다. 기존 스킨 허물 렌더링 분기는 유지합니다.
