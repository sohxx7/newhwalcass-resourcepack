# G 핑 휠 (26.3)

G(바닐라 Quick Actions 키)를 누르면 원형 메뉴가 열린다.

- 바깥 고리 4칸 = 핑. 왼위부터 시계 방향으로 해당 위치(Z), 위험(X), 가는 중(C), 적 사라짐(V)이다. 모드키 핑과 같은 `hwalPing`을 쓴다.
- 가운데 원 위 = 스프레이, 아래 = 이모트. 지금 장착한 것이 나간다. 발동 조건은 9번칸과 같다(게임 중, 피격 직후·투명 아님, 쿨 없음).

## 파일

| 위치 | 내용 |
| --- | --- |
| `sources/gwheel/gwheel_gen.py` | 생성기. 리팩 글리프와 서버 데이터팩을 함께 만든다 |
| `pack/assets/gwheel/` | 폰트 `gwheel:ui`, 휠 배경 4조각, 보이지 않는 클릭 띠 |
| `hwalcass-26.3/world/datapacks/Gwheel/` | 다이얼로그 `gwheel:wheel`, `#minecraft:quick_actions` 등록, `gwheel:spray`/`gwheel:emote` |
| `hwalcass-26.3/plugins/Skript/scripts/gwheel.sk` | 클릭 처리 |
| `hwalcass-26.3/plugins/Skript/scripts/zxcv.sk` | 핑 본체를 `hwalPing(player, key)` 함수로 분리 |

## 배치

- 텍스트 한 덩어리로 그린다. 줄 폭을 모두 232로 맞추고, 글리프마다 ascent를 줘서 y 위치를 정한다.
- 클릭은 글리프 사각형 단위로 판정된다. 그래서 칸 모양을 보이지 않는 띠 글리프로 덮는다.
- 본문은 화면 높이에서 66을 뺀 영역의 위쪽에 붙는다.
- 1080p·GUI 크기 4에서 본문은 204px이다. 그 안에 위 여백 16px과 휠 182px(22줄 = 198px)을 넣었다.

다이얼로그 레지스트리는 서버를 시작할 때만 읽으므로, 다이얼로그를 바꾸면 서버를 재시작해야 한다.

미리보기: `python sources/gwheel/gwheel_gen.py preview <폴더>`. 왼쪽은 화면, 오른쪽은 클릭 영역이다.
