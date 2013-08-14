#!/bin/bash

awkcommand='?'
platform=`uname`
if [[ "$platform" == 'Linux' ]]; then
  awkcommand='awk'
elif [[ "$platform" == 'Darwin' ]]; then
  awkcommand='gawk'
fi

if [ ! -d ~/logs ]; then
  mkdir ~/logs
fi

if [ ! -f ~/logs/memory_consumption.log ]; then
  ps aux | head -n 1 | $awkcommand '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' > ~/logs/memory_consumption.log
fi

ps aux | grep ruby | grep -v grep | $awkcommand '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> ~/logs/memory_consumption.log