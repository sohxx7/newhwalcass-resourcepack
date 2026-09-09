# 빅 배드 울프 — 쌍낫과 폴암

Minecraft Java 1.21.8. 기존 본체 팩과 함께 Newhwalcass를 활성화합니다.

| 무기 | 큐브 수 | item_model |
| --- | ---: | --- |
| 오른손 낫 | 35 | `dor:char/death/sickle_right` |
| 왼손 낫 | 35 | `dor:char/death/sickle_left` |
| 폴암 | 74 | `dor:char/death/polearm` |

《장화신은 고양이: 끝내주는 모험》의 죽음 / 빅 배드 울프를 참고해 만든 초승달 쌍낫과 결합 폴암입니다. 오른손 낫에는 여덟 개의 고양이 표식이 있고, 왼손 낫에는 표식이 없습니다. 날선, 긁힘, 가죽 감김은 128×128 텍스처 두 장으로 표현했습니다. 폴암의 자동 변형이나 전투 스킬은 포함하지 않습니다.

권한 있는 플레이어의 채팅에서 지급합니다. 콘솔에서는 `@s`를 대상 닉네임으로 바꿉니다.

```mcfunction
/give @s minecraft:stick[item_model="dor:char/death/sickle_right",custom_name={text:"죽음의 낫 · 오른손",color:"gray",italic:false},max_stack_size=1]
/give @s minecraft:stick[item_model="dor:char/death/sickle_left",custom_name={text:"죽음의 낫 · 왼손",color:"gray",italic:false},max_stack_size=1]
/give @s minecraft:stick[item_model="dor:char/death/polearm",custom_name={text:"죽음의 폴암",color:"gray",italic:false},max_stack_size=1]
```

양손에 각각 장착하려면 다음 명령을 사용합니다.

```mcfunction
/item replace entity @s weapon.mainhand with minecraft:stick[item_model="dor:char/death/sickle_right",max_stack_size=1]
/item replace entity @s weapon.offhand with minecraft:stick[item_model="dor:char/death/sickle_left",max_stack_size=1]
```

아이템 정의는 `assets/dor/items/char/death/`, 모델은 `assets/dor/models/item/char/death/`, 텍스처는 `assets/dor/textures/item/char/death/`입니다. 모델·텍스처 연결, 허용 좌표·UV, 원본과의 일치, 기존 팩 파일 보존과 ZIP 무결성을 검증했습니다. 실제 Minecraft 클라이언트 장착 확인은 별도입니다.
