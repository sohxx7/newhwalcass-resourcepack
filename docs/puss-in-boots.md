# 장화신은 고양이 장비

서버 148번 **묘객**은 Skript로 동작합니다. 스킬 사운드 9종(`dor:puss.*`), 찌르기·현상금·파편 이펙트와 공중 옆돌기용 프로필 스킨 모형이 이 팩에 포함되어 있습니다. 옆돌기는 양팔을 넓은 V자로 들고 0.5초 동안 한 바퀴 회전하며, 실제 플레이어 카메라의 회전은 바꾸지 않습니다. 스킨 모형은 기존 셰이더의 별도 48~53번 영역을 사용합니다.

장비만 지급하는 아래 명령과 달리, 서버에서 스킬까지 시험하려면 캐릭터 선택 GUI의 148번 묘객 또는 `/function class148:select`를 사용합니다.

Minecraft Java 1.21.8. 기존 본체 `lHwalcass`와 함께 Newhwalcass 팩을 활성화하고 아래 명령으로 지급합니다. 모드는 필요하지 않습니다.

```mcfunction
/give @s minecraft:iron_sword[item_model="dor:char/puss/rapier",custom_name={text:"장화신은 고양이의 레이피어",italic:false}]
/give @s minecraft:carved_pumpkin[item_model="dor:char/puss/hat",custom_name={text:"장화신은 고양이의 모자",italic:false},equippable={slot:"head",equip_sound:"minecraft:item.armor.equip_leather"}]
/give @s minecraft:leather_boots[item_model="dor:char/puss/boots",custom_name={text:"장화신은 고양이의 장화",italic:false},equippable={slot:"feet",asset_id:"dor:char/puss/boots",equip_sound:"minecraft:item.armor.equip_leather"}]
```

권한 있는 플레이어의 채팅에서 실행합니다. 콘솔에서는 `@s`를 대상 닉네임으로 바꾸세요. 모자는 머리 슬롯, 장화는 발 슬롯에 끼웁니다. `equippable`을 교체한 모자는 호박 시야 가림을 적용하지 않습니다.

기존 캐릭터와 같은 `dor` 네임스페이스의 `char/puss` 양식을 사용합니다. `item_model="dor:char/puss/rapier"`는 `assets/dor/items/char/puss/rapier.json`을 선택하고, 그 안의 `model.model="dor:item/char/puss/rapier"`가 `assets/dor/models/item/char/puss/rapier.json`을 연결합니다. 모자·장화도 같은 구조이며, 아이템 텍스처 경로는 `assets/dor/textures/item/char/puss/`입니다.

장화는 인벤토리에서 보이는 아이템 모델과 착용 장비 텍스처를 각각 갖습니다. 착용 경로는 다음과 같습니다.

```text
equippable.asset_id = dor:char/puss/boots
  → assets/dor/equipment/char/puss/boots.json
  → layers.humanoid[].texture = dor:char/puss/boots
  → assets/dor/textures/entity/equipment/humanoid/char/puss/boots.png
```

돌출 발끝·커프·박차의 별도 아이템 지오메트리는 발 슬롯에 그대로 표시되지 않으며, 착용 시 기본 방어구 다리 메시에 전용 텍스처가 적용됩니다.

이름만 변경한 일반 철검·호박·가죽 장화는 바뀌지 않습니다. 지급한 아이템의 `item_model`과 `equippable` 컴포넌트를 유지하세요.

DreamWorks 장화신은 고양이의 장비를 참고해 직접 제작한 팬 모델입니다. 공식 이미지나 타인의 모델을 팩에 포함하지 않았습니다.

배포 전 모델 좌표·허용 회전·텍스처 연결·ZIP 무결성을 검사했습니다. 실제 클라이언트의 장착 화면·1인칭 위치는 별도 확인이 필요합니다.

## 묘객 스킬 사운드

`dor:puss.ultimate`에는 [Universal 공식 예고편](https://www.youtube.com/watch?v=xgZLXyqbYOc)의 110.140–112.120초 대사 “Fear me, if you dare.”를 사용합니다.

- 팡트 `dor:puss.fente`: [GaelanW의 실제 플뢰레 충돌 녹음](https://freesound.org/people/GaelanW/sounds/490074/), [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). 더 맑은 5.869–6.160초 단발을 골라 1.2배속과 중저음 정리로 약 0.24초의 경쾌한 충돌음으로 다듬었습니다.
- 공중 옆돌기 `dor:puss.roll`: [qubodup의 Whoosh](https://freesound.org/people/qubodup/sounds/60013/), [CC0](https://creativecommons.org/publicdomain/zero/1.0/). 실제 대나무를 휘둘러 낸 한 번의 바람 소리를 약 0.457초로 맞췄습니다.
- 펜타킬 `dor:puss.pentakill`: [지정 OST 영상](https://www.youtube.com/watch?v=s8EAdlxwsq8)의 159.30–169.30초, 10초 음악 구간입니다.
- 마무리 대사 `dor:puss.round_win`: [지정 영상](https://www.youtube.com/watch?v=Bm7zI0ksExY)의 81.30–84.85초, 마지막 “death”를 포함한 3.55초입니다.

전체 출처는 ZIP 내부 `assets/dor/sounds/puss/CREDITS.txt`에 있습니다. 음악은 48 kHz 스테레오 Vorbis, 효과음·대사는 48 kHz 모노 Vorbis입니다. 다른 스킬 효과음은 기존 제작 음원을 유지합니다.

공중 옆돌기는 서버의 `148_movement.sk`와 6본 키프레임이 필요합니다. 모션에는 플레이어 스킨만 표시하고 착용 장비는 잠시 숨깁니다. 회전 중 카메라 방향은 유지합니다.
