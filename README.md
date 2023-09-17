# lfs-data-cache-action

A producer/consumer github action to cache and recover LFS data.

Its main use is to avoid cloning LFS data in CI to avoid
haing to pay for LFS bandwidth because of CI needs.
It needs cmake to be available on the host.

The action can be used as a consumer or a producer, and needs
a SHA to recover LFS data with.

Is has the following inputs:

 - `type`: should be `producer` or `consumer`, default producer
 - `repository`: the git repository to recover LFS data from, required
 - `lfs_sha`: The git sha to recover LFS data from, required
 - `cache_index`: An index used in the cache name, default is 0
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

In an first job, recover the LFS sha to recover and use the `producer` action, output the LFS sha
In a second job depending on the first, recover the LFS sha from first job and use the `consumer` action.

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

    # Checkout WITHOUT LFS as the data itself is not needed at this point
    - name: Checkout
      uses: actions/checkout@v3
      with:
        path: 'source'
        fetch-depth: 0
        lfs: false

    # Recover the last time LFS data was changed on the repository
    # TODO: Update the list of directory you want to watch for changes
    - name: Set LFS env var
      working-directory: ${{github.workspace}}/source
      id: lfs_sha_recover
      shell: bash
      run: echo "lfs_sha=$(git log -n 1 --pretty=format:%H -- path/to/lfs/data path/to/lfs/data/again)" >> $GITHUB_OUTPUT

    # Use producer action to recover the LFS data and upload it as cache/artifacts
    - name: Cache LFS Data
      uses: f3d-app/lfs-data-cache-action:latest
      with:
        workflow_label: 'producer'
        repository: 'your/repo'
        lfs_sha: ${{ steps.lfs_sha_recover.outputs.lfs_sha }}
        target_directory: 'source'

  recover_lfs:
    needs: cache_lfs

    # Checkout WITHOUT LFS as the data itself is not needed at this point
    - name: Checkout
      uses: actions/checkout@v3
      with:
        path: 'source'
        fetch-depth: 0
        lfs: false

    - name: Recover LFS Data
      uses: f3d-app/lfs-data-cache-action:latest
      with:
        workflow_label: 'consumer'
        repository: 'your/repo'
        lfs_sha: ${{ inputs.lfs_sha}}
        target_directory: 'source'
```
