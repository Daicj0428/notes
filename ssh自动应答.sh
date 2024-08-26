#! /bin/expect
#by daichangjiang

set host "192.168.1.29"
set username "root"
set password "123456"

spawn ssh $username@$host
expect "yes/no" 
        send "yes\r"

expect "password:"
        sleep 5
        send "$password\r"
interact