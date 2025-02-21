import app/router
import app/web
import envoy
import gleam/erlang/process
import gleam/io
import gleam/result
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn read_connection_uri() -> Result(pog.Connection, Nil) {
  io.println("Attempting to connect to database...")
  use database_url <- result.try(envoy.get("DATABASE_URL"))
  use config <- result.try(pog.url_config(database_url))
  Ok(pog.connect(config))
}

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  // Connect to postgres database here
  use db <- result.try(read_connection_uri())

  wisp.log_info("Connected to Postgres database.")

  // Handle the database connection here
  let context = web.Context(db: db)
  let handler = router.handle_request(_, context)

  wisp.log_info("Request handler initialized.")

  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  wisp.log_info("Server started.")

  process.sleep_forever()

  Ok(Nil)
}
