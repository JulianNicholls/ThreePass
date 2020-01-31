// Retrieved from the Codewars site - 2020-01-31
function Compiler () {
    this.args = [];
    this.tokens = [];
};

Compiler.prototype.compile = function (program) {
  return this.pass3(this.pass2(this.pass1(program)));
};

Compiler.prototype.tokenize = function (program) {
  // Turn a program string into an array of tokens.  Each token
  // is either '[', ']', '(', ')', '+', '-', '*', '/', a variable
  // name or a number (as a string)
  var regex = /\s*([-+*/\(\)\[\]]|[A-Za-z]+|[0-9]+)\s*/g;
  this.tokens = program.replace(regex, ":$1").substring(1).split(':').map( function (tok) {
    return isNaN(tok) ? tok : tok|0;
  });
};

Compiler.prototype.pass1 = function (program) {
  this.tokenize(program);
  this.collectArglist();
  
  // return un-optimized AST

  return this.expression();  
};


Compiler.prototype.pass2 = function (ast) {
  return this.simplify_ast( ast )
};


Compiler.prototype.pass3 = function (ast) {
  return this.generate( ast );
};


Compiler.prototype.collectArglist = function() {
    this.tokens.shift();  // Suck up '['
    var arg = this.tokens.shift();
    
    while( this.tokens.length > 0 && arg != ']' ) {
        this.args.push( arg );
        arg = this.tokens.shift();
    }
};


Compiler.prototype.expression = function() {
    var apart = this.term(),
        t0    = this.tokens[0],
        now   = null;
    
    if( t0 == undefined || (t0 != '+' && t0 != '-') )
        return apart;
        
    while( t0 != undefined && (t0 == '+' || t0 == '-') ) {
      var curop = this.tokens.shift(),
          bpart = this.term();
      
      if( now != null )
        now = { op: curop, a: now, b: bpart }
      else
        now = { op: curop, a: apart, b: bpart }
      
      t0 = this.tokens[0];
    }
    
    return now;
};


Compiler.prototype.term = function() {
    var apart = this.factor(),
        t0    = this.tokens[0],
        now   = null;
    
    if( t0 == undefined || (t0 != '*' && t0 != '/') )
        return apart;
        
    while( t0 != undefined && (t0 == '*' || t0 == '/') ) {
      var curop = this.tokens.shift(),
          bpart = this.factor();
          
      if( now != null )
        now = { op: curop, a: now, b: bpart }
      else
        now = { op: curop, a: apart, b: bpart }
      
      t0 = this.tokens[0];
    }
    
    return now;
};


Compiler.prototype.factor = function() {
    var tok = this.tokens.shift();

    if( typeof( tok ) == 'number' ) 
        return { op: 'imm', n: tok };
        
    if( tok.match( /^\w/ ) )
        return { op: 'arg', n: this.args.indexOf( tok ) };
    
// tok should be a '('
    
    var ret = this.expression();
    
    this.tokens.shift();    // Suck up ')'
    
    return ret;
};


Compiler.prototype.simplify_ast = function( expr ) {
    var this_op = expr.op;
    
    if( this_op == 'imm' || this_op == 'arg' )
        return expr;
        
    var left  = this.simplify_ast( expr.a ),
        right = this.simplify_ast( expr.b );
    
    if( left.op == 'imm' && right.op == 'imm' ) {
      var lval = left.n, rval = right.n;
      
      var value;
      
      switch( this_op ) {
        case '+':   value = lval + rval; break;
        case '-':   value = lval - rval; break;
        case '*':   value = lval * rval; break;
        case '/':   value = lval / rval; break;
      }
      
      return { op: 'imm', n: value };
    }
    
    return { op: this_op, a: left, b: right };
};


Compiler.prototype.generate = function( node ) {
    var mc_ins = []
    
    if( node.op == 'imm' || node.op == 'arg' ) {
        if( node.op == 'imm' )
            mc_ins.push( 'IM ' + node.n );
        else
            mc_ins.push( 'AR ' + node.n );
    }
    else {
      mc_ins = this.generate( node.a );
      mc_ins = mc_ins.concat( this.generate( node.b ) );
      mc_ins = mc_ins.concat( ['PO', 'SW', 'PO'] );
      switch( node.op ) {
        case '+':   mc_ins.push( 'AD' ); break;
        case '-':   mc_ins.push( 'SU' ); break;
        case '*':   mc_ins.push( 'MU' ); break;
        case '/':   mc_ins.push( 'DI' ); break;
      }
    }
      
    return mc_ins.concat( ['PU'] );
};
