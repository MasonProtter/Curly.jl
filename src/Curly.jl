module Curly

export @macro, @progn, @if, @for, @function, @do, @module, @while, @let

curly_to_block(expr::Expr) = ((expr.head == :bracescat || expr.head == :braces) && (expr.head = :block);
                            expr)
curly_to_block(x) = x
in_to_eq(ex::Expr) = ex.head == :call && ex.args[1] ∈ (:∈, :in) ? Expr(:(=), ex.args[2:end]...) : ex

Expr(:macro,
     Expr(:call, :macro, :sig, :body),
     Expr(:block,
          Expr(:quote,
               Expr(:macro,
                    Expr(:call, Expr(:$, :(esc(sig.args[1]))), Expr(:$, :(sig.args[2:end]...)),),
                    Expr(:block, Expr(:$, :(curly_to_block(body)))))))) |> eval


@macro progn(expr) {
    expr.head == :bracescat || expr.head == :braces || error("invalid block syntax, must write @b {...}")
    expr.head = :block
    esc(expr)
}

@eval @macro $(Symbol("if"))(cond, body) {
    esc(:($cond ? $(curly_to_block(body)) : nothing))
}

@eval @macro $(Symbol("if"))(cond, body, false_body) {
    esc(:($cond ? $(curly_to_block(body)) : $(curly_to_block(false_body))))
}



@eval @macro $(Symbol("for"))(args...) {
    specs = args[1:end-1]
    body = args[end]
    @if body.head == :bracescat || body.head == :braces {
        body.head = :block
    }
    esc(Expr(:for, Expr(:block, in_to_eq.(specs)...), body));
}

@eval @macro $(Symbol("function"))(sig, body) {
    esc(:($sig = $(curly_to_block(body))))
}

@eval @macro $(Symbol("do"))(call, args, body) {
    (esc ∘ Expr)(:do, call, :($args -> $(curly_to_block(body))))
}

@eval @macro $(Symbol("module"))(name, body) {
    Expr(:toplevel, (esc ∘ Expr)(:module, true, name, curly_to_block(body)))
}

@eval @macro $(Symbol("while"))(cond, body) {
    (esc ∘ Expr)(:while, cond, curly_to_block(body))
}

@eval @macro $(Symbol("let"))(args...) {
     (esc ∘ Expr)(:let, Expr(:block, args[1:end-1]...), curly_to_block(args[end]))
}

end # module Curly
