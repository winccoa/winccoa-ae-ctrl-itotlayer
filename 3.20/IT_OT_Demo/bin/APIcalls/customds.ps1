#Data source and data point configuration on command without UI
# this allows you to specifiy any custom protocol with its custom parameters
# the configuration will be deployed to the onboarded agent automatically
# the data point mapping can be made in the standard UI afterwards

# the tenant where the agent resides
$tenant = 'etmat'

# the agent e.g. Nano Box, MCSA
$agent_id = 'c43252fbff59427aad2ce25802133fcd'

# the json file that contains the desired data source and data point configuration
$data_source_config_file = 'data_cfg_new.json'

# log into your tenant and open up in the browser the UI plugin for your agent
# use F12 in your browser and read the information from the request the UI performs.
# alternatively you can use the 
# MindSphere Authentication Helper Chrome Extension described at
# https://opensource.mindsphere.io/docs/mindsphere-auth-helper/index.html to read out Session and Xsrf

$x_xsrf_token = '80f835f3-8549-4f3e-b9e1-325676285fb1'
$session = 'NGUzYTRiOTAtNGM5YS00NzBiLTk5NzktOGE4NDVlMTk3NTI1'


curl.exe -v `
   -X PUT https://$tenant-uipluginassetmanagermcnano.eu1.mindsphere.io/api/mindconnectdevicemanagement/v3/devices/$agent_id/dataConfig `
  --cookie "SESSION=$session;XSRF-TOKEN=$x_xsrf_token" `
  --header "x-xsrf-token: $x_xsrf_token" `
  --header "Content-Type: application/json" `
  --data-bin "@$data_source_config_file"

curl.exe -v `
   -X POST https://$tenant-uipluginassetmanagermcnano.eu1.mindsphere.io/api/mindconnectdevicemanagement/v3/devices/$agent_id/applyChanges `
  --cookie "SESSION=$session;XSRF-TOKEN=$x_xsrf_token" `
  --header "x-xsrf-token: $x_xsrf_token" `
  --header "Content-Type: application/json"
