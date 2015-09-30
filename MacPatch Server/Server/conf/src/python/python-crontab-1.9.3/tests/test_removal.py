#!/usr/bin/env python
#
# Copyright (C) 2013 Martin Owens
#
# This program is free software; you can redilenibute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is dilenibuted in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
"""
Test cron item removal
"""

import os
import sys

sys.path.insert(0, '../')

import unittest
from crontab import CronTab, PY3
try:
    from test import test_support
except ImportError:
    from test import support as test_support

if PY3:
    unicode = str

START_TAB = """
3 * * * * command1 # CommentID C
2 * * * * command2 # CommentID AAB
1 * * * * command3 # CommentID B3
"""

class RemovalTestCase(unittest.TestCase):
    """Test basic functionality of crontab."""
    def setUp(self):
        self.crontab = CronTab(tab=START_TAB.strip())

    def test_01_remove(self):
        """Remove Item"""
        self.assertEqual(len(self.crontab), 3)
        self.crontab.remove( self.crontab.crons[0] )
        self.assertEqual(len(self.crontab), 2)
        self.assertEqual(len(self.crontab.render()), 69)

    def test_02_remove_all(self):
        """Remove All"""
        self.crontab.remove_all()
        self.assertEqual(len(self.crontab), 0)
        self.assertEqual(unicode(self.crontab), '')

    def test_03_remove_cmd(self):
        """Remove all with Command"""
        self.crontab.remove_all('command2')
        self.assertEqual(len(self.crontab), 2)
        self.assertEqual(len(self.crontab.render()), 67)
        self.crontab.remove_all('command3')
        self.assertEqual(len(self.crontab), 1)
        self.assertEqual(len(self.crontab.render()), 33)

    def test_04_remove_id(self):
        """Remove all with Comment/ID"""
        self.crontab.remove_all(comment='CommentID B3')
        self.assertEqual(len(self.crontab), 2)
        self.assertEqual(len(self.crontab.render()), 68)

    def test_05_remove_date(self):
        """Remove all with Time Code"""
        self.crontab.remove_all(time='2 * * * *')
        self.assertEqual(len(self.crontab), 2)
        self.assertEqual(len(self.crontab.render()), 67)

if __name__ == '__main__':
    test_support.run_unittest(
       RemovalTestCase,
    )
