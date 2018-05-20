changer-ranger
==============

Fun with the change-making problem.

See [section 1.2 of SICP](https://mitpress.mit.edu/sites/default/files/sicp/full-text/book/book-Z-H-11.html#%_sec_1.2.2) and ["What this country needs is an 18¢ piece"](https://cs.uwaterloo.ca/~shallit/Papers/change2.pdf) (pdf) by Jeffrey Shallit (2003).

The change-making problems
--------------------------

This is a problem that has faced anyone who handles cash: For a given set of coin denominations (e.g. 1 cent, 10 cent, 50 cent), how do we make change for a given amount of money? Assume for the moment that we are not limited in our supply of coins but have to figure out how to make up a given amount in coins. A cashier at a supermarket, for example, might encounter this situation.

In this situation, there are two related problems:

 * **Change-making problem** - How many ways are there to make change for that amount, assuming you are not limited in coins?
 * **Optimal-change problem** - What is the combination that minimizes the number of coins you have to use? (also called the change-making problem in some contexts)

These problems, and the methods for finding the answer, are standard examples in introductions to computing or algorithms. The change-making problem is often used to introduce the subject of recursive algorithms, which involve a function that calls itself as part of its execution.

The optimal-denomination problem
--------------------------------

The change-making problem assumes that you have coins in a given denomination, e.g. 25, 10, 5, 1 for the US dollar. What if you had a free hand in designing your own money? In the **optimal-denomination problem**, we want to find the coinage that minimizes the average change that one has to make. Of course, it would be impractical to have a coin for every number from 1 to 99, so we constrain the problem by specifying that one is limited to, say, 4 or 5 different types of coins (though the euro has 6 coins for values below 1 Eur).

This problem has been tackled by Shallit (2003), who assumed that the coin-user would encounter every amount from 1 to 99 cents with equal probability.

Extending the change-making and optimal-denomination problems
-------------------------------------------------------------

Here we explore some extensions to the above problems:

 * What is the optimal change in terms of total weight? Does it differ for the result that minimizes the number of coins?
 * What is the optimal denomination when we consider real-life prices? For example, prices that end in .99 and .50 are noticeably more common.
 * How do real-life currencies measure up in terms of their optimality?

How to generate change tables
-----------------------------

The script `makechange.pl` computes the best combination of coins for a given amount of change (in cents). This can be either in terms of minimizing the total number of coins, or minimizing the total weight of the change. Data for a number of common currencies have been included with the script. Instructions for using the script are displayed with the help message: `perl makechange.pl --help`.

The script can run in verbose mode (explain in English what the results mean, and also display the combination of coins used) or in default tabular mode, where only the summary statistics are displayed. The best-change statistics can be computed for a single amount (option `--amount`), or for a range of values (options `--min` and `--max`). The latter were used to generate the tables in the folder `changestats`.

Data sources
------------

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
