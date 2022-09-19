import argparse
from app import create_app

if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('--run',      default=False, action='store_true', dest='isRun', help='Run the app')
	parser.add_argument('--version',  default=False, action='store_true', dest='isVersion', help='API Version')
	args = parser.parse_args()

	app = create_app()

	if args.isRun:
		app.run()

	if args.isVersion:
		print("MacPatch 3.7.0")
