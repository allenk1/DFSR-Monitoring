# +---------------------------------------------------------------------------
# | File : DFSR-Monitoring.ps1
# | Version : 1.0
# | Purpose : Generates and Emails a report of DFSR Status
# | Synopsis:
# | Usage : .\DFSR-Monitoring.ps1 (must be ran with elevated permissions)
# +----------------------------------------------------------------------------
# |
# | File Requirements:
# | 
# +----------------------------------------------------------------------------
# | Maintenance History
# | View GitHub notes: https://github.com/allenk1/DFSR-Monitoring
# ********************************************************************************#----------------------------------------------------------------------------

#--- User Variables ---#
$From = "test@test.com"  #From email
$Receipt = "test@testing.com"  #Receipt email
$Server = "smtprelay.domain.com" #SMTP Server
$Object = "DFSR Report for CLIENT NAME Group on "+(Get-Date) #Eamil Subject
$clientname = "CLIENT NAME"


#--- Standard Variable ---$
$RGroups = Get-WmiObject  -Namespace "root\MicrosoftDFS" -Query "SELECT * FROM DfsrReplicationGroupConfig"
$ComputerName=$env:ComputerName
$Succ = 0 # Initialize counter
$Warn = 0 # Initialize counter
$bklog = 0 # Initialize counter
$backlogfiles = "BACKLOG FILES"

$emailcontent = "<h2>DFSR Report for " + $clientname + ". Created on " +(Get-Date) + "</h2>`r`n"
$emailcontent += "<br /><br />"
$emailcontent += "<table style='border: 1px solid black; border-collapse: collapse;'><tr><th style='border: 1px solid black; background: #dddddd; padding: 5px;'>Sending Server</th><th style='border: 1px solid black; background: #dddddd; padding: 5px;'>Recieving Server</th><th style='border: 1px solid black; background: #dddddd; padding: 5px;'>Backlog Count</th></tr>"

foreach ($Group in $RGroups) {
    $RGFoldersWMIQ = "SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicationGroupGUID='" + $Group.ReplicationGroupGUID + "'"
    $RGFolders = Get-WmiObject -Namespace "root\MicrosoftDFS" -Query  $RGFoldersWMIQ
    $RGConnectionsWMIQ = "SELECT * FROM DfsrConnectionConfig WHERE ReplicationGroupGUID='"+ $Group.ReplicationGroupGUID + "'"
    $RGConnections = Get-WmiObject -Namespace "root\MicrosoftDFS" -Query  $RGConnectionsWMIQ
    foreach ($Connection in $RGConnections) {
        $ConnectionName = $Connection.PartnerName#.Trim()
        if ($Connection.Enabled -eq $True) {
            #if (((New-Object System.Net.NetworkInformation.ping).send("$ConnectionName")).Status -eq "Success")
            #{
                foreach ($Folder in $RGFolders) {
                    $RGName = $Group.ReplicationGroupName
                    $RFName = $Folder.ReplicatedFolderName
 
                    if ($Connection.Inbound -eq $True) {
                        $SendingMember = $ConnectionName
                        $ReceivingMember = $ComputerName
                        $Direction="inbound"
                    } else {
                        $SendingMember = $ComputerName
                        $ReceivingMember = $ConnectionName
                        $Direction="outbound"
                    }

                    # Check backlog to great counters
                    if ($BacklogFileCount -eq 0) {
                        $Succ=$Succ+1
                    } elseif ($BacklogFilecount -lt 10) {
                        $Warn=$Warn+1
                    } else {
                        $bklog=$bklog+1
                    }
 
                    $BLCommand = "dfsrdiag Backlog /RGName:'" + $RGName + "' /RFName:'" + $RFName + "' /SendingMember:" + $SendingMember + " /ReceivingMember:" + $ReceivingMember
                    $Backlog = Invoke-Expression -Command $BLCommand
 
                    $BackLogFilecount = 0
                    foreach ($item in $Backlog) {
                        if ($item -ilike "*Backlog File count*") {
                            $BacklogFileCount = [int]$Item.Split(":")[1].Trim()
                        }
                    }

                    if($bklog>0){
                        #Get DFSR Backlog
                        $backlogfiles += "Backlog for $SendingMember"
                        $backlogfiles += Get-DfsrBacklog -SourceComputerName $SendingMember -DestinationComputerName $ReceivingMember -GroupName $RFName
                    }

                    $emailcontent += "<tr><td style='border: 1px solid black; padding: 5px;'>$SendingMember</td><td style='border: 1px solid black; padding: 5px;'>$ReceivingMember</td><td style='border: 1px solid black; padding: 5px;'>$BacklogFileCount</td></tr>"
                    #Write-Host "$BacklogFileCount files in backlog $SendingMember->$ReceivingMember for $RGName" -fore $Color
 
                } # Closing iterate through all folders
            #} # Closing  If replies to ping
        } # Closing  If Connection enabled
    } # Closing iteration through all connections
} # Closing iteration through all groups

$emailcontent += "</table>"
$emailcontent += "<br /><br />"
$emailcontent += "$Succ successful, $Warn warnings and $bklog backlogs from $($Succ+$Warn+$bklog) replications."
$emailcontent += "<br /><br />"
if($bklog>0){
    $emailcontent += $backlogfiles
}

#Mail content
$Content = $emailcontent

$SMTPclient = new-object System.Net.Mail.SmtpClient $Server

$Message = new-object System.Net.Mail.MailMessage $From, $Receipt, $Object, $Content
$Message.IsBodyHtml = $true;
if($bklog>100){
    $Message.Priority = "high" 
}

$SMTPclient.Send($Message)


