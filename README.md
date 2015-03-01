pimatic-openweather
===================

Pimatic Plugin that retrieves the forecast on several devices

Configuration
-------------
Add the plugin to the plugin section:

    {
      "plugin": "openweather"
    },

Then add the device with the location into the devices section:

    {
      "id": "weather",
      "class": "OpenWeatherDevice",
      "name": "Weather Geneva",
      "location": "Geneva, Switzerland",
      "units": "metric",
      "lang": "en",
      "timeout": 300000
    }

If you need a forecast you can use the following device:

    {
      "id": "forecast",
      "class": "OpenWeatherForecastDevice",
      "name": "Forecast 1 day for Geneva",
      "location": "Geneva, Switzerland",
      "units": "metric",
      "lang": "en",
      "timeout": 300000,
      "day": 1
    }

Then you can add the items into the mobile frontend
