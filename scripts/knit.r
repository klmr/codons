library = function (...)
    suppressMessages(base::library(..., warn.conflicts = FALSE, quietly = TRUE))

library(knitr)
library(modules)
library(ggplot2)
library(reshape2)
library(dplyr)

options(stringsAsFactors = FALSE,
        import.path = c('scripts', file.path(Sys.getenv('HOME'), 'Projects/R')))

opts_chunk$set(cache = TRUE)

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

# Configure ggplot2

theme_set(theme_bw())

# Add more functionality to ggplot2

# Inverse hyperbolic sine gives a nice y scale, similar to log but which is also
# defined for zero values (and negative values).

asinh_trans = function ()
    scales::trans_new('asinh', asinh, sinh, domain = c(-Inf, Inf))

scale_y_asinh = function (...)
    scale_y_continuous(..., trans = asinh_trans())

# Manual boxplot, since ggplot2’s doesn’t support coloured outliers.
# <http://stackoverflow.com/q/8499378/1968>

geom_box = function (...) {
    fullbox = function (x) {
        box = setNames(quantile(x, c(0.25, 0.5, 0.75)),
                       c('lower', 'middle', 'upper'))
        iqr = box[3] - box[1]
        ymin = min(x[x >= box[1] - 1.5 * iqr])
        ymax = max(x[x <= box[3] + 1.5 * iqr])
        c(ymin = ymin, box, ymax = ymax)
    }
    stat_summary(fun.data = fullbox, geom = 'boxplot', ...)
}

geom_outliers = function (...) {
    outliers = function (x) {
        box = quantile(x, c(0.25, 0.75))
        iqr = box[2] - box[1]
        x[(x < box[1] - 1.5 * iqr) | (x > box[2] + 1.5 * iqr)]
    }
    stat_summary(fun.y = outliers, geom = 'point', ...)
}

# A boxplot with nice defaults

gg_boxplot = function (data, col_data, colors) {
    data = melt(data, id.vars = NULL, variable.name = 'DO',
                value.name = 'Count') %>%
        inner_join(col_data, by = 'DO')
    ggplot(data, aes(factor(DO), Count, color = Celltype)) +
        geom_box() + geom_outliers(size = 1) +
        xlab('Library') +
        scale_y_asinh() +
        scale_color_manual(values = colors) +
        theme_bw()
}

melt = function (...) {
    args = list(...)
    result = reshape2::melt(...)
    varnames = if ('varnames' %in% names(args))
        args$varnames
    else if ('variable.name' %in% names(args))
        args$variable.name
    else
        'variable'

    result[, varnames] = sapply(result[, varnames], as.character)
    result
}
assign('melt', melt, globalenv())

# Load standard helpers

local({base = import('ebits/base')}, globalenv())
local({io = import('ebits/io')}, globalenv())
local({fs = import('fs')}, globalenv())
