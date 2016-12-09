#! /usr/bin/env bash

#
# This file bootstraps boxan and is intended to be 
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

function warn()
{
    tput setaf 3

    echo "$@"

    tput sgr0
}

function error()
{
    tput setaf 1

    echo "$@"

    tput sgr0
}

###############################################################################
#
# 1) Start logging
#
###############################################################################

LOG=$(mktemp)

echo
info "=> Starting bootstrap" | tee -a "${LOG}"
debug "===> Logs being outputted to ${LOG}"
debug "===> Run tail -f ${LOG} to stream"

###############################################################################
#
# 2) Gathering configuration
#
###############################################################################

echo
info "=> Gathering configuration"

USERNAME=$(id -u -nr)
OSX_VERSION=$(sw_vers | grep ProductVersion | awk '{print $2}')
BOXAN_PATH=/opt/boxan
BOXAN_REPOSITORY="https://github.com/JackPrice/mac-dev-setup.git"

debug "===> Username: ${USERNAME}"
debug "===> OSX version: ${OSX_VERSION}"
debug "===> Boxan path: ${BOXAN_PATH}"
debug "===> Boxan repository: ${BOXAN_REPOSITORY}"

###############################################################################
#
# 3) Obtain sudo 
#
###############################################################################

echo
info "=> Obtaining sudo permissions..."

sudo -p "===> Enter your password:" -v

if [ $? -ne 0 ]; then
    error  "===> Failed"

    exit 1
fi

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
#
# 4) Check for git
#
###############################################################################

echo
info "=> Checking for git..." | tee -a "${LOG}"

if test ! $(which git); then
    warn "===> git not found" | tee -a "${LOG}"
    debug "===> Installing git" | tee -a "${LOG}"

    sudo xcode-select --install 2>&1 | tee -a "${LOG}"

    if [ $? -ne 0 ]; then
        error "=====> xcode-select --install failed" | tee -a "${LOG}"
        debug "=====> See log for details"

        exit 1
    fi
fi

debug "===> Found $(git --version)" | tee -a "${LOG}"

###############################################################################
#
# 5) Check for python
#
###############################################################################

echo
info "=> Checking for python..." | tee -a "${LOG}"

if test ! $(which python); then
    error "===> python not found" | tee -a "${LOG}"

    exit 1
fi

debug "===> Found $(python --version 2>&1)" | tee -a "${LOG}"

###############################################################################
#
# 6) Check for ruby
#
###############################################################################

echo
info "=> Checking for ruby..." | tee -a "${LOG}"

if test ! $(which ruby); then
    error "===> ruby not found" | tee -a "${LOG}"

    exit 1
fi

debug "===> Found $(ruby --version 2>&1)" | tee -a "${LOG}"

###############################################################################
#
# 7) Check for ansible
#
###############################################################################

echo
info "=> Checking for ansible..." | tee -a "${LOG}"

if test ! $(which ansible); then
    warn "===> ansible not found" | tee -a "${LOG}"
    debug "===> Installing ansible" | tee -a "${LOG}"

    sudo pip install ansible | tee -a "${LOG}"

    if [ $? -ne 0 ]; then
        error "=====> ansible install failed" | tee -a "${LOG}"
        debug "=====> See log for details"

        exit 1
    fi
fi

debug "===> Found $(ansible --version | head -n1)" | tee -a "${LOG}"

###############################################################################
#
# 8) Clone repository
#
###############################################################################

echo
info "=> Downloading boxan" | tee -a "${LOG}"

sudo git clone "${BOXAN_REPOSITORY}" "${BOXAN_PATH}" 2>&1 >> ${LOG}

if [ $? -ne 0 ]; then
    error "===> git clone failed" | tee -a "${LOG}"
    debug "===> See log for details"

    exit 1
fi

###############################################################################
#
# 9) Write configuration
#
###############################################################################

echo
info "=> Writing configuration" | tee -a "${LOG}"

TEMPORARY_CONFIG=$(mktemp)

debug "===> Writing temporary configuration to ${TEMPORARY_CONFIG}" | tee -a "${LOG}"

cat > $TEMPORARY_CONFIG <<EOF

---

boxan_user: "${USERNAME}"

EOF

if [ $? -ne 0 ]; then
    error "=====> Failed" | tee -a "${LOG}"

    exit 1
fi

debug "===> Copying configuration" | tee -a "${LOG}"

sudo cp "${TEMPORARY_CONFIG}" "${BOXAN_PATH}/config.yml" >> ${LOG} 2>&1

if [ $? -ne 0 ]; then
    error "=====> Failed" | tee -a "${LOG}"

    exit 1
fi

###############################################################################
#
# 10) Run ansible
#
###############################################################################

echo
info "=> Running ansible" | tee -a "${LOG}"

cd ${BOXAN_PATH} && sudo ansible-playbook "local.yml" >> ${LOG} 2>&1

if [ $? -ne 0 ]; then
    error "===> Failed" | tee -a "${LOG}"
    debug "===> See log for details"

    exit 1
fi

success "===> Done"

