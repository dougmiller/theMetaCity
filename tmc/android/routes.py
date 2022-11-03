from flask import render_template
from tmc import cache
from tmc.android import android


@android.route('/')
@cache.cached()
def index():
    return render_template('index.html')


@android.route('/privacy_policy/')
@cache.cached()
def privacy_policy():
    return render_template('privacy_policy.html')
