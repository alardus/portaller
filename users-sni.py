#!/bin/python
count = 0
data = [] 
proc = []

with open('sniproxy.log', 'r') as fl:
	fl = fl.readlines()

	for i in fl:
		if 'portaller.com' not in i:
			if '107.170.15.247' in i:
				i = i.split()
				i = i[2].split(':')
				data.append(i[0])
			else:
				pass

for i in data:
	if i not in proc:
		proc.append(i)
		count = count + 1

print count