#! /bin/bash

###############################################################
# Authour   : Ben Haubrich                                    #
# File      : reset.bash                                      #
# Synopsis  : Reset the DE2-115 back to the starting address  #
###############################################################

#Reset the DE2-115 processes back to the starting address
nios2-download -r -i 0 -d 1
