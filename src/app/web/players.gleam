import app/web.{type Context}
import app/web/query
import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/int
import gleam/io
import gleam/list.{each}
import gleam/string_tree
import pog
import wisp.{type Request, type Response}

// [GET] /players/::id
// Returns: Player fields as Response
pub fn one(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    Get -> read_player(ctx, id)
    _ -> wisp.method_not_allowed([Get])
  }
}

// [POST] /players/post_user_id
// Returns: "Success" or "Failure"
pub fn print_user_data(req: Request, ctx: Context) -> Response {
  use req_body <- wisp.require_json(req)

  case req.method {
    Post -> {
      process_player_data(ctx, req_body)
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn process_player_data(_ctx: Context, json_body: dynamic.Dynamic) -> Response {
  let player_decoder = {
    use account_hash <- decode.field("accountHash", decode.string)
    use username <- decode.field("username", decode.string)
    use skills <- decode.field("skills", decode.dict(decode.string, decode.int))
    decode.success(#(account_hash, username, skills))
  }

  let result = decode.run(json_body, player_decoder)

  case result {
    Ok(#(_account_hash, _username, skills)) -> {
      let skill_names = [
        "Agility", "Attack", "Construction", "Cooking", "Crafting", "Defence",
        "Farming", "Firemaking", "Fishing", "Fletching", "Herblore", "Hitpoints",
        "Hunter", "Magic", "Mining", "Prayer", "Ranged", "Runecraft", "Slayer",
        "Smithing", "Strength", "Thieving", "Woodcutting",
      ]

      let print_skill_xps = fn(skill_name) {
        case dict.get(skills, skill_name) {
          Ok(xp) -> io.println(skill_name <> " XP: " <> int.to_string(xp))
          Error(_) -> io.println(skill_name <> " XP: 0")
        }
      }

      each(skill_names, print_skill_xps)

      Nil
    }
    _ -> {
      io.println("an error or some shit")
    }
  }

  wisp.json_response(string_tree.from_string("{\"message\": \"Success\"}"), 200)
}

// [fn] 
// Returns: Player row matching id as Response
fn read_player(ctx: Context, id: String) -> Response {
  let single_id_query = "SELECT * FROM players where account_hash = " <> id

  let player_decoder = {
    use account_hash <- decode.field(0, decode.int)
    use username <- decode.field(1, decode.string)
    decode.success(#(account_hash, username))
  }

  let results = query.run_query(single_id_query, player_decoder, ctx)

  case results {
    Ok(pog.Returned(_, [#(account_hash, username)])) -> {
      wisp.json_response(
        string_tree.from_string(
          "{\"account_hash\": "
          <> int.to_string(account_hash)
          <> ", \"username\": "
          <> username
          <> "}",
        ),
        200,
      )
    }
    Ok(_) ->
      wisp.json_response(
        string_tree.from_string("{\"error\": \"Data format not matched\"}"),
        404,
      )
    Error(_) -> {
      wisp.json_response(
        string_tree.from_string("{\"error\": \"User not found\"}"),
        404,
      )
    }
  }
}
