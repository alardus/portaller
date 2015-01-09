import bottle, os, urllib2
from bottle import template, static_file

app = application = bottle.Bottle()
copyright = '2015'

@app.route('/static/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='static')

@app.route('/')
def index():
	return template('index', dict(error = None, year = copyright))


@app.route('/beta')
def index():
	return template('beta', dict(error = None, year = copyright))


@app.route('/setup')
def index():
	return template('setup', dict(error = None, year = copyright))

@app.route('/status')
def index():
	try:
		data = urllib2.urlopen('http://portaller.com/connections.txt').readlines()
		try:
			if data[2].strip() != '': 									#loading SNI
				status, text = ('is-visible', 'Open')
			else:
				status, text = ('is-hidden', 'Closed')
		except:
			status, text = ('is-hidden', 'Closed')		
		
		try:
			if data[1].strip() != '': la = data[1].strip() 				#loading LA
			else: ls = 'not available'
		except: ls = 'not available'
	
		try:
			if data[0].strip() != '': connections = data[0].strip()		#loading connections 
			else: connections = 'not available'
		except: connections = 'not available'
	
	except: 
		status, text = ('is-hidden', 'Closed')
		la = connections = 'not available'
	
	return template('status', dict(error = None, year = copyright, la = la, connections = connections, status = status, text = text))
