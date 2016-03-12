package simtick

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class SimtickSimulation extends Simulation {
  val httpConf = http.baseURL("http://localhost:3000")

  val scn = scenario("SimtickSimulation").exec(
      http("top").get("/")
  )

  setUp(
    scn.inject(
      rampUsersPerSec(10) to 100 during(20 seconds)
    )
  ).protocols(httpConf)

}
