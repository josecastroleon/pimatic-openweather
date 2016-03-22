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
  }
  OpenWeatherForecastDevice: {
    title: "OpenWeatherForecastDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      location:
        description: "City/country"
        type: "string"
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
        description: "day to retrieve forecast (today+value)"
        type: "integer"
        default: "1"
  }
}
