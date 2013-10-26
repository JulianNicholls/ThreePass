require 'pp'


class ParseError < Exception
end

class Compiler

  def initialize( program = nil, options = {} )
    @program = program.dup if program
    @verbose = options[:verbose] || false
  end
  
  
  def pass1( program = nil )
    @program = program.dup if program
    raise ParseError.new "No program specified" unless @program

    puts "PASS1: #@program" if @verbose
    
    tokenise
    collect_arglist
    
    @ast = expression
    pp @ast if @verbose
  end
  
  def pass2
    @ast = simplify @ast
    
    puts "AST (simp): " if @verbose
    pp @ast if @verbose
  end

    
  def expression
    apart = term
    
    return apart if @tokens.first.nil? || !('+-'.include?( @tokens.first ))

    now = nil?
    
    while !@tokens.first.nil? && '+-'.include?( @tokens.first )
      curop = @tokens.shift
      bpart = term
      if now
        now = { op: curop, a: now, b: bpart }
      else
        now = { op: curop, a: apart, b: bpart }
      end
    end
    
    now
  end
  
  
  def term
    apart = factor
    
    return apart if @tokens.first.nil? || !('*/'.include?( @tokens.first ))
    
    now = nil?
    
    while !@tokens.first.nil? && '*/'.include?( @tokens.first )
      curop = @tokens.shift
      bpart = factor
      if now
        now = { op: curop, a: now, b: bpart }
      else
        now = { op: curop, a: apart, b: bpart }
      end
    end
    
    now
  end
  
  
  def factor
    tok = @tokens.shift
    
#    puts "TOKEN: #{tok} (#{tok.class})"
    
    return { op: :imm, n: tok } if tok.is_a? Fixnum      
    return { op: :arg, n: @args.index( tok ) } if tok =~ /^\w/
    
    raise ParseError.new "Expected '(', got #{tok.inspect}" if tok != '('
    
    ret = expression
    
    raise ParseError.new "Expected ')', got #{tok.inspect}" if @tokens.shift != ')'
    
    ret
  end

  
  def simplify expr
    this_op = expr[:op]
    
    if [:imm, :arg].include? this_op
      return expr
    end
      
    left  = simplify expr[:a]
    right = simplify expr[:b]
    
    if left[:op] == :imm && right[:op] == :imm
      lval, rval = left[:n], right[:n]
      
      print "#{lval} #{this_op} #{rval} -> " if @verbose
      
      value = case this_op
        when  '+' then  lval + rval
        when  '-' then  lval - rval
        when  '*' then  lval * rval
        when  '/' then  lval / rval
      end
      puts value if @verbose
      { op: :imm, n: value }
    else
      { op: this_op, a: left, b: right }
    end
  end

  
private

  def tokenise
    regex = /\s*(([-+*\/\(\)\[\]])|([A-Za-z]+)|(\d+))\s*/
    
    @tokens = @program.gsub( regex, ':\1' ).slice( 1..-1 ).split( ':' ).map do |tok|
      (tok =~ /^\d/) ? tok.to_i : tok
    end
    
    p @tokens if @verbose
  end

  
  def collect_arglist
    raise ParseError.new "No lead-in '[' for argument list" if @tokens.shift != '['
    
    @args = []
    arg  = @tokens.shift
    
    while @tokens.length > 0 && arg != ']'
      @args << arg
      arg  = @tokens.shift
    end
    
    p @args if @verbose
    
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

