#!/bin/bash

#kaiqi_server
 rht-vmctl start  servera
 rht-vmctl start  serverg
 sleep 6
 
#ssh_servera-g
 ssh root@172.25.8.10
 echo"uplooking"
