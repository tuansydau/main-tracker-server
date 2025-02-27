import app/web
import gleam/dynamic/decode
import gleam/io
import pog

pub fn run_query(
  query: String,
  decoder: decode.Decoder(a),
  ctx: web.Context,
) -> Result(pog.Returned(a), String) {
  let conn = ctx.db

  case
    pog.query(query)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Ok(results) -> {
      // io.debug(results)
      Ok(results)
    }
    Error(_) -> {
      io.debug(query)
      io.debug(decoder)
      io.debug(conn)
      Error("Query error: Query was unable to run")
    }
  }
}
