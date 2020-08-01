# Old-Programs
An assortment of old programs



## Destack

![Screenshot of a Destack game in progress](/DestackScreenshot.png)

Card game inspired by SHENZHEN SOLITAIRE (Zachtronics 2016).

The game consists of 6 main-field stacks, 3 holding cells, and 3 target stacks.
Inorder to move a card or stack of cards, it must be placed on top of a card with a different suit and of the next value.
Cards can also be "Destacked", allowing the bottom card to be taken and placed on the top or bottom of a stack.
Placing at the bottom of the stack requires the bottom card to be of a different suit and of the previous value.
For instance, in the screenshot, either the black or red 7 at the bottom of the stacks can be placed under the green 6.
There are also three letter cards of each suit, when all three letter cards of a suit are exposed, they can be used to fill a holding cell by clicking the UI button that appears.
The target stacks are filled by placing all of the cards of a suit into them in numerically ascending order.



## DestackV2

![Screenshot of a DestackV2 game in progress](/DestackV2Screenshot.png)

A more presentable version of "Destack" with sound effects and animations, with a few gameplay changes that increased the difficulty.
- The number of main-field stacks was reduced from 6 to 4.
- Letter cards, which are now face cards, occupy a specific slot instead of blocking a holding cell.
- Placing a card at the bottom of a stack now requires the card to be of the same suit.
- New game and exit buttons, hold to activate.

Features that were planned:
- Help and options menu on ? button.
- Suit colour picker for colour blind accessibility and customisation



## PathFind

[![asciicast](https://asciinema.org/a/mcIz7iVlI9FAUBMTSIjfttvcb.svg)](https://asciinema.org/a/mcIz7iVlI9FAUBMTSIjfttvcb)

A* pathfinding implemented in lua.
Maps are randomly generated using a voronoi method with an non-linear distance function, which gives it a a more unique appearance.

Terminal capture hosted by asciinema.org.
