import envoy
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/result
import pog

pub fn read_connection_uri() -> Result(pog.Connection, Nil) {
  io.println("Attempting to connect to database...")
  use database_url <- result.try(envoy.get("DATABASE_URL"))
  use config <- result.try(pog.url_config(database_url))
  Ok(pog.connect(config))
}

pub fn main() {
  let sql_query = "select id from players where username = 'moo shu pork'"
  let skills_query = "select * from skills where user_id = $1"
  let row_decoder = {
    use id <- decode.field(0, decode.int)
    decode.success(id)
  }

  case read_connection_uri() {
    Ok(conn) -> {
      case
        pog.query(sql_query)
        |> pog.returning(row_decoder)
        |> pog.execute(conn)
      {
        Ok(results) -> {
          io.debug(results)
          Nil
        }
        Error(err) -> {
          case err {
            pog.ConstraintViolated(message, _constaint, _detail) ->
              io.println(message)
            pog.PostgresqlError(_code, _name, message) -> io.println(message)
            pog.UnexpectedArgumentCount(expected, got) ->
              io.println(
                "Unexpected argument count, expected "
                <> int.to_string(expected)
                <> " but got "
                <> int.to_string(got),
              )
            pog.UnexpectedArgumentType(expected, got) ->
              io.println(
                "Unexpected argument type, expected "
                <> expected
                <> " but got "
                <> got,
              )
            pog.UnexpectedResultType(_errors) -> io.println("Failed to decode")
            pog.ConnectionUnavailable -> io.println("Connection unavailable")
            _ -> io.println("Rest")
          }
        }
      }
      Nil
    }
    Error(_err) -> io.println("No idea")
  }
  io.println("completed")
}
