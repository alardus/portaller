#!/bin/bash
netstat -ant | grep 80 | grep EST | sort -u | wc -l

