# MacPatch - Install Distribution Server(s)When the first server ("Master") is compiled and built it will create a file called "MacPatch_Server.zip" in /Library/MacPatch. This zip file is a complete copy of the master server build in a unconfigured state. Simply copy the "MacPatch_Server.zip" to your new distribution server.

#### Mac OS X Requirements

Java JDK needs to be installed.

#### Linux Requirements

##### APT

	sudo apt-get update
	sudo apt-get install git
	sudo apt-get install build-essential
	sudo apt-get install openjdk-7-jdk
	sudo apt-get install zip
	sudo apt-get install libssl-dev
	sudo apt-get install libxml2-dev
	sudo apt-get install python-pip
	sudo apt-get install python-mysql.connector 
##### YUM

	sudo yum install gcc-c++
	sudo yum install openssl-devel
	sudo java-1.7.0-openjdk-devel
	sudo yum install libxml2-devel
	sudo yum install bzip2
	sudo yum install bzip2-libs
	sudo yum install bzip2-devel
	sudo yum install python-pip
	sudo yum install mysql-connector-python##### Python

	pip install requests
	pip install python-crontab## Configure Server##### Distribution Server Setup & Config	mkdir -p /Library/MacPatch
	cp {FROM_PATH}/MacPatch_Server.zip /Library/MacPatch
	cd /Library/MacPatch
	unzip ./MacPatch_Server.zip
	mv ./MacPatch_Server ./Server

##### Run Setup Scripts

	cd /Library/MacPatch/Server	
	./conf/scripts/Setup/DataBaseLDAPSetup.sh
	./conf/scripts/Setup/WebServicesSetup.shThis distribution server is now configured and running. The last step is to edit the Apache virtual host balancer to include the new distribution server.##### Configure "Master" MacPatch server
Using your favorite editor edit the following file "/Library/MacPatch/Server/Apache2/conf/extra/httpd-vhosts.conf". You will want to edit the Virtual host "*:2600" (<VirtualHost *:2600>). Find and edit the lines:    #WslBalanceStart
    BalancerMember http://localhost:3601 route=localhost-site1 loadfactor=50    #WslBalanceStop  Add the line below the first "**BalancerMember**"    BalancerMember http://[YOUR_SERVER_NAME_OR_IP]:3601 route=[YOUR_SERVER_NAME]-site1 loadfactor=50Add the server(s) via the Admin consoleLogin to the MacPatch admin console with a admin account and go to "Admin->Server->MacPatch Server" and add the new server.##### Start the MacPatch services

	/Library/MacPatch/Server/conf/scripts/Setup/StartServices.py --load All