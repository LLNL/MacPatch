#!/usr/bin/env python
#
# Copyright (C) 2008 Martin Owens
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

from setuptools import setup
from crontab import __version__, __pkgname__
import os

# remove MANIFEST. distutils doesn't properly update it when the
# contents of directories change.
if os.path.exists('MANIFEST'): os.remove('MANIFEST')

# Grab description for Pypi
with open('README') as fhl:
    description = fhl.read()

setup(
    name             = __pkgname__,
    version          = __version__,
    description      = 'Python Crontab API',
    long_description = description,
    author           = 'Martin Owens',
    url              = 'https://launchpad.net/python-crontab',
    author_email     = 'doctormo@gmail.com',
    test_suite       = 'tests',
    platforms        = 'linux',
    license          = 'GPLv3',
    py_modules       = [ 'crontab', 'cronlog' ],
    provides         = [ 'crontab', 'cronlog' ],
    install_requires = [ 'python-dateutil' ],
    extras_require   = { 'cron-schedule': ['croniter'] },
    classifiers      = [
      'Development Status :: 5 - Production/Stable',
      'Development Status :: 6 - Mature',
      'Intended Audience :: Developers',
      'Intended Audience :: Information Technology',
      'Intended Audience :: System Administrators',
      'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
      'Operating System :: POSIX',
      'Operating System :: POSIX :: Linux',
      'Operating System :: POSIX :: SunOS/Solaris',
      'Programming Language :: Python',
      'Programming Language :: Python :: 2.6',
      'Programming Language :: Python :: 2.7',
      'Programming Language :: Python :: 3.3',
    ]
 )

