module.exports ={
  title: "pimatic-openweather device config schemas"
  OpenWeatherDevice: {
    title: "OpenWeatherDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      apiKey:
        description: "API key for openweather service"
        format: "string"
        default: ""
      location:
        description: "City/country"
        format: "string"
      lang:
        description: "Language"
        format: "string"
        default: "en"
      units:
        description: "Units"
        format: "string"
        default: "metric"
      timeout:
        description: "Timeout between requests"
        format: "integer"
        default: "900000"
      timeoutOnError:
        description: "Timeout between requests if previous request failed"
        format: "integer"
        default: "60000"
  }
  OpenWeatherForecastDevice: {
    title: "OpenWeatherForecastDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      location:
        description: "City/country"
        format: "string"
      lang:
        description: "Language"
        format: "string"
        default: "en"
      units:
        description: "Units"
        format: "string"
        default: "metric"
      timeout:
        description: "Timeout between requests"
        format: "integer"
        default: "900000"
      timeoutOnError:
        description: "Timeout between requests if previous request failed"
        format: "integer"
        default: "60000"
      day:
        description: "day to retrieve forecast (today+value)"
        format: "integer"
        default: "1"
  }
}
