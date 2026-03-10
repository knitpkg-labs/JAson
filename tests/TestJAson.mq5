#property copyright "Copyright © 2019-2021 Artem Maltsev (Vivazzi)"
#property link      "https://vivazzi.pro"
#property description   "Tests for JAson"
#property strict


#include "../knitpkg/include/vivazzi/JAson/JAson.mqh"
#include "unit_test.mqh"


class TestJAson: public TestCase {
public:
    void test_simple() {
        CJAVal data;

        data["a"] = 3.14;
        data["b"] = "foo";
        data["c"].Add("bar");
        data["c"].Add(2);
        data["c"].Add("baz");

        assert_equal(data["b"].ToStr(), "foo");

        string data_str = data.Serialize();  // {"a":3.14000000,"b":"foo","c":["bar",2,"baz"]}
        assert_equal(data_str, "{\"a\":3.14000000,\"b\":\"foo\",\"c\":[\"bar\",2,\"baz\"]}");

        CJAVal data_2;
        data_2.Deserialize(data_str);
        assert_equal(data_2["a"].ToDbl(), 3.14);
        assert_equal(data_2["b"].ToStr(), "foo");

        assert_equal(data_2["c"][0].ToStr(), "bar");
        assert_equal(data_2["c"][1].ToInt(), 2);
        assert_equal(data_2["c"][2].ToStr(), "baz");

        assert_equal(data_2.HasKey("c"), true);
        assert_equal(data_2.HasKey("non-existent"), false);
    }

    void test_complex() {
        CJAVal data;

        data["a"] = 3.14;
        data["b"] = "foo";

        data["c"].Add("bar");
        data["c"].Add(2);
        data["c"].Add("baz");

        CJAVal sub_data_list;
        sub_data_list.Add(1);
        sub_data_list.Add("bar");

        data["c"].Add(sub_data_list);

        CJAVal sub_data_obj_in_list;
        sub_data_obj_in_list["sub_a"] = "muz";
        sub_data_obj_in_list["sub_b"] = 22;

        data["c"].Add(sub_data_obj_in_list);

        CJAVal sub_data_obj;
        sub_data_obj["sub_c"] = "muz2";
        sub_data_obj["sub_d"] = 44;

        data["d"] = sub_data_obj;


        // test: Size()
        assert_equal(data.Size(), 4);
        assert_equal(data["a"].Size(), 0);
        assert_equal(data["b"].Size(), 0);

        assert_equal(data["c"].Size(), 5);
        assert_equal(data["c"][0].Size(), 0);
        assert_equal(data["c"][1].Size(), 0);
        assert_equal(data["c"][2].Size(), 0);
        assert_equal(data["c"][3].Size(), 2);
        assert_equal(data["c"][4].Size(), 2);

        assert_equal(data["d"].Size(), 2);


        // test: Serialize() and Deserialize()
        string serialized_data_str = data.Serialize();  // {"a":3.14000000,"b":"foo","c":["bar",2,"baz",[1,"bar"],{"sub_a":"muz","sub_b":22}],"d":{"sub_c":"muz2","sub_d":44}
        string data_str = "{\"a\":3.14000000,\"b\":\"foo\",\"c\":[\"bar\",2,\"baz\",[1,\"bar\"],{\"sub_a\":\"muz\",\"sub_b\":22}],\"d\":{\"sub_c\":\"muz2\",\"sub_d\":44}}";
        assert_equal(serialized_data_str, data_str);

        CJAVal data_2;
        data_2.Deserialize(data_str);
        assert_equal(data_2["a"].ToDbl(), 3.14);
        assert_equal(data_2["b"].ToStr(), "foo");

        assert_equal(data_2["c"][0].ToStr(), "bar");
        assert_equal(data_2["c"][1].ToInt(), 2);
        assert_equal(data_2["c"][2].ToStr(), "baz");
        assert_equal(data_2["c"][3][0].ToInt(), 1);
        assert_equal(data_2["c"][3][1].ToStr(), "bar");
        assert_equal(data_2["c"][4]["sub_a"].ToStr(), "muz");
        assert_equal(data_2["c"][4]["sub_b"].ToInt(), 22);

        assert_equal(data_2["d"]["sub_c"].ToStr(), "muz2");
        assert_equal(data_2["d"]["sub_d"].ToInt(), 44);
    }

    void test_deserializing() {
        CJAVal data;

        data["a"] = 3.14;
        data["b"] = "foo";

        string data_str = data.Serialize();

        CJAVal data_2;
        bool deserialized;
        deserialized = data_2.Deserialize(data_str);
        assert_equal(deserialized, true);

        data_str = "\"a\":1,\"b\":\"foo\"";  // "a":1,"b":"foo" - you can deserialize without parentheses
        deserialized = data_2.Deserialize(data_str);
        assert_equal(deserialized, true);

        // bad data
        string bad_data_str;
        bad_data_str = "{\"a\":1,\"b\":foo\"}";  // {"a":1,"b":foo"} - missing: "
        deserialized = data_2.Deserialize(bad_data_str);
        assert_equal(deserialized, false);

        bad_data_str = "{\"a\":,\"b\":\"foo\"}";  // {"a":,"b":"foo"} - missing: value
        deserialized = data_2.Deserialize(bad_data_str);
        assert_equal(deserialized, false);

        bad_data_str = "{\"a\":1,\"b\":[\"foo\", \"bar\"}";  // {"a":1,"b":["foo", "bar"} - missing: [
        deserialized = data_2.Deserialize(bad_data_str);
        assert_equal(deserialized, false);
    }

    void test_clear() {
        CJAVal data;
        string data_str;

        data["a"] = 3.14;
        data["b"] = "foo";
        data_str = data.Serialize();
        assert_equal(data_str, "{\"a\":3.14000000,\"b\":\"foo\"}");

        data.Clear();
        data["c"] = 123;
        data["d"] = "bar";
        data_str = data.Serialize();
        assert_equal(data_str, "{\"c\":123,\"d\":\"bar\"}");

        // old notexistent keys
        assert_equal(data["a"].ToDbl(), 0.0);
        assert_equal(data["a"].type, jtUNDEF);
        assert_equal(data["b"].ToStr(), "");
        assert_equal(data["b"].type, jtUNDEF);

        // current keys
        assert_equal(data["c"].ToInt(), 123);
        assert_equal(data["c"].type, jtINT);
        assert_equal(data["d"].ToStr(), "bar");
        assert_equal(data["d"].type, jtSTR);

        // never used keys
        assert_equal(data["e"].ToStr(), "");
        assert_equal(data["e"].type, jtUNDEF);
    }

    void test_loops() {
        CJAVal data;

        data["a"] = 7;
        data["b"] = "foo";

        data["c"].Add("bar");
        data["c"].Add("baz");

        // 1-st level
        string keys[3] = {"a", "b", "c"};
        for (int i = 0; i < ArraySize(data.children); i++) {
            CJAVal* json_obj = GetPointer(data.children[i]);
            assert_equal(json_obj.key, keys[i]);
        }

        // 2-nd level
        string values[2] = {"bar", "baz"};
        for (int i = 0; i < ArraySize(data.children[2].children); i++) {
            CJAVal* json_obj = GetPointer(data.children[2].children[i]);
            assert_equal(json_obj.str_v, values[i]);
        }
    }

    void declare_tests() {
        test_simple();
        test_complex();
        test_deserializing();
        test_clear();
        test_loops();
    }

};

int OnStart(){
    TestJAson test_jason;
    test_jason.run();

	return(INIT_SUCCEEDED);
}