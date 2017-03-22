## Downstream analysis code for the “Mammalian codon usage” manuscript

The code in this repository comprises the entirety of the analysis code for the
manuscript “Mammalian codon usage”. After cloning the repository and installing
the necessary dependencies, the analysis can be run using

```shell
make
```

Be warned that this may take quite a while.
The supplementary material (tables and figures) can then be generated using

```shell
make supplements
```

## Data

In order to run the code, the project data needs to be [downloaded from
Figshare][data] and put directly into the folder `data` under the project root:

[data]: https://doi.org/10.6084/m9.figshare.2056227.v1

```shell
make download-data
```

### Dependencies

The code has a number of dependencies. The following packages need to be
installed manually from their respective sources (CRAN, Bioconductor or Github):

* Biostrings, 2.36.1
* DESeq2, 1.8.1
* brew, 1.0.6
* dplyr, 0.4.3.9000
* ggbeeswarm, 0.3.0
* ggplot2, 1.0.1
* gplots, 2.17.0
* gridExtra, 2.0.0
* knitr, 1.10.5
* lazyeval, 0.1.10.9000
* magrittr, 1.5
* methods, 3.2.1
* modules, 0.8.2
* pander, 0.5.2
* parallel, 3.2.1
* piano, 1.8.2
* reshape2, 1.4.1.9000
* rvest, 0.2.0.9000
* tidyr, 0.3.1.9000
* xlsx, 0.5.7
* xml2, 0.1.9000

The code uses (pre-1.0) ‹[modules][]›. The following modules need to be
installed from Github:

* [sys@4030e59][sys]
* [ebits@d9e42ad][ebits]

[modules]: https://github.com/klmr/modules
[sys]: https://github.com/klmr/sys/tree/4030e59b044de835a2efcbbea507349322951a5d
[ebits]: https://github.com/EBI-predocs/ebits/tree/d9e42ad61ee601b0bad0a499d1ea8224e9ce7f40

> **Note to users**: At the time of writing, ‹ebits› has not yet been published.
> Consequently, the above link unfortunately does not work, and the code in this
> project cannot be run directly.

> However, while crucial to the project, ‹ebits› is merely a collection of
> general purpose programming tools; it does not contain logic pertaining to
> this project. Most of its uses are transparent and should not impact the
> understanding of the code. There is just two exceptions:

> * ‹ebits› introduces a new meaning for the operator `->`, which is used
>   liberally in the code. The code declares an anonymous function. These two
>   are therefore equivalent:
>
>    ```r
>    x -> x * 2
>    ```
>
>    ```r
>    function (x) x * 2
>    ```
>
>   And so are these:
>
>    ```r
>    x ~ y -> x + y
>    ```
>
>    ```r
>    function (x, y) x + y
>    ```
>
> * ‹ebits› introduces the operator `%.%` for function composition. Given two
>   functions `f` and `g`, `(f %.% g)(x)` is equivalent to `f(g(x))`.
