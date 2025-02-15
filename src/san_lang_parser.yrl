Nonterminals
  grammar
  expr expr_list
  eoe eol
  value
  list list_elements
  dual_arithmetic_op mult_arithmetic_op
  boolean_literal and_op or_op
  comparison_rel_op comparison_comp_op
  access_expr access_expr_key
  parens_call
  function_call_args_list function_call_arg
  lambda_fn lambda_args
  match_op
.

Terminals
  %% boolean values
  'true' 'false'
  %% Types
  int float ascii_string
  %% vars and env vars
  identifier env_var
  %% arithmetic operators
  '+' '-' '*' '/'
  %% comparison operators
  '==' '!=' '<' '<=' '>' '>='
  %% match operator
  '='
  %% other
  '(' ')' '[' ']' ','
  %% lambda tokens
  'fn' '->' 'end'
  %% boolean operators
  'and' 'or'
  %% end of expression
  ';' newline
.

Rootsymbol
   grammar
.

%% Precedence
Right 10 match_op.
Left 50  or_op.
Left 60  and_op.
Left 100 comparison_comp_op. %% == !=
Left 200 comparison_rel_op.  %% > < >= <=
Left 300 dual_arithmetic_op. %% + -
Left 400 mult_arithmetic_op. %% * /

grammar -> eoe : {'__block__', []}.
grammar -> expr_list : {'__block__', '$1'}.
grammar -> eoe expr_list : {'__block__', '$2'}.
grammar -> expr_list eoe : {'__block__', '$1'}.
grammar -> eoe expr_list eoe : {'__block__', '$2'}.
grammar -> '$empty' : {'__block__',  []}.

%% end of expression
eol -> newline : '$1'.
eoe -> ';' : '$1'.
eoe -> eol : '$1'.
eoe -> eol ';' : '$1'.
eoe -> ';' eol : '$1'.

%% expr
expr_list -> expr : ['$1'].
expr_list -> expr_list eoe expr: ['$3' | '$1'].

%% Handle parentheses
expr -> '(' expr ')' : '$2'.

%% Handle arithmetic operations
expr -> expr dual_arithmetic_op expr : {'$2', '$1', '$3'}.
expr -> expr mult_arithmetic_op expr : {'$2', '$1', '$3'}.
expr -> expr and_op expr : {'$2', '$1', '$3'}.
expr -> expr or_op expr : {'$2', '$1', '$3'}.

%% Handle comparison operators
expr -> expr comparison_comp_op expr : {'$2', '$1', '$3'}.
expr -> expr comparison_rel_op expr : {'$2', '$1', '$3'}.

%% Handle matching
expr -> identifier match_op expr : {'$2', '$1', '$3'}.

%% Handle values
expr -> value : '$1'.

expr -> lambda_fn : '$1'.

%% match op
match_op -> '=' : '='.

%% Values
value -> int : '$1'.
value -> float : '$1'.
value -> ascii_string : '$1'.
value -> env_var : '$1'.
value -> access_expr : '$1'.
value -> parens_call : '$1'.
value -> identifier : '$1'.
value -> boolean_literal : '$1'.
value -> list : '$1'.

%% booleans
boolean_literal -> 'true' : '$1'.
boolean_literal -> 'false' : '$1'.
and_op -> 'and' : '$1'.
or_op -> 'or' : '$1'.

%% handle multiple levels of access operators: @data["key"], @data["key"]["key2"]
access_expr -> identifier '[' access_expr_key ']' : {access_expr, '$1', '$3'}.
access_expr -> env_var '[' access_expr_key ']' : {access_expr, '$1', '$3'}.
access_expr -> access_expr '[' access_expr_key ']' : {access_expr, '$1', '$3'}.

access_expr_key -> ascii_string : '$1'.
access_expr_key -> identifier : '$1'.

%% arithmetic operator
dual_arithmetic_op -> '+' : '+'.
dual_arithmetic_op -> '-' : '-'.
mult_arithmetic_op -> '*' : '*'.
mult_arithmetic_op -> '/' : '/'.

%% comparison operator
comparison_comp_op -> '==' : {comparison_expr, '$1'}.
comparison_comp_op -> '!=' : {comparison_expr, '$1'}.
comparison_rel_op -> '<' : {comparison_expr, '$1'}.
comparison_rel_op -> '<=' : {comparison_expr, '$1'}.
comparison_rel_op -> '>' : {comparison_expr, '$1'}.
comparison_rel_op -> '>=' : {comparison_expr, '$1'}.

%% Lists
list -> '[' ']' : {list, []}.
list -> '[' list_elements ']' : {list, '$2'}.
list_elements -> value ',' list_elements : ['$1' | '$3'].
list_elements -> value : ['$1'].

%% Lambda function
lambda_fn -> 'fn' lambda_args '->' expr 'end' : {lambda_fn, '$2', '$4'}.
lambda_args -> identifier ',' lambda_args : ['$1' | '$3'].
lambda_args -> identifier : ['$1'].

%% Identifier call (can resolve to function name, lambda, expr returning callable)
parens_call -> identifier '('  ')' : {parens_call, '$1', {list, []}}.
parens_call -> identifier '(' function_call_args_list ')' : {parens_call, '$1', {list, '$3'}}.
parens_call -> '(' expr ')' '('  ')' : {parens_call, '$2', {list, []}}.
parens_call -> '(' expr ')' '(' function_call_args_list ')' : {parens_call, '$2', {list, '$5'}}.

%% Arguments list with at least 1 argument. Function calls with 0 arguments are
%% handled directly by the function_call rule.
function_call_args_list -> function_call_arg ',' function_call_args_list : ['$1' | '$3'].
function_call_args_list -> function_call_arg : ['$1'].

function_call_arg -> value : '$1'.
function_call_arg -> lambda_fn : '$1'.

Erlang code.
