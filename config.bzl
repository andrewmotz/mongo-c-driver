_bson_config_build_file_contents = """
load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "bson_config_internal",
    hdrs = ["bson-config.h"],
)

cc_library(
    name = "bson_config",
    includes = ["."],
    strip_include_prefix = ".",
    include_prefix = "bson",
    hdrs = ["bson-config.h"],
)

cc_library(
    name = "bson_version",
    includes = ["."],
    strip_include_prefix = ".",
    include_prefix = "bson",
    hdrs = ["bson-version.h"],
)

cc_library(
    name = "bson_version_internal",
    hdrs = ["bson-version.h"],
)
"""

_common_config_build_file_contents = """
load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "common_config",
    hdrs = ["common-config.h"],
)
"""

def _bson_config_implementation(rctx):
    bson_version = "1.17.1."
    bson_os = "1" if rctx.os.name.find("windows") == -1 else "2"

    rctx.template(
        "bson-config.h",
        rctx.path(rctx.attr.bson_config_template),
        executable = False,
        substitutions = {
            "@BSON_BYTE_ORDER@": "1234",
            "@BSON_HAVE_STDBOOL_H@": "0",
            "@BSON_OS@": bson_os,
            "@BSON_HAVE_ATOMIC_32_ADD_AND_FETCH@": "0",
            "@BSON_HAVE_ATOMIC_64_ADD_AND_FETCH@": "0",
            "@BSON_HAVE_CLOCK_GETTIME@": "0",
            "@BSON_HAVE_STRINGS_H@": "0",
            "@BSON_HAVE_STRNLEN@": "0",
            "@BSON_HAVE_SNPRINTF@": "0",
            "@BSON_HAVE_GMTIME_R@": "0",
            "@BSON_HAVE_REALLOCF@": "0",
            "@BSON_HAVE_TIMESPEC@": "0",
            "@BSON_EXTRA_ALIGN@": "0",
            "@BSON_HAVE_SYSCALL_TID@": "0",
            "@BSON_HAVE_RAND_R@": "0",
            "@BSON_HAVE_STRLCPY@": "0",
        },
    )

    rctx.template(
        "bson-version.h",
        rctx.path(rctx.attr.bson_version_template),
        executable = False,
        substitutions = {
            "@BSON_MAJOR_VERSION@": "({})".format(bson_version.split('.')[0]),
            "@BSON_MINOR_VERSION@": "({})".format(bson_version.split('.')[1]),
            "@BSON_MICRO_VERSION@": "({})".format(bson_version.split('.')[2]),
            "@BSON_PRERELEASE_VERSION@": "\"{}\"".format(bson_version.split('.')[3]),
            "@BSON_VERSION@": "{}".format(bson_version),
        },
    )

    rctx.file(
        "BUILD.bazel",
        content = _bson_config_build_file_contents,
        executable = False,
    )

_bson_config = repository_rule(
    implementation = _bson_config_implementation,
    attrs = {
        "bson_config_template": attr.label(
            default = Label("@bazelregistry_mongo_c_driver//src/libbson/src/bson:bson-config.h.in"),
            allow_single_file = True,
        ),
        "bson_version_template": attr.label(
            default = Label("@bazelregistry_mongo_c_driver//src/libbson/src/bson:bson-version.h.in"),
            allow_single_file = True,
        ),
    },
)

def bson_config(**kwargs):
    _bson_config(name = "bson_config", **kwargs)


def _common_config_implementation(rctx):
    rctx.template(
        "common-config.h",
        rctx.path(rctx.attr.common_config_template),
        executable = False,
        substitutions = {
            "@MONGOC_ENABLE_DEBUG_ASSERTIONS@": "1" if rctx.attr.enable_debug_assertions else "0",
        },
    )

    rctx.file(
        "BUILD.bazel",
        content = _common_config_build_file_contents,
        executable = False,
    )

_common_config = repository_rule(
    implementation = _common_config_implementation,
    attrs = {
        "enable_debug_assertions": attr.bool(
            default = False,
        ),
        "common_config_template": attr.label(
            default = Label("@bazelregistry_mongo_c_driver//src/common:common-config.h.in"),
            allow_single_file = True,
        ),
    },
)

def mongo_c_driver_common_config(**kwargs):
    _common_config(name = "mongo_c_driver_common_config", **kwargs)
