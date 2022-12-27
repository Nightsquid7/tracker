import Logging

public let logger = Logger(label: "com.nightsquid.tracker")


public func log(_ any: Logger.Message,
                   level: Logger.Level = .debug,
                   file: StaticString = #file,
                   function: StaticString = #function,
                   line: Int = #line) {

  let content: Logger.Message = "\(file) \(function):\(line) \(any)"
  switch level {
  case .info:
    logger.info(content)
    print(content)
    
  case .trace:
    logger.trace(content)
    print(content)
    
  case .debug:
    logger.debug(content)
    print(content)
    
  case .notice:
    logger.notice(content)
    print(content)
    
  case .warning:
    logger.warning(content)
    print(content)
    
  case .error:
    logger.error(content)
    print(content)
    
  case .critical:
    logger.critical(content)
    print(content)
  }
}


