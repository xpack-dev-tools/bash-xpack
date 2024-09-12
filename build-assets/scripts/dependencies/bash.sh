# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu. All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

# https://ftp.gnu.org/gnu/bash/
# https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/main/PKGBUILD
# https://github.com/Homebrew/homebrew-core/blob/master/Formula/b/bash.rb

# 2023-11-09, "5.2.21"

# -----------------------------------------------------------------------------

function bash_build()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  local bash_version="$1"

  # Do not make them local!
  # The folder name as resulted after being extracted from the archive.
  local bash_src_folder_name="bash-${bash_version}"

  # https://ftp.gnu.org/gnu/bash/bash-5.2.21.tar.gz
  local bash_archive="${bash_src_folder_name}.tar.gz"
  local bash_url="https://ftp.gnu.org/gnu/bash//${bash_archive}"

  # The folder name  for build, licenses, etc.
  local bash_folder_name="${bash_src_folder_name}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${bash_folder_name}"

  local bash_patch_file_name="bash-${bash_version}.git.patch"
  local bash_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${bash_folder_name}-installed"
  if [ ! -f "${bash_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_SOURCES_FOLDER_PATH}"
    cd "${XBB_SOURCES_FOLDER_PATH}"

    if [ ! -d "${XBB_SOURCES_FOLDER_PATH}/${bash_src_folder_name}" ]
    then
      (
        if [ ! -z ${XBB_BASH_GIT_URL+x} ]
        then
          run_verbose_develop cd "${XBB_SOURCES_FOLDER_PATH}"
          run_verbose git_clone \
            "${XBB_BASH_GIT_URL}" \
            "${bash_src_folder_name}" \
            --branch="${XBB_BASH_GIT_BRANCH:-""}" \
            --commit="${XBB_BASH_GIT_COMMIT:-""}" \
            --patch="${bash_patch_file_name}"
        else
          download_and_extract "${bash_url}" "${bash_archive}" \
            "${bash_src_folder_name}" "${bash_patch_file_name}"
        fi
      )
    fi

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${bash_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${bash_folder_name}"

      xbb_activate_dependencies_dev

      CFLAGS="${XBB_CPPFLAGS}"
      CXXFLAGS="${XBB_CPPFLAGS}"

      LDFLAGS="${XBB_LDFLAGS_APP}"

      xbb_adjust_ldflags_rpath

      export CFLAGS
      export CXXFLAGS
      export LDFLAGS


      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running bash configure..."

          if is_development
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${bash_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")

          config_options+=("--libdir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${XBB_HOST_TRIPLET}")
          config_options+=("--target=${XBB_TARGET_TRIPLET}")

          config_options+=("--with-curses") # Arch
          config_options+=("--enable-readline") # Arch
          config_options+=("--without-bash-malloc") # Arch
          config_options+=("--with-installed-readline") # Arch

          config_options+=("--with-included-gettext")
          config_options+=("--with-libiconv-prefix=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}")

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${bash_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${bash_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${bash_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running bash build..."

        run_verbose make -j ${XBB_JOBS}

        if [ "${XBB_WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

        echo
        echo "Running bash install..."

        run_verbose make install

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${bash_folder_name}/build-output-$(ndate).txt"

      copy_license \
        "${XBB_SOURCES_FOLDER_PATH}/${bash_src_folder_name}" \
        "${bash_folder_name}"

    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${bash_stamp_file_path}"

  else
    echo "Component bash already installed"
  fi

  tests_add "bash_test" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
}

# -----------------------------------------------------------------------------

function bash_test()
{
  local test_bin_path="$1"

  (
    echo
    echo "Checking the bash shared libraries..."

    show_host_libs "${test_bin_path}/bash"

    echo
    echo "Running the bash binaries..."

    run_host_app_verbose "${test_bin_path}/bash" --version
    run_host_app_verbose "${test_bin_path}/bash" --help

    echo
    echo "Running the bash echo test..."
    expect_host_output "hello" "${test_bin_path}/bash" -c 'echo hello'

  )
}

# -----------------------------------------------------------------------------
