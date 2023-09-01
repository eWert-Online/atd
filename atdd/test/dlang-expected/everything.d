

  // Generated by atdd from type definitions in everything.atd.
  // This implements classes for the types defined in 'everything.atd', providing
  // methods and functions to convert data from/to JSON.
  
  // ############################################################################
  // # Private functions
  // ############################################################################
  
  module everything;

  import std.algorithm : map;
  import std.array : array;
  import std.conv;
  import std.format;
  import std.functional;
  import std.json;
  import std.sumtype;
  import std.typecons : nullable, Nullable, tuple, Tuple;
  
private
{
  class AtdException : Exception
  {
      this(string msg, string file = __FILE__, size_t line = __LINE__)
      {
          super(msg, file, line);
      }
  }
  
  T _atd_missing_json_field(T)(string typeName, string jsonFieldName)
  {
      throw new AtdException("missing field %s in JSON object of type %s".format(typeName, jsonFieldName));
  }
  
  // TODO check later if template is right way to go
  AtdException _atd_bad_json(T)(string expectedType, T jsonValue)
  {
      string valueStr = jsonValue.to!string;
      if (valueStr.length > 200)
      {
          valueStr = valueStr[0 .. 200];
      }
  
      return new AtdException(
          "incompatible JSON value where type '%s' was expected: %s".format(
              expectedType, valueStr
      ));
  }
  
  AtdException _atd_bad_d(T)(string expectedType, T jsonValue)
  {
      string valueStr = jsonValue.to!string;
      if (valueStr.length > 200)
      {
          valueStr = valueStr[0 .. 200];
      }
  
      return new AtdException(
          "incompatible D value where type '%s' was expected: %s".format(
              expectedType, valueStr
      ));
  }
  
  typeof(null) _atd_read_unit(JSONValue x)
  {
      if (x.isNull)
          return null;
      else
          throw _atd_bad_json("unit", x);
  }
  
  bool _atd_read_bool(JSONValue x)
  {
      try
          return x.boolean;
      catch (JSONException e)
          throw _atd_bad_json("bool", x);
  }
  
  int _atd_read_int(JSONValue x)
  {
      try
          return cast(int) x.integer;
      catch (JSONException e)
          throw _atd_bad_json("int", x);
  }
  
  float _atd_read_float(JSONValue x)
  {
      try
          return x.floating;
      catch (JSONException e)
          throw _atd_bad_json("float", x);
  }
  
  string _atd_read_string(JSONValue x)
  {
      try
          return x.str;
      catch (JSONException e)
          throw _atd_bad_json("string", x);
  }
  
  auto _atd_read_list(T)(T delegate(JSONValue) readElements)
  {
      return (JSONValue jsonVal) {
          if (jsonVal.type != JSONType.array)
              throw _atd_bad_json("array", jsonVal);
          auto list = jsonVal.array;
          return array(list.map!readElements());
      };
  }
  
  auto _atd_read_object_to_assoc_array(V)(
      V delegate(JSONValue) readValue)
  {
      auto fun = (JSONValue jsonVal) {
          if (jsonVal.type != JSONType.object)
              throw _atd_bad_json("object", jsonVal);
          V[string] ret;
          foreach (key, val; jsonVal.object)
              ret[key] = readValue(val);
          return ret;
      };
      return fun;
  }
  
  auto _atd_read_array_to_assoc_dict(K, V)(
      K delegate(JSONValue) readKey,
      V delegate(JSONValue) readValue)
  {
      auto fun = (JSONValue jsonVal) {
          if (jsonVal.type != JSONType.array)
              throw _atd_bad_json("list", jsonVal);
          V[K] ret;
          foreach (jsonInnerVal; jsonVal.array)
          {
              if (jsonInnerVal.type != JSONType.array)
                  throw _atd_bad_json("list", jsonInnerVal);
              ret[readKey(jsonInnerVal[0])] = readValue(jsonInnerVal[1]);
          }
          return ret;
      };
      return fun;
  }
  
  auto _atd_read_object_to_tuple_list(T)(
      T delegate(JSONValue) readValue)
  {
      auto fun = (JSONValue jsonVal) {
          if (jsonVal.type != JSONType.object)
              throw _atd_bad_json("object", jsonVal);
          auto tupList = new Tuple!(string, T)[](jsonVal.object.length);
          int i = 0;
          foreach (key, val; jsonVal.object)
              tupList[i++] = tuple(key, readValue(val));
          return tupList;
      };
      return fun;
  }
  
  auto _atd_read_nullable(T)(T delegate(JSONValue) readElm)
  {
      auto fun = (JSONValue e) {
          if (e.isNull)
              return Nullable!T.init;
          else
              return Nullable!T(readElm(e));
      };
      return fun;
  }
  
  auto _atd_read_option(T)(T delegate(JSONValue) readElm)
  {
      auto fun = (JSONValue e) {
          if (e.type == JSONType.string && e.str == "None")
              return Nullable!T.init;
          else if (e.type == JSONType.array && e.array.length == 2 && e[0].type == JSONType.string && e[0].str == "Some")
              return Nullable!T(readElm(e[1]));
          else
              throw _atd_bad_json("option", e);
      };
      return fun;
  }
  
  // this whole set of function could be remplaced by one templated _atd_write_value function
  // not sure it is what we want though
  
  JSONValue _atd_write_unit(typeof(null) n)
  {
      return JSONValue(null);
  }
  
  JSONValue _atd_write_bool(bool b)
  {
      return JSONValue(b);
  }
  
  JSONValue _atd_write_int(int i)
  {
      return JSONValue(i);
  }
  
  JSONValue _atd_write_float(float f)
  {
      return JSONValue(f);
  }
  
  JSONValue _atd_write_string(string s)
  {
      return JSONValue(s);
  }
  
  auto _atd_write_list(T)(JSONValue delegate(T) writeElm)
  {
      return (T[] list) { return JSONValue(array(list.map!writeElm())); };
  }
  
  auto _atd_write_assoc_array_to_object(T)(
      JSONValue delegate(T) writeValue)
  {
      auto fun = (T[string] assocArr) {
          JSONValue[string] ret;
          foreach (key, val; assocArr)
              ret[key] = writeValue(val);
          return JSONValue(ret);
      };
      return fun;
  }
  
  auto _atd_write_assoc_dict_to_array(K, V)(
      JSONValue delegate(K) writeKey,
      JSONValue delegate(V) writeValue)
  {
      auto fun = (V[K] assocArr) {
          JSONValue[] ret;
          foreach (key, val; assocArr)
              ret ~= JSONValue([writeKey(key), writeValue(val)]);
          return JSONValue(ret);
      };
      return fun;
  }
  
  auto _atd_write_tuple_list_to_object(T)(
      JSONValue delegate(T) writeValue)
  {
      auto fun = (Tuple!(string, T)[] tupList) {
          JSONValue[string] ret;
          foreach (tup; tupList)
              ret[tup[0]] = writeValue(tup[1]);
          return JSONValue(ret);
      };
      return fun;
  }
  
  auto _atd_write_nullable(T)(JSONValue delegate(T) writeElm)
  {
      auto fun = (Nullable!T elm) {
          if (elm.isNull)
              return JSONValue(null);
          else
              return writeElm(elm.get);
      };
      return fun;
  }
  
  auto _atd_write_option(T)(JSONValue delegate(T) writeElm)
  {
      auto fun = (Nullable!T elm) {
          if (elm.isNull)
              return JSONValue("None");
          else
              return JSONValue([JSONValue("Some"), writeElm(elm.get)]);
      };
      return fun;
  }
}
  // ############################################################################
  // # Public classes
  // ############################################################################
  
  T fromJsonString(T)(string s)
  {
      JSONValue res = parseJSON(s);
      return res.fromJson!T;
  }
  
  string toJsonString(T)(T obj)
  {
    JSONValue res = obj.toJson;
    return res.toString;
  }


struct RecursiveClass {
    int id;
    bool flag;
    RecursiveClass[] children;
}

RecursiveClass fromJson(T : RecursiveClass)(JSONValue x) {
    RecursiveClass obj;
    obj.id = ("id" in x) ? _atd_read_int(x["id"]) : _atd_missing_json_field!(typeof(obj.id))("RecursiveClass", "id");
    obj.flag = ("flag" in x) ? _atd_read_bool(x["flag"]) : _atd_missing_json_field!(typeof(obj.flag))("RecursiveClass", "flag");
    obj.children = ("children" in x) ? _atd_read_list((&fromJson!RecursiveClass).toDelegate)(x["children"]) : _atd_missing_json_field!(typeof(obj.children))("RecursiveClass", "children");
    return obj;
}
JSONValue toJson(RecursiveClass obj) {
    JSONValue res;
    res["id"] = _atd_write_int(obj.id);
    res["flag"] = _atd_write_bool(obj.flag);
    res["children"] = _atd_write_list(((RecursiveClass x) => x.toJson()))(obj.children);
    return res;
}


// Original type: kind = [ ... | Root | ... ]
struct Root_ {}
JSONValue toJson(Root_ e) {
    return JSONValue("Root");
}


// Original type: kind = [ ... | Thing of ... | ... ]
struct Thing { int value; }
JSONValue toJson(Thing e) {
    return JSONValue([JSONValue("Thing"), _atd_write_int(e.value)]);
}


// Original type: kind = [ ... | WOW | ... ]
struct WOW {}
JSONValue toJson(WOW e) {
    return JSONValue("wow");
}


// Original type: kind = [ ... | Amaze of ... | ... ]
struct Amaze { string[] value; }
JSONValue toJson(Amaze e) {
    return JSONValue([JSONValue("!!!"), _atd_write_list((&_atd_write_string).toDelegate)(e.value)]);
}


alias Kind = SumType!(Root_, Thing, WOW, Amaze);

Kind fromJson(T : Kind)(JSONValue x) {
    if (x.type == JSONType.string) {
        if (x.str == "Root") 
            return Kind(Root_());
        if (x.str == "wow") 
            return Kind(WOW());
        throw _atd_bad_json("Kind", x);
    }
    if (x.type == JSONType.array && x.array.length == 2 && x[0].type == JSONType.string) {
        string cons = x[0].str;
        if (cons == "Thing")
            return Kind(Thing(_atd_read_int(x[1])));
        if (cons == "!!!")
            return Kind(Amaze(_atd_read_list((&_atd_read_string).toDelegate)(x[1])));
        throw _atd_bad_json("Kind", x);
    }
    throw _atd_bad_json("Kind", x);
}

JSONValue toJson(Kind x) {
    return x.match!(
    (Root_ v) => v.toJson,
(Thing v) => v.toJson,
(WOW v) => v.toJson,
(Amaze v) => v.toJson
    );
}


alias Alias = int[];
JSONValue toJson(Alias e) {
    return _atd_write_list((&_atd_write_int).toDelegate)(e);
}
Alias fromJson(T : Alias)(JSONValue e) {
    return _atd_read_list((&_atd_read_int).toDelegate)(e);
}


alias KindParametrizedTuple = Tuple!(Kind, Kind, int);
JSONValue toJson(KindParametrizedTuple e) {
    return ((Tuple!(Kind, Kind, int) x) => JSONValue([((Kind x) => x.toJson())(x[0]), ((Kind x) => x.toJson())(x[1]), _atd_write_int(x[2])]))(e);
}
KindParametrizedTuple fromJson(T : KindParametrizedTuple)(JSONValue e) {
    return ((JSONValue x) { 
    if (x.type != JSONType.array || x.array.length != 3)
      throw _atd_bad_json("Tuple of size 3", x);
    return tuple(fromJson!Kind(x[0]), fromJson!Kind(x[1]), _atd_read_int(x[2]));
  })(e);
}


struct IntFloatParametrizedRecord {
    int field_a;
    float[] field_b = [];
}

IntFloatParametrizedRecord fromJson(T : IntFloatParametrizedRecord)(JSONValue x) {
    IntFloatParametrizedRecord obj;
    obj.field_a = ("field_a" in x) ? _atd_read_int(x["field_a"]) : _atd_missing_json_field!(typeof(obj.field_a))("IntFloatParametrizedRecord", "field_a");
    obj.field_b = ("field_b" in x) ? _atd_read_list((&_atd_read_float).toDelegate)(x["field_b"]) : [];
    return obj;
}
JSONValue toJson(IntFloatParametrizedRecord obj) {
    JSONValue res;
    res["field_a"] = _atd_write_int(obj.field_a);
    res["field_b"] = _atd_write_list((&_atd_write_float).toDelegate)(obj.field_b);
    return res;
}


struct Root {
    string id;
    bool await;
    int integer;
    float x___init__;
    float float_with_auto_default = 0.0;
    float float_with_default = 0.1;
    int[][] items;
    Nullable!int maybe;
    int[] extras = [];
    int answer = 42;
    Alias aliased;
    Tuple!(float, float) point;
    Kind[] kinds;
    Tuple!(float, int)[] assoc1;
    Tuple!(string, int)[] assoc2;
    int[float] assoc3;
    int[string] assoc4;
    Nullable!int[] nullables;
    Nullable!int[] options;
    JSONValue[] untyped_things;
    IntFloatParametrizedRecord parametrized_record;
    KindParametrizedTuple parametrized_tuple;
}

Root fromJson(T : Root)(JSONValue x) {
    Root obj;
    obj.id = ("ID" in x) ? _atd_read_string(x["ID"]) : _atd_missing_json_field!(typeof(obj.id))("Root", "ID");
    obj.await = ("await" in x) ? _atd_read_bool(x["await"]) : _atd_missing_json_field!(typeof(obj.await))("Root", "await");
    obj.integer = ("integer" in x) ? _atd_read_int(x["integer"]) : _atd_missing_json_field!(typeof(obj.integer))("Root", "integer");
    obj.x___init__ = ("__init__" in x) ? _atd_read_float(x["__init__"]) : _atd_missing_json_field!(typeof(obj.x___init__))("Root", "__init__");
    obj.float_with_auto_default = ("float_with_auto_default" in x) ? _atd_read_float(x["float_with_auto_default"]) : 0.0;
    obj.float_with_default = ("float_with_default" in x) ? _atd_read_float(x["float_with_default"]) : 0.1;
    obj.items = ("items" in x) ? _atd_read_list(_atd_read_list((&_atd_read_int).toDelegate))(x["items"]) : _atd_missing_json_field!(typeof(obj.items))("Root", "items");
    obj.maybe = ("maybe" in x) ? _atd_read_option((&_atd_read_int).toDelegate)(x["maybe"]) : typeof(obj.maybe).init;
    obj.extras = ("extras" in x) ? _atd_read_list((&_atd_read_int).toDelegate)(x["extras"]) : [];
    obj.answer = ("answer" in x) ? _atd_read_int(x["answer"]) : 42;
    obj.aliased = ("aliased" in x) ? fromJson!Alias(x["aliased"]) : _atd_missing_json_field!(typeof(obj.aliased))("Root", "aliased");
    obj.point = ("point" in x) ? ((JSONValue x) { 
    if (x.type != JSONType.array || x.array.length != 2)
      throw _atd_bad_json("Tuple of size 2", x);
    return tuple(_atd_read_float(x[0]), _atd_read_float(x[1]));
  })(x["point"]) : _atd_missing_json_field!(typeof(obj.point))("Root", "point");
    obj.kinds = ("kinds" in x) ? _atd_read_list((&fromJson!Kind).toDelegate)(x["kinds"]) : _atd_missing_json_field!(typeof(obj.kinds))("Root", "kinds");
    obj.assoc1 = ("assoc1" in x) ? _atd_read_list(((JSONValue x) { 
    if (x.type != JSONType.array || x.array.length != 2)
      throw _atd_bad_json("Tuple of size 2", x);
    return tuple(_atd_read_float(x[0]), _atd_read_int(x[1]));
  }))(x["assoc1"]) : _atd_missing_json_field!(typeof(obj.assoc1))("Root", "assoc1");
    obj.assoc2 = ("assoc2" in x) ? _atd_read_object_to_tuple_list((&_atd_read_int).toDelegate)(x["assoc2"]) : _atd_missing_json_field!(typeof(obj.assoc2))("Root", "assoc2");
    obj.assoc3 = ("assoc3" in x) ? _atd_read_array_to_assoc_dict((&_atd_read_float).toDelegate, (&_atd_read_int).toDelegate)(x["assoc3"]) : _atd_missing_json_field!(typeof(obj.assoc3))("Root", "assoc3");
    obj.assoc4 = ("assoc4" in x) ? _atd_read_object_to_assoc_array((&_atd_read_int).toDelegate)(x["assoc4"]) : _atd_missing_json_field!(typeof(obj.assoc4))("Root", "assoc4");
    obj.nullables = ("nullables" in x) ? _atd_read_list(_atd_read_nullable((&_atd_read_int).toDelegate))(x["nullables"]) : _atd_missing_json_field!(typeof(obj.nullables))("Root", "nullables");
    obj.options = ("options" in x) ? _atd_read_list(_atd_read_option((&_atd_read_int).toDelegate))(x["options"]) : _atd_missing_json_field!(typeof(obj.options))("Root", "options");
    obj.untyped_things = ("untyped_things" in x) ? _atd_read_list(((JSONValue x) => x))(x["untyped_things"]) : _atd_missing_json_field!(typeof(obj.untyped_things))("Root", "untyped_things");
    obj.parametrized_record = ("parametrized_record" in x) ? fromJson!IntFloatParametrizedRecord(x["parametrized_record"]) : _atd_missing_json_field!(typeof(obj.parametrized_record))("Root", "parametrized_record");
    obj.parametrized_tuple = ("parametrized_tuple" in x) ? fromJson!KindParametrizedTuple(x["parametrized_tuple"]) : _atd_missing_json_field!(typeof(obj.parametrized_tuple))("Root", "parametrized_tuple");
    return obj;
}
JSONValue toJson(Root obj) {
    JSONValue res;
    res["ID"] = _atd_write_string(obj.id);
    res["await"] = _atd_write_bool(obj.await);
    res["integer"] = _atd_write_int(obj.integer);
    res["__init__"] = _atd_write_float(obj.x___init__);
    res["float_with_auto_default"] = _atd_write_float(obj.float_with_auto_default);
    res["float_with_default"] = _atd_write_float(obj.float_with_default);
    res["items"] = _atd_write_list(_atd_write_list((&_atd_write_int).toDelegate))(obj.items);
    if (!obj.maybe.isNull)
        res["maybe"] = _atd_write_option((&_atd_write_int).toDelegate)(obj.maybe);
    res["extras"] = _atd_write_list((&_atd_write_int).toDelegate)(obj.extras);
    res["answer"] = _atd_write_int(obj.answer);
    res["aliased"] = ((Alias x) => x.toJson())(obj.aliased);
    res["point"] = ((Tuple!(float, float) x) => JSONValue([_atd_write_float(x[0]), _atd_write_float(x[1])]))(obj.point);
    res["kinds"] = _atd_write_list(((Kind x) => x.toJson()))(obj.kinds);
    res["assoc1"] = _atd_write_list(((Tuple!(float, int) x) => JSONValue([_atd_write_float(x[0]), _atd_write_int(x[1])])))(obj.assoc1);
    res["assoc2"] = _atd_write_tuple_list_to_object((&_atd_write_int).toDelegate)(obj.assoc2);
    res["assoc3"] = _atd_write_assoc_dict_to_array((&_atd_write_float).toDelegate, (&_atd_write_int).toDelegate)(obj.assoc3);
    res["assoc4"] = _atd_write_assoc_array_to_object((&_atd_write_int).toDelegate)(obj.assoc4);
    res["nullables"] = _atd_write_list(_atd_write_nullable((&_atd_write_int).toDelegate))(obj.nullables);
    res["options"] = _atd_write_list(_atd_write_option((&_atd_write_int).toDelegate))(obj.options);
    res["untyped_things"] = _atd_write_list((JSONValue x) => x)(obj.untyped_things);
    res["parametrized_record"] = ((IntFloatParametrizedRecord x) => x.toJson())(obj.parametrized_record);
    res["parametrized_tuple"] = ((KindParametrizedTuple x) => x.toJson())(obj.parametrized_tuple);
    return res;
}


struct RequireField {
    string req;
}

RequireField fromJson(T : RequireField)(JSONValue x) {
    RequireField obj;
    obj.req = ("req" in x) ? _atd_read_string(x["req"]) : _atd_missing_json_field!(typeof(obj.req))("RequireField", "req");
    return obj;
}
JSONValue toJson(RequireField obj) {
    JSONValue res;
    res["req"] = _atd_write_string(obj.req);
    return res;
}


alias Pair = Tuple!(string, int);
JSONValue toJson(Pair e) {
    return ((Tuple!(string, int) x) => JSONValue([_atd_write_string(x[0]), _atd_write_int(x[1])]))(e);
}
Pair fromJson(T : Pair)(JSONValue e) {
    return ((JSONValue x) { 
    if (x.type != JSONType.array || x.array.length != 2)
      throw _atd_bad_json("Tuple of size 2", x);
    return tuple(_atd_read_string(x[0]), _atd_read_int(x[1]));
  })(e);
}


// Original type: frozen = [ ... | A | ... ]
struct A {}
JSONValue toJson(A e) {
    return JSONValue("A");
}


// Original type: frozen = [ ... | B of ... | ... ]
struct B { int value; }
JSONValue toJson(B e) {
    return JSONValue([JSONValue("B"), _atd_write_int(e.value)]);
}


alias Frozen = SumType!(A, B);

Frozen fromJson(T : Frozen)(JSONValue x) {
    if (x.type == JSONType.string) {
        if (x.str == "A") 
            return Frozen(A());
        throw _atd_bad_json("Frozen", x);
    }
    if (x.type == JSONType.array && x.array.length == 2 && x[0].type == JSONType.string) {
        string cons = x[0].str;
        if (cons == "B")
            return Frozen(B(_atd_read_int(x[1])));
        throw _atd_bad_json("Frozen", x);
    }
    throw _atd_bad_json("Frozen", x);
}

JSONValue toJson(Frozen x) {
    return x.match!(
    (A v) => v.toJson,
(B v) => v.toJson
    );
}


struct DefaultList {
    int[] items = [];
}

DefaultList fromJson(T : DefaultList)(JSONValue x) {
    DefaultList obj;
    obj.items = ("items" in x) ? _atd_read_list((&_atd_read_int).toDelegate)(x["items"]) : [];
    return obj;
}
JSONValue toJson(DefaultList obj) {
    JSONValue res;
    res["items"] = _atd_write_list((&_atd_write_int).toDelegate)(obj.items);
    return res;
}
