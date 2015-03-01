module.exports ={
  title: "pimatic-openweather device config schemas"
  OpenWeatherDevice: {
    title: "OpenWeatherDevice config options"
    type: "object"
    properties: 
      location:
        description: "City/country"
        format: String
      lang:
        description: "Language"
        format: String
        default: "en"
      units:
        description: "Units"
        format: String
        default: "metric"
      timeout:
        description: "Timeout between requests"
        format: Number
        default: "60000"
  }
  OpenWeatherForecastDevice: {
    title: "OpenWeatherForecastDevice config options"
    type: "object"
    properties:
      location:
        description: "City/country"
        format: String
      lang:
        description: "Language"
        format: String
        default: "en"
      units:
        description: "Units"
        format: String
        default: "metric"
      timeout:
        description: "Timeout between requests"
        format: Number
        default: "60000"
      day:
        description: "day to retrieve forecast (today+value)"
        format: Number
        default: "1"
  }
}
