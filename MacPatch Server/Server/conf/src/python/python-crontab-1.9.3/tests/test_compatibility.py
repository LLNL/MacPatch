#!/usr/bin/env python
#
# Copyright (C) 2012 Martin Owens
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
Test crontab interaction.
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

INITAL_TAB = """
# First Comment
*/30 * * * * firstcommand
"""

class CompatTestCase(unittest.TestCase):
    """Test basic functionality of crontab."""
    @classmethod
    def setUpClass(cls):
        crontab.SYSTEMV = True

    @classmethod
    def tearDownClass(cls):
        crontab.SYSTEMV = False

    def setUp(self):
        self.crontab = crontab.CronTab(tab=INITAL_TAB)

    def test_00_enabled(self):
        """Test Compatability Mode"""
        self.assertTrue(crontab.SYSTEMV)

    def test_01_addition(self):
        """New Job Rendering"""
        job = self.crontab.new('addition1')
        job.minute.during(0, 3)
        job.hour.during(21, 23).every(1)
        job.dom.every(1)

        self.assertEqual(job.render(), '0,1,2,3 21,22,23 * * * addition1')

    def test_02_addition(self):
        """New Job Rendering"""
        job = self.crontab.new(command='addition2')

        job.minute.during(4, 9)
        job.hour.during(2, 10).every(2)
        job.dom.every(10)

        self.assertNotEqual(job.render(), '4-9 2-10/2 */3 * * addition2')
        self.assertEqual(job.render(), '4,5,6,7,8,9 2,4,6,8,10 1,11,21,31 * * addition2')


    def test_03_specials(self):
        """Ignore Special Symbols"""
        tab = crontab.CronTab(tabfile=os.path.join(TEST_DIR, 'data', 'specials.tab'))
        self.assertEqual(tab.render(), """0 * * * * hourly
0 0 * * * daily
0 0 * * 0 weekly
""")



if __name__ == '__main__':
    test_support.run_unittest(
       CompatTestCase,
    )
