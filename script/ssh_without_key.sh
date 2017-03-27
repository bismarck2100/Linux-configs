#!/bin/bash
# @author: kaiwang

if [ -z "$1" ] || [ "$1" == "-h" ]; then
	printf "Usage: $0 remote_user remote_host [port]\n"
	exit 0
fi

r_usr=${1:?"-h for usage"}
r_host=${2:?"-h for usage"}
r_port=${3:-"22"}

pub_key=~/.ssh/id_rsa.pub
pri_key=~/.ssh/id_rsa

# generate key-pairs if not present
if ! [ -f $pub_key -a -f $pri_key ]; then
    printf "\n[hint] Overwrite (y/n)? => n\n\n"
    ssh-keygen -t rsa
fi

# copy pub_key to remote server
printf "mkdir ~/.ssh on remote...\n"
ssh -p $r_port $r_usr@$r_host mkdir -p .ssh
printf "copy id_rsa.pub to remote...\n"
cat ~/.ssh/id_rsa.pub | ssh -p $r_port $r_usr@$r_host 'cat >> .ssh/authorized_keys'

