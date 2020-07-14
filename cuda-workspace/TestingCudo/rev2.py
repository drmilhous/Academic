#!/bin/python
import sys
f = open(sys.argv[1],"r")
n = int(sys.argv[2])
i = 0
nl = []
while i < n:
	i+=1
	nl.append(f.readline().rstrip())
nl2 = []
i = n-1
while  i >= 0:
	nl2.append(nl[i]);
	i-=1
for l in nl2:
	print(l[::-1])
