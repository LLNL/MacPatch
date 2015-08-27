#!/usr/bin/env python
#
# Copyright (C) 2012 Jay Sigbrandt <jsigbrandt@slb.com>
#                    Martin Owens <doctormo@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
"""
Test crontab usage.
"""

import os
import sys

import unittest
import crontab
try:
    from test import test_support
except ImportError:
    from test import support as test_support

TEST_DIR = os.path.dirname(__file__)

class DummyStdout(object):
    def write(self, text):
        pass

BASIC = '@hourly firstcommand\n\n'
USER = '\n*/4 * * * * user_command # user_comment\n\n\n'
crontab.CRONCMD = "%s %s" % (sys.executable, os.path.join(TEST_DIR, 'data', 'crontest'))

def flush():
    pass

class UseTestCase(unittest.TestCase):
    """Test use documentation in crontab."""
    def setUp(self):
        self.filenames = []

    def test_01_empty(self):
        """Open system crontab"""
        cron = crontab.CronTab()
        self.assertEqual(cron.render(), "")
        self.assertEqual(cron.__unicode__(), "")

    def test_02_user(self):
        """Open a user's crontab"""
        cron = crontab.CronTab(user='basic')
        self.assertEqual(cron.render(), BASIC)

    def test_03_usage(self):
        """Dont modify crontab"""
        cron = crontab.CronTab(tab='')
        sys.stdout = DummyStdout()
        sys.stdout.flush = flush
        try:
            exec(crontab.__doc__)
        except ImportError:
            pass
        sys.stdout = sys.__stdout__
        self.assertEqual(cron.render(), '')

    def test_04_username(self):
        """Username is True"""
        cron = crontab.CronTab(user=True)
        self.assertNotEqual(cron.user, True)
        self.assertEqual(cron.render(), USER)

    def test_05_nouser(self):
        """Username doesn't exist"""
        cron = crontab.CronTab(user='nouser')
        self.assertEqual(cron.render(), '')

    def test_06_touser(self):
        """Write to use API"""
        cron = crontab.CronTab(tab=USER)
        cron.write_to_user('bob')
        filename = os.path.join(TEST_DIR, 'data', 'bob.tab')
        self.filenames.append(filename)
        self.assertTrue(os.path.exists(filename))

    def test_07_ioerror(self):
        """No filename ioerror"""
        with self.assertRaises(IOError):
            cron = crontab.CronTab(user='error')
            cron.read()

    def test_08_cronitem(self):
        """CronItem Standalone"""
        item = crontab.CronItem(line='noline')
        self.assertTrue(item.is_enabled())
        with self.assertRaises(UnboundLocalError):
            item.delete()
        item.command = str('nothing')
        self.assertEqual(item.render(), '* * * * * nothing')

    def tearDown(self):
        for filename in self.filenames:
            if os.path.exists(filename):
                os.unlink(filename)


if __name__ == '__main__':
    test_support.run_unittest(
       UseTestCase,
    )
