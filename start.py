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

run(host=addr, port=8080, reloader=True)
