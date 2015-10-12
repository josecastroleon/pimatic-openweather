pimatic-openweather
===================

Pimatic Plugin that retrieves the current weather and forecast data on several devices.
Important notes: 
 * To use this plugin you need to sign up to obtain an API key at [openweather.org](http://openweathermap.org/appid). 
   The subscription is free of charge.
 * The service API has been changed recently. As part of the location you'll need to provide the 
   2-letter [ISO 3166](https://en.wikipedia.org/wiki/ISO_3166-1) country code rather than providing the country name.


Configuration
-------------
Add the plugin to the plugin section:

    {
      "plugin": "openweather",
      "apiKey": "xxxxxxxxxxxxx"
    },

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
      "day": 1
    }

Then you can add the items into the mobile frontend.
