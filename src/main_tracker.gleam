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

pub fn run_query(query, decoder) -> Result(pog.Returned(a), Nil) {
  case read_connection_uri() {
    Ok(conn) -> {
      case
        pog.query(query)
        |> pog.returning(decoder)
        |> pog.execute(conn)
      {
        Ok(results) -> {
          Ok(results)
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
          Error(Nil)
        }
      }
    }
    Error(_err) -> {
      io.println("Connection to database failed")
      Error(Nil)
    }
  }
}

pub fn main() {
  // Declare SQL queries and type decoders 

  // 1. Username to pid operations
  // let username_to_id = "select id from players where username = 'moo shu pork'"
  // let id_decoder = {
  //   use id <- decode.field(0, decode.int)
  //   decode.success(id)
  // }

  // 2. User Id to Skills list operations
  let id_to_skills = "select * from skills where user_id = 1"
  let skills_decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.int)
    use skill_name <- decode.field(2, decode.string)
    use level <- decode.field(3, decode.int)
    decode.success(#(id, user_id, skill_name, level))
  }

  case run_query(id_to_skills, skills_decoder) {
    Ok(result) -> {
      io.debug(result)
      Nil
    }
    _ -> {
      io.debug("idgaf man")
      Nil
    }
  }

  io.println("completed")
}
