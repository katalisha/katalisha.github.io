---
layout: post
title: Swift Optionals, it's Christmas!
---
<img src="/images/fulls/present.jpg" class="fit image">


One of the trickier concepts when learning Swift is Optionals. Getting a grasp on Optionals is the first challenge for a new Swift developer. Not only are they crucial to building anything in Swift, they're usually a foreign concept as they don't exist in Objective C and popular web languages. So keeping with the season here's my Christmas themed introduction to Swift Optionals.

It was the night before Christmas
---------------------------------
And Santa was checking his list, Mina, Emily and Charlotte had been really good this year so they would get the best present - a Train Set. So he began to program his delivery drones (which of course run on Swift)

"Ok drone, here is a Train Set for Emily."
`var emilysPresent = TrainSet()`
Santa had the Train Set ready so no Optional was needed, this var's type is TrainSet

Then Santa had a problem, he couldn't find any more Train Sets and the drone couldn't wait.
Santa was sure he had another one nearby. "Here drone, take this box, I promise by the time you get to Mina's house there will be a Train Set  inside...because, magic"
`var minasPresent  : TrainSet!`
This var is Optional, specifically it's an implicitly unwrapped optional which means you can use it as a TrainSet type because Santa promised there's a TrainSet inside. So the drone can use it without checking the box first.

Santa was not sure he could find another TrainSet before the droid got to Charlotte's house. So he said "Drone, take this box, I might be able to magic a Train Set in there in time, if not the box will be empty. You'll have to unwrap it before you use it."
`var charlottesPresent : MilleniumFalcon?`
This var is Optional, it's wrapped so the drone will need to unwrap it and look inside to make sure there is a TrainSet inside before it tries to use it.

When the drone got to Charlottes house it unwrapped the box. If there was a TrainSet inside the box, then the drone would deliver it.
`if let charlottesPresent = charlottesPresent {
  deliver(charlottesPresent)
}`
Inside the if statement scope charlottesPresent is a now TrainSet type as it's been unwrapped.

The moral of the story
----------------------
To use some more standard language:
* vars and lets can be declared Optional if you don't have a value at definition time but may set one later
* Optionals can be implicitly unwrapped, this guarantees the Optional will have a value set before it is used, if the value is not set CRASH!
* To unwrap an Optional explicitly, use the `if let thing = thing {` syntax. `thing` will be the unwrapped type in the if statement scope.


[image attribution](https://www.flickr.com/photos/hades2k/6598576457/in/photolist-b46qTB-7pQUHL-7roJUY-5Hrfq8-7rjXrv-7rjKYV-7royrA-7rog63-j5pa4-7rjD9P-7rjMbX-dE3M7S-7ron1m-7rocfm-7ro6Ho-7rk8EH-7rjgm4-7rjsVM-7rk1yD-7rjJHF-7rjz4F-7ro8kJ-7rjk5n-7rjSPn-94xHpa-7roahL-7ro5fN-7roT9f-7rouZJ-7roupW-7roiMS-7rjYQT-7rjDDi-7rk2cg-7roRRU-7roWiQ-iFEd3B-7roE4E-7rk4cR-7rjdgH-7roxfy-7rjq3n-qibU1M-5M3Egr-5M7TH3-wCkCj-95rFAj-94XM5C-5U6WaZ-94UJD8)
