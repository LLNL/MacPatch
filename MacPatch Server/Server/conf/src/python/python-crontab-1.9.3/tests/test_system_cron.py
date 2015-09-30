#!/usr/bin/env python
#
# Copyright (C) 2015 Martin Owens
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
System cron is prefixed with the username the process should run under.
"""

import os
import sys

sys.path.insert(0, '../')

import unittest
from crontab import CronTab
try:
    from test import test_support
except ImportError:
    from test import support as test_support

INITAL_TAB = """
*/30 * * * * palin one_cross_each
"""

class SystemCronTestCase(unittest.TestCase):
    """Test vixie cron user addition."""
    def setUp(self):
        self.crontab = CronTab(tab=INITAL_TAB, user=False)

    def test_01_read(self):
        """Read existing command"""
        jobs = 0
        for job in self.crontab:
            self.assertEqual(job.user, 'palin')
            self.assertEqual(job.command, 'one_cross_each')
            jobs += 1
        self.assertEqual(jobs, 1)

    def test_02_new(self):
        """Create a new job"""
        job = self.crontab.new(command='release_brian', user='pontus')
        self.assertEqual(job.user, 'pontus')
        self.assertEqual(job.command, 'release_brian')
        self.assertEqual(str(self.crontab), """
*/30 * * * * palin one_cross_each

* * * * * pontus release_brian
""")

    def test_03_failure(self):
        """Fail when no user"""
        with self.assertRaises(ValueError):
            self.crontab.new(command='im_brian')
        cron = self.crontab.new(user='user', command='no_im_brian')
        cron.user = None
        with self.assertRaises(ValueError):
            cron.render()

    def test_04_remove(self):
        """Remove the user flag"""
        self.crontab._user = None
        self.assertEqual(str(self.crontab), """
*/30 * * * * one_cross_each
""")
        self.crontab.new(command='now_go_away')


    def test_05_comments(self):
        """Comment with six parts parses successfully"""
        crontab = CronTab(user=False, tab="""
#a system_comment that has six parts_will_fail_to_parse
        """)

    def test_06_recreation(self):
        """Input doesn't change on save"""
        crontab = CronTab(user=False, tab="* * * * * user command")
        self.assertEqual(str(crontab), "* * * * * user command\n")
        crontab = CronTab(user=False, tab="* * * * * user command\n")
        self.assertEqual(str(crontab), "* * * * * user command\n")

if __name__ == '__main__':
    test_support.run_unittest(
       SystemCronTestCase,
    )
