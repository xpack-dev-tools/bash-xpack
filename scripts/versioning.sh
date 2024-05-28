# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function application_build_versioned_components()
{
  export XBB_BASH_VERSION="$(xbb_strip_version_pre_release "${XBB_RELEASE_VERSION}")"

  if [[ "${XBB_RELEASE_VERSION}" =~ 5[.]2[.]21-.* ]]
  then
    # -------------------------------------------------------------------------
    # Build the native dependencies.

    # None

    # -------------------------------------------------------------------------
    # Build the target dependencies.

    xbb_reset_env
    # Before set target (to possibly update CC & co variables).
    # xbb_activate_installed_bin

    xbb_set_target "requested"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    libiconv_build "1.17"

    # https://ftp.gnu.org/gnu/ncurses/
    ncurses_build "6.5"

    # https://ftp.gnu.org/gnu/readline/
    readline_build "8.2" # requires ncurses

    if false
    then
      # https://gitlab.gnome.org/GNOME/libxml2/-/releases
      libxml2_build "2.12.7"

      # Without it gettext fails:
      # Undefined symbols for architecture x86_64:
      #   "_gl_get_setlocale_null_lock", referenced from:
      #       _libgettextpo_setlocale_null_r in setlocale_null.o
      # ld: symbol(s) not found for architecture x86_64
      # clang-16: error: linker command failed with exit code 1 (use -v to see invocation)

      # https://ftp.gnu.org/gnu/libunistring/
      libunistring_build "1.2"

      # https://ftp.gnu.org/pub/gnu/gettext/
      gettext_build "0.22.5"
    fi

    # -------------------------------------------------------------------------
    # Build the application binaries.

    xbb_set_executables_install_path "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"
    xbb_set_libraries_install_path "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"

    bash_build "${XBB_BASH_VERSION}"

  else
    echo "Unsupported ${XBB_APPLICATION_LOWER_CASE_NAME} version ${XBB_RELEASE_VERSION}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
