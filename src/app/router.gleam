import app/web.{type Context}
import app/web/players
import gleam/io
import gleam/string_tree
import wisp.{type Request, type Response}

// Router for all api requests
pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    // Response returns all fields of player::id
    ["players", id] -> {
      wisp.log_info("endpoint: /players/" <> id <> "/")
      players.one(req, ctx, id)
    }
    ["print_user_data"] -> {
      wisp.log_info("endpoint: /print_user_data" <> "/")
      players.print_user_data(req, ctx)
    }
    // Rest not implemented
    _ -> {
      io.debug(wisp.path_segments)
      wisp.json_response(
        string_tree.from_string("{\"Error\":\"Uncaught path in router\"}"),
        200,
      )
    }
  }
}
