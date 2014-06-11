import os, sys

log_file = []
date_search = []
list_of_client = []
list_of_client_filtered = []
uniq_clients = []
search_pattern = raw_input('Search pattern: ')

os.popen('cat ./named.* >> log_file.txt')
with open('log_file.txt', 'r') as f:
	log_file = f.readlines()

print 'Entries in log', len(log_file)

for i in log_file:
	if 'client' in i:
		if search_pattern in i:
			date_search.append(i)
	else:
		pass

print '... for', search_pattern, len(date_search)

for i in date_search:
	i = i.split()
	list_of_client.append(i[5])

for i in list_of_client:
	i = i.split('#')
	list_of_client_filtered.append(i[0])

for i in list_of_client_filtered:
	if i not in uniq_clients:
		uniq_clients.append(i)
	else:
		pass

print '... uniq clnts', len(uniq_clients)
os.remove("log_file.txt")