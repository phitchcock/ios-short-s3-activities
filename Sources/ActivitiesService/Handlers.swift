import Foundation
import Kitura
import SwiftyJSON
import LoggerAPI
import MySQL

public class Handlers {
    var connectionPool: MySQLConnectionPool

    public init(connectionPool: MySQLConnectionPool) {
        self.connectionPool = connectionPool
    }

    /**
     * Handler for getting an application/json response.
     */
    public func getActivities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        Log.info("GET - /activities route handler...")

        if request.method != RouterMethod.get {
            try response.status(.badRequest).end()
            return
        }

        do {
            let connection = try connectionPool.getConnection()!

            // release the connection back to the pool
            defer {
                connectionPool.releaseConnection(connection)
            }

            let client = MySQLClient(connection: connection)
            let result = client.execute(query: "SELECT * from activities")
            try returnResult(result, response: response)

        } catch {
            Log.error("cannot get connection from pool")
            try response.status(.internalServerError).end()
        }
    }

    private func returnResult(_ result: (MySQLResultProtocol?, error: MySQLError?), response: RouterResponse) throws {

        if let results = result.0 as? MySQLResult {
            let activities = results.toActivities()

            if activities.count > 0 {
                try response.send(json: activities.toJSON()).status(.OK).end()
            } else {
                try response.status(.notFound).end()
            }
        } else {
            Log.error(result.1?.localizedDescription ?? "")
            try response.status(.internalServerError).end()
            return
        }
    }
}
