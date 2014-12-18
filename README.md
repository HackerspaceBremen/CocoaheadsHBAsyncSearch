CocoaheadsHBAsyncSearch
=======================

An iOS demo project showing two ways of doing **async search** while typing in a UITextField. Doing live searching once with standard Grand Central Dispatch calls and once with NSOperations. You can easily compare and see how it's done.

This project was the result of a discussion in **CocoaHeads Bremen**.

## Screenshot

Three screens of the app in action.

![image](//screenshot_animation.gif)

## Features

* displays async search done using Grand Central Dispatch calls
* displays async search done using NSOperations
* searches the holy bible text live while typing in textfield

## Installation

1. download project
2. compile and start
3. enter text in the textfield
4. switch the ways of searching

That's it! Please recognize, that the 200ms difference in the time needed to display the results is the effect of giving poptime.

## License

All code is published under public domain, thus free.

## Attribution

* The code was put together by **Helge Städtler** and **Alexander Repty** from CocoaHeads Bremen
* You con meet us here at [Hackerspace bremen e.V.](https://www.hackerspace-bremen.de/) each 3rd Monday of the month, come by and join a bunch of iOS & OS X geeks