import std.stdio;
import std.string : toLower;
import std.range, std.algorithm;

uint[] parsePattern(string pattern){
	return pattern.map!(c => (toLower(c) - 'a')).array;
}

unittest{
	assert(cmp(parsePattern("aaa"), [0, 0, 0]) == 0, "Testing aaa against 000 failed");
	assert(cmp(parsePattern("abc"), [0, 1, 2]) == 0, "Testing abc against 012 failed");
}

pure string extractPart(string source, const ulong[] borders, ulong index){
	ulong left = 0, right = source.length;
	if(index>0){
		left = borders[index-1];
	}
	if(index<borders.length){
		right = borders[index];
	}

	return source[left .. right];
}

auto byPart(string source, const ulong[] borders){
	struct PartExtractor{
		private string source;
		private const ulong[] borders;
		private ulong index;

		this(string source, const ulong[] borders){
			this.source = source;
			this.borders = borders;
		}

		bool empty(){
			return index == borders.length+1;
		}

		void popFront(){
			++index;
		}

		string front(){
			return source.extractPart(borders, index);
		}
	}
	return PartExtractor(source, borders);
}

unittest{
	auto source = "Hello World!";
	ulong[] borders = [2, 5];
	
	string[] parts = new string[borders.length+1];
	foreach(i; 0 .. borders.length+1){
		parts[i] = source.extractPart(borders, i);
	}
	assert(cmp(parts[0], "He") == 0, "Part 0 should be \"He\"");
	assert(cmp(parts[1], "llo") == 0, "Part 1 should be \"llo\"");
	assert(cmp(parts[2], " World!") == 0, "Part 2 should be \" World!\"");
}

bool check(const ulong[] borders, const uint[] pattern, string buffer){
	// create a list of equivalences, then check that the equivalences are 
	// actually equivalent
	uint[][uint] equivalences;

	debug{
		writeln("Checking borders: ", borders);
	}

	// build equivalence tree
	foreach(index, val; pattern){
		auto p = (val in equivalences);
		if(p is null){
			equivalences[val] = new uint[1];
			equivalences[val][0] = cast(uint)(index);
		}
		else{
			equivalences[val] ~= cast(uint)(index);
		}
	}

	// go through each equivalence array, make sure all parts are the same
	// while also checking that each set is unique
	bool[string] checker;

	foreach(equivalentParts; equivalences.byValue){
		// get reference string
		string reference = extractPart(buffer, borders, equivalentParts[0]);
		auto p = (reference in checker);
		if(p !is null){
			return false;
		}
		checker[reference] = true;

		foreach(partIndex; equivalentParts){
			auto part = extractPart(buffer, borders, partIndex);
			
			if(cmp(part, reference) != 0){
				return false; // equivalence broken
			}
		}
	}
	return true;
}

unittest{
	string source = "testtesttesttest";
	uint[] pattern = [0, 0, 0, 0];
	ulong[] borders = [ 4, 8, 12 ];

	assert(check(borders, pattern, source) == true, "testtesttesttest against 0000 should be true");

	pattern[3] = 2;
	assert(check(borders, pattern, source) == false, "testtesttesttest against 0002 should be false");
}

bool checkAtDepth(string source, const uint[] pattern, ulong[] borders, uint depth){
	debug{
		writeln("Checking at depth ", depth);
	}
	if(depth < borders.length){
		// enumerate through possible border positions
		// 
		// get left and right edges of enumerating depth
		// left is 1+border position of left edge, or 1 if depth = 0
		ulong left = 1;
		if(depth > 0){
			left = borders[depth-1]+1;
		}
		// right is max length to squeeze in all borders
		ulong right = source.length - (borders.length - depth) + 1;
		foreach(i; left .. right){
			borders[depth] = i;
			if(checkAtDepth(source, pattern, borders, depth+1)){
				return true;
			}
		}
		return false;
	}
	else{
		return check(borders, pattern, source);
	}
}

bool checkPattern(uint[] pattern, string buffer){
	ulong[] borders = new ulong[pattern.length-1];

	debug{
		writeln("Border count: ", borders.length);
		writeln("\nEntering recursive check");
	}

	auto result = checkAtDepth(buffer, pattern, borders, 0);
	if(result){
		// print parts
		foreach(part; buffer.byPart(borders)){
			writeln("Part: ", part);
		}
	}
	return result;
}

void main(string[] args){
	if(args.length != 3){
		stderr.writeln("Usage: prog pattern string");
		return;
	}
	const string buffer = args[2];
	
	auto pattern = parsePattern(args[1]);

	debug{
		writeln("Analyzing buffer: ", buffer);
		writeln("Checked pattern: ", pattern);
	}

	writeln("Result: ", checkPattern(pattern, buffer));
}
