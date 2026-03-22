module serialize_test;
import std::collections;
import std::core::test;
import json;

fn void test_basic() @test {
	test::eq(json::to_json(true, tmem)!!, "true");
	test::eq(json::to_json("one", tmem)!!, `"one"`);
	test::eq(json::to_json(1, tmem)!!, "1");
}

struct Foo {
	bool is_bar;
	int baz;
}

fn void test_struct() @test {
	Foo foo = { .is_bar = true, .baz = 1 };
	test::eq(json::to_json(foo, tmem)!!, `{"is_bar":true,"baz":1}`);
}

fn void test_array() @test {
	int[] xs = { 1, 2 };
	test::eq(json::to_json(xs, tmem)!!, "[1,2]");
}

struct Bar {
	int[] bar;
}
fn void test_soa() @test {
	Bar bar = { .bar = { 1, 2 } };
	test::eq(json::to_json(bar, tmem)!!, `{"bar":[1,2]}`);
}

fn void test_aos() @test {
	Foo[] foos = { { .is_bar = true, .baz = 1 }, { .is_bar = false, .baz = 2 } };
	String expected = `[{"is_bar":true,"baz":1},{"is_bar":false,"baz":2}]`;
	test::eq(json::to_json(foos, tmem)!!, expected);
}

fn void test_maybe() @test {
	Maybe{int} x = maybe::value{int}(1);
	test::eq(json::to_json(x, tmem)!!, "1");
}

struct MaybeSkip {
	Maybe{int} foo @tag("json", "skip_empty");
	Maybe{int} bar @tag("json", "skip_empty");
	Maybe{int} foo_noskip;
	Maybe{int} bar_noskip;
}
fn void test_maybe_skip() @test {
	MaybeSkip maybe_skip = {
		.foo = maybe::value{int}(1),
		.bar = maybe::EMPTY{int},
		.foo_noskip = maybe::value{int}(1),
		.bar_noskip = maybe::EMPTY{int},
	};
	test::eq(json::to_json(maybe_skip, tmem)!!, `{"foo":1,"foo_noskip":1,"bar_noskip":null}`);
}

enum MyEnum {
	FOO,
	BAR,
}
fn void test_enum() @test {
	MyEnum my = FOO;
	test::eq(json::to_json(my, tmem)!!, `"FOO"`);
}

constdef MyConst {
	ONE,
	TWO,
	THREE,
}

enum MyEnumAssoc : char (String json_repr) {
	FOO { "foo" },
	BAR { "bar" },
}
fn void test_enum_assoc() @test {
	MyEnumAssoc my = BAR;
	test::eq(json::to_json(my, tmem)!!, `"bar"`);
}

struct StructWithUnion {
	union {
		Foo foo;
	}
}
fn void test_struct_with_union() @test {
	StructWithUnion s = {};
	if (catch err = json::to_json(s, tmem)) {
		test::eq(err, serialize::UNION_NOT_SUPPORTED);
	}
}

struct StructWithUnionCustom {
	union {
		Foo foo;
	}
}
fn void? StructWithUnionCustom.to_json(self, DString* dest) {
	// Unions not supported, must handle each variant manually
	serialize::add_json(self.foo, dest)!;
}
fn void test_struct_with_union_custom() @test {
	StructWithUnionCustom s = { .foo = { .is_bar = true} };
	test::eq(json::to_json(s, tmem)!!, `{"is_bar":true,"baz":0}`);
}

fn void test_hashmap() @test {
	HashMap{String,int} s;
	s.tinit();
	s.set("one", 1);
	test::eq(json::to_json(s, tmem)!!, `{"one":1}`);
}
