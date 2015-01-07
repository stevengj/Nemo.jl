###########################################################################################
#
#   fmpz_poly.jl : Flint polynomials over ZZ
#
###########################################################################################

## FIXME : add clear_readonly and fmpz initialiser/finalizer and use instead of init/clear
## FIXME : make function names conform to Julia standard
## FIXME : put special polynomials back in

export fmpz_poly

###########################################################################################
#
#   Data types and memory management
#
###########################################################################################

type fmpz_poly{S} <: PolyElem
   coeffs :: Ptr{Void}
   alloc :: Int
   length :: Int
   parent :: PolyRing

   function fmpz_poly()
      z = new()
      z.parent = PolyRing{fmpz_poly, S}(ZZ)
      ccall((:fmpz_poly_init, :libflint), Void, (Ptr{fmpz_poly},), &z)
      finalizer(z, _fmpz_poly_clear_fn)
      return z
   end

   function fmpz_poly(a::Array{BigInt, 1})
      z = new()
      z.parent = PolyRing{fmpz_poly, S}(ZZ)
      ccall((:fmpz_poly_init2, :libflint), Void, (Ptr{fmpz_poly}, Int), &z, length(a))
      for i = 1:length(a)
         temp = fmpz_readonly(a[i])
         ccall((:fmpz_poly_set_coeff_fmpz, :libflint), Void, 
                     (Ptr{fmpz_poly}, Int, Ptr{fmpz}), &z, i - 1, &temp)
      end
      finalizer(z, _fmpz_poly_clear_fn)
      return z
   end

   function fmpz_poly(a::Int)
      z = new()
      z.parent = PolyRing{fmpz_poly, S}(ZZ)
      ccall((:fmpz_poly_init, :libflint), Void, (Ptr{fmpz_poly},), &z)
      ccall((:fmpz_poly_set_si, :libflint), Void, (Ptr{fmpz_poly}, Int), &z, a)
      finalizer(z, _fmpz_poly_clear_fn)
      return z
   end

   function fmpz_poly(a::BigInt)
      z = new()
      z.parent = PolyRing{fmpz_poly, S}(ZZ)
      ccall((:fmpz_poly_init, :libflint), Void, (Ptr{fmpz_poly},), &z)
      ccall((:fmpz_poly_set_mpz, :libflint), Void, (Ptr{fmpz_poly}, Ptr{BigInt}), &z, &a)
      finalizer(z, _fmpz_poly_clear_fn)
      return z
   end
end

function _fmpz_poly_clear_fn(a::fmpz_poly)
   ccall((:fmpz_poly_clear, :libflint), Void, (Ptr{fmpz_poly},), &a)
end

###########################################################################################
#
#   Basic manipulation
#
###########################################################################################    
   
length(x::fmpz_poly) = ccall((:fmpz_poly_length, :libflint), Int, (Ptr{fmpz_poly},), &x)

function coeff(x::fmpz_poly, n::Int)
   n < 0 && throw(DomainError())
   temp = fmpz()
   init(temp)
   ccall((:fmpz_poly_get_coeff_fmpz, :libflint), Void, 
               (Ptr{fmpz}, Ptr{fmpz_poly}, Int), &temp, &x, n)
   z = BigInt(temp)
   clear(temp)
   return z
end

isgen(x::fmpz_poly) = ccall((:fmpz_poly_is_x, :libflint), Bool, (Ptr{fmpz_poly},), &x)

###########################################################################################
#
#   String I/O
#
###########################################################################################

function show{S}(io::IO, x::fmpz_poly{S})
   if length(x) == 0
      print(io, "0")
   else
      cstr = ccall((:fmpz_poly_get_str_pretty, :libflint), Ptr{Uint8}, 
                (Ptr{fmpz_poly}, Ptr{Uint8}), &x, bytestring(string(S)))

      print(io, bytestring(cstr))

      ccall((:flint_free, :libflint), Void, (Ptr{Uint8},), cstr)
   end
end

show_minus_one{S}(::Type{fmpz_poly{S}}) = show_minus_one(BigInt)

###########################################################################################
#
#   Unary operations
#
###########################################################################################

function -{S}(x::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_neg, :libflint), Void, (Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &x)
   return z
end

###########################################################################################
#
#   Binary operations
#
###########################################################################################

function +{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_add, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly},  Ptr{fmpz_poly}), 
               &z, &x, &y)
   return z
end

function -{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_sub, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly},  Ptr{fmpz_poly}), 
               &z, &x, &y)
   return z
end

function *{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_mul, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly},  Ptr{fmpz_poly}), 
               &z, &x, &y)
   return z
end

###########################################################################################
#
#   Ad hoc binary operators
#
###########################################################################################

function *{S}(x::Int, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_scalar_mul_si, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &y, x)
   return z
end

function *{S}(x::BigInt, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   temp = fmpz_readonly(x)
   ccall((:fmpz_poly_scalar_mul_fmpz, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz}), &z, &y, &temp)
   return z
end

function +{S}(x::fmpz_poly{S}, y::Int)
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_add_si, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &x, y)
   return z
end

function +{S}(x::fmpz_poly{S}, y::BigInt)
   z = fmpz_poly{S}()
   temp = fmpz_readonly(y)
   ccall((:fmpz_poly_add_fmpz, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz}), &z, &x, &temp)
   return z
end

function -{S}(x::fmpz_poly{S}, y::Int)
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_sub_si, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &x, y)
   return z
end

function -{S}(x::fmpz_poly{S}, y::BigInt)
   z = fmpz_poly{S}()
   temp = fmpz_readonly(y)
   ccall((:fmpz_poly_sub_fmpz, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz}), &z, &x, &temp)
   return z
end

function -{S}(x::Int, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_si_sub, :libflint), Void, 
                (Ptr{fmpz_poly}, Int, Ptr{fmpz_poly}), &z, x, &y)
   return z
end

function -{S}(x::BigInt, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   temp = fmpz_readonly(x)
   ccall((:fmpz_poly_fmpz_sub, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz}, Ptr{fmpz_poly}), &z, &temp, &y)
   return z
end

+(x::Int, y::fmpz_poly) = y + x

+(x::BigInt, y::fmpz_poly) = y + x

*(x::fmpz_poly, y::Int) = y*x

*(x::fmpz_poly, y::BigInt) = y*x

+(x::Integer, y::fmpz_poly) = y + BigInt(x)

-(x::Integer, y::fmpz_poly) = BigInt(x) - y

*(x::Integer, y::fmpz_poly) = BigInt(x)*y

+(x::fmpz_poly, y::Integer) = x + BigInt(y)

-(x::fmpz_poly, y::Integer) = x - BigInt(y)

*(x::fmpz_poly, y::Integer) = BigInt(y)*x

###########################################################################################
#
#   Powering
#
###########################################################################################

function ^{S}(x::fmpz_poly{S}, y::Int)
   y < 0 && throw(DomainError())
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_pow, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), 
               &z, &x, y)
   return z
end

###########################################################################################
#
#   Comparisons
#
###########################################################################################

==(x::fmpz_poly, y::fmpz_poly) = ccall((:fmpz_poly_equal, :libflint), Bool, 
                                       (Ptr{fmpz_poly}, Ptr{fmpz_poly}), &x, &y)

###########################################################################################
#
#   Ad hoc comparisons
#
###########################################################################################

function ==(x::fmpz_poly, y::BigInt) 
   if length(x) > 1
      return false
   elseif length(x) == 1 
      z = fmpz()
      init(z)
      temp = fmpz_readonly(y)
      ccall((:fmpz_poly_get_coeff_fmpz, :libflint), Void, 
                       (Ptr{fmpz}, Ptr{fmpz_poly}, Int), &z, &x, 0)
      res = ccall((:fmpz_equal, :libflint), Bool, 
               (Ptr{fmpz}, Ptr{fmpz}, Int), &z, &temp, 0)
      clear(z)
      return res
   else
      return y == 0
   end 
end

==(x::fmpz_poly, y::Integer) = x == BigInt(y)

###########################################################################################
#
#   Truncation
#
###########################################################################################

function truncate{S}(a::fmpz_poly{S}, n::Int)
   n < 0 && throw(DomainError())
   
   if length(a) <= n
      return a
   end

   z = fmpz_poly{S}()
   ccall((:fmpz_poly_set_trunc, :libflint), Void,
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &a, n)
   return z
end

function mullow{S}(x::fmpz_poly{S}, y::fmpz_poly{S}, n::Int)
   n < 0 && throw(DomainError())
   
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_mullow, :libflint), Void,
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &x, &y, n)
   return z
end

###########################################################################################
#
#   Reversal
#
###########################################################################################

function reverse{S}(x::fmpz_poly{S}, len::Int)
   len < 0 && throw(DomainError())
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_reverse, :libflint), Void,
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &x, len)
   return z
end

###########################################################################################
#
#   Shifting
#
###########################################################################################

function shift_left{S}(x::fmpz_poly{S}, len::Int)
   len < 0 && throw(DomainError())
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_shift_left, :libflint), Void,
      (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &x, len)
   return z
end

function shift_right{S}(x::fmpz_poly{S}, len::Int)
   len < 0 && throw(DomainError())
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_shift_right, :libflint), Void,
       (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &x, len)
   return z
end

###########################################################################################
#
#   Exact division
#
###########################################################################################

function divexact{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   y == 0 && throw(DivideError())
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_div, :libflint), Void, 
            (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &x, &y)
   return z
end

###########################################################################################
#
#   Ad hoc exact division
#
###########################################################################################

function divexact{S}(x::fmpz_poly{S}, y::BigInt)
   y == 0 && throw(DivideError())
   z = fmpz_poly{S}()
   temp = fmpz_readonly(y)
   ccall((:fmpz_poly_scalar_divexact_fmpz, :libflint), Void, 
          (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz}), &z, &x, &temp)
   return z
end

function divexact{S}(x::fmpz_poly{S}, y::Int)
   y == 0 && throw(DivideError())
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_scalar_divexact_si, :libflint), Void, 
                        (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Int), &z, &x, y)
   return z
end

divexact(x::fmpz_poly, y::Integer) = divexact(x, BigInt(y)) 

###########################################################################################
#
#   Pseudodivision
#
###########################################################################################

function pseudorem{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   y == 0 && throw(DivideError())
   diff = length(x) - length(y)
   r = fmpz_poly{S}()
   d = Array(Int, 1)
   ccall((:fmpz_poly_pseudo_rem, :libflint), Void, 
        (Ptr{fmpz_poly}, Ptr{Int}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), &r, d, &x, &y)
   if (diff > d[1])
      return lead(y)^(diff - d[1])*r
   else
      return r
   end
end

function pseudodivrem{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   y == 0 && throw(DivideError())
   diff = length(x) - length(y)
   q = fmpz_poly{S}()
   r = fmpz_poly{S}()
   d = Array(Int, 1)
   ccall((:fmpz_poly_pseudo_divrem_divconquer, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{Int}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), 
               &q, &r, d, &x, &y)
   if (diff > d[1])
      m = lead(y)^(diff - d[1])
      return m*q, m*r
   else
      return q, r
   end
end

###########################################################################################
#
#   Content, primitive part, GCD and LCM
#
###########################################################################################

function gcd{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_gcd, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &x, &y)
   return z
end

function content(x::fmpz_poly)
   temp = fmpz()
   init(temp)
   ccall((:fmpz_poly_content, :libflint), Void, (Ptr{fmpz}, Ptr{fmpz_poly}), &temp, &x)
   res = BigInt(temp)
   clear(temp)
   return res
end

function primpart{S}(x::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_primitive_part, :libflint), Void, 
         (Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &x)
   return z
end

###########################################################################################
#
#   Evaluation
#
###########################################################################################

function evaluate(x::fmpz_poly, y::BigInt)
   z = fmpz()
   init(z)
   temp = fmpz_readonly(y)
   ccall((:fmpz_poly_evaluate_fmpz, :libflint), Void, 
                (Ptr{fmpz}, Ptr{fmpz_poly}, Ptr{fmpz}), &z, &x, &temp)
   res = BigInt(z)
   clear(z)
   return res
end

evaluate(x::fmpz_poly, y::Integer) = evaluate(x, BigInt(y))

###########################################################################################
#
#   Composition
#
###########################################################################################

function compose{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_compose, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &x, &y)
   return z
end

###########################################################################################
#
#   Derivative
#
###########################################################################################

function derivative{S}(x::fmpz_poly{S})
   z = fmpz_poly{S}()
   ccall((:fmpz_poly_derivative, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &x)
   return z
end

###########################################################################################
#
#   Resultant
#
###########################################################################################

function resultant(x::fmpz_poly, y::fmpz_poly)
   temp = fmpz()
   init(temp)
   ccall((:fmpz_poly_resultant, :libflint), Void, 
                (Ptr{fmpz}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), &temp, &x, &y)
   res = BigInt(temp)
   clear(temp)
   return res
end

###########################################################################################
#
#   Discriminant
#
###########################################################################################

function discriminant(x::fmpz_poly)
   temp = fmpz()
   init(temp)
   ccall((:fmpz_poly_discriminant, :libflint), Void, 
                (Ptr{fmpz}, Ptr{fmpz_poly}), &temp, &x)
   res = BigInt(temp)
   clear(temp)
   return res
end

###########################################################################################
#
#   Bezout
#
###########################################################################################

function bezout{S}(x::fmpz_poly{S}, y::fmpz_poly{S})
   temp = fmpz()
   init(temp)
   u = fmpz_poly{S}()
   v = fmpz_poly{S}()
   ccall((:fmpz_poly_xgcd_modular, :libflint), Void, 
        (Ptr{fmpz}, Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), 
            &temp, &u, &v, &x, &y)
   z = BigInt(temp)
   clear(temp)
   return (z, u, v)
end

###########################################################################################
#
#   Unsafe functions
#
###########################################################################################

function setcoeff!(z::fmpz_poly, n::Int, x::BigInt)
   temp = fmpz_readonly(x)
   ccall((:fmpz_poly_set_coeff_fmpz, :libflint), Void, 
                    (Ptr{fmpz_poly}, Int, Ptr{fmpz}), &z, n, &temp)
end

function mul!(z::fmpz_poly, x::fmpz_poly, y::fmpz_poly)
   ccall((:fmpz_poly_mul, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &x, &y)
end

function addeq!(z::fmpz_poly, x::fmpz_poly)
   ccall((:fmpz_poly_add, :libflint), Void, 
                (Ptr{fmpz_poly}, Ptr{fmpz_poly}, Ptr{fmpz_poly}), &z, &z, &x)
end

###########################################################################################
#
#   PolynomialRing constructor
#
###########################################################################################

function PolynomialRing(R::IntegerRing, s::String)
   S = symbol(s)
   T = fmpz_poly{S}
   P = PolyRing{T, S}

   eval(:(Base.call(a::$P) = $T()))
   eval(:(Base.call(a::$P, x::Int) = $T(x)))
   eval(:(Base.call(a::$P, x::Integer) = $T(BigInt(x))))
   eval(:(Base.call(a::$P, x::BigInt) = $T(x)))
   eval(:(Base.call(a::$P, x::$T) = x))
   eval(:(Base.call(a::$P, x::Array{BigInt, 1}) = $T(x)))

   return P(R), T([ZZ(0), ZZ(1)])
end