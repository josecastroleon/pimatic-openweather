pimatic-openweather
===================

Pimatic Plugin that retrieves the current weather and forecast data on several devices.
Important notes: 
 * To use this plugin you need to sign up to obtain an API key at [openweather.org](http://openweathermap.org/appid). 
   The subscription is free of charge.
 * The service API has been changed recently. As part of the location you'll need to provide the 
   2-letter [ISO 3166](https://en.wikipedia.org/wiki/ISO_3166-1) country code rather than providing the country name.
   
Notable Changes with v9.0
-------------------------

* As some users had problems with sporadic "location not found" errors, the `cityId` property has been added 
  which allows for setting the location id to work-around the problem
* The `blacklist` property has been added to `OpenWeatherDevice` which allows for defining a list 
  of weather results to ignore as they contain false data
* The `day` property default value of the `OpenWeatherForecastDevice` has been changed to `2` to obtain the forecast 
  for the next day by default. The property denotes the forecast day starting from 1 to 16 where 1 means today.

Configuration
-------------

### Plugin Configuration

Add the plugin to the plugin section:

    {
      "plugin": "openweather",
      "apiKey": "xxxxxxxxxxxxx",
      "debug": false
    }

### Device Configuration

Then add the device with the location into the devices section:

    {
      "id": "weather",
      "class": "OpenWeatherDevice",
      "name": "Weather Geneva",
      "location": "Geneva, CH",
      "units": "metric",
      "lang": "en",
      "timeout": 900000
    }

If you need a forecast you can use the following device:

    {
      "id": "forecast",
      "class": "OpenWeatherForecastDevice",
      "name": "Forecast 1 day for Geneva",
      "location": "Geneva, CH",
      "units": "metric",
      "lang": "en",
      "timeout": 900000,
      "day": 2
    }

Then you can add the items into the mobile frontend.

### Hiding Attributes

Attributes can be hidden from the display in the mobile frontend by using the `xattributeOptions` property as shown in the example below.

	{
	  "id": "weather",
	  "class": "OpenWeatherDevice",
	  "name": "Today",
	  "location": "Geneva, CH",
	  "units": "metric",
	  "timeout": 900000,
	  "lang": "en",
	  "xAttributeOptions": [
		{
		  "name": "humidity",
		  "hidden": true
		},
		{
		  "name": "pressure",
		  "hidden": true
		}
	  ]
	}

### Using the Blacklist Feature

Unfortunately, some weather stations emit false weather data. As a result for some locations false data 
is returned at times. The idea of blacklisting is to filter out such outlier results. A blacklist entry may 
consist of up to three of the following properties. 

* base: a string indicating an internal identification for the type of weather station network. For example, 
  "cmc stations" refers to the weather stations of the Canadian Meteorological Centre while "stations" appears to be 
  weather stations operated on a private basis. This property is mandatory
* "id": The weather condition id set in the blacklisted result. This property is optional. If provided, the value
  match will be ANDed with the remainder of the filter
* "temperature": The temperature set in the blacklisted result. This property is optional. If provided, the value
  match will be ANDed with the remainder of the filter



