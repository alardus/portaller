import os

lst = []
uniq = []

os.popen("cat named.* > log.txt")
os.popen("cat log.txt | awk '{print $6}' > clients.txt")

with open('clients.txt', 'r') as f:
	f = f.readlines()
	for i in f:
		i = i.split('#')
		lst.append(i[0])

for i in lst:
	if i not in uniq:
		uniq.append(i)
	else:
		pass

print len(uniq)
os.remove("clients.txt")
os.remove("log.txt")