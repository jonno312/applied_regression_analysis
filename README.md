# Applied Regression Analysis

## Description

This is a (bare-bones, first-draft) textbook on applied regression analysis.
It's a "Just the facts, ma'am"-style treatment of the material that focuses
more on concepts and less on math.

## Contents

1. Prerequisites
    1. [Exponents](01_prereqs/01_exponents.qmd)
    2. [Logarithms](01_prereqs/02_logarithms.qmd)
    3. [Intercept and Slope](01_prereqs/03_intercept_and_slope.qmd)
    4. [Integrals](01_prereqs/04_integral.qmd)
    5. [Derivatives](01_prereqs/05_derivative.qmd)
    6. [Probability](01_prereqs/06_probability.qmd)
    7. [Random Variable](01_prereqs/07_random_variable.qmd)
    8. [Distribution](01_prereqs/08_distribution.qmd)
    9. [Support](01_prereqs/09_support.qmd)
    10. [Continuous and Discrete Random Variables](01_prereqs/10_continuous_discrete.qmd)
    11. [Probability Mass Function](01_prereqs/11_PMF.qmd)
    12. [Probability Density Function](01_prereqs/12_PDF.qmd)
    13. [Graphical Representations of Probability](01_prereqs/13_graph_prob.qmd)
    14. [Expected Value](01_prereqs/14_expected_value.qmd)
    15. [Independence](01_prereqs/15_independence.qmd)
    16. [Population and Sample](01_prereqs/16_population_sample.qmd)
    17. [Sample Average](01_prereqs/17_sample_average.qmd)
    18. [Parameter and Statistic](01_prereqs/18_parameter_statistic.qmd)
    19. [Tilde](01_prereqs/19_tilde.qmd)
    20. [Estimator and Estimand](01_prereqs/20_estimator_estimand.qmd)
    21. [Variance](01_prereqs/21_variance.qmd)
    22. [Bias](01_prereqs/22_bias.qmd)
    23. [Accuracy and Precision](01_prereqs/23_accuracy_precision.qmd)
    24. [Hypothesis Test](01_prereqs/24_hypothesis_test.qmd)
    25. [Marginal and Conditional Distributions](01_prereqs/25_marginal_conditional.qmd)
    26. [Conditional Expectation](01_prereqs/26_conditional_expectation.qmd)
2. Simple Linear Regression
    1. [Linearity Assumption](02_simple/01_linear_assumption.qmd)
    2. [Consequences of the Linearity Assumption](02_simple/02_linear_consequences.qmd)
    3. [Fitted Values and Residuals](02_simple/03_fitted_values_residuals.qmd)
    4. [Checking the Linearity Assumption](02_simple/04_linear_evaluation.qmd)
    5. [IID Assumption](02_simple/05_iid_assumption.qmd)
    6. [Consequences of the IID Assumption](02_simple/06_iid_consequences.qmd)
    7. [Checking the IID Assumption](02_simple/07_iid_evaluation.qmd)
    8. [Homoscedasticity Assumption](02_simple/08_homoscedasticity_assumption.qmd)
    9. [Consequences of the Homoscedasticity Assumption](02_simple/09_homoscedasticity_consequences.qmd)
    10. [Checking the Homoscedasticity Assumption](02_simple/10_homoscedasticity_evaluation.qmd)
    11. [Normality Assumption](02_simple/11_normality_assumption.qmd)
    12. [Consequences of the Normality Assumption](02_simple/12_normality_consequences.qmd)
    13. [Checking the Normality Assumption](02_simple/13_normality_evaluation.qmd)
    14. [LINE](02_simple/14_LINE.qmd)
    15. [Interpretation](02_simple/15_interpretation.qmd)
    16. [Hypothesis Testing](02_simple/16_hypothesis_testing.qmd)
    17. [Ordinary Least Squares](02_simple/17_OLS.qmd)
    18. [Log-Transformed Outcomes](02_simple/18_log_transform_outcome.qmd)
    19. [Shifting the Data to Make the Intercept Interpretable](02_simple/19_shift_for_intercept.qmd)
    20. [Robust Standard Errors](02_simple/20_robust_SE.qmd)

## Using the Textbook

### Software

In order to use the textbook, I recommend that you download
[R](https://lib.stat.cmu.edu/R/CRAN/) and
[RStudio](https://posit.co/downloads).

### Cloning This Repository

The first time you use this textbook, you will have to clone the GitHub
repository.
To do so, follow these instructions:

1. Open RStudio.
2. In the upper right-hand corner of your screen, look for an R inside
a blue cube. It should be next to the words "Project: (None)".
Click here.
3. Click "New Project..."
4. Click "Version Control".
5. Click "Git".
6. Under "Repository URL:", enter
`https://github.com/jonno312/applied_regression_analysis`.
7. Click "Browse..." to tell RStudio where to put the clone on your computer.
8. Click "Create Project".

### Updating Your Clone

Each time you use the textbook, you should check for updates.
You can do so by following these instructions:

1. At the top of your screen, look for an icon consisting of "GIt"
written vertically, with the "G" in gray, the "I" in red,
and the "t" in green.
Click this icon.
2. Click "Pull Branches" next to the blue arrow pointing down.


### Rendering to HTML

Once you've cloned the repo, you'll have to render the Quarto documents
to HTML.
There should be a "Render" button at the top of the window when you
open each Quarto document.
If you need to install any packages,
RStudio should tell you.

### Closing the Project

When you're done using the textbook, you should close the project in R.

1. Click the R in the blue cube next to "applied_regression_analysis".
2. Click "Close Project".

## License

This work is licensed under a Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International license
([CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)).

## AI

I did not use AI to create these materials.
I thought that creating them myself would make me a better teacher
and statistician.
Jury's still out on that one.
