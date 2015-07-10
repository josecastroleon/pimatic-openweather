module.exports ={
  title: "pimatic-openweather device config schemas"
  OpenWeatherDevice: {
    title: "OpenWeatherDevice config options"
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
        default: "60000"
      day:
        description: "day to retrieve forecast (today+value)"
        format: "integer"
        default: "1"
  }
  OpenWeatherForecast16Device: {
    title: "OpenWeatherForecast16Device config options"
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
        default: "60000"
      day:
        description: "day to retrieve forecast (today+value)"
        format: "integer"
        default: "1"
  }
}
