#!bin/zsh
if read -q '?Generate new ssh (y/n)? '; then
  echo "Creating an SSH key for you..."
  ssh-keygen -t rsa

  echo "Please add this public key to Github \n"
  echo "https://github.com/account/ssh \n"
  read -p "Press [Enter] key after this..."
fi


if read -q '?Setup GPG key (y/n)? '; then
  brew install gnupg
  # gpg --full-generate-key
  # gpg --list-secret-keys --keyid-format=long

  # read -p "Press [Enter] key after this and put your gpg into github"
  gpg --armor --export EXAMPLE
fi

echo "Installing xcode-stuff"
xcode-select --install

if ! which brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo >>/Users/jackmckew/.zprofile
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>/Users/jackmckew/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Update homebrew recipes
  echo "Updating homebrew..."
  brew update
fi


if ! which git >/dev/null; then
  echo "Installing Git..."
  brew install git

  echo "Git config"

  git config --global user.name "Jack McKew"
  git config --global user.email jackmckew2@gmail.com

  echo "Cleaning up brew"
  brew cleanup
fi

echo "Installing Oh My ZSH..."
curl -L http://install.ohmyz.sh | sh

echo "Setting up Oh My Zsh theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

if ! grep -q "ZSH_THEME=\"powerlevel10k" ~/.zshrc; then
  echo "Updating theme"
  sed -ie "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/" ~/.zshrc
fi

zsh_plugins=(
  git
  zsh-autosuggestions
  zsh-autocomplete
  zsh-syntax-highlighting
)

if ! grep -q "zsh-autocomplete" ~/.zshrc; then
    echo "Installing zsh-autosuggestions"
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ~/.oh-my-zsh/plugins/zsh-autocomplete
    brew install zsh-autosuggestions
    echo "source ~/.oh-my-zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh\n$(cat ~/.zshrc)" > ~/.zshrc
    echo "zstyle ':autocomplete:*' default-context history-incremental-search-backward" >> ~/.zshrc
fi

if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
    echo "Installing zsh-syntax-highlighting"
    brew install zsh-syntax-highlighting
    echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
    echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
fi

if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
  echo "Installing zsh-autocomplete"
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
fi

plugins_str=$(
  IFS=' '
  echo "${zsh_plugins[*]}"
)
echo "Adding plugins to .zshrc.."
echo "plugins=($plugins_str)"
if grep -q "plugins=(" ~/.zshrc; then
  sed -ie "s/plugins=(\(.*\))/plugins=($plugins_str)/" ~/.zshrc
fi

if ! grep -q "nvm" ~/.zshrc; then
  echo "Installing NVM..."
  brew install nvm
  echo "export NVM_DIR=\"$HOME/.nvm\"" >>~/.zshrc
  echo "[ -s \"/opt/homebrew/opt/nvm/nvm.sh\" ] && \. \"/opt/homebrew/opt/nvm/nvm.sh\"" >>~/.zshrc                                       # This loads nvm
  echo "[ -s \"/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm\" ] && \. \"/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm\"" >>~/.zshrc # This loads nvm bash_completion
fi

if ! which conda >/dev/null; then
  echo "Installing miniconda3..."
  mkdir -p ~/miniconda3/
  curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -o ~/miniconda3/miniconda.sh
  sudo bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
  rm -rf ~/miniconda3/miniconda.sh
  ~/miniconda3/bin/conda init zsh
fi

if ! which gh >/dev/null; then
  echo "Installing gh..."
  brew install gh
  gh auth login
fi

# For M1 macs
brew install battery

# For removing .DS_Store from all git
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
echo .DS_Store >>~/.gitignore_global
echo ".DS_Store" >>~/.gitignore_global
echo "._.DS_Store" >>~/.gitignore_global
echo "**/.DS_Store" >>~/.gitignore_global
echo "**/._.DS_Store" >>~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# Fuzzy finding
if ! which fzf >/dev/null; then
  brew install fzf
fi

klogs() {
  pod="$(kubectl get po -o wide --namespace=$1 | tail -n+2 | fzf -n1 --reverse --tac --preview='kubectl logs --tail=20 --all-containers=true {1}' --preview-window=down:50%:hidden --bind=ctrl-p:toggle-preview --header="^P: Preview Logs" | awk '{print $1}')"
  if [[ -n $pod ]]; then
    echo $pod
    # kubectl logs --all-containers=true $pod
  fi
}

kdelete() {
  pod="$(kubectl get po -o wide --namespace=$1 | tail -n+2 | fzf -n1 --reverse --tac --preview='kubectl logs --tail=20 --all-containers=true {1}' --preview-window=down:50%:hidden --bind=ctrl-p:toggle-preview --header="^P: Preview Logs" | awk '{print $1}')"
  if [[ -n $pod ]]; then
    kubectl delete -n $1 pod $pod
  fi
}
alias kdeletejobs="kubectl delete jobs --field-selector status.successful=1 && kubectl delete jobs --field-selector status.successful=0"
