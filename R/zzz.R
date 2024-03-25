.onAttach <- function(libname = find.package("trackRcheck"), pkgname = "trackRcheck") {
  packageStartupMessage("This is version ", utils::packageVersion(pkgname), " of ", pkgname)}
