await page.evaluateOnNewDocument(function() {
  navigator.geolocation.getCurrentPosition = function (cb) {
    setTimeout(() => {
      cb({
        'coords': {
          accuracy: 21,
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          latitude: 23.129163,
          longitude: 113.264435,
          speed: null
        }
      })
    }, 1000)
  }
});
