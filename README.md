DFSR Monitoring Script
======================

Purpose
-------

This script will provide a simple reporting mechanism for DFSR. A scheduled task
will run the script and send a report via email.

Requirements
------------

-   This script has been test in Powershell version 4 and 5. But should work
    in Powershell 3.

-   This script assumes you have an SMTP relay onsite that allows anonymous
    authentication

-   Requires the script to be ran as an elevated admin in order to query DFSR

Usage
-----

1.Fill in the information found in these lines:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$From = "test@test.com"  #From email
$Receipt = "test@testing.com"  #Receipt email
$Server = "smtprelay.domain.com" #SMTP Server
$Object = "DFSR Report for CLIENT NAME Group on "+(Get-Date) #Eamil Subject
$clientname = "CLIENT NAME"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

2.Setup a scheduled task to run this script

Notes
-----

The email that will be recieved will be of the following format

| DFSR Report for CLIENT NAME. Created on 10/19/2015 22:28:13                                                                                                                     |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| \| Sending Server \| Recieving Server \| Backlog Count \| \| ------------- \| ----------- \| ----------- \| \| Sending1 \| Receiving1 \| 0 \| \| Receiving1 \| Sending1 \| 0 \| |
| 2 successful, 0 warnings and 0 backlogs from 2 replications.                                                                                                                    |
| *REPORT WILL SHOW WHAT FILES ARE NOT SYNCED*                                                                                          |

Thanks & Acknowlegements
------------------------
Michael Levine - for double checking and testing the script

The core DFSR check of this script was based on work by NullPayload. You can
find him here:
http://chris-nullpayload.rhcloud.com/2014/08/powershell-script-to-monitor-dfs-replication/
