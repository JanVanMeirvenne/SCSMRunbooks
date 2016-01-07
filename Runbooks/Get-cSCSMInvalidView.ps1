 <#
    .SYNOPSIS 
      Checks all views within a SCSM management group and returns information on views that have invalid enum criteria (guid no longer valid)
    .EXAMPLE
     Get-cSCSMInvalidView -ComputerName MySCSMServer
     
  #>

param(
	# The name of a SCSM management server
	[string] $ComputerName = 'localhost'
)

# set the smlet default scsm server and load the module
$smdefaultcomputer = $ComputerName
import-module smlets -force

# Get all views that are stored in unsealed management packs
$Views = Get-SCSMView|?{$_.GetManagementPack().Sealed -eq $false}
# Because we can't do a Get-SCSMFolder based on Id, we just retrieve all folders at once and do in-memory filtering later on
$Folders = Get-SCSMFolder
# We will store all the output in a variable which we will return at the end
$Output = ""

# Iterate through each view we want to check for invalid criteria
foreach($View in $Views){
    
        # Get the XML criteria code for the view
        $XML = ([xml]$View.GetXML())
        $Criteria = $XML.View.Data.Criteria.InnerText
	    # Only continue if a criteria is present
        if($Criteria -ne ''){
				# Extract all guids from the criteria 
                $guids = $Criteria | Select-String -Pattern '{[-0-9A-F]+?}' -AllMatches | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
                foreach($guid in $guids){
                   
                    # Check if the guid resolves to a valid enumeration
                    if((Get-SCSMEnumeration -Id $guid -ErrorAction SilentlyContinue) -ne $null){
                      #  Do nothing if the guid is valid
                    } else {
                        # Generate the full folder path to the view so that the impacted view can be quickly looked up
                        $Parent = $View.ParentFolderIds
                        $Folder = $Folders|?{$_.Id -eq "$Parent"}
                        

                        $ViewPath = @()
                        $ViewPath += $Folder.DisplayName
                     
                        $Parent = $Folder.ParentFolder.Id
                        while($Parent){
                            
							$Folder = $Folders|?{$_.Id -eq $Parent}
                            
                            $ViewPath += $Folder.DisplayName
                            
                            $Parent = $Folder.ParentFolder.Id
   
                        }
                        
                        $FolderPath = ""
                        
                        [array]::Reverse($ViewPath)
                        for($i = 2;$i -le $ViewPath.Count - 1;$i++){
                           
                            $FolderPath += "$($ViewPath[$i])/"
                        }

                       
                            
                       # Put all relevant information in the output variable 
                       $Output += "Missing guid '$guid' in view '$($View.DisplayName)' of type '$((get-scsmclass -id $View.Target.Id).DisplayName)' in folder-path '$FolderPath'`r`n"
                      
                    }
                   
                }
               
            
        }
        
            

}

# When all views are processed, return the outtput to show the impacted views
$Output


<#
SAMPLE OUTPUT:

Missing guid '{a12f6e91-d223-4741-3ca9-41088c314b84}' in view 'Microsoft Outlook' of type 'Problem' in folder-path 'Work Items/Problem Management - SEC/Problem per Service/Communication/'
Missing guid '{f4272a24-62f2-9268-4b3c-cf97a5826815}' in view 'Open Service Requests' of type 'Service Request' in folder-path 'Work Items/Service Request Fulfillment - SEC/Requests per Team/System Administration/'
Missing guid '{53ed0149-0ab0-82b5-9a15-cad88cb9baaf}' in view 'Open Service Requests' of type 'Service Request' in folder-path 'Work Items/Service Request Fulfillment - SEC/Requests per Team/System Administration/'
Missing guid '{7055e658-9b34-912a-d8bf-36b9eb8bc961}' in view 'Open Service Requests' of type 'Service Request' in folder-path 'Work Items/Service Request Fulfillment - SEC/Requests per Team/System Administration/'
Missing guid '{c03eef03-2f70-8067-6e87-0912a75f03d7}' in view 'Open Service Requests' of type 'Service Request' in folder-path 'Work Items/Service Request Fulfillment - SEC/Requests per Team/System Administration/'
Missing guid '{ca22b681-5e61-32c8-d3fe-380a8552d710}' in view '3rd Line Service Requests' of type 'Service Request' in folder-path 'Work Items/Service Request Fulfillment - SEC/Requests per Team/Application Administration/'
Missing guid '{9754cf58-192f-7a9b-a9b5-3d0139eb52c2}' in view 'iWriter' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Service/Business/'
Missing guid '{8ac9bbb4-7750-ca1d-f984-2f15400b71ae}' in view 'Internet Explorer' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Service/Business/'
Missing guid '{f8b6c6ea-6c44-c7d8-358e-f98662df4c04}' in view 'System Administration - Active' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{6e751a52-904b-1b90-ed2a-d4053dcd1be3}' in view 'System Administration - Active' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{fe1c831f-13ef-94a7-69ff-1b31f2007b0c}' in view 'System Administration - Active' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{b44dafc0-2c8a-f527-2087-e9c28664de5a}' in view 'System Administration - Active' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{7e2b888d-ed4a-e4ca-efb7-74bc85138b8f}' in view 'System Administration - Active' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{39beec18-cfa0-d401-782b-b419c876d719}' in view 'System Administration - Active' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{39beec18-cfa0-d401-782b-b419c876d719}' in view 'Microsoft Outlook' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Service/Communication/'
Missing guid '{f8b6c6ea-6c44-c7d8-358e-f98662df4c04}' in view 'System Administration - Critical tickets' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{7e2b888d-ed4a-e4ca-efb7-74bc85138b8f}' in view 'System Administration - Critical tickets' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{39beec18-cfa0-d401-782b-b419c876d719}' in view 'System Administration - Critical tickets' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{6e751a52-904b-1b90-ed2a-d4053dcd1be3}' in view 'System Administration - Critical tickets' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{fe1c831f-13ef-94a7-69ff-1b31f2007b0c}' in view 'System Administration - Critical tickets' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{b44dafc0-2c8a-f527-2087-e9c28664de5a}' in view 'System Administration - Critical tickets' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{7e2b888d-ed4a-e4ca-efb7-74bc85138b8f}' in view 'System Administration - Closed/Resolved' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{39beec18-cfa0-d401-782b-b419c876d719}' in view 'System Administration - Closed/Resolved' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{6e751a52-904b-1b90-ed2a-d4053dcd1be3}' in view 'System Administration - Closed/Resolved' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{fe1c831f-13ef-94a7-69ff-1b31f2007b0c}' in view 'System Administration - Closed/Resolved' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{b44dafc0-2c8a-f527-2087-e9c28664de5a}' in view 'System Administration - Closed/Resolved' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{f8b6c6ea-6c44-c7d8-358e-f98662df4c04}' in view 'System Administration - Closed/Resolved' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{7e2b888d-ed4a-e4ca-efb7-74bc85138b8f}' in view 'System Administration - In Progress' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{39beec18-cfa0-d401-782b-b419c876d719}' in view 'System Administration - In Progress' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{6e751a52-904b-1b90-ed2a-d4053dcd1be3}' in view 'System Administration - In Progress' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{fe1c831f-13ef-94a7-69ff-1b31f2007b0c}' in view 'System Administration - In Progress' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{b44dafc0-2c8a-f527-2087-e9c28664de5a}' in view 'System Administration - In Progress' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'
Missing guid '{f8b6c6ea-6c44-c7d8-358e-f98662df4c04}' in view 'System Administration - In Progress' of type 'Incident' in folder-path 'Work Items/Incident Management - SEC/Incidents per Team/'

#>