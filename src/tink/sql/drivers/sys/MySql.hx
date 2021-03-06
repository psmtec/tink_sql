package tink.sql.drivers.sys;

import tink.sql.Driver;

@:require(neko || java || php) //making sure this is not used on nodejs ... deserves refinement
class MySql extends StdDriver {
  
  public function new(settings:MySqlSettings) {
    #if (!macro && (neko || java || php))
      check();
      super(function (name) return sys.db.Mysql.connect({ //TODO: this fella seems to generate invalid JavaScript code
        host: switch settings.host {
          case null: 'localhost';
          case v: v;
        },
        user: settings.user,
        pass: settings.password,
        database: name,
      }), tink.sql.drivers.MySql.getSanitizer);
    #else
      super(null);
    #end
  }
  
  macro static function check() {
    if (haxe.macro.Context.defined('java'))
      try {
        haxe.macro.Context.getType('com.mysql.jdbc.jdbc2.optional.MysqlDataSource');
      }
      catch (e:Dynamic) {
        haxe.macro.Context.error('It seems your build does not include a mysql driver. Consider using `-lib jdbc.mysql`', haxe.macro.Context.currentPos());
      }
    return macro null;
  }  
}