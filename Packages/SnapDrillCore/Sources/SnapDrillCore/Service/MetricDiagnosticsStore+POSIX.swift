//
//  MetricDiagnosticsStore+POSIX.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation

nonisolated struct MetricDiagnosticsFileSystem: @unchecked Sendable {
    var makeDirectoryAt: (_ parent: Int32, _ name: String, _ mode: mode_t) -> Int32
    var open: (_ path: String, _ flags: Int32) -> Int32
    var openAt: (_ parent: Int32, _ name: String, _ flags: Int32) -> Int32
    var createAt: (_ parent: Int32, _ name: String, _ flags: Int32, _ mode: mode_t) -> Int32
    var close: (_ descriptor: Int32) -> Int32
    var write: (_ descriptor: Int32, _ buffer: UnsafeRawPointer?, _ count: Int) -> Int
    var read: (_ descriptor: Int32, _ buffer: UnsafeMutableRawPointer?, _ count: Int) -> Int
    var stat: (_ descriptor: Int32, _ metadata: UnsafeMutablePointer<Darwin.stat>) -> Int32
    var statAt: (
        _ parent: Int32,
        _ name: String,
        _ metadata: UnsafeMutablePointer<Darwin.stat>,
        _ flags: Int32
    ) -> Int32
    var unlinkAt: (_ parent: Int32, _ name: String, _ flags: Int32) -> Int32
    var renameAt: (_ parent: Int32, _ oldName: String, _ newName: String, _ flags: UInt32) -> Int32
    var fullSynchronize: (_ descriptor: Int32) -> Int32
    var synchronize: (_ descriptor: Int32) -> Int32
    var listNames: (_ descriptor: Int32) throws -> [String]

    static var live: Self {
        Self(
            makeDirectoryAt: { parent, name, mode in
                MetricDiagnosticsPOSIX.restoringErrno(name) { Darwin.mkdirat(parent, $0, mode) }
            },
            open: { path, flags in
                MetricDiagnosticsPOSIX.restoringErrno(path) { Darwin.open($0, flags) }
            },
            openAt: { parent, name, flags in
                MetricDiagnosticsPOSIX.restoringErrno(name) { Darwin.openat(parent, $0, flags) }
            },
            createAt: { parent, name, flags, mode in
                MetricDiagnosticsPOSIX.restoringErrno(name) {
                    Darwin.openat(parent, $0, flags, mode)
                }
            },
            close: { Darwin.close($0) },
            write: { Darwin.write($0, $1, $2) },
            read: { Darwin.read($0, $1, $2) },
            stat: { Darwin.fstat($0, $1) },
            statAt: { parent, name, metadata, flags in
                MetricDiagnosticsPOSIX.restoringErrno(name) {
                    Darwin.fstatat(parent, $0, metadata, flags)
                }
            },
            unlinkAt: { parent, name, flags in
                MetricDiagnosticsPOSIX.restoringErrno(name) { Darwin.unlinkat(parent, $0, flags) }
            },
            renameAt: { parent, oldName, newName, flags in
                MetricDiagnosticsPOSIX.restoringErrno(oldName, newName) { oldPath, newPath in
                    Darwin.renameatx_np(parent, oldPath, parent, newPath, flags)
                }
            },
            fullSynchronize: { Darwin.fcntl($0, F_FULLFSYNC) },
            synchronize: { Darwin.fsync($0) },
            listNames: Self.readNames
        )
    }

    private static func readNames(from descriptor: Int32) throws -> [String] {
        let iteratorDescriptor = Darwin.dup(descriptor)
        guard iteratorDescriptor >= 0 else {
            throw MetricDiagnosticsPOSIXError(code: errno)
        }
        guard let directory = Darwin.fdopendir(iteratorDescriptor) else {
            let code = errno
            _ = Darwin.close(iteratorDescriptor)
            throw MetricDiagnosticsPOSIXError(code: code)
        }
        defer { Darwin.closedir(directory) }

        var names: [String] = []
        while true {
            errno = 0
            guard let entry = Darwin.readdir(directory) else {
                if errno != 0 {
                    throw MetricDiagnosticsPOSIXError(code: errno)
                }
                return names
            }
            let name = withUnsafePointer(to: &entry.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXNAMLEN) + 1) {
                    String(cString: $0)
                }
            }
            if name != ".", name != ".." {
                names.append(name)
            }
        }
    }
}

nonisolated enum MetricDiagnosticsPOSIX {
    static func call<Result>(
        _ text: String,
        operation: (UnsafePointer<CChar>) -> Result
    ) -> (value: Result, code: Int32) {
        text.withCString { pointer in
            let value = operation(pointer)
            return (value, errno)
        }
    }

    static func restoringErrno<Result>(
        _ text: String,
        operation: (UnsafePointer<CChar>) -> Result
    ) -> Result {
        let result = call(text, operation: operation)
        errno = result.code
        return result.value
    }

    static func restoringErrno<Result>(
        _ first: String,
        _ second: String,
        operation: (UnsafePointer<CChar>, UnsafePointer<CChar>) -> Result
    ) -> Result {
        let result = first.withCString { firstPointer in
            second.withCString { secondPointer in
                let value = operation(firstPointer, secondPointer)
                return (value: value, code: errno)
            }
        }
        errno = result.code
        return result.value
    }
}
