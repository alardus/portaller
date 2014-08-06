#!/bin/python
count = 0
data = [] 
proc = []

with open('sniproxy.log', 'r') as fl:
	fl = fl.readlines()

	for i in fl:
		if 'portaller.com' not in i:
			#print i
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