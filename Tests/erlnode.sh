#!/bin/bash

erl -sname erlnode -setcookie secretcookie -s server1 start
