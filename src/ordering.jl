# A total ordering

<ₑ(a::Real,    b::Real) = abs(a) < abs(b)
<ₑ(a::Complex, b::Complex) = (abs(real(a)), abs(imag(a))) < (abs(real(b)), abs(imag(b)))
<ₑ(a::Real,    b::Complex) = true
<ₑ(a::Complex, b::Real) = false

<ₑ(a::Symbolic, b::Number) = false
<ₑ(a::Number,   b::Symbolic) = true

###### A variation on degree lexicographic order ########
# find symbols and their corresponding degrees
function get_degrees(expr)
    if issym(expr)
        (nameof(expr) => 1,)
    elseif istree(expr)
        op = operation(expr)
        args = arguments(expr)
        if operation(expr) == (^) && args[2] isa Number
            return map(get_degrees(args[1])) do (base, pow)
                (base => pow * args[2])
            end
        elseif operation(expr) == (*)
            return mapreduce(get_degrees,
                             (x,y)->(x...,y...,), args)
        elseif operation(expr) == (+)
            ds = map(get_degrees, args)
            _, idx = findmax(x->sum(last.(x), init=0), ds)
            return ds[idx]
        else
            return (Symbol("zzzzzzz", hash(expr)) => 1,)
        end
    else
        return ()
    end
end

function monomial_lt(degs1, degs2)
    d1 = sum(last, degs1, init=0)
    d2 = sum(last, degs2, init=0)
    d1 != d2 ? d1 < d2 : lexlt(degs1, degs2)
end

function lexlt(degs1, degs2)
    for (a, b) in zip(degs1, degs2)
        if a[1] == b[1] && a[2] != b[2]
            return a[2] > b[2]
        elseif a[1] != b[1]
            return a < b
        end
    end
    return false # they are equal
end

_arglen(a) = istree(a) ? length(unsorted_arguments(a)) : 0
function <ₑ(a::BasicSymbolic, b::BasicSymbolic)
    da, db = get_degrees(a), get_degrees(b)
    fw = monomial_lt(da, db)
    bw = monomial_lt(db, da)
    if fw === bw && !isequal(a, b)
        if _arglen(a) == _arglen(b)
            return hash(a) < hash(b)
        else
            return _arglen(a) < _arglen(b)
        end
    else
        return fw
    end
end
