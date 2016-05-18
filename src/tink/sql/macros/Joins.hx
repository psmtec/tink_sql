package tink.sql.macros;

import haxe.macro.Context;
import tink.sql.Target.JoinType;
import haxe.macro.Type;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;

class Joins { 
  static function getFilter(e:Expr) {
    return switch Context.typeof(macro @:pos(e.pos) {
      var source = $e;
      var x = null;
      @:privateAccess source._all(x);
      x;
    }).reduce() {
      case TFun(args, ret):
        args;
      default:
        throw 'assert';
    }
  }
  
  static function getRow(e:Expr)
    return Context.typeof(macro @:pos(e.pos) {
      var source = $e, x = null;
      source.all().forEach(function (y) { x = y; return true; } );
      x;
    });
    
  static public function perform(type:JoinType, left:Expr, right:Expr, cond:Expr) {
        
    var rowFields = new Array<Field>(),
        fieldsObj = [];
    
    function traverse(e:Expr, fieldsExpr:Expr) {
      
      function add(name, type, ?nested) {
        
        rowFields.push({
          name: name,
          pos: e.pos,
          kind: FProp('default', 'null', type),
        });              
        
        fieldsObj.push({
          field: name,
          expr: 
            if (nested) macro $fieldsExpr.fields.$name
            else macro $fieldsExpr.fields
        });
      }
      
      var parts = getFilter(e);
      switch parts {
        case [single]:
          
          add(single.name, getRow(e).toComplex());
          
        default:
          switch getRow(e).reduce().toComplex() {
            case TAnonymous([for (f in _) f.name => f] => byName):
              for (p in parts)
                add(p.name, switch byName[p.name] {
                  case null: e.reject('Lost track of ${p.name}');
                  case f: f.getVar().sure().type;
                }, true);
            default:
              e.reject();
          }
      }
      return parts;
    }
    
    var total = traverse(left, macro left);
    total = total.concat(traverse(right, macro right));//need separate statements because of evaluation order
    
    var f:Function = {
      expr: macro return null,
      ret: macro : tink.sql.Expr.Condition,
      args: [for (a in total) {
        name: a.name,
        type: a.t.toComplex({ direct: true }),
      }],
    }
    
    switch cond {
      case { expr: EFunction(_, _) } :
      default:
        cond = cond.func(f.args).asExpr(cond.pos);
    }
    
    var rowType = TAnonymous(rowFields);
    var filterType = f.asExpr().typeof().sure().toComplex( { direct: true } );
    
    var ret = macro @:pos(left.pos) @:privateAccess {
      
      var left = $left,
          right = $right;
      
      function toCondition(filter:$filterType)
        return ${(macro filter).call([for (field in fieldsObj) field.expr])};
        
      var ret = new tink.sql.Dataset(
        ${EObjectDecl(fieldsObj).at()},
        left.cnx, 
        tink.sql.Target.TJoin(left.target, right.target, ${joinTypeExpr(type)}, toCondition($cond)), 
        toCondition
      );
      
      if (false) {
        ret._all().forEach(function (item:$rowType) return true);
      }
      
      ret;
      
    }
    
    return ret;
  }
  
  static function joinTypeExpr(t:JoinType)
    return switch t {
      case Inner: macro Inner;
      case Left: macro Left;
      case Right: macro right;
    }
  
}