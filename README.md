# 활카스 Minecraft 26.3 리소스팩

이 브랜치는 `codex/minecraft-26.3`입니다. 1.21.8용 `main`과 별도로 관리하며, 리소스팩 포맷은 **97.1**입니다.

## 설치

[26.3 릴리스](https://github.com/sohxx7/newhwalcass-resourcepack/releases/tag/v2026.10.13-minecraft26.3.1)에서 아래 ZIP을 받습니다. GitHub의 자동 생성 `Source code` 압축파일은 게임 설치용이 아닙니다.

| 팩 | 설치 파일 | 브랜치 소스 |
| --- | --- | --- |
| 기본 | `base-26.3.zip` | `packs/base/` |
| 저사양 | `low-26.3.zip` | `packs/low/` |
| 일반 BGM | `bgm-26.3.zip` | `packs/bgm/` |
| 신규·업데이트 | `new-26.3.zip` | `pack/` |

기본팩 또는 저사양팩 하나와 일반 BGM, 신규팩을 함께 사용합니다. ZIP을 풀지 않고 리소스팩 폴더에 넣고, 신규팩을 가장 위에 놓습니다. 고음질 BGM은 이 릴리스에서 제외하며 기존 수동 설치 파일을 유지합니다.

원본 26.3 ZIP을 재압축하지 않고 배포했습니다. 원본 ZIP의 해시는 `SHA256SUMS-26.3.txt` / `SHA1SUMS-26.3.txt`, 다운로드 주소와 크기는 `release-26.3.json`, 압축 내부 파일과 브랜치 소스의 해시는 `sources/26.3-file-sha256.json`에 있습니다.

## 수정 및 빌드

```sh
python tools/build-26.3.py
python tools/build-26.3.py --pack new
```

첫 명령은 팩 4개를, 두 번째는 신규팩만 `dist/`에 생성합니다. 빌드 결과와 새 체크섬은 `dist/build-all-26.3.json` 또는 `dist/build-new-26.3.json`에 기록됩니다. ZIP 메타데이터·압축 설정이 원본 배포본과 다를 수 있으므로 재빌드한 ZIP의 해시는 위 릴리스 체크섬과 별도로 취급합니다. 빌드 도구는 ZIP의 CRC와 모든 내부 파일의 원본 일치를 검사합니다.

기존 `tools/build.py`는 `pack/`만 `dist/Newhwalcass.zip`으로 만듭니다. 26.3 배포 파일 이름과 기본·저사양·BGM 빌드에는 `build-26.3.py`를 사용합니다. 다른 `sources/`와 `docs/` 자료는 이전 작업 기록이며 현재 팩 전체를 다시 구성하는 입력은 아닙니다.

릴리스는 고정된 파일을 제공하므로 서버 PC의 HTTP 서비스 없이도 위 4개 팩을 다운로드할 수 있습니다. 브랜치만 수정하면 이미 게시한 ZIP이 자동 갱신되는 것은 아닙니다. 에셋을 바꾼 뒤에는 새 ZIP과 체크섬을 배포하고 서버의 `resourcepack.sk` 및 `ServerLinksZ/links.yml` 다운로드 주소를 함께 갱신해야 합니다. 고음질 BGM의 기존 서버 PC 주소는 이번에 바꾸지 않았습니다.

## 검증 범위

이번 게시에서는 기존 26.3 팩 내용과 모델·음원을 바꾸지 않았습니다. ZIP CRC, 포맷, SHA-1/SHA-256, 브랜치 소스와의 바이트 일치 및 비밀정보 패턴을 검사했습니다. 실제 클라이언트 접속·렌더링·음원 재생은 새로 시험하지 않았습니다.

신규팩의 이전 전체 참조 검사에는 기존 오류 4건/경고 29건이 남아 있습니다: `dor:item/generated` 2건, `dor:item/template_skull` 텍스처, `minecraft:skill/flowery/wind` 음원. 기존 수동 고음질팩의 레인걸 BGM 2곡 미포함도 그대로입니다.

1.21.8 작업 안내는 [`docs/1.21.8-README.md`](docs/1.21.8-README.md)에 보존했습니다. 이 브랜치의 ZIP을 1.21.8 서버에 적용하지 않습니다.
