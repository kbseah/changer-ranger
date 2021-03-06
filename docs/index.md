---
layout: home
---

![By Michael Sander [GFDL (http://www.gnu.org/copyleft/fdl.html) or CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0)], from Wikimedia Commons](https://upload.wikimedia.org/wikipedia/commons/e/ee/Kiloware.JPG)

*Photo source: by Michael Sander, CC BY-SA 4.0, via [Wikimedia Commons](https://upload.wikimedia.org/wikipedia/commons/e/ee/Kiloware.JPG)*

 * The coins of the US dollar are not rationally designed
 * The optimal denomination using three coins is: 1, 30, and 90 ¢

How does one come to these conclusions? Read on ...

## Background

### The change-making problem

This is a problem that has faced anyone who handles cash: For a given set of coin denominations (e.g. 1 cent, 10 cent, 50 cent), how do we make change for a given amount of money? Assume for the moment that we are not limited in our supply of coins but have to figure out how to make up a given amount in coins. A cashier at a supermarket, for example, might encounter this situation.

In this situation, there are two related problems:

 * **Change-making problem** - How many ways are there to make change for that amount, assuming you are not limited in coins?
 * **Optimal-change problem** - What is the combination that minimizes the number of coins you have to use? (also called the change-making problem in some contexts)

These problems, and the methods for finding the answer, are standard examples in introductions to computing or algorithms. The change-making problem is often used to introduce the subject of recursive algorithms, which involve a function that calls itself as part of its execution.

### The optimal-denomination problem

The change-making problem assumes that you have coins in a given denomination, e.g. 25, 10, 5, 1 for the US dollar. What if you had a free hand in designing your own money? In the **optimal-denomination problem**, we want to find the coinage that minimizes the average change that one has to make. Of course, it would be impractical to have a coin for every number from 1 to 99, so we constrain the problem by specifying that one is limited to, say, 4 or 5 different types of coins (though the euro has 6 coins for values below 1 EUR).

This problem has been tackled by Shallit (2003), who assumed that the coin-user would encounter every amount from 1 to 99 cents with equal probability.

## Extending the change-making and optimal-denomination problems

Here we explore some extensions to the above problems:

 * [Real-life currencies](real.html)
    - What is the optimal change in terms of total weight? Does it differ for the result that minimizes the number of coins?
    - How do real-life currencies measure up in terms of their optimality?
 * [Real-life prices](prices.md)
    - What is the optimal denomination when we consider real-life prices? For example, prices that end in .99 and .50 are noticeably more common.
    - Is the optimal denomination for a cashier different than that for a customer?

## How the results were generated

[Algorithms](algorithms.html) for calculating the optimal change for a given amount and denomination have been implemented in the script `makechange.pl` available in the accompanying [GitHub repository](https://github.com/kbseah/changer-ranger). The script computes the best combination of coins for a given amount of change (in cents). This can be either in terms of minimizing the total number of coins, or minimizing the total weight of the change. The solution from the greedy algorithm is also supplied for comparison. Data for a number of common currencies have been included with the script. Instructions for using the script are displayed with the help message: `perl makechange.pl --help`.

The script can run in verbose mode (explain in English what the results mean, and also display the combination of coins used) or in default tabular mode, where only the summary statistics are displayed. The best-change statistics can be computed for a single amount (option `--amount`), or for a range of values (options `--min` and `--max`). The latter were used to generate the tables in the folder `changestats`.

## Further reading

 * Abelson H and Sussman GJ, with Sussman J. 1996. [Section 1.2. Procedures and the processes they create.](http://www.mitpress.mit.edu/sites/default/files/sicp/full-text/book/book-Z-H-11.html#%_sec_1.2) In: Structure and interpretation of computer programs. 2nd ed. MIT Press.
 * Dominus MJ. 2005. Chapter 1. Recursion and Callbacks. In: [Higher-order Perl](https://hop.perl.plover.com/book/). Elsevier.
 * Shallit J. 2003. "What this country needs is an 18¢ piece" ([pdf](https://cs.uwaterloo.ca/~shallit/Papers/change2.pdf)). Mathematical Intelligencer 25 (2) : 20-23.
 * Wright JW. 1975. ["The change-making problem"](https://dl.acm.org/citation.cfm?doid=321864.321874). Journal of the Association for Computing Machinery 22 (1) : 125-128.
 * Wikipedia: [Change-making problem](https://en.wikipedia.org/wiki/Change-making_problem)

## Data sources

The [ISO 4217 code](https://en.wikipedia.org/wiki/ISO_4217) is used to refer to the currencies in the included data, except for pre-decimal British currency, where I have used the abbreviation "[LSD](https://en.wikipedia.org/wiki/£sd)" (for *librae solidi denarii* - pounds, shillings, pence).

Data on coin denominations and weights are from the following English Wikipedia articles:
 * [Japanese Yen](https://en.wikipedia.org/wiki/Japanese_yen)
 * [Euro coins](https://en.wikipedia.org/wiki/Euro_coins)
 * [Coins of the pound sterling](https://en.wikipedia.org/wiki/Coins_of_the_pound_sterling)
 * [Coins of the United States dollar](https://en.wikipedia.org/wiki/Coins_of_the_United_States_dollar)
 * [Coins of the Australian dollar](https://en.wikipedia.org/wiki/Coins_of_the_Australian_dollar)
 * [Singapore dollar](https://en.wikipedia.org/wiki/Singapore_dollar)
 * [Pre-decimal British coinage](https://en.wikipedia.org/wiki/Coins_of_the_pound_sterling)
 * [Coins of the Swiss franc](https://en.wikipedia.org/wiki/Coins_of_the_Swiss_franc)

Some additional data were obtained from [Numista](https://en.numista.com), which is also a great general resource for numismatics.
