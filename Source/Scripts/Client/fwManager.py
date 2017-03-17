#!/usr/bin/env python

'''
 Copyright (c) 2017, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.
 
 This file is part of MacPatch, a program for installing and patching
 software.
 
 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.
 
 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.
 
 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
'''

'''
    Script: fwManager
    Version: 1.0.0

    Usage:

    Actions	(verify,set,update,remove)

    	verify 					Verify Firmware Password
    		Args:
    			--password 		Password to verify 

	    set 					Set Firmware Password
	    	Args:
    			--password 		Password to set firmware password

	    update 					Update Firmware Password
	    	Args:
    			--old-password 		Current firmware password
    			--new-password 		New firmware password

	    remove      			Remove Firmware Password
	    	Args:
    			--password 		Password to remove firmware password

'''


import os
import pexpect
import subprocess
import argparse

class fwPassword():

	def __init__(self,fwTool):
		self.fwTool = fwTool

		if not os.path.exists(self.fwTool):
			print ("firmwarepasswd tool not found.")
			exit(1)
	    

	def hasPassword(self):
		has_pass_set = subprocess.check_output([self.fwTool, "-check"])
		if 'No' in has_pass_set:
			# No firmware password set.
			return False
		elif 'Yes' in has_pass_set:	
			# Yes firmware password set.
			return True
		else:
			print "Error with checking for password."
			print has_pass_set
			return False

	def verifyPassword(self, password):
		cmd = ' '.join([self.fwTool, "-verify"])
		p_cmd = pexpect.spawn(cmd)
		p_cmd.expect('Enter password:')
		p_cmd.sendline(password)
		result = p_cmd.expect(['Correct', 'Incorrect'])
		p_cmd.close()

		if result == 0:
			return True
		else:
			return False

	def removePassword(self, password):
		cmd = ' '.join([self.fwTool, "-delete"])
		p_cmd = pexpect.spawn(cmd)
		p_cmd.expect('Enter password:')
		p_cmd.sendline(password)
		result = p_cmd.expect(['removed', 'incorrect'])
		p_cmd.close()

		if result == 0:
			print "Removed Firmware Password. Reboot is required."
			return True
		else:
			return False

	def setPassword(self, password):
		if self.hasPassword:
			print "System already has a password."
			return False

		cmd = ' '.join([self.fwTool, "-setpasswd"])
		p_cmd = pexpect.spawn(cmd)
		res = p_cmd.expect('Enter new password:')
		if res != 0:
			print "Unexpected response."
			return False
		p_cmd.sendline(password)

		cmd = p_cmd.expect('Re-enter new password:')
		if res != 0:
			print "Unexpected response."
			return False
		p_cmd.sendline(password)
		
		result = p_cmd.expect(pexpect.EOF)
		p_cmd.close()

		if result == 0:
			print "Set Firmware Password."
			return True
		else:
			return False

	def updatePassword(self, oldPassword, newPassword):
		if not self.hasPassword:
			print "System does not already have a password. No password update can occure."
			return False

		cmd = ' '.join([self.fwTool, "-setpasswd"])
		p_cmd = pexpect.spawn(cmd)
		res = p_cmd.expect('Enter password:')
		if res != 0:
			print "Unexpected response."
			return False
		p_cmd.sendline(oldPassword)

		res = child.expect('Enter new password:')
		if res != 0:
			print "Unexpected response."
			return False
		p_cmd.sendline(newPassword)

		res = child.expect('Re-enter new password:')
		if res != 0:
			print "Unexpected response."
			return False
		p_cmd.sendline(newPassword)

		result = child.expect(pexpect.EOF)
		child.close()

		if result == 0:
			print "Updated Firmware Password."
			return True
		else:
			return False


def main():
	'''Main command processing'''
	firmwarepasswd = '/usr/sbin/firmwarepasswd'

	parser = argparse.ArgumentParser(description='Firmware password manager')

	subparsers = parser.add_subparsers(description='Actions')
	
	verify_parser = subparsers.add_parser('verify', help='Verify Firmware Password')
	verify_parser.add_argument('--password', dest='verify_password', action='store', help='Password')

	set_parser = subparsers.add_parser('set', help='Set Firmware Password')
	set_parser.add_argument('--password', dest='set_password', action='store', help='Password')

	update_parser = subparsers.add_parser('update', help='Update Firmware Password')
	update_parser.add_argument('--old-password', dest='old_password', action='store', help='Old Password')
	update_parser.add_argument('--new-password', dest='new_password', action='store', help='New Password')

	remove_parser = subparsers.add_parser('remove', help='Remove Firmware Password')
	remove_parser.add_argument('--password', dest='rm_password', action='store', help='Password')
	
	args = parser.parse_args()
	
	fwp = fwPassword(firmwarepasswd)

	# Verify Firmware password
	if args.verify_password:
		fwp.verifyPassword(args.verify_password)

	# Set Firmware password
	if args.set_password:
		fwp.setPassword(args.set_password)

	# Update Firmware password
	if args.old_password and args.new_password:
		fwp.updatePassword(args.old_password, args.new_password)
	
	# Remove Firmware password
	if args.rm_password:
		fwp.removePassword(args.rm_password)


if __name__ == '__main__':
    main()