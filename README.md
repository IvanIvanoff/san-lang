# SanLang

- [SanLang](#sanlang)
  - [Overview](#overview)
  - [Why a language?](#why-a-language)
  - [Technologies used](#technologies-used)
  - [Language overview](#language-overview)
  <!--toc:end-->

## Overview

`SanLang` is a small interpreted language that can execute expressions like `flat_map(map_keys(@projects), fn slug -> @projects[slug]["github_organizations"]`.

To improve the templating engine capabilities for Queries 2.0 we introduce **SanLang** -- an interpreted language inspired by the Elixir syntax.

We want to provide the ability for small code snippets (one-liners in most cases) that extract and manipulate some data.

For example, if a user wants to add a text widget with `About the author` information, the user doesn't have to hardcode the email/twitter/telegram/etc. links, but can use code like `Email: {{@owner["email"}}, Twitter: {{@owner.twitter_handle}}`

The identifiers starting with `@` are provided as environment bindings by the backend and the user has access to it without doing anything else.

## Why a language?

We want to allow the users to write **code** that is executed on the **backend**. To allow this, we need to be _very careful_ in what and how we allow it to be executed.

Doing `String.split`/`Regex.scan`/etc. parsing won't suffice, or it will be much more complicated and hard to maintain and debug.
Allowing users to write Elixir code will force either to analyze all the code for un-safe operations `System.cmd`/`http calls`/etc. and it can be hard to verify that it is indeed safe.

Using a separate language like python/lua/etc. will require us to add this language compiler/interpreter as a dependency **and** support inter-language compatibility.

Executing Elixir in a safe environment (container/jail/etc.) will also induce complexity.

Considering all these precautions, developing a new small language does not sound so terrible.

## Technologies used

The `SanLang` language has three main components: lexer, parser, and interpreter.

- The lexer and parser how the input is tokenized and parsed -- validating the syntax and building an abstract syntax tree.
- The lexer and parser are written declaratively in [leex](https://www.erlang.org/doc/man/leex.html) and [yecc](https://www.erlang.org/doc/man/yecc.html). These are the Erlang equivalent of `lex` and `yacc` tools for LALR(1) parsing.
- The lexer and parser together are ~120 lines of code, which includes support for: named functions, env vars, local vars, lambda functions, chained access operator, arithmetic operations.
- The interpreter is written in Elixir and translates the AST to elixir code and executes it.
- The interpreter produces Elixir values as result, which makes it trivial to use the result in the backend without any transformations.

## Language overview

The following are valid SanLang expressions:

- Literals evaluate to themselves: `1`, `"string"`, `3.14`;
- Special boolean literals `true` and `false`;
- Basic arithmetic with proper precedence: `1 + 2*3 + 10` evaluates to 17;
- Named functions with literal arguments: `pow(10,18)`, `div(6,4)` (for integer division);
- Access to environment variables that are provided by the execution environment: `@projects`
- Access operator, `map` function and lambda functions for working with this environment variables. See below for more examples.
- Access operator that can be chained: `@projects["santiment"]["main_contract_address"]["decimals"]`
- Comparisons operators: `1 == 1`, `1 != 2`, `1 > 2`, `1 < 2`, `1 >= 2`, `1 <= 2`;
- Boolean operators `and` and `or`: `true and false`, `true or false`;
- Proper precedence of boolean/comparison/arithmetic operators: `5 + 6 < 10`, `pow(2, 10) - 1 < 1024 and pow(2,10) + 1 > 1024`.

Examples:

- Get the list of all slugs from the `@projects` map:
  `map_keys(@projects)`
- Get the token decimals for sentiment:
  `@projects["sentiment"]["main_contract_address"]["decimals"]
- Get all github organizations of all projects in a list:
  `flat_map(map_keys(@projects), fn slug -> @projects[slug]["github_organizations"] end)`
- Get the email address of the owner of the dashboard:
  `@owner["email"]`
- `filter(@data, fn x -> x > 1 and x < 10 end)`
- See `san_lang_test.exs` for more examples.
