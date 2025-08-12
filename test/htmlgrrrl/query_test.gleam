import birdie
import gleam/list
import gleam/string
import htmgrrrl/query

pub fn html_tree_to_readable_string_test() {
  let html =
    query.Element("div", [#("class", "thingy"), #("data-size", "big")], [
      query.Element("h1", [], [query.Text("Greeting!")]),
      query.Text("Hello"),
      query.Element("br", [], []),
      query.Text("Joe!"),
    ])
  query.html_tree_to_readable_string(html)
  |> birdie.snap("html_tree_to_readable_string_test")
}

fn parse_to_html_tree_snapshot(input: String) -> String {
  let assert Ok(html) = query.parse_to_html_tree(input)
  let output =
    html |> list.map(query.html_tree_to_readable_string) |> string.join("\n")
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

pub fn parse_to_html_tree_3_test() {
  "<p><div class=it>Hello!</div></p>"
  |> parse_to_html_tree_snapshot
  |> birdie.snap("parse_to_html_tree_3_test")
}

pub fn parse_to_html_tree_4_test() {
  "
<span>1</span>
<span>2</span>
"
  |> parse_to_html_tree_snapshot
  |> birdie.snap("parse_to_html_tree_4_test")
}

pub fn parse_to_html_tree_5_test() {
  "
<span>1</span>
<span>2</span>
<span>3</span>
<span>4</span>
"
  |> parse_to_html_tree_snapshot
  |> birdie.snap("parse_to_html_tree_5_test")
}

pub fn find_element_by_id_test() {
  let query = query.element(matching: query.id("login-form"))
  let assert Ok(element) = query.find_all(page, query)

  element
  |> to_snapshot(query)
  |> birdie.snap("[find] Login form by id")
}

pub fn find_element_by_tag_test() {
  let query = query.element(query.tag("h1"))
  let assert Ok(element) = query.find_all(page, query)

  element
  |> to_snapshot(query)
  |> birdie.snap("[find] Wordmark by tag")
}

pub fn find_element_by_class_test() {
  let query = query.element(query.class("cta"))
  let assert Ok(element) = query.find_all(page, query)

  element
  |> to_snapshot(query)
  |> birdie.snap("[find] Call to action button by class")
}

pub fn find_element_by_multiple_classes_test() {
  let query = query.element(query.class("content hero"))
  let assert Ok(element) = query.find_all(page, query)

  element
  |> to_snapshot(query)
  |> birdie.snap("[find] Hero section by multiple classes")
}

// pub fn find_element_by_inline_style_test() {
//   let query = query.element(style("list-style-type", "none"))
//   let assert Ok(element) = query.find_all(page, query)
//
//   element
//   |> to_snapshot(query)
//   |> birdie.snap("[find] Features list by inline style")
// }
//
// pub fn find_element_by_text_content_test() {
//   let query = query.element(text("©"))
//   let assert Ok(element) = query.find_all(page, query)
//
//   element
//   |> to_snapshot(query)
//   |> birdie.snap("[find] Copyright notice by text")
// }
//
// pub fn find_child_by_tag_test() {
//   let query = query.element(query.tag("form")) |> query.child(query.tag("h2"))
//   let assert Ok(element) = query.find_all(page, query)
//
//   element
//   |> to_snapshot(query)
//   |> birdie.snap("[find] Login form title by child selector")
// }
//
// pub fn find_child_descendant_by_data_attribute_test() {
//   let query =
//     query.element(query.tag("header"))
//     |> query.child(query.tag("nav"))
//     |> query.descendant(query.tag("a") |> and(data("active", "true")))
//   let assert Ok(element) = query.find_all(page, query)
//
//   element
//   |> to_snapshot(query)
//   |> birdie.snap("[find] Active link by child and descendant selector")
// }
//
pub fn find_descendant_by_attribute_test() {
  let query =
    query.element(query.tag("form"))
    |> query.descendant(
      query.tag("button") |> query.and(query.attribute("type", "submit")),
    )
  let assert Ok(element) = query.find_all(page, query)

  element
  |> to_snapshot(query)
  |> birdie.snap("[find] Submit button by descendant selector")
}

pub fn find_all_by_tag_test() {
  let query = query.element(query.tag("section"))
  let assert Ok([_, ..] as elements) = query.find_all(page, query)

  elements
  |> to_snapshot(query)
  |> birdie.snap("[find_all] All sections by tag")
}

pub fn find_all_by_attribute_test() {
  let query = query.element(query.attribute("href", ""))
  let assert Ok([_, ..] as elements) = query.find_all(page, query)
  echo elements

  elements
  |> to_snapshot(query)
  |> birdie.snap("[find_all] All links with href attribute")
}

pub fn find_all_by_class_test() {
  let query = query.element(query.class("vertical-nav"))
  let assert Ok([_, ..] as elements) = query.find_all(page, query)

  elements
  |> to_snapshot(query)
  |> birdie.snap("[find_all] All footer nav sections by class")
}

fn to_snapshot(elements: List(query.HtmlTree), query: query.Query) -> String {
  let elements_snapshot =
    list.map(elements, fn(element) {
      element
      |> query.html_tree_to_readable_string
      |> string.replace("\n", "\n  ")
    })

  let query_snapshot = query.query_to_string(query)

  "
Query:

  ${query}

Match:

  ${elements}"
  |> string.replace("${query}", query_snapshot)
  |> string.replace("${elements}", string.join(elements_snapshot, "\n  "))
}

const page: String = "
<header>
  <h1>
    Lustre Labs
  </h1>
  <nav>
    <ul class=\"horizontal-nav\">
      <li>
        <a data-active=\"true\" href=\"/\">
          Home
        </a>
      </li>
      <li>
        <a href=\"/contact\">
          Contact
        </a>
      </li>
    </ul>
  </nav>
</header>
<div>
  <main class=\"hero\">
    <form id=\"login-form\">
      <h2>
        Login
      </h2>
      <label>
        <p>
          Email
        </p>
        <input name=\"email\" type=\"email\">
      </label>
      <label>
        <p>
          Password
        </p>
        <input name=\"password\" type=\"password\">
      </label>
      <div class=\"form-actions\">
        <button class=\"primary\" type=\"submit\">
          Sign In
        </button>
        <a href=\"/forgot-password\">
          Forgot Password?
        </a>
      </div>
      <p class=\"form-footer\">
        Don&#39;t have an account?
        <a href=\"/signup\">
          Sign up
        </a>
      </p>
    </form>
  </main>
  <section class=\"hero content\">
    <h2>
      The Universal Framework
    </h2>
    <p>
      Static HTML, SPAs, Web Components, and interactive Server Components.
    </p>
    <button class=\"cta\">
      Get Started
    </button>
  </section>
  <section class=\"content\">
    <h2>
      Features
    </h2>
    <ul style=\"list-style-type:none;\">
      <li>
        Feature 1
      </li>
      <li>
        Feature 2
      </li>
      <li>
        Feature 3
      </li>
    </ul>
  </section>
  <section class=\"content\">
    <h2>
      Testimonials
    </h2>
    <div>
      <blockquote>
        <p>
          Lustre is amazing!
        </p>
        <cite>
          John Doe
        </cite>
      </blockquote>
      <blockquote>
        <p>
          I love using Lustre!
        </p>
        <cite>
          Jane Smith
        </cite>
      </blockquote>
    </div>
  </section>
</div>
<footer>
  <p>
    Built with 💕 by Lustre Labs
  </p>
  <nav>
    <ul class=\"vertical-nav\">
      <h2>
        Lustre Pro
      </h2>
      <li>
        <a href=\"/dashboard\">
          Dashboard
        </a>
      </li>
      <li>
        <a href=\"/faq\">
          FAQ
        </a>
      </li>
      <li>
        <a href=\"/pricing\">
          Pricing
        </a>
      </li>
    </ul>
    <ul class=\"vertical-nav\">
      <h2>
        Lustre
      </h2>
      <li>
        <a href=\"https://hexdocs.pm/lustre\">
          Documentation
        </a>
      </li>
      <li>
        <a href=\"https://github.com/lustre-labs/lustre\">
          GitHub
        </a>
      </li>
    </ul>
    <ul class=\"vertical-nav\">
      <h2>
        Legal
      </h2>
      <li>
        <a href=\"/terms-of-service\">
          Terms of service
        </a>
      </li>
      <li>
        <a href=\"/privacy-policy\">
          Privacy policy
        </a>
      </li>
      <li>
        <a href=\"/impressum\">
          Impressum
        </a>
      </li>
    </ul>
  </nav>
  <p>
    © 2025 Lustre Labs BV.
    <br>
    All rights reserved.
  </p>
</footer>
"
