(
~phrasesA = [
	["the state", "the people","justice" ,"wealth"],
	["will", "can't"],
	["accommodate", "exclude", "trust"],
	["everyone", "anyone", "no one"],
	["in need", "without cause", "without question"]
];

~output = [];
)


(
~unpack = {|idx, tree, list|

	//straight down
	if(idx[0]< tree.size(),
	{
		tree[idx[0]].size().do(
		{|count|
				var nlist = list.copy;
				nlist = list ++ " " ++ tree[idx[0]][count];
				//record the text into the dictionary
				nlist.postln;
				~unpack.value([idx[0] + 1, count], tree, nlist);
		});
	});

}
)

(

var idx = [0,0];
~unpack.value(idx,~phrasesA, "" );

)

//NB. could we have a word tree that bifurcates into other sentences ?


