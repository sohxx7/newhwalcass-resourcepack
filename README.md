# Newhwalcass Resource Pack

## 설명

활카스 Minecraft 1.21.8용 신규·업데이트 리소스팩입니다. 캐릭터 장비, 효과, 사운드 리소스를 포함합니다.

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
