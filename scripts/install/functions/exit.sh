#!/bin/bash

swapoff -a &>/dev/null
umount -R /mnt &>/dev/null

exit ${1:-1}