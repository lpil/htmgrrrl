import birdie
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import htmgrrrl.{
  type SaxEvent, Characters, EndDocument, EndElement, EndPrefixMapping,
  StartDocument, StartElement, StartPrefixMapping,
}

pub fn main() {
  gleeunit.main()
}

fn accumulate(
  state: List(#(SaxEvent, Int)),
  line: Int,
  event: SaxEvent,
) -> List(#(SaxEvent, Int)) {
  [#(event, line), ..state]
}

pub fn basic_test() {
  "<h1>Hello, Joe!</h1>"
  |> htmgrrrl.sax([], accumulate)
  |> should.equal(
    Ok([
      #(EndDocument, 1),
      #(EndPrefixMapping(""), 1),
      #(EndElement("http://www.w3.org/1999/xhtml", "html", #("", "html")), 1),
      #(EndElement("http://www.w3.org/1999/xhtml", "body", #("", "body")), 1),
      #(Characters("Hello, Joe!"), 1),
      #(
        StartElement("http://www.w3.org/1999/xhtml", "body", #("", "body"), []),
        1,
      ),
      #(EndElement("http://www.w3.org/1999/xhtml", "head", #("", "head")), 1),
      #(
        StartElement("http://www.w3.org/1999/xhtml", "head", #("", "head"), []),
        1,
      ),
      #(
        StartElement("http://www.w3.org/1999/xhtml", "html", #("", "html"), []),
        1,
      ),
      #(StartPrefixMapping("", "http://www.w3.org/1999/xhtml"), 1),
      #(StartDocument, 1),
    ]),
  )
}

pub fn example_test() {
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

pub fn html_tree_to_readable_string_test() {
  let html =
    htmgrrrl.Element("div", [#("class", "thingy"), #("data-size", "big")], [
      htmgrrrl.Element("h1", [], [htmgrrrl.Text("Greeting!")]),
      htmgrrrl.Text("Hello"),
      htmgrrrl.Element("br", [], []),
      htmgrrrl.Text("Joe!"),
    ])
  htmgrrrl.html_tree_to_readable_string(html)
  |> birdie.snap("html_tree_to_readable_string_test")
}

fn parse_to_html_tree_snapshot(input: String) -> String {
  let assert Ok(html) = htmgrrrl.parse_to_html_tree(input)
  let output =
    html |> list.map(htmgrrrl.html_tree_to_readable_string) |> string.join("\n")
  input <> "\n----------------------------------------------\n\n" <> output
}

pub fn parse_to_html_tree_0_test() {
  "<html>
  <head>
  </head>
  <body>
    <h1>
      Hello!
    </h1>
    <p>
      How ya be getting on?
      <br>
      Good I hope.
    </p>
  </body>
</html>
"
  |> parse_to_html_tree_snapshot
  |> birdie.snap("parse_to_html_tree_0_test")
}

pub fn parse_to_html_tree_1_test() {
  "<h1>
    Hello!
  </h1>
  <p>
    How ya be getting on?
    <br>
    Good I hope.
  </p>
"
  |> parse_to_html_tree_snapshot
  |> birdie.snap("parse_to_html_tree_1_test")
}

pub fn parse_to_html_tree_2_test() {
  "<p>sup!</p>"
  |> parse_to_html_tree_snapshot
  |> birdie.snap("parse_to_html_tree_2_test")
}
