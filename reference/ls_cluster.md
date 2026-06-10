# Cluster LIBS Spectra

Unsupervised clustering via k-means, hierarchical, or DBSCAN (DBSCAN
requires the `dbscan` package in Suggests).

## Usage

``` r
ls_cluster(dataset, method = "kmeans", k = 3, ...)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- method:

  Character. `"kmeans"`, `"hclust"`, or `"dbscan"`. Default `"kmeans"`.

- k:

  Integer. Number of clusters for kmeans/hclust. Default 3.

- ...:

  Additional arguments passed to the underlying clustering function.

## Value

An S3 object of class `libs_clusters` with elements `cluster`, `method`,
`k`, `silhouette` (mean silhouette score when computable),
`sample_info`.

## Examples

``` r
ds <- ls_example_data("tissue")
cl <- ls_cluster(ds, method = "kmeans", k = 5)
cl$cluster
#>   bone_01   bone_02   bone_03   bone_04   bone_05   bone_06   bone_07   bone_08 
#>         1         1         2         1         2         1         2         1 
#>   bone_09   bone_10  liver_01  liver_02  liver_03  liver_04  liver_05  liver_06 
#>         2         1         5         3         3         3         3         5 
#>  liver_07  liver_08  liver_09  liver_10 kidney_01 kidney_02 kidney_03 kidney_04 
#>         4         3         3         4         3         4         4         5 
#> kidney_05 kidney_06 kidney_07 kidney_08 kidney_09 kidney_10 muscle_01 muscle_02 
#>         5         5         4         4         4         5         3         3 
#> muscle_03 muscle_04 muscle_05 muscle_06 muscle_07 muscle_08 muscle_09 muscle_10 
#>         4         3         3         3         4         4         3         5 
#>    fat_01    fat_02    fat_03    fat_04    fat_05    fat_06    fat_07    fat_08 
#>         4         3         3         3         4         5         4         4 
#>    fat_09    fat_10 
#>         4         4 
```
