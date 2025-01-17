# R script to analyze SSLB biclusters
# 1. calculate p-value for difference in factor values for ER-negative patients
# 2. find p-values (Fisher's exact test) for other marker genes from Zhang et al (2014) "Estrogen receptor- positive breast cancer molecular signatures and therapeutic potentials"
# 3. calculate proportions of patients in each hypothesised breast cancer subtype
# 4. conduct gene ontology enrichement analysis using clusterProfiler (and create enrichment maps)

library(clusterProfiler)
library(org.Hs.eg.db)
library(enrichplot)
library(pals)

source('../SSLB_functions.R', echo=TRUE)

load("SSLB_result/SSLB_out.RData")
load("data/gene_info.RData")
load("data/sample_info.RData")

Y <- read.table("data/Y_raw.txt", stringsAsFactors = F)
Y <- as.matrix(Y)
N <- nrow(Y)
G <- ncol(Y)

gene_info[] <- lapply(gene_info, as.character)

er <- sample_info$er
er[er == 0] <- -1

er_order <- order(er)
er_factor <- factor(er)

X_SSLB <- out$X
K_SSLB <- out$K
B_SSLB <- out$B

# which biclusters contain ESR1
B_SSLB[which(gene_info$HUGO.gene.symbol == "ESR1"), ]

# HER2 markers
B_SSLB[which(gene_info$HUGO.gene.symbol == "ERBB2"), ]

# sign change to make ERRB2 positive in B for consistent colors
X_SSLB[, 2] <- -X_SSLB[, 2]
B_SSLB[, 2] <- -B_SSLB[, 2]

# order biclusters (columns)
X_SSLB <- X_SSLB[, union(c(3, 2), 1:K_SSLB)]
B_SSLB <- B_SSLB[, union(c(3, 2), 1:K_SSLB)]

# significant difference
p_vals <- numeric(K_SSLB)
for (k in 1:K_SSLB) {
  p_vals[k] <- wilcox.test(X_SSLB[, k] ~ er_factor)$p.value
}

er_k <- which.min(p_vals)
p_vals < 0.01/K_SSLB

#  Testing further gene markers (ZMZ14) --------------------------------
# luminal A (ER+, HER2-)
markers <- c("KRT8", "FOXA1", "XBP1", "GATA3", "ADH1B")
B_SSLB[which(gene_info$HUGO.gene.symbol %in% markers), ]

in_bic <- B_SSLB[which(gene_info$HUGO.gene.symbol %in% markers), 1]

found <- sum(in_bic != 0)
tot <- length(markers)
n_bic <- sum(B_SSLB[,1] != 0)

mat <- matrix(c(found, tot - found, n_bic - found, G - tot - (n_bic - found)), 2, 2)
fisher.test(mat)

# luminal B (ER+, HER2+)
markers <- c("KRT8", "FGFR1", "EGFR", "CCNE1","CCNB1", "MYBL2")

in_bic <- B_SSLB[which(gene_info$HUGO.gene.symbol %in% markers), 2]
found <- sum(in_bic != 0)
tot <- length(markers)

n_bic <- sum(B_SSLB[,2] != 0)
mat <- matrix(c(found, tot - found, n_bic - found, G - tot - (n_bic - found)), 2, 2)
fisher.test(mat)


# ER-/HER2+
markers <- c("GRB7")
B_SSLB[which(gene_info$HUGO.gene.symbol == "GRB7"), ]


# basal-like (ER-, HER2-)
markers <- c("KRT5", "KRT14", "KRT17", "EGFR", "KIT", "FOXC1", "CDH3", "VIM")
B_SSLB[which(gene_info$HUGO.gene.symbol %in% markers), ]

in_bic <- B_SSLB[which(gene_info$HUGO.gene.symbol %in% markers), 2]
found <- sum(in_bic != 0)
tot <- length(markers)

n_bic <- sum(B_SSLB[,2] != 0)
mat <- matrix(c(found, tot - found, n_bic - found, G - tot - (n_bic - found)), 2, 2)
fisher.test(mat)

# proportions ---------------------------------

# ER-/HER2-
sum(X_SSLB[,1] < 0 & X_SSLB[, 2] <= 0)/N

# ER-/HER2+
sum(X_SSLB[,1] < 0 & X_SSLB[, 2] > 0)/N

# ER+/HER2-
sum(X_SSLB[,1] >= 0 & X_SSLB[, 2] <= 0)/N

# ER+/HER2+
sum(X_SSLB[,1] >= 0 & X_SSLB[, 2] > 0)/N


# ENRICHMENT ---------------------------------

enrich_list <- vector("list", K_SSLB)
n_enrich <- numeric(K_SSLB)
for (i in 1:K_SSLB) {
  test <- gene_info$EntrezGene.ID[which(B_SSLB[, i] != 0)]
  enrich_list[[i]] <- enrichGO(test, ont = "BP", OrgDb = org.Hs.eg.db, qvalueCutoff = 0.05)
  n_enrich[i] <- length(enrich_list[[i]]$Description)
}

save(enrich_list, file = "SSLB_result/enriched_raw.RData")

i <- 1
test <- gene_info$EntrezGene.ID[which(B_SSLB[, i] > 0)]
test_go <- enrichGO(test, ont = "BP", OrgDb = org.Hs.eg.db, qvalueCutoff = 0.05)

go_simple <- simplify(test_go, cutoff = 0.7)

emapplot(test_go, showCategory = 30)

pdf(file = "figures/raw_bic_1_up.pdf", width = 11, height = 7)
emapplot(go_simple)
dev.off()



i <- 2
test <- gene_info$EntrezGene.ID[which(B_SSLB[, i] > 0)]
test_go <- enrichGO(test, ont = "BP", OrgDb = org.Hs.eg.db, qvalueCutoff = 0.05)

go_simple <- simplify(test_go, cutoff = 0.7)

emapplot(test_go, showCategory = 30)

pdf(file = "figures/raw_bic_2_up.pdf", width = 11, height = 7)

emapplot(go_simple, showCategory = 25)

dev.off()
