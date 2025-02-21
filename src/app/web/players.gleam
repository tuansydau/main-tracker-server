import app/web.{type Context}
import app/web/query
import gleam/dynamic/decode
import gleam/http.{Get}
import gleam/int
import gleam/string_tree
import pog
import wisp.{type Request, type Response}

// GET
// players/::id
// Returns the row item for the player with the given id minus skills
pub fn one(req: Request, ctx: Context, id: String) {
  case req.method {
    Get -> read_player(ctx, id)
    _ -> wisp.method_not_allowed([Get])
  }
}

pub fn read_player(ctx: Context, id: String) -> Response {
  let single_id_query = "SELECT * FROM players where id = " <> id

  let player_decoder = {
    use id <- decode.field(0, decode.int)
    use username <- decode.field(1, decode.string)
    decode.success(#(id, username))
  }

  let results = query.run_query(single_id_query, player_decoder, ctx)

  case results {
    Ok(pog.Returned(_, [#(id, username)])) -> {
      wisp.json_response(
        string_tree.from_string(
          "{\"id\": "
          <> int.to_string(id)
          <> ", \"username\": "
          <> username
          <> "}",
        ),
        200,
      )
    }
    Ok(_) ->
      wisp.json_response(
        string_tree.from_string("{\"error\": \"User not found\"}"),
        404,
      )
    Error(_) ->
      wisp.json_response(
        string_tree.from_string("{\"error\": \"User not found\"}"),
        404,
      )
  }
}
