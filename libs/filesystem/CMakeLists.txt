# Copyright (c) 2019 The STE||AR-Group
#
# SPDX-License-Identifier: BSL-1.0
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

cmake_minimum_required(VERSION 3.6.3 FATAL_ERROR)

set(__boost_filesystem)
if(HPX_FILESYSTEM_WITH_BOOST_FILESYSTEM_COMPATIBILITY)
  set(__boost_filesystem hpx::boost::filesystem)
endif()

set(filesystem_headers "hpx/filesystem.hpp")

include(HPX_AddModule)
add_hpx_module(filesystem
  FORCE_LINKING_GEN
  GLOBAL_HEADER_GEN OFF
  HEADERS ${filesystem_headers}
  DEPENDENCIES
    hpx_config
    ${__boost_filesystem}
  CMAKE_SUBDIRS examples tests
)
