#### deviceId is displayed in MS below MindConnect Software Agent Geräte ID: ...

# log into your tenant and open up in the browser the UI plugin for your agent
# use F12 in your browser and read the information from the request the UI performs.
# alternatively you can use the 
# MindSphere Authentication Helper Chrome Extension described at
# https://opensource.mindsphere.io/docs/mindsphere-auth-helper/index.html to read out Session and Xsrf

curl --location --request POST 'https://connint6-uipluginassetmanagermcsoftware.eu1-int.mindsphere.io/api/deploymentworkflow/v3/instances' \
--header 'Content-Type: application/json' \
--header 'X-XSRF-TOKEN: be8f24e5-2240-42a2-9580-d935b2ff5426' \
--header 'Cookie: SESSION=ZGM5OTUyZGUtZjE1Yi00NGRkLWI4NWUtMTIwMzFmZWE1OWNm; XSRF-TOKEN=be8f24e5-2240-42a2-9580-d935b2ff5426' \
--data-raw '{
"deviceId": "72ba3b9b-187c-4694-b25f-2c23a624d924",
"model": {
"key": "mdsp-core-commandDispatcher"
},
"data": {
"type": "datapoint-write",
"version": "v1.0",
"to": "SINUMERIK",
"payload": {
      "desiredValue": "4",
      "dataSourceId": "3ce580c7-5549-443d-ad9f-2c03048851c5",
      "dataPointId": "25f0afc3675d4",
      "protocol": "SINUMERIK"
    }
}
}'