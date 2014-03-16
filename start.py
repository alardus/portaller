from bottle import route, run, template, static_file
import netifaces as ni, os

addr = ni.ifaddresses('eth0')[2][0]['addr']

@route('/static/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='static')

@route('/')
def index():
	check = os.path.isfile('/var/tmp/sniproxy.pid')
	status = ''
	if check == True:
		status = 'Portal is active. Have fun!'
	else:
		status = 'Oops, something goes wrong'

	return template('index', dict(error = None, addr = addr, status = status))


@route('/beta')
def index():
	check = os.path.isfile('/var/tmp/sniproxy.pid')
	status = ''
	if check == True:
		status = 'Portal is active. Have fun!'
	else:
		status = 'Oops, something goes wrong'

	return template('beta', dict(error = None, addr = addr, status = status))


@route('/setup')
def index():
	return template('setup', dict(error = None, addr = addr))

@route('/status')
def index():
	snipid = '/var/tmp/sniproxy.pid'
	check = os.path.isfile(snipid)
	sni = ''
	if check == True:
		with open(snipid, 'r') as file:
			sni = file.readline()
	else:
		sni = 'process is dead'

	la = os.popen("uptime | awk -F'[a-z]:' '{ print $2}'").read()

	# connections = os.popen('netstat -ant | grep 80 | grep EST | sort -u | wc -l').read()

	ip = []
	connections = []
	lst = os.popen("netstat -ant | grep 80 | grep EST | awk '{print $5}'").readlines()
	for i in lst:
		ip.append(i.split(":")[0])

	for i in ip:
		if i not in connections:
			connections.append(i)
		else:
			pass

	connections = len(connections)

	return template('status', dict(error = None, sni = sni, la = la, connections = connections))

run(host=addr, port=8080, reloader=True)