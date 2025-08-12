import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import houdini
import htmgrrrl.{
  AttributeDeclaration, Characters, Comment, ElementDecl, EndCdata, EndDocument,
  EndDtd, EndElement, EndPrefixMapping, ExternalEntityDeclaration,
  IgnorableWhitespace, InternalEntityDeclaration, NotationDeclaration,
  ProcessingInstruction, StartCdata, StartDocument, StartDtd, StartElement,
  StartPrefixMapping, UnparsedEntityDeclaration,
}

/// A type that represents a tree of HTML.
pub type HtmlTree {
  Element(
    tag: String,
    attributes: List(#(String, String)),
    children: List(HtmlTree),
  )
  Text(String)
}

pub fn html_tree_to_readable_string(html: HtmlTree) -> String {
  case readable("", html, 0) {
    "" -> ""
    out -> out <> "\n"
  }
}

fn readable(out: String, html: HtmlTree, level: Int) -> String {
  let indent = string.repeat("  ", level)
  case html {
    Text(text) -> out <> indent <> houdini.escape(text)

    Element(tag: "area" as tag, attributes:, ..)
    | Element(tag: "base" as tag, attributes:, ..)
    | Element(tag: "br" as tag, attributes:, ..)
    | Element(tag: "col" as tag, attributes:, ..)
    | Element(tag: "embed" as tag, attributes:, ..)
    | Element(tag: "hr" as tag, attributes:, ..)
    | Element(tag: "img" as tag, attributes:, ..)
    | Element(tag: "input" as tag, attributes:, ..)
    | Element(tag: "link" as tag, attributes:, ..)
    | Element(tag: "meta" as tag, attributes:, ..)
    | Element(tag: "source" as tag, attributes:, ..)
    | Element(tag: "track" as tag, attributes:, ..)
    | Element(tag: "wbr" as tag, attributes:, ..) -> {
      let out = out <> indent <> "<" <> tag
      let out =
        list.fold(attributes, out, fn(out, attribute) {
          out <> " " <> attribute.0 <> "=\"" <> attribute.1 <> "\""
        })
      out <> ">"
    }

    Element(tag:, attributes:, children:) -> {
      let out = out <> indent <> "<" <> tag
      let out =
        list.fold(attributes, out, fn(out, attribute) {
          out <> " " <> attribute.0 <> "=\"" <> attribute.1 <> "\""
        })
      let out = out <> ">"
      let out =
        list.fold(children, out, fn(out, element) {
          let out = out <> "\n"
          readable(out, element, level + 1)
        })
      out <> "\n" <> indent <> "</" <> tag <> ">"
    }
  }
}

pub fn parse_to_html_tree(html: String) -> Result(List(HtmlTree), Nil) {
  htmgrrrl.sax(html, [], fn(stack, _, event) { sax_event_to_tree(stack, event) })
}

fn sax_event_to_tree(
  stack: List(HtmlTree),
  event: htmgrrrl.SaxEvent,
) -> List(HtmlTree) {
  case event {
    StartDocument
    | EndDocument
    | StartPrefixMapping(..)
    | EndPrefixMapping(..)
    | IgnorableWhitespace(..)
    | ProcessingInstruction(..)
    | Comment(..)
    | StartCdata
    | EndCdata
    | StartDtd(..)
    | EndDtd
    | ElementDecl(..)
    | InternalEntityDeclaration(..)
    | ExternalEntityDeclaration(..)
    | UnparsedEntityDeclaration(..)
    | NotationDeclaration(..)
    | AttributeDeclaration(..) -> stack

    StartElement(local_name:, attributes:, ..) -> {
      let attributes =
        list.map(attributes, fn(attr) { #(attr.name, attr.value) })
      let element = Element(tag: local_name, attributes:, children: [])
      [element, ..stack]
    }

    EndElement(local_name:, ..) -> {
      case stack {
        [
          Element(tag:, attributes:, children:),
          Element(tag: p_tag, attributes: p_attributes, children: siblings),
          ..stack
        ] -> {
          let element = Element(tag, attributes, list.reverse(children))
          let parent = Element(p_tag, p_attributes, [element, ..siblings])
          [parent, ..stack]
        }

        [Element(tag:, attributes:, children:), ..stack] -> {
          let element = Element(tag, attributes, list.reverse(children))
          [element, ..stack]
        }

        _ -> panic as "EndElement event without StartElement event"
      }
    }

    Characters("") -> stack

    Characters(text) ->
      case stack {
        [Element(tag:, attributes:, children:), ..stack] -> {
          let element = Element(tag, attributes, [Text(text), ..children])
          [element, ..stack]
        }
        _ -> panic as "EndElement event without StartElement event"
      }
  }
}

// Query

pub opaque type Query {
  FindElement(Selector)
  // FineChild(parent: Selector, child: Query)
  FindDescendant(parent: Query, child: Selector)
}

/// A `Selector` describes how to match a specific element in an `Element` tree.
/// It might be the element's tag name, a class name, an attribute, or some
/// combination of these.
///
pub opaque type Selector {
  HasAll(List(Selector))
  HasType(namespace: String, tag: String)
  HasAttribute(name: String, value: String)
  HasClass(name: String)
  // // HasStyle(name: String, value: String)
  // // Contains(content: String)
}

/// Find any elements in a view that match the given [`Selector`](#Selector).
///
pub fn element(matching selector: Selector) -> Query {
  FindElement(selector)
}

/// Given a `Query` that finds an element, find any of that element's _descendants_
/// that match the given [`Selector`](#Selector). This will walk the entire tree
/// from the matching parent.
///
pub fn descendant(of parent: Query, matching selector: Selector) -> Query {
  FindDescendant(parent, selector)
}

/// Select elements based on their tag name, like `"div"`, `"span"`, or `"a"`.
/// To select elements with an XML namespace - such as SVG elements - use the
/// [`namespaced`](#namespaced) selector instead.
///
pub fn tag(value: String) -> Selector {
  HasType(namespace: "http://www.w3.org/1999/xhtml", tag: value)
}

/// Select elements based on their tag name and XML namespace. This is useful
/// for selecting SVG elements or other elements that have a namespace.
///
pub fn namespaced(namespace: String, tag: String) -> Selector {
  HasType(namespace:, tag:)
}

/// Select elements that have the specified attribute with the given value. If
/// the value is left blank, this selector will match any element that has the
/// attribute, _regardless of its value_.
///
pub fn attribute(name: String, value: String) -> Selector {
  HasAttribute(name:, value:)
}

/// Select elements that include the given space-separated class name(s).
///
/// If you need to match the class attribute exactly, you can use the [`attribute`](#attribute)
/// selector instead.
///
pub fn class(name: String) -> Selector {
  HasClass(name)
}

/// Select an element based on its `id` attribute. Well-formed HTML means that
/// only one element should have a given id.
///
pub fn id(name: String) -> Selector {
  HasAttribute(name: "id", value: name)
}

/// Select elements that have the given `data-*` attribute.
///
pub fn data(name: String, value: String) -> Selector {
  HasAttribute(name: "data-" <> name, value: value)
}

/// It is a common convention to use the `data-test-id` attribute to mark elements
/// for easy selection in tests. This function is a shorthand for writing
/// `query.data("test-id", value)`
///
pub fn test_id(value: String) -> Selector {
  data("test-id", value)
}

/// Select elements that have the given `aria-*` attribute.
///
pub fn aria(name: String, value: String) -> Selector {
  HasAttribute(name: "aria-" <> name, value: value)
}

type Finder {
  Finder(
    found: List(HtmlTree),
    current: List(HtmlTree),
    query: List(Selector),
    past: List(Option(Selector)),
  )
}

fn query_to_list(query: Query, out: List(Selector)) -> List(Selector) {
  case query {
    FindDescendant(parent:, child:) -> query_to_list(parent, [child, ..out])
    FindElement(selector) -> [selector, ..out]
  }
}

/// Find the first element in a view that matches the given [`Query`](#Query).
///
pub fn find_all(
  in html: String,
  matching query: Query,
) -> Result(List(HtmlTree), Nil) {
  let query = query_to_list(query, [])
  let state = Finder(found: [], current: [], query:, past: [])
  htmgrrrl.sax(html, state, fn(state, _, event) {
    case event {
      AttributeDeclaration(..)
      | Comment(_)
      | ElementDecl(..)
      | EndCdata
      | EndDocument
      | EndDtd
      | EndPrefixMapping(..)
      | ExternalEntityDeclaration(..)
      | IgnorableWhitespace(_)
      | InternalEntityDeclaration(..)
      | NotationDeclaration(..)
      | ProcessingInstruction(..)
      | StartCdata
      | StartDocument
      | StartDtd(..)
      | StartPrefixMapping(..)
      | UnparsedEntityDeclaration(..) -> state

      Characters(_) -> {
        case state.query {
          [] -> {
            let current = sax_event_to_tree(state.current, event)
            Finder(..state, current:)
          }
          _ -> state
        }
      }

      StartElement(uri: namespace, local_name: tag, attributes:, ..) -> {
        case state.query {
          // We have found a new element that is a descendent of one that matched
          [] -> {
            let current = sax_event_to_tree(state.current, event)
            let past = [None, ..state.past]
            Finder(..state, current:, past:)
          }

          [selector] ->
            // We have found a new element that itself matches
            case selector_matches(selector, namespace, tag, attributes) {
              True -> {
                let current = sax_event_to_tree(state.current, event)
                let past = [Some(selector), ..state.past]
                Finder(..state, query: [], past:, current:)
              }
              False -> {
                let past = [None, ..state.past]
                Finder(..state, past:)
              }
            }

          [selector, ..query] ->
            // We have found a new element that itself matches this first part
            // of the query, but there is yet more to come.
            case selector_matches(selector, namespace, tag, attributes) {
              True -> {
                let past = [Some(selector), ..state.past]
                Finder(..state, query: query, past:)
              }
              False -> {
                let past = [None, ..state.past]
                Finder(..state, past:)
              }
            }
        }
      }

      EndElement(..) -> {
        let current = case state.query {
          [] -> sax_event_to_tree(state.current, event)
          _ -> state.current
        }
        case state.past {
          // We are still inside the element that matched the query, continue
          // collecting elements.
          [None, ..past] -> {
            Finder(..state, current:, past:)
          }
          // We have reached the end of the element that matched the query,
          // move it to "found" now that we have collected it and its descendants.
          [Some(selector), ..past] -> {
            let found = list.append(current, state.found)
            let query = [selector, ..state.query]
            Finder(current: [], found:, past:, query:)
          }
          [] -> panic as "empty past for end element should not be possible"
        }
      }
    }
  })
  |> result.map(fn(state) { list.reverse(state.found) })
}

fn selector_matches(
  selector: Selector,
  namespace: String,
  tag: String,
  attributes: List(htmgrrrl.Attribute),
) -> Bool {
  case selector {
    HasAll(selectors) ->
      list.all(selectors, selector_matches(_, namespace, tag, attributes))
    HasType(namespace: n, tag: t) -> tag == t && namespace == n
    HasAttribute(name:, value:) -> has_attribute(name, value, attributes)
    HasClass(name:) -> {
      let desired = name |> string.split(" ") |> list.filter(fn(n) { n != "" })
      list.any(attributes, fn(attribute) {
        list.all(desired, fn(name) {
          attribute.name == "class"
          && {
            attribute.value == name
            || string.starts_with(attribute.value, name <> " ")
            || string.ends_with(attribute.value, " " <> name)
            || string.contains(attribute.value, " " <> name <> " ")
          }
        })
      })
    }
  }
}

fn has_attribute(
  name: String,
  value: String,
  attributes: List(htmgrrrl.Attribute),
) -> Bool {
  list.any(attributes, fn(attr) {
    name == attr.name && { value == "" || value == attr.value }
  })
}

pub fn query_to_string(query: Query) -> String {
  case query {
    FindElement(selector) -> selector_to_string(selector)
    // FindChild(of: parent, selector) ->
    //   query_to_string(parent) <> " > " <> selector_to_string(selector)
    FindDescendant(parent, selector) ->
      query_to_string(parent) <> " " <> selector_to_string(selector)
  }
}

fn selector_to_string(selector: Selector) -> String {
  case selector {
    HasAll(selectors) ->
      selectors
      |> sort_selectors
      |> list.map(selector_to_string)
      |> string.concat
    HasType("http://www.w3.org/1999/xhtml", tag) -> tag
    HasType(namespace:, tag:) -> namespace <> ":" <> tag
    HasAttribute(name: "id", value:) -> "#" <> value
    HasAttribute(name:, value: "") -> "[" <> name <> "]"
    HasAttribute(name:, value:) -> "[" <> name <> "=\"" <> value <> "\"]"
    HasClass(name:) -> "." <> name
  }
}

fn sort_selectors(selectors: List(Selector)) -> List(Selector) {
  use a, b <- list.sort({
    use selector <- list.flat_map(selectors)

    case selector {
      HasAll(selectors) -> selectors
      _ -> [selector]
    }
  })

  case a, b {
    HasAll(..), _ | _, HasAll(..) ->
      panic as "`HasAll` selectors should be flattened"

    HasType(..), HasType(..) ->
      case string.compare(a.namespace, b.namespace) {
        order.Eq -> string.compare(a.tag, b.tag)
        order -> order
      }

    HasType(..), _ -> order.Lt
    _, HasType(..) -> order.Gt

    HasAttribute(name: "id", ..), HasAttribute(name: "id", ..) ->
      string.compare(a.value, b.value)

    HasAttribute(name: "id", ..), _ -> order.Lt
    _, HasAttribute(name: "id", ..) -> order.Gt

    HasAttribute(..), HasAttribute(..) ->
      case string.compare(a.name, b.name) {
        order.Eq -> string.compare(a.value, b.value)
        order -> order
      }

    HasAttribute(..), _ -> order.Lt
    _, HasAttribute(..) -> order.Gt

    HasClass(..), HasClass(..) -> string.compare(a.name, b.name)
  }
}

/// Combine two selectors into one that must match both. For example, if you have
/// a selector for div elements and a selector for elements with the class "wibble"
/// then they can be combined into a selector that matches only div elements with
/// the class "wibble".
///
/// > **Note**: if you find yourself crafting complex selectors, consider using
/// > a test id on the element(s) you want to find instead.
///
pub fn and(first: Selector, second: Selector) -> Selector {
  case first {
    HasAll([]) -> HasAll([second])
    HasAll(others) -> HasAll([second, ..others])
    _ -> HasAll([first, second])
  }
}
