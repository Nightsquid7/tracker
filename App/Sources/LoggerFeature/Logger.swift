import Logging
import Pulse

public struct TrackerLogger {
  static var logger: Logger = Logger(label: "com.nightsquid.tracker")

  public static func setup() {
    LoggingSystem.bootstrap(PersistentLogHandler.init)
    logger.logLevel = .debug
  }

}

public func log(_ any: Logger.Message,
                   level: Logger.Level = .debug,
                   file: StaticString = #file,
                   function: StaticString = #function,
                   line: Int = #line) {

  let fileMessage = "\(file)".split(separator: "/").last!
  let content: Logger.Message = "\(fileMessage) \(function):\(line) \(any)"
  switch level {
  case .info:
    TrackerLogger.logger.info(content)
    print(content)
    
  case .trace:
    TrackerLogger.logger.trace(content)
    print(content)
    
  case .debug:
    TrackerLogger.logger.debug(content)
    print(content)
    
  case .notice:
    TrackerLogger.logger.notice(content)
    print(content)
    
  case .warning:
    TrackerLogger.logger.warning(content)
    print(content)
    
  case .error:
    TrackerLogger.logger.error(content)
    print(content)
    
  case .critical:
    TrackerLogger.logger.critical(content)
    print(content)
  }
}


