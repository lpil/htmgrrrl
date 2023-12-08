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
