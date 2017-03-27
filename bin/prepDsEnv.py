#!/usr/bin/env python
# @author: kaiwang

import getpass
import pexpect
import os
import sys
import logging

################
##    VARS    ##
################

LOG_LEVEL = logging.INFO
LOG_DATE_FMT = "%b %d %H:%M:%S"

DEF_USER = "root"
DEF_FIX_SSH_USER = "admin"
SSH_PORT = 22
TIMEOUT = 10

dsAlias = ""
passwd = ""
ip = ""
user = DEF_USER
port = SSH_PORT
fix_root_ssh = False
fix_root_user = DEF_FIX_SSH_USER

#####################
##    FUNCTIONS    ##
#####################

def Usage():
    script = os.path.basename(sys.argv[0])
    print "Usage: {0} [-f] passwd ip ds_alias [user] [port] [fuser]".format(script)
    print "   -f: work around DSM 6.0 root ssh issue."

def PreCheck():
    global fix_root_ssh

    argc = len(sys.argv)

    if "root" != getpass.getuser():
        print "Must be run as 'root'"
        exit(1)

    if argc < 4:
        Usage()
        exit(1)

    if sys.argv[1] == "-f":
        fix_root_ssh = True;
        sys.argv.pop(1)

def Pause():
    try:
        raw_input("=> Press any key to continue ")
    except KeyboardInterrupt:
        print ""
        exit(0)


def GetArgv():
    global passwd, ip, dsAlias, user, port, fix_root_ssh, fix_root_user

    try:
        passwd = sys.argv[1]
        ip = sys.argv[2]
        dsAlias = sys.argv[3]
        user = sys.argv[4] if len(sys.argv) >= 5 else DEF_USER
        port = sys.argv[5] if len(sys.argv) >= 6 else SSH_PORT
        fix_root_user = sys.argv[6] if (len(sys.argv) >= 7) and (fix_root_ssh == True) else DEF_FIX_SSH_USER
    except:
        Usage()
        exit(1)

    print "fix_root_ssh: '{0}'".format("true" if fix_root_ssh else "false")
    print "ds_alias: '{0}'".format(dsAlias)
    print "passwd: '{0}'".format(passwd)
    print "ip: '{0}'".format(ip)
    print "port: '{0}'".format(port)

    Pause()

def UpdateEtcHosts():
    logging.info("UpdateEtcHosts...")

    global dsAlias, passwd, ip

    # Check existing entry
    cmd = 'egrep "^{0} | {1} # " {2}'.format(ip, dsAlias, "/etc/hosts")
    output = pexpect.run(cmd)

    if output != "":
        print "[warn] Old entry already exists:"
        print "=> /etc/hosts (these entries will be removed): "
        print output
        Pause()

        # Remove existing entry
        cmd = "sed -i '/^{0} .*/d' {1}".format(ip, "/etc/hosts")
        pexpect.run(cmd, logfile = sys.stdout)
        cmd = "sed -i '/.* {0} # .*/d' {1}".format(dsAlias, "/etc/hosts")
        pexpect.run(cmd, logfile = sys.stdout)

    # Add new entry
    cmd = "bash -c \"echo '{0} {1} # (passwd: {2})' >> {3}\"".format(ip, dsAlias, passwd, "/etc/hosts")
    pexpect.run(cmd, logfile = sys.stdout)

def FixRootSSH():
    logging.info("FixRootSSH...")

    global ip, port, fix_root_user

    cmd = "ssh {0}@{1} -p {2}".format(fix_root_user, ip, port)
    rootCmd = "cp /etc/pam.d/sshd /etc/pam.d/sshd.bak; cp /etc/pam.d/login /etc/pam.d/sshd; " + \
              "cp /etc/pam.d/remote /etc/pam.d/remote.bak; cp /etc/pam.d/login /etc/pam.d/remote"
    rootCmdSent = False
    child = pexpect.spawn(cmd, logfile = sys.stdout)

    while True:
        res = child.expect(["continue connecting", "password: ", "Password:",
                            fix_root_user + "@.*\$", "ash-.*#",
                            "Permission denied", "Connection reset by peer",
                            pexpect.TIMEOUT, pexpect.EOF])
        if   res == 0 : child.send("yes\n")
        elif res == 1 : child.send(passwd + "\n")
        elif res == 2 : child.send(passwd + "\n")
        elif res == 3 : child.send("sudo su\n")
        elif res == 4 :
            if False == rootCmdSent:
                child.send(rootCmd + "\n")
                rootCmdSent = True
            else:
                break

        elif res == 5 : print "[wrong password]";    exit(1)
        elif res == 6 : print "[connection reset]";  exit(1)
        elif res == 7 : print "[time out]";          exit(1)
        else : break

    print ""

def SshExpect(child):
    global passwd

    while True:
        res = child.expect(["continue connecting", "[Pp]assword: ",
                            "Permission denied", "Connection reset by peer",
                            pexpect.TIMEOUT, pexpect.EOF])
        if   res == 0 : child.send("yes\n")
        elif res == 1 : child.send(passwd + "\n")
        elif res == 2 : print "[wrong password]";    exit(1)
        elif res == 3 : print "[connection reset]";  exit(1)
        elif res == 4 : print "[time out]";          exit(1)
        else : break


def GenSshKey():
    logging.info("GenSshKey...")

    global passwd, ip, port

    cmd = "ssh-keygen -f '/root/.ssh/known_hosts' -R {0}".format(dsAlias)
    pexpect.run(cmd, logfile = sys.stdout)

    cmd = "ssh-keygen -f '/root/.ssh/known_hosts' -R {0}".format(ip)
    pexpect.run(cmd, logfile = sys.stdout)

    cmd = "/root/script/ssh_without_key.sh root {0} {1}".format(dsAlias, port)
    child = pexpect.spawn(cmd, timeout = TIMEOUT, logfile = sys.stdout)
    # kkk
    SshExpect(child)


def CpDsXScript():
    logging.info("Copy x script to ds & bootstrap...")

    global ip, port

    cmd = "scp -P {0} {1} root@{2}:".format(port, '/root/script/ds.sh', ip)
    child = pexpect.spawn(cmd, logfile = sys.stdout)
    SshExpect(child)

    cmd = "ssh -p {0} root@{1} {2}".format(port, ip, './ds.sh -e')
    child = pexpect.spawn(cmd, logfile = sys.stdout)
    SshExpect(child)


def init_logger(filename=None):
    if filename:
        logging.basicConfig(format='%(asctime)s [%(levelname)s] - %(message)s',
                            datefmt=LOG_DATE_FMT, level=LOG_LEVEL)
    else:
        logging.basicConfig(format='%(asctime)s [%(levelname)s] - %(message)s',
                            datefmt=LOG_DATE_FMT, level=LOG_LEVEL,
                            filename=filename, filemode='w')

################
##    MAIN    ##
################

if __name__ == "__main__":
    init_logger()
    PreCheck()
    GetArgv()

    UpdateEtcHosts()

    if True == fix_root_ssh:
        FixRootSSH()

    GenSshKey()
    CpDsXScript()
