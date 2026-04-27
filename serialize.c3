module json::serialize;
import std::core;
import std::io;

macro void? add_json(src, DString* dest) {
	$if ($defined($typeof(src).to_json)):
		src.to_json(dest)!;
		return;
	$endif

	// Switch on primitives
	$switch ($typeof(src)):
		$case String:
			dest.append(`"`);
			dest.append(src);
			dest.append(`"`);
			return;
		$case bool:
			if (src) {
				dest.append("true");
			} else {
				dest.append("false");
			}
			return;
		$case int:
			dest.appendf("%d", src);
			return;
	$endswitch

	// Switch on complex types
	$switch ($typeof(src)::kind):
		$case TypeKind.ENUM:
			dest.appendf(`"`);
			$if ($defined($typeof(src).json_repr)):
				dest.appendf(src.json_repr);
			$else
				dest.appendf(src.description);
			$endif
			dest.appendf(`"`);
		$case TypeKind.STRUCT:
			String $struct_name = $typeof(src)::name;
			// Check Maybe first
			$if (@starts_with($struct_name, "Maybe{")):
				if (src.has_value) {
					add_json(src.$eval($typeof(src)::members[0].name), dest)!!;
				} else {
					dest.appendf("null");
				}
				return;
			$endif

			$if (@starts_with($struct_name, "HashMap{")):
				add_hashmap(src, dest)!!;
				return;
			$endif

			// Not Maybe, just regular struct
			dest.append("{");
			int members_written;
			$foreach $member : $typeof(src)::members:
				// TODO why not just kind directly?
				$if ($member.type.kind == TypeKind.UNION):
					return UNION_NOT_SUPPORTED~;
				$else
					// check for @tag("json", "skip_empty")
					bool $memb_is_maybe_skip = false;
					String $member_name = $member.name;
					typeid $member_type = $member.type;
					$if (@starts_with($member_type.name, "Maybe{")):
						$if ($member.has_tag("json")):
							$if ($member.get_tag("json") == "skip_empty"):
								$memb_is_maybe_skip = true;
							$endif
						$endif
					$endif

					// TODO clean up this logic. compile time and runtime interaction is a bit messy
					$if ($memb_is_maybe_skip):
						if (!src.$eval($member_name).has_value) {
						// do nothing
						} else {
							if (members_written > 0) {
								dest.append(",");
							}
							dest.appendf(`"%s":`, $member.name);
							add_json(src.$eval($member.name), dest)!!;
							members_written += 1;
						}
					$else
						if (members_written > 0) {
							dest.append(",");
						}
						dest.appendf(`"%s":`, $member.name);
						add_json(src.$eval($member.name), dest)!!;
						members_written += 1;
					$endif
				$endif
			$endforeach
			dest.append("}");
			return;
		$case TypeKind.SLICE:
			dest.append("[");
			foreach (idx, element : src) {
				if (idx > 0) {
					dest.append(",");
				}
				add_json(element, dest)!!;
			}
			dest.append("]");
			return;
		$case TypeKind.UNION:
			return UNION_NOT_SUPPORTED~;
	$endswitch

	// TODO add error here if type not supported?
}

// Using iter; with the @each_entry, didn't like using var
// in the macro body call.
macro void? add_hashmap(src, DString* dest) {
	$if (!@starts_with($typeof(src)::name, "HashMap{")):
		return EXPECTED_HASHMAP~;
	$endif

	dest.append("{");
	usz idx;
	var iter = src.iter();
	while (idx < iter.len()) {
		var entry = iter.get(idx);
		var key = entry.key;
		var value = entry.value;
		if (idx > 0) {
			dest.append(",");
		}
		add_json(key, dest)!;
		dest.append(":");
		add_json(value, dest)!;
		idx += 1;
	};
	dest.append("}");
}

faultdef UNION_NOT_SUPPORTED, EXPECTED_HASHMAP;

macro @starts_with($s, $prefix) {
	$switch:
		$case $prefix.len > $s.len: return false;
		$case !$prefix.len: return true;
		$default: return $s[:$prefix.len] == $prefix;
	$endswitch
}
