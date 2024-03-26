.onAttach <- function(libname = find.package("trackRcheck"), pkgname = "trackRcheck") {
  packageStartupMessage("This is version ", utils::packageVersion(pkgname), " of ", pkgname)
  packageStartupMessage("Here I can insert some more comments fpr the starting")}
