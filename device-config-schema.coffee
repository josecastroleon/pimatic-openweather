module.exports ={
  title: "pimatic-openweather device config schemas"
  OpenWeatherDevice: {
    title: "OpenWeatherDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      location:
        description: "City/country"
        type: "string"
      cityId:
        description: "City ID. If provided, data will queried for the given id instead of using the location property"
        type: "string"
        required: false
      lang:
        description: "Language"
        type: "string"
        default: "en"
      units:
        description: "Units"
        type: "string"
        default: "metric"
      timeout:
        description: "Timeout between requests"
        type: "integer"
        default: "900000"
      timeoutOnError:
        description: "Timeout between requests if previous request failed"
        type: "integer"
        default: "60000"
      blacklist:
        description: "List of weather results to ignore as they contain false data"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            base:
              description: "Indicates the origin of the weather data, e.g., 'stations' or 'cmc_stations'"
              type: "string"
            weatherId:
              description: "The weather condition id set in the blacklisted result"
              type: "integer"
              required: false
            temperature:
              description: "The temperature set in the blacklisted result"
              type: "number"
              required: false
  }
  OpenWeatherForecastDevice: {
    title: "OpenWeatherForecastDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      location:
        description: "City/country"
        type: "string"
      cityId:
        description: "City ID. If provided, data will queried for the given id instead of using the location property"
        type: "string"
        required: false
      lang:
        description: "Language"
        type: "string"
        default: "en"
      units:
        description: "Units"
        type: "string"
        default: "metric"
      timeout:
        description: "Timeout between requests"
        type: "integer"
        default: "900000"
      timeoutOnError:
        description: "Timeout between requests if previous request failed"
        type: "integer"
        default: "60000"
      day:
        description: "day to retrieve forecast for, from 1 to 16 (1=today, 2=tomorrow, ...)"
        type: "integer"
        default: 2
        minimum: 1
        maximum: 16
  }
}
