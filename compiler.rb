require 'pp'


class ParseError < Exception
end

class Compiler

  def initialize( program = nil )
    @program = program.dup if program
  end
  
  
  def pass1( program = nil )
    @program = program.dup if program
    raise ParseError.new "No program specified" unless @program

    puts "PASS1: #@program"
    
    tokenise
    collect_arglist
    
    @ast = expression
    pp @ast
  end
  
  def pass2
    @ast = simplify @ast
    
    puts "AST (simp): "
    pp @ast
  end

  def simplify expr
    if [:imm, :arg].include? expr[:op]
      return expr
    end
      
    left  = simplify expr[:a]
    right = simplify expr[:b]
    
    if left[:op] == :imm && right[:op] == :imm
      lval, rval = left[:n], right[:n]
      
      print "#{lval} #{expr[:op]} #{rval} -> "
      
      value = case expr[:op]
        when  '+' then  lval + rval
        when  '-' then  lval - rval
        when  '*' then  lval * rval
        when  '/' then  lval / rval
      end
      puts value
      { op: :imm, n: value }
    else
      { op: expr[:op], a: left, b: right }
    end
  end
  
  def expression
    apart = term
    
    return apart if @tokens.first.nil? || !('+-'.include?( @tokens.first ))
    
    { op: @tokens.shift, a: apart, b: expression }
  end
  
  def term
    apart = factor
    
    return apart if @tokens.first.nil? || !('*/'.include?( @tokens.first ))
    
    { op: @tokens.shift, a: apart, b: term }
  end
  
  def factor
    tok = @tokens.shift
    
#    puts "TOKEN: #{tok} (#{tok.class})"
    
    return { op: :imm, n: tok } if tok.is_a? Fixnum      
    return { op: :arg, n: tok } if tok =~ /^\w/
    
    raise ParseError.new "Expected '(', got #{tok.inspect}" if tok != '('
    
    ret = expression
    
    raise ParseError.new "Expected ')', got #{tok.inspect}" if @tokens.shift != ')'
    
    ret
  end

private

  def tokenise
    regex = /\s*(([-+*\/\(\)\[\]])|([A-Za-z]+)|(\d+))\s*/
    
    @tokens = @program.gsub( regex, ':\1' ).slice( 1..-1 ).split( ':' ).map do |tok|
      (tok =~ /^\d/) ? tok.to_i : tok
    end
    
#    p @tokens
  end

  
  def collect_arglist
    raise ParseError.new "No lead-in '[' for argument list" if @tokens.shift != '['
    
    @args = []
    arg  = @tokens.shift
    
    while @tokens.length > 0 && arg != ']'
      @args << arg
      arg  = @tokens.shift
    end
    
#    p @args
    
    raise ParseError.new "No final ']' for argument list" if @tokens.length == 0
  end
end

if $0 ==  __FILE__
  cmp = Compiler.new
  cmp.pass1( '[x y] x + y' )
  puts
  cmp.pass1( '[x y] x - y' )
  puts
  cmp.pass1( '[x y] x * y' )
  puts
  cmp.pass1( '[x y] x / y' )
  puts
  cmp.pass1( '[x y z] x + y * z' )
  puts
  cmp.pass1( '[x y z] x + y + z' )

  puts
  cmp.pass1( '[x y z] (x + y) * z' )
  
  puts
  cmp.pass1( '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)' )
  cmp.pass2
end

# pass1( '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)' )

=begin
{op: "/", 
  a: {op: "-", 
        a: {op: "+", 
              a: { op: "*", a: { op: "*", a: {op: :imm, n: 2}, b: {op: :imm, n: 3}
              }, b: {op: :arg, n: 0}
              }, b: { op: "*", a: {op: :imm, n: 5}, b: {op: :arg, n: 1} }
                 }, b: { op: "*", a: {op: :imm, n: 3}, b: {op: :arg, n: 2} }
  }, b: {op: "+", 
          a: { op: "+", a: {op: :imm, n: 1}, b: {op: :imm, n: 3}
          }, b: { op: "*", a: {op: :imm, n: 2}, b: {op: :imm, n: 2} }
    }
}
=end

