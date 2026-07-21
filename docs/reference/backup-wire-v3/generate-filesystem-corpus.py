#!/usr/bin/env python3

import errno
import hashlib
import importlib.util
import json
import os
import pathlib
import stat
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
EXPECTED_SEMANTIC_MANIFEST_SHA256 = (
    "d12b65fc12946b3f73620bc57b1b8d2bdc7a75b491a9fcfe07c1693766bd9f10"
)

REFERENCE_PATH = ROOT / "reference-validator.py"
REFERENCE_SPEC = importlib.util.spec_from_file_location(
    "filesystem_reference_validator",
    REFERENCE_PATH,
)
if REFERENCE_SPEC is None or REFERENCE_SPEC.loader is None:
    raise RuntimeError("cannot load reference validator")
REFERENCE = importlib.util.module_from_spec(REFERENCE_SPEC)
REFERENCE_SPEC.loader.exec_module(REFERENCE)


def expect_open_failure(identifier, path, flags, allowed_errors):
    try:
        descriptor = os.open(path, flags)
    except OSError as error:
        if error.errno not in allowed_errors:
            raise AssertionError(
                f"{identifier}: unexpected errno {error.errno}"
            ) from error
        return
    os.close(descriptor)
    raise AssertionError(f"{identifier}: hostile open unexpectedly succeeded")


def expect_validation_failure(identifier, expected_code, validation):
    try:
        validation()
    except REFERENCE.ValidationError as error:
        if error.code != expected_code:
            raise AssertionError(
                f"{identifier}: expected {expected_code}, observed {error.code}"
            ) from error
    else:
        raise AssertionError(
            f"{identifier}: hostile node unexpectedly passed validation"
        )


def case(identifier, target_rule):
    return {
        "case_id": identifier,
        "target_rule": target_rule,
    }


def positive_quarantine_case(root):
    identifier = "V3-P-FS-QUARANTINE-NODE"
    construction = root / "construction"
    construction.mkdir(mode=0o700)
    construction.chmod(0o700)
    path = construction / "input.snapdrillbackup"
    descriptor = os.open(
        path,
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | os.O_NOFOLLOW
        | os.O_CLOEXEC,
        0o600,
    )
    try:
        os.write(descriptor, b"fixture")
        os.fsync(descriptor)
        node = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    path.chmod(0o444)
    directory = construction.stat()
    final_node = path.lstat()
    if not stat.S_ISDIR(directory.st_mode):
        raise AssertionError(f"{identifier}: construction root is not a directory")
    if stat.S_IMODE(directory.st_mode) != 0o700:
        raise AssertionError(f"{identifier}: construction root mode drift")
    if not stat.S_ISREG(node.st_mode):
        raise AssertionError(f"{identifier}: quarantine node is not regular")
    if stat.S_IMODE(node.st_mode) != 0o600:
        raise AssertionError(f"{identifier}: initial quarantine mode drift")
    if node.st_uid != os.getuid() or node.st_nlink != 1:
        raise AssertionError(f"{identifier}: ownership/link invariant failed")
    if stat.S_IMODE(final_node.st_mode) != 0o444:
        raise AssertionError(f"{identifier}: final quarantine mode drift")
    REFERENCE.validate_quarantine_node(path)
    return case(identifier, "owned-regular-link-count-one-0700-0444")


def source_symlink_case(root):
    identifier = "V3-N-FS-SOURCE-SYMLINK"
    target = root / "source-target"
    target.write_bytes(b"source")
    link = root / "source-link"
    link.symlink_to(target.name)
    expect_open_failure(
        identifier,
        link,
        os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC,
        {errno.ELOOP},
    )
    return case(identifier, "source-open-no-follow")


def source_directory_case(root):
    identifier = "V3-N-FS-SOURCE-DIRECTORY"
    directory = root / "source-directory"
    directory.mkdir()
    descriptor = os.open(
        directory,
        os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC,
    )
    try:
        node = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    if stat.S_ISREG(node.st_mode):
        raise AssertionError(f"{identifier}: directory reported as regular")
    return case(identifier, "source-must-be-regular")


def preexisting_quarantine_case(root):
    identifier = "V3-N-FS-QUARANTINE-PREEXISTING"
    path = root / "preexisting.snapdrillbackup"
    path.write_bytes(b"occupied")
    expect_open_failure(
        identifier,
        path,
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | os.O_NOFOLLOW
        | os.O_CLOEXEC,
        {errno.EEXIST},
    )
    return case(identifier, "quarantine-create-exclusive")


def quarantine_symlink_case(root):
    identifier = "V3-N-FS-QUARANTINE-SYMLINK"
    construction = root / "construction"
    construction.mkdir(mode=0o700)
    construction.chmod(0o700)
    target = construction / "quarantine-target"
    target.write_bytes(b"target")
    link = construction / "quarantine-link"
    link.symlink_to(target.name)
    expect_open_failure(
        identifier,
        link,
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | os.O_NOFOLLOW
        | os.O_CLOEXEC,
        {errno.EEXIST, errno.ELOOP},
    )
    expect_validation_failure(
        identifier,
        "filesystem:not-regular",
        lambda: REFERENCE.validate_quarantine_node(link),
    )
    return case(identifier, "quarantine-exclusive-create-and-node-validation")


def quarantine_hardlink_case(root):
    identifier = "V3-N-FS-QUARANTINE-HARDLINK"
    construction = root / "construction"
    construction.mkdir(mode=0o700)
    construction.chmod(0o700)
    path = construction / "quarantine"
    path.write_bytes(b"fixture")
    path.chmod(0o444)
    alias = construction / "quarantine-alias"
    os.link(path, alias)
    node = path.stat()
    if node.st_nlink != 2:
        raise AssertionError(f"{identifier}: hard-link count is {node.st_nlink}")
    expect_validation_failure(
        identifier,
        "filesystem:link-count",
        lambda: REFERENCE.validate_quarantine_node(path),
    )
    return case(identifier, "quarantine-link-count-one")


def fixed_root_symlink_case(root):
    identifier = "V3-N-FS-CONSTRUCTION-ROOT-SYMLINK"
    target = root / "real-root"
    target.mkdir()
    link = root / "construction-root"
    link.symlink_to(target.name)
    if not stat.S_ISLNK(link.lstat().st_mode):
        raise AssertionError(f"{identifier}: root symlink absent")
    expect_validation_failure(
        identifier,
        "filesystem:construction-root-type",
        lambda: REFERENCE.validate_construction_root(link),
    )
    return case(identifier, "construction-root-fixed-node-validation")


def writable_quarantine_case(root):
    identifier = "V3-N-FS-QUARANTINE-WRITABLE"
    construction = root / "construction"
    construction.mkdir(mode=0o700)
    construction.chmod(0o700)
    path = construction / "input.snapdrillbackup"
    path.write_bytes(b"fixture")
    path.chmod(0o600)
    expect_validation_failure(
        identifier,
        "filesystem:writable-quarantine",
        lambda: REFERENCE.validate_quarantine_node(path),
    )
    return case(identifier, "quarantine-read-only-before-sqlite-open")


def construction_root_mode_case(root):
    identifier = "V3-N-FS-CONSTRUCTION-ROOT-MODE"
    construction = root / "construction"
    construction.mkdir(mode=0o755)
    construction.chmod(0o755)
    expect_validation_failure(
        identifier,
        "filesystem:construction-root-mode",
        lambda: REFERENCE.validate_construction_root(construction),
    )
    return case(identifier, "construction-root-mode-0700")


def source_size_mutation_case(root):
    identifier = "V3-N-FS-SOURCE-SIZE-MUTATION"
    path = root / "mutable-source"
    path.write_bytes(b"original")
    descriptor = os.open(
        path,
        os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC,
    )
    try:
        initial = os.fstat(descriptor)
        with path.open("ab") as writer:
            writer.write(b"-changed")
            writer.flush()
            os.fsync(writer.fileno())
        final = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    if (
        initial.st_dev != final.st_dev
        or initial.st_ino != final.st_ino
        or initial.st_size == final.st_size
    ):
        raise AssertionError(f"{identifier}: expected same node with changed size")
    return case(identifier, "source-final-fstat-must-match-initial")


def source_path_substitution_case(root):
    identifier = "V3-P-FS-SOURCE-DESCRIPTOR-PIN"
    path = root / "coordinated-source"
    original = b"original-descriptor-bytes"
    replacement = b"replacement-path-bytes"
    path.write_bytes(original)
    descriptor = os.open(
        path,
        os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC,
    )
    moved = root / "moved-original"
    try:
        initial = os.fstat(descriptor)
        path.rename(moved)
        path.write_bytes(replacement)
        os.lseek(descriptor, 0, os.SEEK_SET)
        observed = os.read(descriptor, len(original) + 1)
        final = os.fstat(descriptor)
        replacement_node = path.stat()
    finally:
        os.close(descriptor)
    if observed != original:
        raise AssertionError(f"{identifier}: descriptor followed replacement path")
    if (initial.st_dev, initial.st_ino) != (final.st_dev, final.st_ino):
        raise AssertionError(f"{identifier}: descriptor identity changed")
    if (final.st_dev, final.st_ino) == (
        replacement_node.st_dev,
        replacement_node.st_ino,
    ):
        raise AssertionError(f"{identifier}: replacement reused original identity")
    return case(identifier, "read-open-descriptor-never-reopen-user-path")


def generate_corpus(root):
    builders = [
        positive_quarantine_case,
        source_symlink_case,
        source_directory_case,
        preexisting_quarantine_case,
        quarantine_symlink_case,
        quarantine_hardlink_case,
        fixed_root_symlink_case,
        writable_quarantine_case,
        construction_root_mode_case,
        source_size_mutation_case,
        source_path_substitution_case,
    ]
    cases = []
    for index, builder in enumerate(builders):
        case_root = root / f"{index:02d}-{builder.__name__}"
        case_root.mkdir()
        cases.append(builder(case_root))
    return cases


def main():
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-fs-a-") as first:
        with tempfile.TemporaryDirectory(prefix="snapdrill-v3-fs-b-") as second:
            first_cases = generate_corpus(pathlib.Path(first))
            second_cases = generate_corpus(pathlib.Path(second))
            if first_cases != second_cases:
                raise AssertionError("filesystem corpus manifest is nondeterministic")
            manifest_bytes = json.dumps(
                first_cases,
                separators=(",", ":"),
                sort_keys=True,
            ).encode()
            manifest_sha256 = hashlib.sha256(manifest_bytes).hexdigest()
            if manifest_sha256 != EXPECTED_SEMANTIC_MANIFEST_SHA256:
                raise AssertionError("filesystem corpus case manifest changed")
            print(
                json.dumps(
                    {
                        "case_count": len(first_cases),
                        "semantic_manifest_sha256": manifest_sha256,
                    },
                    sort_keys=True,
                )
            )
    print("PASS deterministic POSIX filesystem corpus")


if __name__ == "__main__":
    main()
