from flask import render_template, jsonify, request
import json
import base64
import re
import collections
import uuid

from datetime import datetime

from . import reports
from .. import login_manager
from .. model import *
from .. import db

@reports.route('/new')
def new():

    return render_template('patch_groups.html', data={}, columns={})
