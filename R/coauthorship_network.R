#' Motu working paper co-authorship network
#' 
#' \code{coauthorship_network} returns the co-authorship network among Motu working paper authors.
#' 
#' \code{coauthorship_network} returns one of three networks, depending on the \code{weights} argument:
#' \describe{
#' \item{"counts"}{The network with edge weights equal to the number of working papers co-authored by incident authors.}
#' \item{"newman"}{The network with edge weights equal to those defined in equation (2) of Newman (2001).}
#' \item{"none"}{An unweighted network in which authors are adjacent if they have co-authored a working paper.}
#' }
#' 
#' @usage coauthorship_network(weights = "none")
#' 
#' @param weights Character scalar.
#' Possible values are \code{counts}, \code{newman}, and \code{none} (the default).
#' See details.
#' 
#' @return An igraph graph object.
#' 
#' @references Newman, M. E. J. (2001).
#' Scientific collaboration networks: II. Shortest paths, weighted networks, and centrality.
#' \emph{Physical Review E} 64, 016132.
coauthorship_network <- function(weights = "none") {
  if (!weights %in% c("counts", "newman", "none")) {
    stop("Unrecognised value of argument `weights`")
  }
  if (weights == "newman") {
    A <- table(motuwp::authors$number, motuwp::authors$author)
    w <- 1 / (rowSums(A) - 1)
    w[is.infinite(w)] <- 0
    W <- t(A) %*% diag(w) %*% A
    diag(W) <- 0
    return(igraph::graph.adjacency(W, mode = "undirected", weighted = TRUE))
  }
  bip <- igraph::graph_from_data_frame(motuwp::authors, directed = FALSE)
  igraph::V(bip)$type <- igraph::V(bip)$name %in% motuwp::authors$author
  if (weights == "counts") {
    return(igraph::bipartite_projection(bip, which = "true"))
  } else (
    return(igraph::bipartite_projection(bip, which = "true", multiplicity = FALSE))
  )
}
