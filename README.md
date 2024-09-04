# lfs-data-cache-action

A producer/consumer github action to cache and recover LFS data.

Its main use is to avoid cloning LFS data in CI to avoid
having to pay for LFS bandwidth because of CI needs.

It expects cmake to be available on the host.

The action can be used as a consumer or a producer, and must
provide the repository containing the LFS data to recover from.

It is possible to provide a specific SHA to produce.
If not provided, the last commit modyfing the LFS file will be produced.

Is has the following inputs:

 - `type`: should be `producer` or `consumer`, default to `producer`
 - `repository`: the git repository to produce LFS data from, default: ${{ github.repository }}
 - `lfs_sha`: The git sha to recover LFS data from, optional
 - `cache_postfix`: An postfix added to the cache name, to support multiple caches, default to `cache`
 - `target_directory`: A target directory to copy LFS data to

## Logic

Producer/Consumer first use the classic cache action to recover a cache named
`lfs-data-${{lfs_sha}}-${{cache_index}}`.

If Producer does not found it, it will clone the `repository` at `lfs_sha` commit
and upload the content as an artifact.

If Consumer does not found it, it will try to download a potential artifact
produced earlier by the Producer.

If it fails Consumer will clone the `repository` at `lfs_sha` commit.

Finally, Producer/Consumer will copy the LFS data only using cmake to the `target_directory`

## Usage

In an first job, use the `producer` action, which output the LFS sha that will be produced
In a second job, usually a matrix joib, depending on the first,
recover the LFS sha from first job and use the `consumer` action.

```
jobs:

#----------------------------------------------------------------------------
# Cache LFS: Checkout LFS data and update the cache to limit LFS bandwidth
#----------------------------------------------------------------------------
  cache_lfs:
    runs-on: ubuntu-latest
    name: Update LFS data cache
    outputs:
      lfs_sha: ${{ steps.lfs_sha_recover.outputs.lfs_sha }}
    steps:

    # Checkout your repository WITHOUT LFS
    - name: Checkout
      uses: actions/checkout@v3
      with:
        path: 'source'
        fetch-depth: 0
        lfs: false

    # Use producer action to recover the LFS data and upload it as cache/artifacts
    - name: Cache LFS Data
      uses: f3d-app/lfs-data-cache-action:v1

  recover_lfs:
    needs: cache_lfs

    # Checkout your repository WITHOUT LFS
    - name: Checkout
      uses: actions/checkout@v3
      with:
        path: 'source'
        fetch-depth: 0
        lfs: false

    - name: Recover LFS Data
      uses: f3d-app/lfs-data-cache-action:v1
      with:
        workflow_label: 'consumer'
        lfs_sha: ${{ needs.cache_lfs.outputs.lfs_sha}}
```
