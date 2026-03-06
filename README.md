# Neovim setup

## 1. Install Neovim
```zsh
brew install nvim
```

## 2. Clone config
1.
```zsh
git clone git@github.com:9mada4/nvim-config.git ~/.config/nvim
```
or
1. unzip nvim-config-main.zip 
```zsh
cd ~/Downloads
mkdir -p ~/.config
mv nvim-config-main ~/.config/nvim
```
2. `ls ~/.config` -> nvim ok

## 3. Open Neovim
nvim

## 4. Set Font

- Nerd Fontをいれる (参考: https://formulae.brew.sh/cask/font-fira-code-nerd-font )
```bash
brew install --cask font-fira-code-nerd-font
```

- Terminal.app で，`設定 > プロファイル > フォント` から `FiraCode Nerd Font Mono` へ変更

|                 設定画面                 |               フォント選択画面               |
| :----------------------------------: | :----------------------------------: |
| ![[Pasted image 20260303200304.png]] | ![[Pasted image 20260303200431.png]] |
