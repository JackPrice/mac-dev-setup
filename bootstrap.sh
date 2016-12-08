#! /usr/bin/env bash

#
# This file bootstraps and initialises the setup process.
#

function info()
{
	tput setaf 7
    tput bold

    echo "$@"

    tput sgr0
}

function debug()
{
    tput setaf 7
    tput dim

    echo "$@"

    tput sgr0
}

function success()
{
    tput setaf 2

    echo "$@"

    tput sgr0
}

function error()
{
    tput setaf 1

    echo "$@"

    tput sgr0
}

function check_git()
{
	info "=> Checking git..."

	which git &>/dev/null

	if [ $? -eq 0 ]; then
		debug "===> Found $(git --version)"
	else
		debug "===> No git found, installing"

		sudo xcode-select --install
	fi
}

function check_ansible()
{
	info "=> Checking ansible..."

	which ansible &>/dev/null

	if [ $? -eq 0 ]; then
		debug "===> Found $(ansible --version | head -n 1)"
	else
		debug "===> No ansible found, installing"

		sudo pip install ansible
	fi
}

echo
echo "==============================================================================="
echo "=                                                                             ="
echo "= This installer will bootstrap the dev environment setup.                    ="
echo "=                                                                             ="
echo "==============================================================================="
echo

check_git
check_ansible

info "=> Running ansible..."

ansible-pull -U https://github.com/JackPrice/mac-dev-setup.git -d $(mktemp -d)
