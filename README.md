# 활카스 Minecraft 26.3 리소스팩

`codex/minecraft-26.3` 브랜치의 리소스팩 포맷은 **97.1**입니다. 1.21.8용 main과 별도로 관리합니다.

## 다운로드

| 팩 | 다운로드 | 브랜치 소스 |
| --- | --- | --- |
| 신규·업데이트 | [new-26.3.zip](https://github.com/sohxx7/newhwalcass-resourcepack/releases/download/v2026.10.30-minecraft26.3-fire.1/new-26.3.zip) | `pack/` |
| 기본 | [base-26.3.zip](https://github.com/sohxx7/newhwalcass-resourcepack/releases/download/v2026.10.13-minecraft26.3.1/base-26.3.zip) | `packs/base/` |
| 저사양 | [low-26.3.zip](https://github.com/sohxx7/newhwalcass-resourcepack/releases/download/v2026.10.13-minecraft26.3.1/low-26.3.zip) | `packs/low/` |
| 일반 BGM | [bgm-26.3.zip](https://github.com/sohxx7/newhwalcass-resourcepack/releases/download/v2026.10.13-minecraft26.3.1/bgm-26.3.zip) | `packs/bgm/` |

기본 또는 저사양 하나와 일반 BGM, 신규팩을 함께 사용하고 신규팩을 가장 위에 놓습니다. ZIP을 풀지 않습니다. GitHub의 자동 생성 Source code 압축파일은 게임 설치용이 아닙니다. 고음질 BGM은 기존 수동 설치 파일과 주소를 유지합니다.

## 2026-10-30 불꽃 테두리

- 독립 테스트용 `hwalcass:fire_border`를 추가했습니다. 네 변의 노랑·주황 불길을 PNG 없이 셰이더로 생성합니다.
- [적용 명령과 검증](docs/fire-border-post-effect.md), GIF는 `C:\단타\0활카스\posteffect\fire_border.gif`입니다.

## 2026-10-30 Jett 상승기류

- 제트의 양옆에 넓은 바람 면·여러 굵기의 긴 결·빠른 바람줄기를 겹쳐, 여러 겹이 동시에 위로 흐르도록 다시 만들었습니다.
- [동작과 검증](docs/jett-post-effect.md), GIF는 `C:\단타\0활카스\posteffect\jett.gif`입니다.

## 2026-10-28 포스트이펙트

- 14종 포스트이펙트와 서버의 기존 오버레이 11종 대체를 배포합니다.
- 김치포식자는 화면 반전 없는 어두운 적갈색/초록색, 레인걸은 흑백 필름과 약한 비입니다.
- Superstar의 격자는 화면 좌표에 고정됩니다. Shinobu 두 색은 2프레임 속도선입니다.
- 기존 로컬 나레이션 음원과 flowery_wind 이벤트 보정도 포함해 배포 ZIP과 작업 팩의 내용이 일치합니다.
- 서버 연결 및 검증은 [포스트이펙트 적용 안내](docs/post-effects-26.3.md)를 참고하세요.

## 2026-10-24 반영 내용

- 상어핑 채팅 아이콘, ㄹㅇㄱ 이모트의 모델·음원·음량, 후잉 음량을 반영했습니다.
- 별도로 추가된 44번 이모트 `L을 가져가`의 모델·애니메이션·음원·등록을 포함합니다.
- 감시자·제천대성·키네시스와 기존 26.3 보정을 보존했습니다. 직전 로컬 팩 에셋 1,474개는 바이트 그대로입니다.
- 이 릴리스에는 갱신된 신규팩과 체크섬만 게시합니다. 기본·저사양·일반 BGM은 위 기존 릴리스 주소를 사용합니다.

파일별 배포 주소와 ZIP 해시는 `release-26.3.json`, 소스 내부 파일 해시는 `sources/26.3-file-sha256.json`에 있습니다. 루트 체크섬 목록은 팩 4개를 포함하고 이번 릴리스 첨부 체크섬은 신규팩을 대상으로 합니다.

## 빌드

```sh
python tools/build-26.3.py --pack new
python tools/build-26.3.py
```

신규팩 또는 팩 4개를 `dist/`에 생성합니다. ZIP 압축 메타데이터에 따라 재빌드 파일의 해시는 배포본과 다를 수 있습니다. 빌드 도구는 CRC와 내부 파일 바이트 일치를 확인합니다. 기존 `tools/build.py`는 pack/만 Newhwalcass.zip이라는 이름으로 만들기 때문에 26.3 배포에는 위 도구를 사용합니다.

## 검증 범위

ZIP CRC·전체 JSON 파싱, 변경된 모델·음원·폰트·이모트 경로의 엄격 참조 검사(경고 0), 기존 에셋 보존을 확인했습니다. 새 클라이언트 렌더링·청취 검사는 하지 않았습니다. 이전 전체 검사에서 확인된 기존 참조 오류 4건/경고 29건과 수동 고음질팩의 레인걸 BGM 미포함은 이번 변경 대상이 아닙니다.

브랜치 수정만으로 릴리스 ZIP이 자동 갱신되지는 않습니다. 새 ZIP 배포 시 서버의 resourcepack.sk와 ServerLinksZ/links.yml을 함께 갱신합니다. 1.21.8 작업 안내는 [docs/1.21.8-README.md](docs/1.21.8-README.md)에 있습니다.
