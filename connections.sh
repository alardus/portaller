#!/bin/bash
/bin/netstat -atW | grep EST | awk {'print $5'} | cut -d : -f 1 | sort | uniq | grep -v pandora | grep -v spotify | grep -v amazon | grep -v netflix | grep -v rdio | grep -v portaller | wc -l > ./connections.txt
