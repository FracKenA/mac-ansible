#!/usr/bin/env bash

# Default directory and repo name
working_path="./"
working_directory="mac-ansible"
repo_name="mac-ansible"
git_user="FracKenA"

show_help() {
  cat << EOF
NAME
    setup-script - A bash script for setting up Mac using ansible.

SYNOPSIS
    setup-script [-d directory] [--directory directory] [-r repo_name] [--repo repo_name] [-u git_user] [--user git_user] [-p working_path] [--path working_path]

DESCRIPTION
    setup-script is a bash script that clones a git repository and runs ansible to set up a Mac. 
    It checks and installs the necessary dependencies and tools before proceeding.

OPTIONS
    -d, --directory directory
        The directory of the script to be used in the path. Default is 'mac-ansible'.

    -r, --repo repo_name
        The repository name to clone. Default is 'mac-ansible'.

    -u, --user git_user
        The Git user name whose repository is to be cloned. No default value.

    -p, --path working_path
        The path to execute the script in. Default is './' (current directory).
EOF
  exit 1
}

# Parse command-line flags
for arg in "$@"
do
  case $arg in
    -d=*|--working-directory=*)
      working_directory="${arg#*=}"
      ;;
    -p=*|--working-path=*)
      working_path="${arg#*=}"
      ;;
    -r=*|--repo=*)
      repo_name="${arg#*=}"
      ;;
    -u=*|--user=*)
      git_user="${arg#*=}"
      ;;
    -h|--help)
      show_help
      ;;
  esac
done

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &> /dev/null; then
    echo "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    echo "Waiting for Xcode Command Line Tools to finish installing..."
    until xcode-select --print-path &> /dev/null; do
        echo "Pausing to wait for xcode command line tools to finish installing."
        sleep 5;
    done
else
    echo "Xcode Command Line Tools are already installed"
fi

# Check if python3 and pip3 are installed
command -v python3 >/dev/null 2>&1 || { echo "Python 3 not found. Please install it."; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "pip3 not found. Please install it."; exit 1; }

# Detect Python version
PyVer=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if [[ ! "$PyVer" =~ "3." ]]; then
  echo "Python 3 is required."
  exit 1
fi

# Update PATH
export PATH="$HOME/Library/Python/$PyVer/bin:/opt/homebrew/bin:$PATH"

# Upgrade pip and install packages
pip3 install --upgrade pip && \
pip3 install requests && \
pip3 install ansible || { echo "Installation failed. Please check your internet connection or package name"; exit 1; }

# Check if git is installed
command -v git >/dev/null 2>&1 || { echo "git not found. Please install it."; exit 1; }

# Clone repository if it doesn't exist
if [ ! -d "${working_path}/${working_directory}" ]; then
    git clone https://github.com/${git_user}/${repo_name}.git ${working_path}/${working_directory} || { echo "Could not clone the repository. Please check your internet connection or repo URL"; exit 1; }
else
    echo "${working_path}/${working_directory} directory already exists. Updating instead..."
    git -C ${working_path}/${working_directory} pull || { echo "Could not update the repository. Please check your internet connection or repo URL"; exit 1; }
fi

# Check if requirements.yml exists before running ansible-galaxy
if [ -f "${working_path}/${working_directory}/requirements.yml" ]; then
    ansible-galaxy install -r "${working_path}/${working_directory}/requirements.yml" || { echo "ansible-galaxy command failed. Please check your ansible configuration"; exit 1; }
else
    echo "${working_path}/${working_directory}/requirements.yml not found. Skipping..."
fi

# Run playbook
if [ -f "${working_path}/${working_directory}/main.yml" ]; then
    ansible-playbook "${working_path}/${working_directory}/main.yml" --ask-become-pass -i "${working_path}/${working_directory}/inventory" || { echo "ansible-playbook command failed. Please check your ansible configuration"; exit 1; }
else
    echo "${working_path}/${working_directory}/main.yml not found. Skipping..."
fi
