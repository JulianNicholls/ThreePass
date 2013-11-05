require 'pp'

require './simulate'

class ParseError < Exception
end

class Compiler

  OP_MAP = { imm: 'LD.I', arg: 'LD.M', '+' => 'ADD', '-' => 'SUB', '*' => 'MUL', '/' => 'DIV' };

  attr_reader :assembler

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
    @ast = simplify_ast @ast
    
    print "AST (simp): " if @verbose
    pp @ast if @verbose
  end

  
  def pass3
    @assembler = generate( @ast )
    
    print "Generated: " if @verbose
    pp @assembler if @verbose
    
    simplify_assembler
    
    print "Optimised: " if @verbose
    pp @assembler if @verbose
  end
  
  
  def expression
    now = term
    
    while !@tokens.first.nil? && '+-'.include?( @tokens.first )
      curop = @tokens.shift
      now = { op: curop, a: now, b: term }
    end
    
    now
  end
  
  
  def term
    now = factor
    
    while !@tokens.first.nil? && '*/'.include?( @tokens.first )
      curop = @tokens.shift
      now = { op: curop, a: now, b: factor }
    end
    
    now
  end
  
  
  def factor
    tok = @tokens.shift
    
    return { op: :imm, n: tok }                if tok.is_a? Fixnum      
    return { op: :arg, n: @args.index( tok ) } if tok =~ /^\w/
    
    raise ParseError.new "Expected '(', got #{tok.inspect}" if tok != '('
    
    ret = expression
    
    raise ParseError.new "Expected ')', got #{tok.inspect}" if @tokens.shift != ')'
    
    ret
  end

  
  def simplify_ast expr
    this_op = expr[:op]
    
    return expr if [:imm, :arg].include? this_op
      
    left  = simplify_ast expr[:a]
    right = simplify_ast expr[:b]
    
    return { op: this_op, a: left, b: right } if left[:op] != :imm || right[:op] != :imm

    lval, rval = left[:n], right[:n]
      
    print "#{lval} #{this_op} #{rval} -> " if @verbose
    
    value = lval.send( this_op.to_sym, rval )
    puts value if @verbose
    { op: :imm, n: value }
  end

  
  def generate( node )    # Post-order traversal
    this_op = node[:op]
    
    # Simple imm or arg OP imm OR arg => LD right, SWAP, LD left, OP, PUSH
    
    if is_data_load?( node[:a] ) && is_data_load?( node[:b] )
      return ["#{OP_MAP[node[:b][:op]]} #{node[:b][:n]}", "SWAP", 
              "#{OP_MAP[node[:a][:op]]} #{node[:a][:n]}", OP_MAP[this_op], 
              "PUSH"]
    end
    
    # Simple load
    
    return ["#{OP_MAP[this_op]} #{node[:n]}", "PUSH"] if is_data_load? this_op

    # More involved operation
    
    generate( node[:a] ) + generate( node[:b] ) +
    ['POP', 'SWAP', 'POP', OP_MAP[this_op], 'PUSH']
  end
  
    
  def simplify_assembler
    idx = 0
    while idx < @assembler.length
      # Remove a redundant PUSH followed by POP
      
      if @assembler[idx] == 'PUSH' && @assembler[idx+1] == 'POP'
        @assembler.slice!( idx, 2 )
      else
        idx += 1
      end
    end
    
    # A final push is superfluous
    
    @assembler.slice!( -1, 1 ) if @assembler.last == 'PUSH'
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
  
  def is_data_load? op
    if op.is_a? Hash
      op = op[:op]
    end
    
    [:imm, :arg].include? op
  end
end






if $0 ==  __FILE__
  cmp = Compiler.new nil
#  cmp.pass1( '[x y] x + y' )
#  puts
#  cmp.pass1( '[x y] x - y' )
#  puts
#  cmp.pass1( '[x y] x * y' )
#  puts
#  cmp.pass1( '[x y] x / y' )
#  puts
#  cmp.pass1( '[x y z] x + y * z' )
#  puts
#  cmp.pass1( '[x y z] x + y + z' )
#
#  puts
  cmp.pass1( '[x y z] (x + y) * z' )
  cmp.pass2
  cmp.pass3

  runner = Simulator.new( cmp.assembler, [2, 3, 4], verbose: true )
  puts "Run: #{runner.run}" # Expect 20
  
  puts
  cmp.pass1( '[ x y z ] ( 2*3*x + 5*y - 2*z ) / (1 + 3 + 2*2)' )
  cmp.pass2
  cmp.pass3
  
  runner.set_code( cmp.assembler, [8, 4, 2] )
  
  puts "Run: #{runner.run}" # Expect 8
  
end
