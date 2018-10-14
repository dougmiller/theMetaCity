from flask import render_template
from tmc import tmc

@tmc.route('/')
def index():
    return render_template('index.html')

@tmc.route('/blog')
def blog():
    pass

@tmc.route('/workshop')
def workshop():
    pass