module.exports = {
  title: "OpenWeather"
  type: "object"
  properties: {
    apiKey:
      description: "API key for openweather service"
      type: "string"
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
  }
}
