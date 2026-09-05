# Newhwalcass Resource Pack

활카스 Minecraft 1.21.8용 신규·업데이트 리소스팩. 플라워 스페셜의 현재 플레이어 스킨 분신·무지개 tint와 장화신은 고양이의 레이피어·모자·착용 장화가 포함되어 있습니다.

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

## 룰루 모자

`dor:char/lulu/hat`의 아이템 등록·모델·텍스처를 기존 서버 배포본에서 복구했습니다. 원본 모양과 머리 착용 변환, 제작자 표기를 유지합니다. 서버의 Class146 모자 지급 코드는 그대로 사용할 수 있습니다.

## 장화신은 고양이 장비

검은 모자와 버건디 테두리·굽은 금색 깃털, 은색 컵 가드 레이피어, 붉은 커프 테두리가 있는 검은 장화입니다. 기존 캐릭터와 같은 `dor` 네임스페이스의 `char/puss` 양식으로 등록했습니다. 아이템 ID는 `dor:char/puss/rapier`, `dor:char/puss/hat`, `dor:char/puss/boots`입니다.

지급 명령과 착용 방식은 [장비 사용 안내](docs/puss-in-boots.md)를 참고하세요. 장화는 발 슬롯에 장착하면 전용 텍스처가 보이고, 착용 중 입체 모양은 바닐라 방어구 형태를 사용합니다.

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
