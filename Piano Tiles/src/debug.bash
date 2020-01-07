#! /bin/bash

###########################################################################
# Authour   : Ben Haubrich                                                #
# File      : debug.bash                                                  #
# Synopsis  : Start the gdb server, so you can run nio2-elf-gdb and target#
#             remote localhost:44000                                      #
###########################################################################


nios2-gdb-server --tcpport 44000 -d 1 -i 0
#gnome-terminal -e nios2-terminal -d 1 -i 0

#sometimes it might not be able to bind, so kill the gdb server
#if [ $? -ne 0 ]; then
#  pkill -9 -f nios2-gdb-server
#  nios2-gdb-server --tcpport 44000 --tcppersist -d 1 -i 0
#fi
