# WinCC OA IT OT Layer
**Turning configuration into automation. This application example shows how one JSON file can automatically configure southbound drivers, datapoints, publishing to northbound, subscribing to northbound, and creating dashboards in WinCC OA --- reducing engineering effort and errors.**

<img width="1280" height="720" alt="Architecture_new" src="https://github.com/user-attachments/assets/2fbf0a20-70f2-4770-a86c-850185dc1b01" />

> Figure 1 – Architecture Overview

## Overview

The **IT/OT layer application example** provides a ready-to-use automation layer that drives a complete WinCC OA project from a single JSON file. 
This approach eliminates manual setup and enables: 

- Automatic creation of southbound drivers and datapoints 

- Publishing and subscribing to/from Northbound layer through OPC UA and MQTT 

- Unified Namespace (UNS) support during publishing to Northbound layer 

- Auto-generated dashboards with ready-to-use widgets linked to the needed datapoints 

This ensures faster engineering, consistency, and scalability for IT/OT integration projects. 

**Version:** WinCC OA 3.20 

**Operating System:** Linux 


## Key Features

**Single JSON Configuration**

All connections, datapoints, and dashboards are described in one file. 

![Video1_JSON](https://github.com/user-attachments/assets/d9852a37-08f5-47f6-82fb-59ed6e6fb2dd)
> Video 01 – JSON Structure

**Auto Creation of Southbound WinCC OA Managers**

WinCC OA driver managers (S7, Sinumerik, BACnet, IEC61850…) are created directly based on the JSON’s Southbound Section 

![Video2_SouthboundManagerCreation](https://github.com/user-attachments/assets/abc2c9ff-c366-477c-9086-f50c7338ed3c)
> Video 02 – Southbound Manager Creation 

**Southbound Datapoint Auto Creation**

Datapoints are automatically generated with PLC addresses, archiving settings, and engineering ranges based on the JSON file entries, as well as the drivers’ connections and the associated IPs/ports 

![Video3_Southbound](https://github.com/user-attachments/assets/4b786c7a-1357-46b9-9133-c9f4c64a57c7)
> Video 03 – Southbound Datapoints creation

**Northbound Publishing**

Southbound data will be published via OPC UA and MQTT. The data will be made available either per southbound driver or as part of a Unified Namespace (UNS), based on entries in the JSON file. Both the data to be exposed and its target OPC UA or MQTT endpoint are defined in the JSON entries. 

![Video4_Publish](https://github.com/user-attachments/assets/fcc2dbea-1e00-4235-afbf-ea42e1710bd8)
> Video 04 – Northbound Publishing

**Northbound Subscribing**

Datapoints from external OPC UA servers or MQTT brokers are automatically created and configured inside WinCC OA based on the JSON file. 

![Video5_Subscribe](https://github.com/user-attachments/assets/edb34854-0628-4107-8cc1-4f15f36cc5f6)
> Video 05 – Northbound Subscribing

**Automatic Dashboards Creation**

Dashboards with gauges, labels, trends, and pie charts are instantly created linked to the needed datapoints and ready for visualization. 

![Video6_Dashboard](https://github.com/user-attachments/assets/384cb885-a881-48cf-b368-f579b3ce7c87)
> Video 06 – Dashboard creation


## Conclusion 

The IT/OT layer application example is a blueprint for fast, error-free IT/OT integration. By driving everything from a single JSON file, it brings speed, consistency, and flexibility to engineering industrial projects with WinCC OA. 

## Content:
This repository includes the project folder, documentation, and the legal information of the application example, organized as following:
- **IT_OT_Demo:** The application example project
- **IT_OT_Demo_Datasheet_V1.0.pdf:** HowTo of Implementation, Installation and Usage of the application example
- **LEGAL_INFO.md:** Legal Information
- **LICENSE.md:** License Information
- **README.md:** this file


