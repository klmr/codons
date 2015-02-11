library = function (...) suppressMessages(base::library(...))
assign('library', library, globalenv())

library(knitr)
library(modules)
library(ggplot2)

options(stringsAsFactors = FALSE,
        import.path = c('scripts', file.path(Sys.getenv('HOME'), 'Projects/R')))

#opts_chunk$set(cache = TRUE)

# Pretty-print tables

library(pander)

panderOptions('table.split.table', Inf)
panderOptions('table.alignment.default',
              function (df) ifelse(sapply(df, is.numeric), 'right', 'left'))
panderOptions('table.alignment.rownames', 'left')

# Enable automatic table reformatting.
opts_chunk$set(render = function (object, ...) {
    if (is.data.frame(object) ||
        is.matrix(object) ||
        is.tbl_df(object))
        pander(object, style = 'rmarkdown')
    else if (isS4(object))
        show(object)
    else
        print(object)
})

# Helpers for dplyr tables

is.tbl_df = function (x)
    'tbl_df' %in% class(x)

pander.tbl_df = function (x, ...)
    pander(trunc_mat(x), ...)

# Copied from dplyr:::print.trunc_mat
pander.trunc_mat = function (x, ...) {
    if (! is.null(x$table))
        pander(x$table, ...)

    if (length(x$extra) > 0) {
        var_types = paste0(names(x$extra), ' (', x$extra, ')', collapse = ', ')
        pander(dplyr:::wrap('Variables not shown: ', var_types))
    }
}

# Disable code re-formatting.
opts_chunk$set(tidy = FALSE)

# Configure ggplot

theme_set(theme_bw())

# Load standard helpers

local({base = import('ebits/base')}, globalenv())
local({io = import('ebits/io')}, globalenv())
local({fs = import('fs')}, globalenv())
