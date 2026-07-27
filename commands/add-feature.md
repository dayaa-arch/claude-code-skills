---
description: CLAUDE.md と docs/ を読み込み、ステアリングファイル規則に従って「ステアリング作成→Issue起票→実装→テスト→検証→PR作成→mainマージ」までを自動実行する（ステアリング作成後に1回だけ承認）
argument-hint: <開発タイトル または 追加したい機能の説明>
---

# 機能追加の自動実行（add-feature）

`dev-docs` の「機能追加・修正時の手順」を、**ステアリングファイル作成後の1回の承認**を挟んで全工程自動で回す。
CLAUDE.md と `docs/` 配下の永続的ドキュメントを真とし、CLAUDE.md に記載されたステアリングファイル規則
（`.steering/[YYYYMMDD]-[開発タイトル]/` に `requirements.md` / `design.md` / `tasklist.md`）に従う。

全体の流れ:

```
ステアリング3ファイル作成 → 【承認ゲート】 → GitHub Issue 起票 → 作業ブランチ作成
  → 実装 → lint/型/テスト → 動作検証 → commit & push → PR 作成 → main へマージ → 完了報告
```

引数: `$ARGUMENTS`

- 引数 = 追加・変更したい機能の説明、または `<開発タイトル>`（例: `add-tag-feature`、`タグ機能を追加`）
- 引数なし → 「どんな機能を追加するか」をユーザーに尋ねてから開始する

---

## Step 0: 前提チェック

- `CLAUDE.md` と `docs/` が存在するか確認する（`Glob` で `docs/**/*.md` と `CLAUDE.md`）。
  - どちらも無い／`docs/` が未生成 → **中断**し、「先に `/dev-docs init` で永続的ドキュメントを整備してください」と案内する。
- GitHub 連携の前提を確認する:

  ```bash
  gh auth status
  gh repo view --json nameWithOwner,defaultBranchRef
  git status --porcelain
  ```

  - `gh` が未認証／リモートが GitHub でない → Issue・PR の工程はスキップし、その旨を Step 5 の提示に明記する（実装自体は続行）。
  - 作業ツリーに未コミットの変更がある → ユーザーに知らせ、stash / commit するか確認してから進む。
- 引数が空なら、追加したい機能の内容をユーザーに確認する。

## Step 1: コンテキスト読み込み（CLAUDE.md と docs/ を全て）

次を読み込み、実装の前提を把握する:

- `CLAUDE.md` — **ここに書かれたステアリングファイル規則を最優先で順守する**（ディレクトリ命名、作成するファイル、各種規約）。CLAUDE.md の規則が以下の手順と食い違う場合は CLAUDE.md を優先。**ただし承認の粒度は例外**: CLAUDE.md や dev-docs に「1ファイルごとに承認」とあっても、本スキルではステアリング3ファイルを一括作成し、承認は Step 5 の1回にまとめる（これは dev-docs が認める例外である）。
- `docs/` 配下の永続的ドキュメント全て（product-requirements / functional-design / architecture / repository-structure / development-guidelines / glossary / development-roadmap）。
- `docs/ideas/initial-requirements.md`（あれば。プロダクトの North Star）。

特に次を押さえる: 確定した技術スタックとビルド/テスト/lint コマンド（`architecture.md`・`CLAUDE.md`・`package.json`・`pyproject.toml` 等）、コーディング/命名/テスト/**Git 規約（ブランチ命名・コミットメッセージ形式）**（`development-guidelines.md`）、用語（`glossary.md`）、配置ルール（`repository-structure.md`）。

## Step 2: 影響分析

- 今回の機能が**永続的ドキュメント（`docs/`）に影響するか**を判定する（要求・設計・技術スタック・構造・用語の変更を伴うか）。
- 影響する場合は「どのファイルをどう更新するか」を控えておく（実際の更新は承認後の Step 7 で行う）。
- 既存コードへの影響範囲（変更/追加するモジュール・関数・データ構造）を洗い出す。`Glob`/`Grep`/`Read` で関連箇所を特定する。

## Step 3: ステアリングディレクトリ作成

開発タイトルを決める（引数から。日本語説明なら短い英語ケバブケースに変換。例: `タグ機能を追加` → `add-tag-feature`）。
このタイトルはステアリングディレクトリ名・ブランチ名・Issue/PR タイトルで一貫して使う。
日付は実行時に取得する。

```bash
DATE=$(date +%Y%m%d)
mkdir -p ".steering/${DATE}-<開発タイトル>"
```

CLAUDE.md にこれと異なる命名規則があればそれに従う。

## Step 4: ステアリング3ファイルを一括作成

`.steering/[YYYYMMDD]-[開発タイトル]/` に、dev-docs 規約に沿って3ファイルを作成する（ここでは承認を取らず一括で作る）:

1. **requirements.md** — 今回の要求内容 / ユーザーストーリー / 受け入れ条件 / 制約事項
2. **design.md** — 実装アプローチ / 変更するコンポーネント / データ構造の変更 / 影響範囲の分析（Step 2 の `docs/` 更新方針もここに明記）
3. **tasklist.md** — 具体的な実装タスク（チェックボックス形式）/ 進捗状況 / 完了条件。**テスト作成と動作検証もタスクに含める。**

要求・設計は `docs/` の永続的ドキュメントおよび North Star と矛盾しないようにする。

## Step 5: 【承認ゲート】← ここだけ人が確認

実装に入る前に、ユーザーへ次を**簡潔に**提示し、承認を求めて**いったん停止する**:

- 開発タイトルとステアリングディレクトリのパス
- requirements / design / tasklist の要点（各2〜4行程度のサマリ。全文は貼らない）
- 影響する `docs/` 更新の有無と対象ファイル
- 主要な実装タスク一覧
- **GitHub 連携の実行内容**（承認はここで一括して得る）:
  - 起票する Issue のタイトル・付けるラベル
  - 作成する作業ブランチ名
  - 完了後に **PR を作成し、green なら `main` へマージする**（マージ方式・ブランチ削除の有無も明記）

「この内容で実装に進んでよいか？（Issue 起票 → 実装 → PR → main マージまで自動実行します）」と確認する。
修正要望があればステアリングを直して再提示する。
**承認が得られるまで Step 6 以降に進まない。** この承認をもって、Issue 起票・PR 作成・main マージの実行許可とみなす。

---
（以下、承認後に自動実行）

## Step 6: GitHub Issue 起票 と 作業ブランチ作成

### 6-1. Issue を立てる

ステアリングの `requirements.md` / `design.md` を要約して Issue 本文を組み立て、`gh` で起票する。

```bash
gh issue create \
  --title "<開発タイトルを表す簡潔な日本語タイトル>" \
  --body "$(cat <<'EOF'
## 概要
<何を追加・変更するか>

## 背景 / 目的
<なぜ必要か>

## 受け入れ条件
- [ ] <requirements.md の受け入れ条件>

## 影響範囲
<変更するコンポーネント・docs/ の更新有無>

## ステアリング
`.steering/[YYYYMMDD]-[開発タイトル]/`
EOF
)" \
  --label "<enhancement / bug / documentation のいずれか>"
```

- ラベルは `gh label list` に存在するものだけを使う。存在しないラベルは付けない（新規作成もしない）。
- 返ってきた Issue 番号を控える（以降 `#<issue-number>` として使う）。

### 6-2. 作業ブランチを作成する

`main` を最新化してからブランチを切る。**`main` 上で直接実装しない。**

```bash
git switch main && git pull --ff-only
git switch -c "<prefix>/<開発タイトル>"
```

- ブランチ名の prefix は `development-guidelines.md` の Git 規約に従う。規約が無ければ既存の履歴（`git log --oneline --decorate -20`）に倣い、機能追加は `feat/`、修正は `fix/`、ドキュメントは `docs/` を使う。
- ステアリングファイルはこのブランチに含める（先に作成済みのものをそのままブランチへ持ち込む）。

## Step 7: 永続的ドキュメント更新（必要な場合のみ）

Step 2 で影響ありと判定していれば、該当する `docs/` 内のドキュメントを更新する。設計に影響しないなら何もしない。

## Step 8: 実装

`tasklist.md` に従って実装する。`development-guidelines.md` の規約（命名・スタイル・テスト・Git）と `repository-structure.md` の配置ルールを順守する。
各タスク完了ごとに `tasklist.md` のチェックボックスを更新する。

## Step 9: 品質チェック（lint・型・テスト）

dev-docs の原則「コード変更後は必ずリント・型チェックを実施する」に従う。
実際のコマンドは `CLAUDE.md`・`architecture.md`・`package.json`・`pyproject.toml` から判断する。

```bash
# Node/Next.js 構成の例
npm run lint
npx tsc --noEmit
npm test          # or: npx vitest run

# uv 構成の例
uv run ruff check .
uv run ruff format --check .
uv run mypy . || uv run pyright
uv run pytest -q
```

- 新規/変更ロジックに対するテストを追加・更新する（`development-guidelines.md` のテスト規約に従う）。
- 失敗があれば修正し、lint・型・テストが**すべて green** になるまで繰り返す。
- 設定が見つからないコマンドはスキップし、その旨を最終報告に明記する（勝手に新ツールを導入しない）。

## Step 10: 動作検証

テストだけでなく、実際にアプリを動かして期待挙動を確認する。プロジェクト種別に応じて:

- CLI/ライブラリ: エントリポイントやサンプル実行で挙動確認
- API(FastAPI/Next.js Route Handler 等): サーバ起動 → 対象エンドポイントを叩いて応答確認
- フロント/ブラウザ: 起動して該当画面の動作を確認

利用可能なら `/run` スキルの手順に委ねてよい。検証結果（実行コマンドと観測した挙動）を控える。

## Step 11: commit & push

`tasklist.md` を最終状態（全チェック完了 or 残課題明記）に更新してから、まとめてコミットする。

```bash
git status            # 意図しないファイル・機密情報が混ざっていないか必ず目視確認
git add <変更ファイル>  # `git add -A` を使った場合も status で中身を確認する
git commit -m "$(cat <<'EOF'
<type>: <変更内容の簡潔な要約>

<必要なら本文>

Closes #<issue-number>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
git push -u origin "<ブランチ名>"
```

- コミットメッセージ形式は `development-guidelines.md` の Git 規約に従う（規約が無ければ既存履歴に倣い Conventional Commits）。
- `.env` / 鍵 / トークンなど機密ファイルが含まれていないか push 前に必ず確認する。

## Step 12: PR 作成 → main へマージ

```bash
gh pr create \
  --base main \
  --title "<type>: <変更内容の簡潔な要約>" \
  --body "$(cat <<'EOF'
## 概要
<何を変更したか（1〜3行）>

## 変更内容
- <主な変更点>

## テスト / 検証
- lint: <結果>
- 型チェック: <結果>
- テスト: <結果>
- 動作検証: <実行したことと観測した挙動>

Closes #<issue-number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

PR 作成後、**Step 9 の lint・型・テストがすべて green で、Step 10 の動作検証も期待どおりだった場合に限り** マージする。

```bash
gh pr checks --watch   # CI がある場合は完了を待つ
gh pr merge --merge --delete-branch
git switch main && git pull --ff-only
```

- マージ方式はリポジトリ設定に合わせる（`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed` で確認。既存履歴が merge commit なら `--merge`）。
- **マージを止める条件**（該当したら PR は作成したままマージせず、ユーザーに判断を仰ぐ）:
  - lint / 型 / テストのいずれかが失敗している、または実行できなかった
  - CI チェックが失敗 / pending のまま
  - コンフリクトが発生している
  - ブランチ保護やレビュー必須設定でマージがブロックされる
- マージ後、Issue が自動クローズされたか確認する（`Closes #N` が効かなかった場合は `gh issue close <N> --comment "..."` で閉じる）。

## Step 13: 完了報告

次を簡潔に報告する:

- 作成したステアリングディレクトリ
- 起票した Issue（番号・URL）と作成した PR（番号・URL）、マージ結果
- 変更/追加したファイル一覧
- 更新した `docs/`（あれば）
- lint・型・テストの結果、動作検証で確認した挙動
- 残課題・次のステップ

`docs/` を更新した場合は、`/review-docs` でドキュメント整合性を確認することを提案する。

---

## 守ること

- **CLAUDE.md のステアリング規則を最優先**で順守する（命名・ファイル構成が本手順と異なればそちらに従う）。
- ステアリングは `.steering/[YYYYMMDD]-[開発タイトル]/` に作る。既存ディレクトリは上書きせず、新規作業は新規ディレクトリ。
- 承認ゲート（Step 5）より前に、コードを書かない・Issue を立てない・ブランチを切らない。
- **`main` に直接コミットしない。** 必ず作業ブランチを切り、PR 経由で main に入れる。
- commit / push / PR 作成 / マージは、Step 5 の承認を得た本フロー内でのみ行う。品質チェックが green でない状態でマージしない。
- `git push --force` / `git reset --hard` / ブランチ削除など、作業を失う操作は行わない（マージ後の `--delete-branch` を除く）。
- 機密情報（APIキー等）をコード・ドキュメント・Issue・PR 本文に書かない。
- 永続的ドキュメントと作業単位ドキュメントを混同しない。`docs/` の更新は設計に影響する場合のみ。
