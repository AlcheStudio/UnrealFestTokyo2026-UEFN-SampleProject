# JsonSystem

@editable の JSON の文字列を読んで、キューブの色と大きさを決めるサンプルです。「データで見た目を変える」例です。

## 見どころ

- **データ駆動**：見た目を決める値を、個別の @editable ではなく 1 つの JSON 文字列で渡しています。
- **Verse の書き方**
  - `Parse[Json]` → `AsObject[]` → `Fields[Key]` → `AsFloat[]` と、失敗しうる関数（`<decides>`）をつないで読みます。どこかで失敗すれば `else` に進みます。
  - 数値は `AsFloat[]` に失敗したら `AsInt[]` を試し、`1.0 *` で float にしています（`1` と書いても `1.0` と書いても読める）。
  - Verse の文字列の中では `{` `}` を `\{` `\}` とエスケープします（`{}` は文字列補間になるため）。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `json_style_component` | JSON の `r` `g` `b` で色、`size` で大きさを決める | `SM_TutorialCube` と同じ entity | `Json` |

JSON の例：`{"r":1.0,"g":0.5,"b":0.1,"size":1.5}`

- `r` / `g` / `b` が無い項目は 0.35 になります。
- `size` が無ければ大きさは変えません。
- JSON として読めなければ Print で知らせ、何も変えません。

## イベントの流れ

```
OnBeginSimulation → Parse[Json] → AsObject
  → r/g/b を読んで M_TutorialCube の Color に
  → size を読んで SetLocalTransform の Scale に
```

## レベルでの置き場所

エリア中心 (-4000, -4000)（SyntaxSystem と同じエリア）。

- `JsonCube`

## 試してみよう

1. `Json` を `{"r":0.1,"g":1.0,"b":0.3}` にする。緑になり、大きさはそのままです。
2. `{"size":3}` のように整数で書いてみる。`AsInt` で読まれて大きくなります（色は r/g/b が無いのでグレー）。
3. わざと `{"r":1.0,` のように壊れた JSON にする。出力ログに「JSON を読めなかった」が出ます。

## UE5 との違い

- UE5 の DataTable / DataAsset のような専用アセットではなく、文字列の JSON を Verse の `/UnrealEngine.com/JSON` で読んでいます。
