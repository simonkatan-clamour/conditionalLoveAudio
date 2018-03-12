(
~phraseBook =();

// Plurals
~phraseBook.put("PL", ["the people", "the wealthy", "the poor", "the strivers", "the successful", "the wretched", "men", "women", "rights", "priviledges"]);

// Mass Nouns - people
~phraseBook.put("MN1", ["the state", "hierarchy", "oligarchy", "everyone", "anyone", "nobody", "the individual", "the underclass", "the population" ]);

// Mass Nouns - concepts
~phraseBook.put("MN2", ["government", "wealth", "justice", "freedom", "truth", "equality"]);

//Modal Verbs (MV)
~phraseBook.put("MV", ["can", "can’t", "will", "will not", "must", "must not"]);

//Verb (V)
~phraseBook.put("V", ["accommodate", "support", "trust", "recognise", "punish", "protect", "restrict", "resist"]);

//PastVerb (PV)
~phraseBook.put("PV", ["accommodated", "supported", "trusted", "recognised", "punished", "protected", "restricted", "resisted"]);

//Adv phrases (Adv)
~phraseBook.put("PV", ["without cause", "with good cause", "without compromise", "with reason", "in good faith"]);


//recursive function to create sentences
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

var sentenceTypes = [
	["(MN|PL)", "MV", "V"],
	["MN|PL", "MV", "V", "Adv"],
	["MN|PL", "MV", "V", "MN|PL", "Adv"],

(MN|PL), V (s)

(MN|PL), V (s), Adv

(MN|PL), V (s), (MN|PL), Adv

MN2, MV + be, PV +  by, (MN|PL)

]


//I'm abandoning this to do it in js
)

