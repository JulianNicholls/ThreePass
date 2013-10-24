require 'pp'

def tokenise( program )
  regex = /\s*(([-+*\/\(\)\[\]])|([A-Za-z]+)|(\d+))\s*/
  
  tokens = program.gsub( regex, ':\1' ).slice( 1..-1 ).split( ':' ).map do |tok|
    (tok =~ /^\d/) ? tok.to_i : tok
  end
  
  p tokens
end

tokenise( '[ x y z ] ( 2*3*x + 5*y - 3*z ) / (1 + 3 + 2*2)' )


#tokenize: (program) ->
#    # Turn a program string into an array of tokens.  Each token
#    # is either '[', ']', '(', ')', '+', '-', '*', '/', a variable
#    # name or a number
#    regex = /\s*([-+*/\(\)\[\]]|[A-Za-z]+|[0-9]+)\s*/g
#    program.replace(regex, ":$1").substring(1).split(':').map (tok) ->
#      if isNaN(tok) then tok else tok|0