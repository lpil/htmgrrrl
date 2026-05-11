import gleeunit
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
  let assert Ok([
    event13,
    event12,
    event11,
    event10,
    event9,
    event8,
    event7,
    event6,
    event5,
    event4,
    event3,
    event2,
    event1,
  ]) = htmgrrrl.sax("<h1>Hello, Joe!</h1>", [], accumulate)
  let ns = "http://www.w3.org/1999/xhtml"

  assert event1 == #(StartDocument, 1)
  assert event2 == #(StartPrefixMapping("", ns), 1)
  assert event3 == #(StartElement(ns, "html", #("", "html"), []), 1)
  assert event4 == #(StartElement(ns, "head", #("", "head"), []), 1)
  assert event5 == #(EndElement(ns, "head", #("", "head")), 1)
  assert event6 == #(StartElement(ns, "body", #("", "body"), []), 1)
  assert event7 == #(StartElement(ns, "h1", #("", "h1"), []), 1)
  assert event8 == #(Characters("Hello, Joe!"), 1)
  assert event9 == #(EndElement(ns, "h1", #("", "h1")), 1)
  assert event10 == #(EndElement(ns, "body", #("", "body")), 1)
  assert event11 == #(EndElement(ns, "html", #("", "html")), 1)
  assert event12 == #(EndPrefixMapping(""), 1)
  assert event13 == #(EndDocument, 1)
}

pub fn example_test() {
  let take_text = fn(state, _line, event) {
    case event {
      Characters(text) -> [text, ..state]
      _ -> state
    }
  }

  assert htmgrrrl.sax("<p>Hello, Joe!</p><p>Hello, Mike!</p>", [], take_text)
    == Ok(["Hello, Mike!", "Hello, Joe!"])
}
