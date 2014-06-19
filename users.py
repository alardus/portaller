#!/usr/bin/env python
import os, sys, threading, Queue

# define variables
log_file = []
date_search = []
uniq_clients = []
query_counter = []
list_of_client = []
position_in_queue = 1
queue = Queue.Queue()
list_of_client_filtered = []
search_pattern = raw_input('Search pattern: ')


# phase 1, count how many uniq. users we had 
#os.popen('cat ./named.* > log_file.txt')
with open('log_file_small.txt', 'r') as f:
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


# phase 2, count uniq users with more then X queries
phase2 = raw_input('Calculate users with more then X queries?')

class ThreadUrl(threading.Thread):
  def __init__(self, queue):
    threading.Thread.__init__(self)
    self.queue = queue

  def run(self):
    while True:
      #grabs data from queue
      host = self.queue.get()

      # set queries counter to zero
      count = 0

      # looking for queries for IP
      global position_in_queue
      print position_in_queue, '/', len(uniq_clients)
      for i in date_search:
      	if 'client' in i:
          if host in i:
            count = count + 1
      	else:
      		pass

      # if found more then X queries, do something
      if count > 5:
      	global query_counter
      	query_counter.append(host)

      position_in_queue = position_in_queue + 1

      #signals to queue job is done
      self.queue.task_done()

def main():
  #spawn a pool of threads, and pass them queue instance 
  for i in range(1):
    t = ThreadUrl(queue)
    t.setDaemon(True)
    t.start()

  #populate queue with data   
  for host in uniq_clients:
    queue.put(host)

  #wait on the queue until everything has been processed     
  queue.join()

if phase2 == 'yes' or phase2 == 'y':
  main()
  print len(query_counter)

else:
  print 'Finished.'