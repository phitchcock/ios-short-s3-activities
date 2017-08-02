import Kitura
import LoggerAPI
import HeliumLogger
import Foundation
import ActivitiesService
import MySQL

// Disable stdout buffering (so log will appear)
setbuf(stdout, nil)

// Init logger
HeliumLogger.use()

// Create connection string (use env variables, if exists)
let env = ProcessInfo.processInfo.environment
var connectionString = MySQLConnectionString(host: env["MYSQL_HOST"] ?? "localhost")
if let portString = env["MYSQL_PORT"], let port = Int(portString) {
  connectionString.port = port
}
connectionString.user = env["MYSQL_USER"] ?? "root"
connectionString.password = env["MYSQL_PASSWORD"] ?? "password"
connectionString.database = env["MYSQL_DATABASE"] ?? "game-night"

// Create connection pool
var pool = MySQLConnectionPool(connectionString: connectionString, poolSize: 10) {
  return MySQL.MySQLConnection()
}

// Create handlers
let handlers = Handlers(connectionPool: pool)

// Create router
let router = Router()

// Handle HTTP GET requests to /
router.get("/activities", handler: handlers.getActivities)

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
