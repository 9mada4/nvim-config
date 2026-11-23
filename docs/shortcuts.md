[Help]   Spc + ?  ヒント表示（j/kでスクロール、qで閉じる）
[Move]    h j k l     Ctrl + w : move window
          ← ↓ ↑ →
     gg       next   ↱w  → w → w     画面表示
     ↑               ■jump word■    top    zt
 0 ← ■ → $   before   b ←  b ← ↲   center  zz
     ↓         end   ↳ → e  →  e   bottom  zb
     G                                       
[Mode]   Esc   ==   Ctrl + [   ==   jj (Insertのみ)
   Insert             Visual
 i  a  o  O        v   V    Ctrl+v
 左 右 下 上           行    矩形
[Edit]  Spc + mp  写真ペースト       u    undo
            + mi  環境で開く      Ctrl+r  redo
            + mb  ブラウザで開く    v選択→gc  ｺﾒﾝﾄ
            + mv  md外部プレビュー
            + mf  TeX PDFを開く
            + mc  TeX途中生成物を削除
       macOS Insert: ⌘Z undo / ⌘⇧Z redo（Insertを継続）
       macOS ⌘V: ターミナル標準の貼り付け
       ※ ⌘Z/⌘⇧Zはターミナル側からNeovimへキーを送信する設定が必要
       CSV   Spc + cv  表表示ON/OFF（初期はOFF）
             Tab/Shift-Tab/Enter  セル移動（表表示ON時）

[Codex] Spc + cc  Codex開閉
            + cf  Codexへ移動
            + ci  画像パス送信
       v選択 + cs  選択範囲送信
       Ctrl-J      入力欄で改行
       /model      モデル変更
       /vim        Vimモード切替
       /exit       Codex終了

       Vmode 行全体 単語 Cursorから終わりまで   
 Copy   vy     yy   vwy    Y       
 編集   vc     cc   vwc    C       
 カット vd     dd   vwd    D       
[Search]           ? 上に検索   * カーソル単語検索
Spc sr  現在のバッファをポップアップで置換（検索語→Tab→置換語→Enter）
        プレビュー: j/k 選択  y/Enter 1件置換  n スキップ  a 残り全部置換
                    l 1件置換して終了  u 直前の置換を戻す  q 閉じる
                    s 次の検索・置換を開始  e/E 既存の入力を編集
        閉じた後は通常モードの u でも直前の置換操作を戻せる
        / 下に検索   N ←→ n 選択
Spc sR  作業ディレクトリ全体の検索・置換
         Normal Enter  全アクション選択（下分割）
Spc h   検索Highlight ON/OFF   :noh 一時解除
[Git] Spc gg  Open Neogit   Spc gd  git diff
      Status: Tab Diff | s Stage | u Unstage | c Commit | x Discard
              p Pull  | P Push  | Z Stash   | ? Help   | q Close
      c → c  通常のコミット編集
      c → g  Generate (Rule): ルールのみ（LLMなし）
      c → G  Generate (Rule + LLM): 件名はルール、本文にLLM補足
      p → -r → p/u  Pull --rebase（Pullメニューで-rをON、取得元を選択）
      生成はステージ済みの変更のみ。先にsでステージする。
      生成操作はCommit Popupのフラグを使わない（-aも適用しない）。
      LLM生成は非同期。完了後に編集画面が開き、失敗時はルール文を保持する。
      編集して :wq / Ctrl-c Ctrl-c で確定、Ctrl-c Ctrl-k で中止。
      Spc gm  生成済みLLM補足文をプレビュー（c → Gの編集画面、再生成なし）
              本文に挿入済み。Enter/q/Escでプレビューを閉じる。
      上部2行は設定済みキーを使う仮想行。狭いウィンドウでは右端が省略される。
      Statusの独自R/Gは廃止。標準キーは維持（RはNeogit標準のRename）。
[VimCmd]    :q  quit    :q!  force
            :w  save    :e   open
