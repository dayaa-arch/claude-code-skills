# claude-code-skills

[Claude Code](https://claude.com/claude-code) 用に自作した、再利用可能なカスタムスキル（スラッシュコマンド）集です。

主にドキュメント駆動開発（DDD: 永続的ドキュメント + 作業単位のステアリングファイル）と、
FastAPI / Python プロジェクトのスキャフォールディングを対象にしています。

## 収録スキル

### コマンド（`commands/`）— `~/.claude/commands/` に配置

| コマンド | 説明 |
| --- | --- |
| [`/init-idea`](commands/init-idea.md) | アイデアの雛形（タイトル/背景/やりたいこと）を対話で埋め、`docs/ideas/initial-requirements.md` を作成する |
| [`/dev-docs`](commands/dev-docs.md) | ドキュメント駆動開発プロセス（永続的ドキュメント + ステアリング）の標準ルールを適用する |
| [`/add-feature`](commands/add-feature.md) | `CLAUDE.md` と `docs/` を読み込み、「ステアリング作成 → GitHub Issue 起票 → 実装 → テスト → 検証 → PR 作成 → main マージ」までを、ステアリング作成後の承認1回を挟んで自動実行する |
| [`/fsos-dev`](commands/fsos-dev.md) | 自作の案件管理システム（FieldSpec OS）の MCP から案件仕様を取得し、それを唯一の情報源として `README.md` / `CLAUDE.md` / 永続的ドキュメントを生成する（`/dev-docs` の MCP 連携版） |
| [`/review-docs`](commands/review-docs.md) | `/dev-docs` が生成した永続的ドキュメントと `CLAUDE.md` を、専用サブエージェントでレビューする |
| [`/understand-code`](commands/understand-code.md) | コードベースを「抽象 → 具体 → 抽象」のサイクルで読み解き、理解ノート（`.understanding/`）に残しながら理解を深める |
| [`/fastapi-new`](commands/fastapi-new.md) | FastAPI プロジェクト（`uv` 構成）を新規作成する。規模感に応じて3パターンのディレクトリ構成を使い分ける |
| [`/python-new`](commands/python-new.md) | 汎用 Python プロジェクト（`uv` + `src` パッケージ構成）を新規作成する |

### スキル（`skills/`）— `~/.claude/skills/` に配置

| スキル | 説明 |
| --- | --- |
| [`hearing-sheet`](skills/hearing-sheet/SKILL.md) | Google Drive の案件フォルダからヒアリングシート雛形を読み込み、対話でヒアリングを実施し、回答を Drive とローカル `docs/idea.md` に保存する |
| [`decision-rules`](skills/decision-rules/SKILL.md) | 業務理解・業務設計から要件定義に落とし込む過程の意思決定を、パレートの法則（80/20で急所を絞る）とシンプルルール（3〜5本の一行ルール）で行い、決定記録として残す |
| [`obsidian-log`](skills/obsidian-log/SKILL.md) | セッションの会話を構造化サマリ（何をやったか / 決めたこととその理由 / 詰まった点 / 次にやること）のノート1枚にまとめ、Obsidian 保管庫の `AI Log/` に書き出す |

### サブエージェント（`agents/`）— `~/.claude/agents/` に配置

`/dev-docs` / `/fsos-dev` / `/add-feature` から呼び出される、重い読み込み・生成処理をメインの会話から隔離するための専用サブエージェント群です。

| エージェント | 説明 |
| --- | --- |
| [`doc-writer`](agents/doc-writer.md) | 永続的ドキュメント（`docs/` 配下）や `CLAUDE.md` / `README.md` を1ファイルずつ生成・更新し、書いたパスと根拠だけを要約して返す |
| [`docs-digest`](agents/docs-digest.md) | `CLAUDE.md` と `docs/` を読み込み、実装に入る前に必要な前提だけを圧縮した「実装前提ダイジェスト」として返す（`/add-feature` 冒頭で使用） |
| [`fsos-spec-fetcher`](agents/fsos-spec-fetcher.md) | FieldSpec OS の MCP から案件の確定済み仕様を取得し、生の仕様をローカルキャッシュに書き出して索引だけを返す（`/fsos-dev` で使用） |
| [`review-docs`](agents/review-docs.md) | `/dev-docs` が生成した永続的ドキュメントと `CLAUDE.md` の品質・整合性をレビューし、簡潔な指摘リストだけを返す |

## インストール

### 1ファイルだけ使う場合

対象ファイルを対応するディレクトリにコピーするだけです。

```bash
# コマンド（スラッシュコマンド）
cp commands/dev-docs.md ~/.claude/commands/

# スキル
cp -r skills/hearing-sheet ~/.claude/skills/

# サブエージェント
cp agents/doc-writer.md ~/.claude/agents/
```

### まとめて使う場合

```bash
./install.sh
```

`~/.claude/commands/`・`~/.claude/skills/`・`~/.claude/agents/` に全ファイルをコピーします。同名ファイルがある場合は上書き前に確認します。

## 前提・注意事項

- 各スキルは特定のプロジェクト構成（`docs/` 配下7ファイル、`.steering/` ディレクトリなど）を前提にしています。詳細は各ファイル冒頭の `description` と本文を参照してください。
- `/fsos-dev` は筆者が自作した MCP サーバ（FieldSpec OS）への接続を前提とします。同名の MCP を持たない環境では `/dev-docs` を使ってください。
- `/fastapi-new` / `/python-new` は `uv` の利用を前提とします。
- `obsidian-log` は **使う前に `SKILL.md` 冒頭の `VAULT` を自分の Obsidian 保管庫の絶対パスに書き換える**必要があります。
- いずれのスキルも、機密情報（APIキー・顧客情報等）をコードやドキュメントに書き込まないことを原則としています。

## ライセンス

[MIT License](LICENSE)
