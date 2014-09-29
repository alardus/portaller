import bottle, os
from bottle import template, static_file

app = application = bottle.Bottle()

@app.route('/static/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='static')

@app.route('/')
def index():
	return template('index', dict(error = None))


@app.route('/beta')
def index():
	return template('beta', dict(error = None))


@app.route('/setup')
def index():
	return template('setup', dict(error = None))

@app.route('/status')
def index():
	snipid = '/var/tmp/sniproxy.pid'
	check = os.path.isfile(snipid)
	sni = ''
	if check == True:
		with open(snipid, 'r') as file:
			sni = file.readline()
	else:
		sni = 'proxy dead'

	la = os.popen("uptime | awk -F'[a-z]:' '{ print $2}'").read()

	connections = os.popen("netstat -atW | grep EST | awk {'print $5'} | cut -d : -f 1 | sort | uniq | grep -v pandora | grep -v spotify | grep -v amazon | grep -v netflix | grep -v rdio | grep -v portaller | wc -l").read().rstrip()

	return template('status', dict(error = None, sni = sni, la = la, connections = connections))
