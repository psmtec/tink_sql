package tink.sql;

import haxe.macro.Context;
import haxe.macro.Type;

#if macro
using tink.MacroApi;
#end

enum TargetType {
	From<T>(target:Dataset<T>);
	LeftJoin<T1, T2>(target:Target<T1>, join:Dataset<T2>);
	RightJoin<T1, T2>(target:Target<T1>, join:Dataset<T2>);
	InnerJoin<T1, T2>(target:Target<T1>, join:Dataset<T2>);
	OuterJoin<T1, T2>(target:Target<T1>, join:Dataset<T2>);
}

// e.g. Datasets = {tbl1:Dataset, tbl2:Dataset}
class Target<Datasets> {
	var datasets:Datasets;
	var type:TargetType;
	
	public function new(datasets, type) {
		this.datasets = datasets;
		this.type = type;
	}
	
	/*
	from({a1: t1}).leftJoin({a2: t2})
	
	{a1:Dataset<T1>, a2:Dataset<T2>}
	*/
	public macro function leftJoin(ethis, expr) {
		var alias = switch Context.typeof(expr).reduce() {
			case TAnonymous(_.get() => {fields: [field]}):
				field.name;
			default:
				expr.pos.error('leftJoin() accepts anonymous object with one field');
		}
		return macro @:pos(ethis.pos) {
			var _this = $ethis;
			var dataset = $expr;
			new tink.sql.Target(
				tink.Anon.merge(@:privateAccess _this.datasets, dataset),
				LeftJoin(_this, dataset.$alias.as($v{alias}))
			);
		}
	}
	
	/*
	target.select({col1: table1.a, col2: table2.a})
	
	Dataset<{col1:Column<Int>, col2:Column<Int>}>
	*/
	public macro function select(ethis, expr) {
		return macro {
			tink.sql.macro.Macro.splatFields(@:privateAccess $ethis.datasets, 'columns');
			new Dataset(null, null, $expr);
		}
	}
	
}