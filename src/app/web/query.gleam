import app/web
import gleam/dynamic/decode
import pog

pub fn run_query(
  query: String,
  decoder: decode.Decoder(a),
  ctx: web.Context,
) -> Result(pog.Returned(a), Nil) {
  let conn = ctx.db

  case
    pog.query(query)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Ok(results) -> Ok(results)
    Error(_) -> Error(Nil)
  }
}
