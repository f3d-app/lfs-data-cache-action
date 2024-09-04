# Check that a LFS data file is big enough to be an actual file
file(SIZE "${CMAKE_ARGV3}" lfs_file_size)
if (lfs_file_size LESS_EQUAL 500)
  message(FATAL_ERROR "File is is small than 500 bytes, lfs data not correctly recovered")
endif()
