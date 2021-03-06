# Return TRUE if x and y are equal or both NA
null_equal <- function(x, y) {
  if (is.null(x) && is.null(y)) {
    return(TRUE)
  } else if (is.null(x) || is.null(y)) {
    return(FALSE)
  } else {
    return(x == y)
  }
}

#' Check that the current PHATE version in Python is up to date.
#'
#' @importFrom utils packageVersion
#' @export
check_pyphate_version <- function() {
  pyversion <- strsplit(pyphate$`__version__`, '\\.')[[1]]
  rversion <- strsplit(as.character(packageVersion("phateR")), '\\.')[[1]]
  major_version <- as.integer(rversion[1])
  minor_version <- as.integer(rversion[2])
  if (as.integer(pyversion[1]) < major_version) {
    warning(paste0("Python PHATE version ", pyphate$`__version__`, " is out of date (recommended: ",
                   major_version, ".", minor_version, "). Please update with pip ",
                   "(e.g. ", reticulate::py_config()$python, " -m pip install --upgrade phate) or phateR::install.phate()."))
    return(FALSE)
  } else if (as.integer(pyversion[2]) < minor_version) {
    warning(paste0("Python PHATE version ", pyphate$`__version__`, " is out of date (recommended: ",
                   major_version, ".", minor_version, "). Consider updating with pip ",
                   "(e.g. ", reticulate::py_config()$python, " -m pip install --upgrade phate) or phateR::install.phate()."))
    return(FALSE)
  }
  return(TRUE)
}

failed_pyphate_import <- function(e) {
  message("Error loading Python module phate")
  message(e)
  result <- as.character(e)
  if (length(grep("ModuleNotFoundError: No module named 'phate'", result)) > 0 ||
      length(grep("ImportError: No module named phate", result)) > 0) {
    # not installed
    if (utils::menu(c("Yes", "No"), title="Install PHATE Python package with reticulate?") == 1) {
      install.phate()
    }
  } else if (length(grep("r\\-reticulate", reticulate::py_config()$python)) > 0) {
    # installed, but envs sometimes give weird results
    message("Consider removing the 'r-reticulate' environment by running:")
    if (length(grep("virtualenvs", reticulate::py_config()$python)) > 0) {
      message("reticulate::virtualenv_remove('r-reticulate')")
    } else {
      message("reticulate::conda_remove('r-reticulate')")
    }
  }
}

load_pyphate <- function() {
  py_config <- try(reticulate::py_discover_config(required_module = "phate"))
  delay_load = list(on_load=check_pyphate_version, on_error=failed_pyphate_import)
  # load
  pyphate <- try(reticulate::import("phate", delay_load = delay_load))
  pyphate
}

#' Install PHATE Python Package
#'
#' Install PHATE Python package into a virtualenv or conda env.
#'
#' On Linux and OS X the "virtualenv" method will be used by default
#' ("conda" will be used if virtualenv isn't available). On Windows,
#' the "conda" method is always used.
#'
#' @param envname Name of environment to install packages into
#' @param method Installation method. By default, "auto" automatically finds
#' a method that will work in the local environment. Change the default to
#' force a specific installation method. Note that the "virtualenv" method
#' is not available on Windows.
#' @param conda Path to conda executable (or "auto" to find conda using the PATH
#'  and other conventional install locations).
#' @param pip Install from pip, if possible.
#' @param ... Additional arguments passed to conda_install() or
#' virtualenv_install().
#'
#' @export
install.phate <- function(envname = "r-reticulate", method = "auto",
                          conda = "auto", pip=TRUE, ...) {
  tryCatch({
    message("Attempting to install PHATE Python package with reticulate")
    reticulate::py_install("phate",
      envname = envname, method = method,
      conda = conda, pip=pip, ...
    )
    message("Install complete. Please restart R and try again.")
  },
  error = function(e) {
    stop(paste0(
      "Cannot locate PHATE Python package, please install through pip ",
      "(e.g. ", reticulate::py_config()$python, " -m pip install --user phate) and then restart R."
    ))
  }
  )
}

pyphate <- NULL

#' @importFrom reticulate py_discover_config
#' @importFrom memoise memoise
.onLoad <- function(libname, pkgname) {
  pyphate <<- memoise::memoise(load_pyphate)
}
