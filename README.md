# htmgrrrl

[![Package Version](https://img.shields.io/hexpm/v/htmgrrrl)](https://hex.pm/packages/htmgrrrl)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/htmgrrrl/)

Gleam bindings to htmerl, the fast and memory efficient Erlang HTML SAX parser.

```gleam
pub fn main_test() {
  let take_text = fn(state, _line, event) {
    case event {
      Characters(text) -> [text, ..state]
      _ -> state
    }
  }

  "<p>Hello, Joe!</p><p>Hello, Mike!</p>"
  |> htmgrrrl.sax([], take_text)
  |> should.equal(Ok(["Hello, Mike!", "Hello, Joe!"]))
}
```

## Installation

This package can be added to your Gleam project:

```sh
gleam add htmgrrrl
```

and its documentation can be found at <https://hexdocs.pm/htmgrrrl>.

## What's with the name?

It's a Gleam-y play on "htmerl" that makes a nod to [Riot Grrrl](https://en.wikipedia.org/wiki/Riot_grrrl).
