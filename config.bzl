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

_mongoc_config_build_file_contents = """
load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

constraint_setting(
    name = "ssl",
    visibility = ["//visibility:public"],
    default_constraint_value = ":no_ssl",
)

constraint_value(
    name = "no_ssl",
    visibility = ["//visibility:public"],
    constraint_setting = "ssl",
)

constraint_value(
    name = "openssl",
    visibility = ["//visibility:public"],
    constraint_setting = "ssl",
)

constraint_value(
    name = "boringssl",
    visibility = ["//visibility:public"],
    constraint_setting = "ssl",
)

cc_library(
    name = "mongoc_config",
    hdrs = ["mongoc-config.h"],
)

cc_library(
    name = "mongoc_version",
    hdrs = ["mongoc-version.h"],
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

def _mongoc_config_implementation(rctx):
    mongoc_version = "1.17.1."

    rctx.template(
        "mongoc-config.h",
        rctx.path(rctx.attr.mongoc_config_template),
        executable = False,
        substitutions = {
            # Compiler info
            "@MONGOC_USER_SET_CFLAGS@": "",
            "@MONGOC_USER_SET_LDFLAGS@": "",
            "@MONGOC_CC@": "",

            # Options
            "@MONGOC_ENABLE_SSL_SECURE_CHANNEL@": "0",
            "@MONGOC_ENABLE_CRYPTO_CNG@": "0",
            "@MONGOC_ENABLE_SSL_SECURE_TRANSPORT@": "0",
            "@MONGOC_ENABLE_CRYPTO_COMMON_CRYPTO@": "0",
            "@MONGOC_ENABLE_SSL_LIBRESSL@": "0",
            "@MONGOC_ENABLE_SSL_OPENSSL@": "0",
            "@MONGOC_ENABLE_CRYPTO_LIBCRYPTO@": "0",
            "@MONGOC_ENABLE_SSL@": "0",
            "@MONGOC_ENABLE_CRYPTO@": "0",
            "@MONGOC_ENABLE_CRYPTO_SYSTEM_PROFILE@": "0",
            "@MONGOC_HAVE_ASN1_STRING_GET0_DATA@": "0",
            "@MONGOC_ENABLE_SASL@": "0",
            "@MONGOC_ENABLE_SASL_CYRUS@": "0",
            "@MONGOC_ENABLE_SASL_SSPI@": "0",
            "@MONGOC_HAVE_SASL_CLIENT_DONE@": "0",
            "@MONGOC_NO_AUTOMATIC_GLOBALS@": "1",
            "@MONGOC_HAVE_SOCKLEN@": "0",
            "@MONGOC_HAVE_DNSAPI@": "0",
            "@MONGOC_HAVE_RES_NSEARCH@": "0",
            "@MONGOC_HAVE_RES_NDESTROY@": "0",
            "@MONGOC_HAVE_RES_NCLOSE@": "0",
            "@MONGOC_HAVE_RES_SEARCH@": "0",
            "@MONGOC_SOCKET_ARG2@": "struct sockaddr",
            "@MONGOC_SOCKET_ARG3@": "int",
            "@MONGOC_ENABLE_COMPRESSION@": "0",
            "@MONGOC_ENABLE_COMPRESSION_SNAPPY@": "0",
            "@MONGOC_ENABLE_COMPRESSION_ZLIB@": "0",
            "@MONGOC_ENABLE_COMPRESSION_ZSTD@": "0",
            "@MONGOC_ENABLE_SHM_COUNTERS@": "0",
            "@MONGOC_ENABLE_RDTSCP@": "0",
            "@MONGOC_HAVE_SCHED_GETCPU@": "0",
            "@MONGOC_TRACE@": "0",
            "@MONGOC_ENABLE_ICU@": "0",
            "@MONGOC_ENABLE_CLIENT_SIDE_ENCRYPTION@": "0",
            "@MONGOC_HAVE_SS_FAMILY@": "0",
            "@MONGOC_ENABLE_MONGODB_AWS_AUTH@": "0",
        },
    )

    rctx.template(
        "mongoc-version.h",
        rctx.path(rctx.attr.mongoc_version_template),
        executable = False,
        substitutions = {
            "@MONGOC_MAJOR_VERSION@": "({})".format(mongoc_version.split('.')[0]),
            "@MONGOC_MINOR_VERSION@": "({})".format(mongoc_version.split('.')[1]),
            "@MONGOC_MICRO_VERSION@": "({})".format(mongoc_version.split('.')[2]),
            "@MONGOC_PRERELEASE_VERSION@": "\"{}\"".format(mongoc_version.split('.')[3]),
            "@MONGOC_VERSION@": "{}".format(mongoc_version),
        },
    )

    rctx.file(
        "BUILD.bazel",
        content = _mongoc_config_build_file_contents,
        executable = False,
    )

_mongoc_config = repository_rule(
    implementation = _mongoc_config_implementation,
    attrs = {
        "mongoc_config_template": attr.label(
            default = Label("@bazelregistry_mongo_c_driver//src/libmongoc/src/mongoc:mongoc-config.h.in"),
            allow_single_file = True,
        ),
        "mongoc_version_template": attr.label(
            default = Label("@bazelregistry_mongo_c_driver//src/libmongoc/src/mongoc:mongoc-version.h.in"),
            allow_single_file = True,
        ),
    },
)

def mongoc_config(**kwargs):
    _mongoc_config(name = "mongoc_config", **kwargs)

