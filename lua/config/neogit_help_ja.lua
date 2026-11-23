-- Japanese explanations for Neogit popup items.
-- actions[popup name][key or English description] / args["--flag"] / config[name]
-- Each entry: { "何が起きるか", "注意", "相当する git コマンド" } (lines, any count).
local M = {}

M.actions = {
  NeogitPullPopup = {
    p = { "push 先リモート（pushRemote）の同名ブランチから取り込みます。", "相当: git pull <pushRemote> <branch>" },
    u = { "上流ブランチ（upstream）から変更を取り込みます。通常の pull はこれです。",
      "ローカルに未 push のコミットがあるとマージコミットができます（-r で rebase に変更可）。",
      "相当: git pull" },
    e = { "リモートとブランチを選んで、そこから取り込みます。", "相当: git pull <remote> <branch>" },
    C = { "ブランチの upstream / pushRemote / rebase 設定を変更する画面を開きます。" },
  },
  NeogitPushPopup = {
    p = { "現在のブランチを push 先リモート（pushRemote）へ送ります。", "相当: git push <pushRemote> <branch>" },
    u = { "現在のブランチを上流ブランチ（upstream）へ送ります。通常の push はこれです。",
      "未設定なら -u を付けると upstream も同時に設定できます。", "相当: git push" },
    e = { "リモートとブランチを選んで送ります。", "相当: git push <remote> <branch>" },
    o = { "現在以外のローカルブランチを選んで送ります。", "相当: git push <remote> <other>:<remote-branch>" },
    r = { "送り元と送り先を refspec で指定して送ります（上級者向け）。", "相当: git push <remote> <src>:<dst>" },
    m = { "リモートに同名ブランチがあるすべてのブランチを送ります。", "相当: git push <remote> :" },
    T = { "タグを1つ選んで送ります。", "相当: git push <remote> <tag>" },
    t = { "ローカルのタグをすべて送ります。", "相当: git push <remote> --tags" },
    C = { "ブランチの push 関連の設定を変更する画面を開きます。" },
  },
  NeogitCommitPopup = {
    c = { "ステージした変更で新しいコミットを作ります。エディタでメッセージを書きます。", "相当: git commit" },
    e = { "ステージした変更を直前のコミットに追加します。メッセージは変えません。",
      "注意: 履歴を書き換えます。push 済みなら force push が必要になります。",
      "相当: git commit --amend --no-edit" },
    a = { "ステージした変更を直前のコミットに追加し、メッセージも編集します。",
      "注意: 履歴を書き換えます。push 済みなら force push が必要になります。", "相当: git commit --amend" },
    w = { "直前のコミットのメッセージだけを書き直します。変更内容はそのままです。",
      "注意: 履歴を書き換えます。", "相当: git commit --amend --only" },
    f = { "選んだコミットへの修正用コミット（fixup!）を作ります。後で rebase --autosquash でまとめます。",
      "相当: git commit --fixup=<commit>" },
    s = { "選んだコミットに統合する squash! コミットを作ります。統合時にメッセージを編集できます。",
      "相当: git commit --squash=<commit>" },
    A = { "選んだコミットの内容を置き換える amend! コミットを作ります（メッセージも変更）。",
      "相当: git commit --fixup=amend:<commit>" },
    n = { "選んだコミットに内容を足しつつメッセージも直す squash! コミットを作ります。" },
    W = { "選んだコミットのメッセージだけを直す reword コミットを作ります。",
      "相当: git commit --fixup=reword:<commit>" },
    F = { "fixup! コミットを作り、すぐに rebase で対象コミットへ統合します。",
      "注意: 履歴を書き換えます。", "相当: git commit --fixup + git rebase -i --autosquash" },
    S = { "squash! コミットを作り、すぐに rebase で対象コミットへ統合します。", "注意: 履歴を書き換えます。" },
    x = { "ステージした変更を、それぞれ関係する過去のコミットへ自動で振り分けます（git absorb が必要）。" },
    g = { "ステージした変更から、ルールベースでコミットメッセージを生成してエディタを開きます。LLM は使いません。" },
    G = { "ルールベースの件名に加えて、LLM が本文を生成してエディタを開きます。" },
  },
  NeogitStashPopup = {
    z = { "ステージ済み・未ステージの変更をまとめて退避し、作業ツリーをきれいにします。", "相当: git stash push" },
    i = { "ステージ済みの変更だけを退避します。", "相当: git stash push --staged" },
    w = { "未ステージの変更だけを退避します。" },
    x = { "変更を退避しますが、ステージ済みの内容は作業ツリーに残します。", "相当: git stash push --keep-index" },
    P = { "選んだファイルだけを退避します。", "相当: git stash push -- <path>" },
    Z = { "作業ツリーは変えずに、現在の状態のスナップショットだけを stash に記録します。" },
    I = { "ステージ済みの変更のスナップショットを記録します（作業ツリーはそのまま）。" },
    W = { "未ステージの変更のスナップショットを記録します（作業ツリーはそのまま）。" },
    r = { "スナップショットを wip 用の ref に記録します。" },
    p = { "退避した変更を戻し、その stash を一覧から削除します。",
      "注意: 衝突すると stash は残ります。", "相当: git stash pop" },
    a = { "退避した変更を戻します。stash は一覧に残ります。", "相当: git stash apply" },
    d = { "選んだ stash を削除します。", "注意: 取り消しは困難です。", "相当: git stash drop" },
    l = { "stash の一覧を表示します。", "相当: git stash list" },
    v = { "stash の内容（差分）を表示します。", "相当: git stash show -p" },
    b = { "stash を作った時点から新しいブランチを作り、そこへ変更を戻します。", "相当: git stash branch" },
    B = { "現在の位置から新しいブランチを作り、stash を戻します。" },
    m = { "stash のメッセージを変更します。" },
    f = { "stash をパッチファイルとして書き出します。" },
  },
  -- The help popup's keys come from user config, so it is keyed by name.
  NeogitHelpPopup = {
    ["Commit"] = { "コミット操作のポップアップを開きます（新規コミット・amend・fixup など）。" },
    ["Pull"] = { "リモートの変更を取り込むポップアップを開きます（fetch + merge / rebase）。" },
    ["Push"] = { "ローカルのコミットをリモートへ送るポップアップを開きます。" },
    ["Fetch"] = { "リモートの最新情報を取得するだけのポップアップを開きます。作業中のブランチは変わりません。" },
    ["Stash"] = { "作業中の変更を一時退避・復元するポップアップを開きます。" },
    ["Branch"] = { "ブランチの作成・切り替え・削除などのポップアップを開きます。" },
    ["Merge"] = { "他のブランチを現在のブランチへ統合するポップアップを開きます。" },
    ["Rebase"] = { "コミットを別の土台へ付け替える（履歴を書き換える）ポップアップを開きます。",
      "注意: push 済みのコミットに使うと force push が必要になります。" },
    ["Reset"] = { "ブランチの指す位置を戻すポップアップを開きます。",
      "注意: --hard は未コミットの変更を消します。" },
    ["Revert"] = { "過去のコミットを打ち消す新しいコミットを作るポップアップを開きます。履歴は書き換えません。" },
    ["Cherry Pick"] = { "他のブランチのコミットを現在のブランチへコピーするポップアップを開きます。" },
    ["Log"] = { "コミット履歴を表示するポップアップを開きます。" },
    ["Diff"] = { "差分を表示するポップアップを開きます。" },
    ["Tag"] = { "タグの作成・削除のポップアップを開きます。" },
    ["Remote"] = { "リモートの追加・削除・名前変更のポップアップを開きます。" },
    ["Worktree"] = { "複数の作業ディレクトリ（worktree）を管理するポップアップを開きます。" },
    ["Bisect"] = { "二分探索でバグを入れたコミットを探すポップアップを開きます。" },
    ["Ignore"] = { "ファイルを .gitignore などに追加して無視するポップアップを開きます。" },
    ["Margin"] = { "ステータス画面の余白表示（日時・作者など）を切り替えます。" },
    ["Command"] = { "任意の git コマンドを入力して実行します。" },
    ["History"] = { "Neogit が実行した git コマンドの履歴を表示します。" },
    ["Init"] = { "現在のディレクトリを Git リポジトリとして初期化します。", "相当: git init" },
    ["Stage"] = { "カーソル下のファイル／差分の塊をステージします（次のコミットに含める）。", "相当: git add" },
    ["Stage unstaged"] = { "未ステージの変更をすべてステージします（未追跡ファイルは除く）。", "相当: git add -u" },
    ["Stage all"] = { "未追跡ファイルを含むすべての変更をステージします。", "相当: git add -A" },
    ["Unstage"] = { "カーソル下のファイル／塊をステージから外します。変更自体は残ります。", "相当: git restore --staged" },
    ["Unstage all"] = { "ステージした変更をすべて外します。変更自体は残ります。", "相当: git reset" },
    ["Discard"] = { "カーソル下の変更を破棄します。", "注意: 未コミットの変更は元に戻せません。",
      "相当: git restore / 未追跡なら削除" },
    ["Untrack"] = { "ファイルを Git の管理から外します。ファイル自体は残ります。", "相当: git rm --cached" },
    ["Refresh"] = { "ステータス画面を最新の状態に更新します。" },
    ["Go to file"] = { "カーソル下のファイルを開きます。" },
    ["Toggle"] = { "カーソル下の項目の差分を開閉します。" },
  },
}

M.args = {
  ["--ff-only"] = { "早送り（fast-forward）できる場合だけ取り込み、できなければ中止します。マージコミットを作りません。" },
  ["--rebase"] = { "マージの代わりに rebase で取り込みます。ローカルの未 push コミットを取り込んだ変更の後ろに付け直します。",
    "注意: ローカルのコミットの ID が変わります。" },
  ["--autostash"] = { "未コミットの変更を一時退避してから実行し、終わったら戻します。" },
  ["--tags"] = { "タグも一緒に取得／送信します。" },
  ["--force"] = { "リモートの履歴を強制的に上書きします。",
    "注意: 他人が push したコミットも消えます。通常は --force-with-lease を使ってください。" },
  ["--force-with-lease"] = { "自分が最後に見た状態からリモートが変わっていない場合だけ、強制的に上書きします。",
    "amend や rebase の後の push に使います。他人の更新があれば中止されるので --force より安全です。" },
  ["--no-verify"] = { "pre-commit / pre-push などのフックを実行しません。" },
  ["--dry-run"] = { "実際には送らず、何が送られるかだけ表示します。" },
  ["--set-upstream"] = { "送り先を現在のブランチの upstream として設定します。初回 push で使います。" },
  ["--follow-tags"] = { "送るコミットに付いている注釈付きタグも一緒に送ります。" },
  ["--all"] = { "Commit: 変更・削除された追跡ファイルを自動でステージしてからコミットします（未追跡は含まない）。",
    "Stash: 未追跡と無視ファイルも含めて退避します。" },
  ["--allow-empty"] = { "変更がなくてもコミットを作ります。" },
  ["--verbose"] = { "コミットメッセージのエディタに、コミットする差分を表示します。" },
  ["--reset-author"] = { "作者を自分に、作成日時を現在に置き換えます（amend 時など）。" },
  ["--author"] = { "コミットの作者を指定した人に変更します。" },
  ["--signoff"] = { "メッセージの末尾に Signed-off-by 行を追加します。" },
  ["--gpg-sign"] = { "GPG 鍵でコミットに署名します。" },
  ["--reuse-message"] = { "既存のコミットのメッセージをそのまま使います。" },
  ["--include-untracked"] = { "未追跡ファイルも退避します。" },
}

local function title(item)
  if item.cli then
    return string.format("%s  %s (%s)", item.keys, item.description, item.cli)
  end
  return string.format("%s  %s", item.keys, item.description)
end

---@return {title: string, body: string[]}
function M.lookup(item)
  local body
  if item.kind == "action" then
    local popup = M.actions[item.popup] or {}
    body = popup[item.keys] or popup[item.description]
    if item.popup == "NeogitHelpPopup" then
      body = popup[item.description]
    end
  elseif item.cli then
    body = M.args[item.cli]
  end
  return { title = title(item), body = body or { "説明未登録: " .. (item.description or "") } }
end

return M
