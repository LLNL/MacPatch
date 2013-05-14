   ___                   ____  ____         ____     ___  
  / _ \ _ __   ___ _ __ | __ )|  _ \__   __|___ \   / _ \ 
 | | | | '_ \ / _ \ '_ \|  _ \| | | \ \ / /  __) | | | | |
 | |_| | |_) |  __/ | | | |_) | |_| |\ V /  / __/ _| |_| |
  \___/| .__/ \___|_| |_|____/|____/  \_/  |_____(_)\___/ 
       |_| Ready-2-Run Jetty 7.5.4 distribution



This is the official OpenBD+Jetty distribution has been
configured with OpenBD within the root context.

In other words, you can utilise CFML across all contexts
and virtual hosts, in much the same way you can with JSP.

Getting Started ---------------------------------------

Please make sure you have Java 1.5+ installed on your system.
If you do not, then please goto http://java.sun.com/ and 
select the correct one for your operating system.

From the release, you can run the server with:

   java -jar start.jar

and then point your browser at 

   http://127.0.0.1:8080/

to get to the administration panel

   http://127.0.0.1:8080/bluedragon/administrator/index.cfm
   
Directory Structure ---------------------------------------

The following directories is where you will find OpenBD specific
files:

  + <jettyroot>/etc/jetty.xml
    The main configuration file for jetty

  + <jettyroot>/webapps/openbd/
    The directory where all the CFML apps live
    
Web Configuration ---------------------------------------

This release we have preloaded the OpenBD context so it will
startup when Jetty starts up.  You can move this root directory
anywhere you want, as long as you update the path in the
<jettyroot>/contexts/openbd.xml file

OpenBD Support ---------------------------------------

  Web:
  http://openbd.org/

Microsoft Windows Service Support -------------------------

Provided by:

  http://commons.apache.org/daemon/procrun.html
  
  
  
--end@ November 2011 Release 2.0