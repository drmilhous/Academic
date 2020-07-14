#!/bin/python
import sys
f = open(sys.argv[1],"r")
n = int(sys.argv[2])
i = 0
l = []
while i < n:
	i+=1
	l.append(f.readline().rstrip())
#print(l)	
nl = []
i = n-1
while  i >= 0:
	nl.append(l[i]);
	i-=1
for l in nl:
	print(l)
