/// class that contains functions for working with Unix Timestamps
class UnixManager {
  /// the date and time right now in milliseconds
  int get dateNowMilli {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// the date and time right now in microseconds
  int get dateNowMicro {
    return DateTime.now().microsecondsSinceEpoch;
  }

  /// returns true if the given date is expired, else return false
  ///
  /// input must be unix timestamp milliseconds
  bool isExpired(int expirationDate) {
    /// returns true if expired
    bool isExpired = false;

    /// get the date time now
    int dateNow = DateTime.now().millisecondsSinceEpoch;

    // compute the expiry
    if (dateNow > expirationDate) {
      isExpired = true;
    }

    // return true if expired, else return false
    return isExpired;
  }

  /// creates a timestamp in the future to set as expiry
  int setExpiry({
    int seconds = 0,
    int minutes = 0,
    int hours = 0,
    int days = 0,
  }) {
    /// get the date now
    int dateNow = DateTime.now().millisecondsSinceEpoch;

    /// convert the given seconds to milliseconds
    int totalSeconds = seconds * oneSecond;

    /// convert the given minutes to milliseconds
    int totalMinutes = minutes * oneMinute;

    /// convert the given hours to milliseconds
    int totalHours = hours * oneHour;

    /// convert the days hours to milliseconds
    int totalDays = days * oneDay;

    /// get the total by adding all values
    int expiryDate =
        dateNow + totalSeconds + totalMinutes + totalHours + totalDays;

    /// return the expiry date
    return expiryDate;
  }

  /// 1 second in milliseconds
  final int oneSecond = 1000;

  /// 1 minute in milliseconds
  final int oneMinute = 60000;

  /// 1 hour in milliseconds
  final int oneHour = 3600000;

  /// 1 day in milliseconds
  final int oneDay = 86400000;
}
