# Newhwalcass Resource Pack

## 설명

활카스 Minecraft 1.21.8용 신규·업데이트 리소스팩입니다. 캐릭터 장비, 효과, 사운드 리소스를 포함합니다.

## 설치

1. [최신 릴리스](https://github.com/sohxx7/newhwalcass-resourcepack/releases/latest)에서 `Newhwalcass.zip`을 다운로드합니다.
2. Minecraft의 `resourcepacks` 폴더에 넣고 리소스팩 설정에서 활성화합니다.
3. 기존 본체 팩 `lHwalcass.zip`보다 위에 배치합니다. 이 저장소는 Newhwalcass 업데이트 팩이며 본체 팩은 별도로 필요합니다.

## 수정 및 빌드

실제 게임 리소스는 `pack/`에 있습니다. `pack/assets/` 아래 모델·텍스처·사운드·셰이더를 수정한 뒤 Python 3으로 실행합니다.

```sh
python tools/build.py
```

결과는 `dist/Newhwalcass.zip`입니다. GitHub의 자동 생성 Source code ZIP 대신 이 빌드 파일을 게임에 넣습니다.

## 로컬 서버와 함께 작업

서버 코드 저장소와 이 저장소는 서로 독립적으로 관리합니다. 서버 저장소 안에 이 저장소를 복사하거나 서브모듈로 추가하지 않습니다.

현재 Windows 작업 경로:

- 서버 코드: `C:\단타\0활카스\git` → `sohxx7/hwal`
- 리소스팩: `C:\단타\0활카스\resourcepack` → `sohxx7/newhwalcass-resourcepack`
- 서버의 `C:\단타\0활카스\git\pack`은 이 저장소의 `pack` 폴더를 가리키는 디렉터리 연결(junction)입니다. 두 경로에서 편집하는 파일은 동일합니다.

기존 서버 명령은 그대로 사용합니다. `build-resourcepack.sk`의 `/build`가 서버의 `pack`을 압축해 `plugins/SimpleWebServer/web/hwalcass.zip`에 만들고, `/r [닉네임]`이 기존 8080 포트의 ZIP을 전송합니다. 이 과정에 Git push나 GitHub 릴리스는 필요하지 않습니다. 접속 시 자동 배포하는 GitHub Release 링크는 `resourcepack.sk`에서 별도로 관리합니다.

Git 명령은 대상 저장소를 명시해 실행합니다.

```powershell
git -C 'C:\단타\0활카스\git' status
git -C 'C:\단타\0활카스\resourcepack' status
```

리소스팩 작업의 commit/pull/push는 두 번째 경로에서 실행합니다. 연결 경로인 `git\pack`에서 Git 명령을 실행하면 상위 서버 저장소를 선택할 수 있으므로, Git 작업에는 항상 실제 `resourcepack` 경로를 사용합니다. 서버 저장소의 기존 `/pack` 제외 설정은 유지합니다. 문서·편집 자료·도구·`.git`은 `pack/` 밖에 두어 `/build`와 릴리스 ZIP에 들어가지 않게 합니다. 새 환경에서 연결을 만들 때에는 기존 서버 `pack`을 먼저 백업하고 양쪽 파일을 비교·병합해야 합니다. 변경이 남아 있는 상태에서 강제 pull/reset이나 폴더 덮어쓰기를 하지 않습니다.

`docs/` 및 `sources/`의 기존 `assets/...` 표기는 팩 내부 경로입니다. 저장소에서 찾을 때는 앞에 `pack/`을 붙입니다.
