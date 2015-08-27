#
# Copyright 2013, Martin Owens <doctormo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import os
import re
import sys
import string
import codecs
import platform

py3 = platform.python_version()[0] == '3'
if py3:
    unicode = str

from dateutil import parser as dateparse

MATCHER = r'(?P<date>\w+ +\d+ +\d\d:\d\d:\d\d) (?P<host>\w+) ' + \
        r'CRON\[(?P<pid>\d+)\]: \((?P<user>\w+)\) CMD \((?P<cmd>.*)\)'

def size(filename):
    return os.stat(filename)[6]

class LogReader(object):
    """Opens a Log file, reading backwards and watching for changes"""
    def __init__(self, filename, mass=4096):
        self.filename = filename
        self.pipe     = codecs.open(filename, 'r', encoding='utf-8')
        self.mass     = mass
        self.size     = -1
        self.read     = -1

    def readlines(self, until=0):
        """Iterator for reading lines from a file backwards"""
        if not self.pipe or self.pipe.closed:
            raise IOError("Can't readline, no opened file.")
        # Always seek to the end of the file, this accounts for file updates
        # that happen during our running process.
        self.size = size(self.filename)
        block_num = 0
        location  = self.size
        halfline  = ''

        while location > until:
            location -= self.mass
            mass = self.mass
            if location < 0:
                mass = self.mass + location
                location = 0
            self.pipe.seek(location)
            line = self.pipe.read(mass) + halfline
            data = line.split('\n')
            if location != 0:
                halfline = data.pop(0)
            loc = location + mass
            data.reverse()
            for line in data:
                if line.strip() == '':
                    continue
                yield (loc, line)
                loc -= len(line)

    def __iter__(self):
        for (offset, line) in self.readlines():
            yield line


class CronLog(LogReader):
    def __init__(self, filename='/var/log/syslog', user=None):
        LogReader.__init__(self, filename)
        self.user = user

    def for_program(self, command):
        return ProgramLog(self, command)

    def __iter__(self):
        for (offset, line) in self.readlines():
            c = re.match(MATCHER, unicode(line))
            datum = c and c.groupdict()
            if datum and (not self.user or datum['user'] == self.user):
                datum['date'] = dateparse.parse(datum['date'])
                yield datum


class ProgramLog(object):
    """Specific log control for a single command/program"""
    def __init__(self, log, command):
        self.log = log
        self.command = command

    def __iter__(self):
        for entry in self.log:
            if entry['cmd'] == unicode(self.command):
                yield entry

