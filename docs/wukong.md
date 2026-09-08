# 제천대성 장비

Minecraft Java 1.21.8. 기존 본체 팩과 함께 Newhwalcass를 활성화합니다.

| 장비 | 큐브 수 | item_model |
| --- | ---: | --- |
| 여의봉 | 256 | `dor:char/wukong/jingubang` |
| 긴고아 | 298 | `dor:char/wukong/jingeuna` |
| 근두운 | 292 | `dor:char/wukong/jindouyun` |

여의봉은 선택한 v2 최적화본으로, 붉은 봉과 금색 끝장식을 유지하고 소용돌이 무늬를 제거한 형태입니다. 긴고아는 786개에서 298개로 줄였으며 금색 입체 장식·양쪽 말림·착용 크기를 유지합니다. 근두운은 단순화한 292큐브 외형 모델입니다.

권한 있는 플레이어의 채팅에서 지급합니다. 콘솔에서는 `@s`를 대상 닉네임으로 바꿉니다.

```mcfunction
/give @s minecraft:stick[item_model="dor:char/wukong/jingubang",custom_name={text:"여의봉",color:"gold",italic:false},max_stack_size=1]
/give @s minecraft:paper[item_model="dor:char/wukong/jingeuna",custom_name={text:"긴고아",color:"gold",italic:false},max_stack_size=1,equippable={slot:"head",equip_sound:"minecraft:item.armor.equip_gold",damage_on_hurt:false}]
/give @s minecraft:paper[item_model="dor:char/wukong/jindouyun",custom_name={text:"근두운",color:"yellow",italic:false},max_stack_size=1]
```

긴고아는 머리 슬롯에 착용합니다. 근두운의 탑승·비행과 여의봉 스킬은 별도 서버 구현이 필요합니다. 이름만 바꾼 일반 아이템에는 모델이 적용되지 않습니다.

아이템 등록은 `assets/dor/items/char/wukong/`, 모델은 `assets/dor/models/item/char/wukong/`, 텍스처는 `assets/dor/textures/item/char/wukong/`입니다. 여의봉의 기존 팔레트와 긴고아·근두운의 공용 팔레트는 파일명을 분리하여 색상 충돌을 방지했습니다.

모델·텍스처 참조, 허용 좌표·회전, UV, Blockbench 원본과의 일치, ZIP 무결성을 확인했습니다. 착용 비교 이미지는 모델 데이터로 렌더링했으며 실제 Minecraft 클라이언트 장착 화면과 FPS는 별도 확인이 필요합니다.
