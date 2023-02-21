

xcode-select --install

PyVer="3.9"

PATH="$HOME/Library/Python/$PyVer/bin:/opt/homebrew/bin:$PATH"

pip3 install --upgrade pip

pip3 install requests

pip3 install ansible

ansible-galaxy install -r requirements.yml

git clone https://github.com/FracKenA/mac-ansible.git

ansible-playbook ./mac-ansible/main.yml --ask-become-pass -i ./mac-ansible/inventory