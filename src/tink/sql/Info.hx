package tink.sql;

import haxe.ds.Option;
import tink.core.Any;

interface DatabaseInfo {
  function tablesnames():Iterable<String>;
  function tableinfo<Row:{}>(name:String):TableInfo<Row>;
}

interface TableInfo<Row:{}> {
  function getName():String;
  function getFields():Iterable<Column>;
  function fieldnames():Iterable<String>;
  function sqlizeRow(row:Insert<Row>, val:Any->String):Array<String>;
}

typedef Column = {
  > FieldType,
  name:String,
  keys:Array<KeyType>,
}

typedef FieldType = {
  nullable:Bool,
  type:DataType,
}

enum KeyType {
  Primary;
  Index(indexName:Option<String>);
  Unique(indexName:Option<String>);
}

enum DataType {
  DBool;
  DInt(bits:Int, signed:Bool, autoIncrement:Bool);
  DFloat(bits:Int);
  DString(maxLength:Int);
  DText(size:TextSize);
  DBlob(maxLength:Int);
  DDateTime;
  DPoint; // geojson
  DMultiPolygon; // geojson
}

enum TextSize {
  Tiny;
  Default;
  Medium;
  Long;
}

typedef Insert<Row> = Row;