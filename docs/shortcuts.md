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
       CSV   Tab/Shift-Tab/Enter  セル移動

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
Spc sr  単語置換   / 下に検索   N ←→ n 選択
Spc sR  作業ディレクトリ全体の検索・置換
         Normal Enter  Replace/Syncアクション選択
:noh    検索Highlight
[Git] p  pull   Spc gg  Open LazyGit   G  auto comit msg  
      P  push   Spc gd  git diff       R  pull --rebase   
[VimCmd]    :q  quit    :q!  force
            :w  save    :e   open
