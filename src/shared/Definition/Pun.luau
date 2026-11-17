--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
local PUNS: { string } = table.freeze({
	"What do you say to impatient jockeys? Hold your horses.",
	"I applied for a position at the hair-replacement company because I heard there was growth potential.",
	"You know the problem with grapes these days. People just aren't raisin them right.",
	"My phone has to wear glasses ever since it lost its contacts.",
	"Did you hear about the guy whose whole left side was cut off? He's all right now.",
	"I wondered why the baseball was getting bigger. Then it hit me.",
	"I'm reading a book about anti-gravity. It's impossible to put down.",
	"I'd tell you a chemistry joke but I know I wouldn't get a reaction.",
	"I used to be a banker but I lost interest",
	"Did you hear about the guy who got hit in the head with a can of soda? He was lucky it was a soft drink.",
	"Claustrophobic people are more productive thinking outside the box.",
	"Have you ever tried to eat a clock? It's very time consuming.",
	"I don't trust these stairs because they're always up to something.",
	"My friend's bakery burned down last night. Now his business is toast.",
	"I used to have a fear of hurdles, but I got over it.",
	"I couldn't quite remember how to throw a boomerang, but eventually it came back to me.",
	"Need an ark to save two of every animal? I noah guy.",
	"To write with a broken pencil is pointless.",
	"Police were called to a daycare where a three-year-old was resisting a rest.",
	"I'm glad I know sign language, it's pretty handy.",
	"A bicycle can't stand on its own because it is two-tired.",
	"When Peter Pan punches, they Neverland.",
	"A prisoner's favorite punctuation mark is the period. It marks the end of his sentence.",
	"I relish the fact that you've mustard the strength to ketchup to me.",
	"The roundest knight at king Arthur's round table was Sir Cumference.",
	"There was once a cross-eyed teacher who couldn't control his pupils.",
	"Yesterday I accidentally swallowed some food coloring. The doctor says I'm OK, but I feel like I've dyed a little inside.",
	"The butcher backed up into the meat grinder and got a little behind in his work.",
	"I did a theatrical performance about puns. Really it was just a play on words.",
	"The one who invented the door knocker got a No-bell prize.",
	"A new type of broom came out, it is sweeping the nation.",
	"The other day I held the door open for a clown. I thought it was a nice jester.",
	"Why did the pig stop sunbathing? He was bacon in the heat.",
	"What did the grape say when it got stepped on? Nothing - but it let out a little whine.",
	"I think Santa has riverfront property in Brazil. All our presents came from Amazon this year.",
	"Don't trust people that do acupuncture, they're back stabbers.",
	"Always trust a glue salesman. They tend to stick to their word.",
	"It was an emotional wedding. Even the cake was in tiers.",
	"Sleeping comes so naturally to me, I could do it with my eyes closed.",
	"Novice pirates make terrible singers because they can't hit the high seas.",
	"I used to be addicted to soap, but I'm clean now.",
	"I was going to look for my missing watch, but I could never find the time.",
	"I was going to buy a book on phobias, but I was afraid it wouldn't help me.",
	"The girl quit her job at the doughnut factory because she was fed up with the hole business.",
	"Jill broke her finger today, but on the other hand she was completely fine.",
	"When a clock is hungry it goes back four seconds.",
	"Two hats were hanging on a hat rack in the hallway. One hat says to the other, 'You stay here, I'll go on a head.'",
	"The dead batteries were given out free of charge.",
	"Some people's noses and feet are built backwards: their feet smell and their noses run.",
	"If towels could tell jokes they would probably have a dry sense of humor.",
	"I went to the dentist without lunch, and he gave me a plate.",
	"I really wanted a camouflage shirt, but I couldn't find one.",
	"My new theory on inertia doesn't seem to be gaining momentum.",
	"Pencils could be made with erasers at both ends, but what would be the point?",
	"Broken puppets for sale. No strings attached.",
	"Einstein developed a theory about space, and it was about time too.",
	"I heard the new auto body shop that opened comes highly wreck-a-mended.",
	"There was a big paddle sale at the boat store. It was quite an oar deal.",
	"Did you hear about these new reversible jackets? I'm excited to see how they turn out.",
	"Time flies like an arrow. Fruit flies like a banana.",
	"The magician got so mad he pulled his hare out.",
	"I was going to tell you a joke about infinity, but it didn't have an ending!",
	"I try wearing tight jeans, but I can never pull it off.",
	"I can't believe I got fired from the calendar factory. All I did was take a day off.",
	"For Sale: Parachute. Only used once, never opened.",
	"What was Forrest Gump's email password? '1forrest1'",
	"Why was Cinderella thrown off the basketball team? She ran away from the ball.",
	"A book just fell on my head. I've only got myshelf to blame.",
	"I was going to give him a nasty look, but he already had one.",
	"Last time I got caught stealing a calendar I got 12 months.",
	"Why did the bee get married? Because he found his honey.",
	"What if there were no hypothetical questions?",
	"What part of a football ground is never the same? The changing rooms.",
	"What do ghosts serve for dessert? I Scream.",
	"What do sea monsters eat for lunch? Fish and ships.",
	"Do skunks celebrate Valentine's Day? Sure, they're very scent-imental!",
	"What do prisoners use to call each other? Cell phones.",
	"What do you call a fish with no eye? FSH",
	"Where do you find a birthday present for a cat? In a cat-alogue!",
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.roll = function(rng: Random): string
	return PUNS[rng:NextInteger(1, #PUNS)]
end

return Module
