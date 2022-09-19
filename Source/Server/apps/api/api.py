import argparse
import getpass
import sys

from registration import *
from app import create_app


def getDBUserPassword():
	print("Please enter the MySQL root user account name and password")

	_ruser = input("MySQL DB root user name[root]: ") or "root"
	_rPass1 = getpass.getpass("MySQL Database Root Password:")
	_rPass2 = getpass.getpass("Verify MySQL Database Root Password:")
	
	while _rPass1 != _rPass2:
		print("Passwords did not match, would you like to try again?")
		_again = input("[Y]es / [N]o: ")
		if _again.lower() != "y":
			return None

		_rPass1 = getpass.getpass("MySQL Database Root Password:")
		_rPass2 = getpass.getpass("Verify MySQL Database Root Password:")

	return _ruser,_rPass1

if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('--run',      default=False, action='store_true', dest='isRun', help='Run the app')
	parser.add_argument('--dbSetup',  default=False, action='store_true', dest='isDBSetup', help='Populate Default Database')
	parser.add_argument('--dbCreate',  default=False, action='store_true', dest='isDBCreate', help='Populate Default Database')
	parser.add_argument('--version',  default=False, action='store_true', dest='isVersion', help='API Version')
	args = parser.parse_args()

	app = create_app()

	if args.isRun:
		app.run()

	if args.isDBCreate:
		with app.app_context():
			_up = getDBUserPassword()
			if _up == None:
				sys.exit(1)

			res = createDB(_up[0],_up[1])
			if res == None:
				print('\nThere were errors creating the database. Please review the failed tasks before trying again.')	
			else:
				print('\nCreate Database Done')

	if args.isDBSetup:
		with app.app_context():
			print('Add Default Data to Database')
			addDefaultData()
			print('Default Data Added to Database')

	if args.isVersion:
		print("MacPatch 3.7.0")
