Hello! **If you're looking at my GitHub profile from my resume, welcome! Here's what to know:**

This whole thing is one file. That's one of the restrictions of making a game with PICO-8. Most heinous? Maybe, but I don't make the rules.
Different sections are delineated with a `--- XXX ---` comment, where `XXX` describes that section.
If you open this in the PICO-8 editor (drag and drop the file to https://www.pico-8-edu.com/, esc to edit, ctrl+R to run), you'll see it broken into 
several tabs. In the text file, these are separated with a `-->8`.

I do some funky binary/bit manipulation in here to enable Saving under PICO-8's restrictions. There's also some interesting metatable swapping for
different game modes which feels like a Lua-implementation of both functional programming and OO simultaneously. Those algorithms are 100% original.
No StackOverflow nor AI involved here. This is a for-fun project and that's the sort of creative puzzle-solving I really enjoy.

The class inheritance structure was pulled from [this video](https://www.youtube.com/watch?v=X9qKODb-wXg&pp=ygUOcGljbyA4IGNsYXNzZXM%3D). That's the only
one I pulled from elsewhere.

Sprites, map, sounds, and level design were also all created 100% by me. I'm pretty pleased with how the sprites turned out :)

--

**If you're here from the PICO-8 community:**
Welcome! I'm thrilled with PICO-8. I've always wanted to make a game but every game engine I've found has overwhelmed me with its bells and whistles.
I already know how to code, I don't want to learn a whole new system. And many of the plugins that game engines include take away from the 
problem-solving/imagination aspect that I so enjoy from coding that inspires me to make a game. All I really want is something that makes rendering
easy (so I don't have to figure out buffers) and otherwise just lets me code a game. Enter: PICO-8! Exactly what I'm looking for. 

I also love the harsh restrictions of the system. These helped me limit the scope of the game from this massive idea in my brain down to something
more manageable. I've had a game idea in my head for a few years and this project feels like a huge stepping stone towards that goal while still making
something rewarding and satisfying to play. Plus I can play on my Miyoo Mini!

And there's a cool community. And the color palette for the sprites is already figured out. And ctrl+R to run makes iterating unbelievably quick. Etc.

--

Anyways, **about the game**. I learned early on that saving is not an automatic inclusion with PICO-8 and has to be implemented specifically if you want it.
I wanted it. The limitations around saving were the main constraints that determined many aspects of this game: the number of bugs, their stats,
the number of achievements, the size of the dungeon, etc. The `subint()` and `writeint()` methods in the first tab were created to support this. Since you 
can only save 64 32-bit Numbers, having the option to write N bits within that number allows you much more flexibility with data storage: 2048 bits instead of just
64 Numbers. Use `writeint()` to write your bits to a number, then `dset()` to save that number. When loading, use `dget()` to retrieve the number and 
`subint()` to pull specific values out of it. You'll have to keep track of which values are stored in which indices in which numbers elsewhere, usually a 
comment, but this is a great place to start.

The "glom" concept was pulled from Dragon Quest Monsters: Joker, which was one of mine and my brother's favorite games as a kid. I always thought it added 
some extra planning, engagement, and surprise factor that made it more fun than Pokemon. The 3x3 battle box concept was pulled from Defenders of Texel. I
loved that game on my iPod Touch until they started cranking out bad patches and tanked it, eventually removing it from the app store. I've never seen that
battle concept anywhere else and thought it would be fun to revisit. It makes more sense on a touch screen, where you can swipe a line easily, but I still
think it's intuitive enough on here and makes battles/strategizing more interesting. The roguelike level style is a symptom of PICO-8's paring-down. I think
it grants the game way more replay value though than my original idea (a huge Zelda-like world). I've always loved roguelikes like Binding of Isaac, Hades,
and Dead Cells. They're so easy to pick up and play when I've got 30 minutes that I find myself coming back to them year after year way more often than the
big RPGs. I hoped to capture some of that ease-of-play here. I really wanted to make a game that I could play for 2 minutes on a bathroom break or for 2 
hours at home and either way feel like I accomplished something and had fun.

--

Thanks for checking it out!

\- Brendan Boyd
