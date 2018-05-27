---
title: Algorithms
layout: page
---

How do we solve the different change-making problems? The problem is easy to state, but finding a solution is not so straightforward. The problem is a standard example in algorithms so you can easily find more details in most textbooks. Here is a short discussion on the implementation. The functions referred to are in the file [`Makechange.pm`](https://github.com/kbseah/changer-ranger/blob/master/Makechange.pm) of the accompanying code.

## Greedy change-making

This is the method that most people use to make change. Start with the largest coins that you have, and work your way down. This can be done via an explicit iteration ("loop") or as a recursion. The function `makechange_greedy` uses this method.

## Enumerating all ways to make change

How can we find all the possible combinations of coins that add up to a certain amount? If we start making a list, how do we do so systematically such that we are sure that we haven't missed anything?

One solution is to use a recursive procedure. This is simply a procedure that calls itself. The procedure is nicely explained in [SICP](http://www.mitpress.mit.edu/sites/default/files/sicp/full-text/book/book-Z-H-11.html#%_sec_1.2.1), and is implemented in the function `makechange`.

If one wants in addition to the total number of coins also the actual types of coins used to make change, then the function must be modified. In `makechange2` I added an array to keep track of the solutions. This is passed as a reference to the internal function `makechange2_internal`.

## Finding the optimal change faster

The above algorithm takes a long time because it exhaustively enumerates all the possible solutions, including those that are obviously not the optimal way to make change (e.g. using only 1 cent coins).

We can speed this up with a ['branch and bound'](https://en.wikipedia.org/wiki/Branch_and_bound) method. This is a very simple idea when searching for the shortest route down a bunch of forking paths: if we are going down a path that is already longer than the shortest solution that we've found so far, backtrack and try the next path. In that way, we avoid wasting time in paths that we already know to be ineffective.

This is implemented in `makechange3`, which keeps track of the lowest solution found thus far, compares it to the currently active solution, and updates it when a better one is found. The savings in not going down the garden paths more than compensates for the extra overhead that this entails.
